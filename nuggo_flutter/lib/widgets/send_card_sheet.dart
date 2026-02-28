import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';

import '../models/card_data.dart';
import '../providers/app_provider.dart';
import '../services/card_capture_service.dart';
import 'login_bottom_sheet.dart';

/// 공통 명함 보내기 바텀시트 (내 명함/에디터/미리보기 통일)
/// 카카오/문자/이메일 모두 명함 이미지를 OS 공유시트로 전달.
class SendCardSheet extends StatelessWidget {
  final String url;
  final String name;
  final String language;
  final CardData? cardData;
  final void Function(String method)? onRecordSend;

  const SendCardSheet({
    super.key,
    required this.url,
    required this.name,
    required this.language,
    this.cardData,
    this.onRecordSend,
  });

  static void show(
    BuildContext context, {
    required String url,
    required String name,
    required String language,
    CardData? cardData,
    void Function(String)? onRecordSend,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SendCardSheet(
        url: url,
        name: name,
        language: language,
        cardData: cardData,
        onRecordSend: onRecordSend,
      ),
    );
  }

  String _tr(String ko, String en) => language == 'en' ? en : ko;

  /// 명함 텍스트 (이미지 캡처 실패 시 폴백)
  String _buildCardText() {
    final d = cardData;
    if (d == null) return name;
    final lines = <String>[];
    final parts = <String>[];
    if (d.fullName.trim().isNotEmpty) parts.add(d.fullName.trim());
    if (d.jobTitle.trim().isNotEmpty) parts.add(d.jobTitle.trim());
    if (d.companyName.trim().isNotEmpty) parts.add(d.companyName.trim());
    if (parts.isNotEmpty) lines.add(parts.join(' | '));
    if (d.phone.trim().isNotEmpty) lines.add('📞 ${d.phone.trim()}');
    if (d.email.trim().isNotEmpty) lines.add('✉️ ${d.email.trim()}');
    if (d.kakao.trim().isNotEmpty) lines.add('💬 ${d.kakao.trim()}');
    if (d.website.trim().isNotEmpty) lines.add('🔗 ${d.website.trim()}');
    if (d.address.trim().isNotEmpty) lines.add('📍 ${d.address.trim()}');
    return lines.isEmpty ? name : lines.join('\n');
  }

  /// 명함 이미지 캡처 → OS 공유시트로 전달.
  /// 캡처 실패 시 텍스트로 폴백.
  Future<void> _shareCardImage(
    BuildContext context,
    AppProvider provider,
    String channel,
  ) async {
    if (!provider.canAttemptGuestShare()) {
      await LoginBottomSheet.show(context);
      return;
    }

    // 로딩 표시 (캡처에 ~250ms 소요)
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr('명함 이미지 준비 중...', 'Preparing card image...')),
          duration: const Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    XFile? imageFile;
    if (cardData != null && context.mounted) {
      imageFile = await CardCaptureService.captureCard(context, cardData!);
    }

    if (!context.mounted) return;

    final displayName = cardData?.fullName.trim().isNotEmpty == true
        ? cardData!.fullName.trim()
        : name;
    final subject = _tr('$displayName 명함', '$displayName\'s Card');
    final text = _buildCardText();

    ShareResult result;
    try {
      if (imageFile != null) {
        result = await SharePlus.instance.share(
          ShareParams(
            files: [imageFile],
            subject: subject,
            text: text,
          ),
        );
      } else {
        // 이미지 캡처 실패 → 텍스트로 폴백
        result = await SharePlus.instance.share(
          ShareParams(text: text, subject: subject),
        );
      }

      if (result.status == ShareResultStatus.success && provider.isGuest) {
        await provider.markGuestShareTrialUsed();
      } else if (result.status == ShareResultStatus.unavailable) {
        // 공유시트 사용 불가 → 클립보드 복사
        if (context.mounted) {
          await Clipboard.setData(ClipboardData(text: text));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _tr('명함 정보를 복사했어요. 붙여넣기 해주세요.', 'Card info copied!'),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        await Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _tr('명함 정보를 복사했어요. 붙여넣기 해주세요.', 'Card info copied!'),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleKakao(BuildContext context) async {
    onRecordSend?.call(_tr('카카오톡', 'KakaoTalk'));
    Navigator.pop(context);
    final provider = context.read<AppProvider>();
    await _shareCardImage(context, provider, 'kakao');
  }

  void _handleSms(BuildContext context) async {
    onRecordSend?.call(_tr('문자(SMS)', 'SMS'));
    Navigator.pop(context);
    final provider = context.read<AppProvider>();
    await _shareCardImage(context, provider, 'sms');
  }

  void _handleEmail(BuildContext context) async {
    onRecordSend?.call(_tr('이메일', 'Email'));
    Navigator.pop(context);
    final provider = context.read<AppProvider>();
    await _shareCardImage(context, provider, 'email');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey.shade900 : Colors.grey.shade100;
    final textColor = isDark ? Colors.white : Colors.black87;
    final dividerColor = isDark ? Colors.white12 : Colors.black12;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 3,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              _tr('명함 보내기', 'Send Card'),
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            _SendOptionTile(
              icon: Icons.chat_bubble_outline,
              iconColor: const Color(0xFFFFE000),
              label: _tr('카카오톡으로 보내기', 'Send via KakaoTalk'),
              onTap: () => _handleKakao(context),
              bgColor: bgColor,
              textColor: textColor,
            ),
            Divider(height: 1, color: dividerColor, indent: 72, endIndent: 24),
            _SendOptionTile(
              icon: Icons.sms_outlined,
              iconColor: Colors.green.shade600,
              label: _tr('문자(SMS)로 보내기', 'Send via SMS'),
              onTap: () => _handleSms(context),
              bgColor: bgColor,
              textColor: textColor,
            ),
            Divider(height: 1, color: dividerColor, indent: 72, endIndent: 24),
            _SendOptionTile(
              icon: Icons.email_outlined,
              iconColor: Colors.red.shade500,
              label: _tr('이메일로 보내기', 'Send via Email'),
              onTap: () => _handleEmail(context),
              bgColor: bgColor,
              textColor: textColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _SendOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final Color bgColor;
  final Color textColor;

  const _SendOptionTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: textColor.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
