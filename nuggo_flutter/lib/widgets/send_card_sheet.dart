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
/// 카카오/문자/이메일: 명함 이미지(카드+푸터) → OS 공유시트로 전달.
class SendCardSheet extends StatefulWidget {
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

  @override
  State<SendCardSheet> createState() => _SendCardSheetState();
}

class _SendCardSheetState extends State<SendCardSheet> {
  bool _isLoading = false;

  String _tr(String ko, String en) => widget.language == 'en' ? en : ko;

  String _buildCardText() {
    final d = widget.cardData;
    if (d == null) return widget.name;
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
    return lines.isEmpty ? widget.name : lines.join('\n');
  }

  Future<void> _doShare(String channel) async {
    final provider = context.read<AppProvider>();

    if (!provider.canAttemptGuestShare()) {
      await LoginBottomSheet.show(context);
      return;
    }

    setState(() => _isLoading = true);

    // 1. 이미지 캡처 (bottom sheet가 열린 상태에서 → context 유효)
    XFile? imageFile;
    if (widget.cardData != null && mounted) {
      imageFile =
          await CardCaptureService.captureCard(context, widget.cardData!);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    // 2. sheet 닫기 (캡처 완료 후)
    if (mounted) Navigator.of(context).pop();

    // 3. OS 공유시트 열기
    final displayName = widget.cardData?.fullName.trim().isNotEmpty == true
        ? widget.cardData!.fullName.trim()
        : widget.name;
    final subject = _tr('$displayName 명함', '$displayName\'s Card');
    final text = _buildCardText();

    ShareResult? result;
    try {
      result = await SharePlus.instance.share(
        imageFile != null
            ? ShareParams(files: [imageFile], subject: subject, text: text)
            : ShareParams(text: text, subject: subject),
      );
    } catch (_) {
      // 공유시트 오류 → 클립보드 복사
      await Clipboard.setData(ClipboardData(text: text));
      return;
    }

    if (result.status == ShareResultStatus.success) {
      widget.onRecordSend?.call(channel);
      if (provider.isGuest) await provider.markGuestShareTrialUsed();
    } else if (result.status == ShareResultStatus.unavailable) {
      await Clipboard.setData(ClipboardData(text: text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey.shade900 : Colors.grey.shade100;
    final textColor = isDark ? Colors.white : Colors.black87;
    final dividerColor = isDark ? Colors.white12 : Colors.black12;
    final sheetBg = isDark ? const Color(0xFF1F2937) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
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
              // 로딩 중이면 로딩 인디케이터
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(
                        color: Color(0xFF6366F1),
                        strokeWidth: 2.5,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _tr('명함 이미지 생성 중...', 'Creating card image...'),
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                _SendOptionTile(
                  icon: Icons.chat_bubble_outline,
                  iconColor: const Color(0xFFFFE000),
                  label: _tr('카카오톡으로 보내기', 'Send via KakaoTalk'),
                  onTap: () => _doShare('카카오톡'),
                  bgColor: bgColor,
                  textColor: textColor,
                ),
                Divider(
                    height: 1,
                    color: dividerColor,
                    indent: 72,
                    endIndent: 24),
                _SendOptionTile(
                  icon: Icons.sms_outlined,
                  iconColor: Colors.green.shade600,
                  label: _tr('문자(SMS)로 보내기', 'Send via SMS'),
                  onTap: () => _doShare('문자(SMS)'),
                  bgColor: bgColor,
                  textColor: textColor,
                ),
                Divider(
                    height: 1,
                    color: dividerColor,
                    indent: 72,
                    endIndent: 24),
                _SendOptionTile(
                  icon: Icons.email_outlined,
                  iconColor: Colors.red.shade500,
                  label: _tr('이메일로 보내기', 'Send via Email'),
                  onTap: () => _doShare('이메일'),
                  bgColor: bgColor,
                  textColor: textColor,
                ),
              ],
            ],
          ),
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
