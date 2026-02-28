import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../models/card_data.dart';
import '../providers/app_provider.dart';
import '../services/card_capture_service.dart';
import 'business_card_web_view.dart';
import 'login_bottom_sheet.dart';

/// 공통 명함 보내기 바텀시트
/// 전송 포맷: PNG 이미지 단독 (URL 텍스트 없이)
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

  String _displayName() =>
      widget.cardData?.fullName.trim().isNotEmpty == true
          ? widget.cardData!.fullName.trim()
          : widget.name;

  // ── 게스트 체크 ──────────────────────────────────────────────────────
  bool _guestCheck(AppProvider provider) {
    if (!provider.canAttemptGuestShare()) {
      LoginBottomSheet.show(context);
      return false;
    }
    return true;
  }

  // ── 전송 결과 스낵바 ──────────────────────────────────────────────────
  void _showResult(bool success, String channel, AppProvider provider) {
    if (!mounted) return;
    if (success) {
      widget.onRecordSend?.call(channel);
      if (provider.isGuest) provider.markGuestShareTrialUsed();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(_tr('명함을 보냈습니다!', 'Card sent!')),
          ]),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ── 이미지 캡처 (공통) ────────────────────────────────────────────────
  Future<XFile?> _captureImage() async {
    if (widget.cardData == null || !mounted) return null;
    return CardCaptureService.captureCard(context, widget.cardData!);
  }

  // ── 핵심 공유: PNG 이미지 단독 → OS 공유시트 ─────────────────────────
  Future<void> _shareImage(String channel, AppProvider provider) async {
    setState(() => _isLoading = true);
    final imageFile = await _captureImage();
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).pop();

    final name = _displayName();
    final subject = _tr('$name 명함', "$name's Card");

    ShareResult? result;
    try {
      result = await SharePlus.instance.share(
        imageFile != null
            ? ShareParams(files: [imageFile], subject: subject)
            : ShareParams(text: '$name 명함', subject: subject),
      );
    } catch (_) {
      return;
    }
    _showResult(result.status == ShareResultStatus.success, channel, provider);
  }

  // ── 문자(SMS): sms: URL → Messages 앱 직접 열기 ──────────────────────
  Future<void> _handleSms(AppProvider provider) async {
    setState(() => _isLoading = true);
    final imageFile = await _captureImage();
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).pop();

    // 이미지가 있으면 공유시트로 → 사용자가 Messages 선택
    if (imageFile != null) {
      final name = _displayName();
      ShareResult? result;
      try {
        result = await SharePlus.instance.share(
          ShareParams(files: [imageFile], subject: _tr('$name 명함', "$name's Card")),
        );
      } catch (_) {}
      _showResult(result?.status == ShareResultStatus.success, '문자(SMS)', provider);
      return;
    }

    // 이미지 캡처 실패 → SMS 텍스트로 대체
    final name = _displayName();
    final body = Uri.encodeComponent(_tr('$name 님의 명함입니다.', "$name's business card"));
    try {
      final uri = Uri.parse('sms:?body=$body');
      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: name));
    }
  }

  // ── 이메일: 이미지 공유시트 → 사용자가 Mail 선택 ─────────────────────
  Future<void> _handleEmail(AppProvider provider) async {
    setState(() => _isLoading = true);
    final imageFile = await _captureImage();
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).pop();

    final name = _displayName();
    final subject = _tr('$name 명함', "$name's Card");

    if (imageFile != null) {
      ShareResult? result;
      try {
        result = await SharePlus.instance.share(
          ShareParams(files: [imageFile], subject: subject),
        );
      } catch (_) {}
      _showResult(result?.status == ShareResultStatus.success, '이메일', provider);
      return;
    }

    // 이미지 없음 → mailto: 대체
    final subjectEnc = Uri.encodeComponent(subject);
    try {
      final uri = Uri.parse('mailto:?subject=$subjectEnc');
      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  // ── 웹카드 미리보기 ──────────────────────────────────────────────────
  Future<void> _handleWebPreview() async {
    Navigator.of(context).pop();
    if (!mounted || widget.cardData == null) return;
    await BusinessCardWebView.show(context, widget.cardData!);
  }

  Future<void> _doShare(String channel) async {
    final provider = context.read<AppProvider>();
    if (!_guestCheck(provider)) return;

    switch (channel) {
      case '카카오톡':
        await _shareImage('카카오톡', provider);
      case '문자(SMS)':
        await _handleSms(provider);
      case '이메일':
        await _handleEmail(provider);
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
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
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
                // ① 인터랙티브 미리보기
                if (widget.cardData != null) ...[
                  _SendOptionTile(
                    icon: Icons.preview_outlined,
                    iconColor: const Color(0xFF6366F1),
                    label: _tr('인터랙티브 카드 미리보기', 'Interactive Card Preview'),
                    sublabel: _tr('전화·이메일·카카오 아이콘 탭으로 직접 연결', 'Tap icons to call, email, kakao'),
                    onTap: _handleWebPreview,
                    bgColor: bgColor,
                    textColor: textColor,
                  ),
                  Divider(height: 1, color: dividerColor, indent: 72, endIndent: 24),
                ],
                // ② 카카오톡
                _SendOptionTile(
                  icon: Icons.chat_bubble_outline,
                  iconColor: const Color(0xFFFFE000),
                  label: _tr('카카오톡으로 보내기', 'Send via KakaoTalk'),
                  onTap: () => _doShare('카카오톡'),
                  bgColor: bgColor,
                  textColor: textColor,
                ),
                Divider(height: 1, color: dividerColor, indent: 72, endIndent: 24),
                // ③ 문자
                _SendOptionTile(
                  icon: Icons.sms_outlined,
                  iconColor: Colors.green.shade600,
                  label: _tr('문자(SMS)로 보내기', 'Send via SMS'),
                  onTap: () => _doShare('문자(SMS)'),
                  bgColor: bgColor,
                  textColor: textColor,
                ),
                Divider(height: 1, color: dividerColor, indent: 72, endIndent: 24),
                // ④ 이메일
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
  final String? sublabel;
  final VoidCallback onTap;
  final Color bgColor;
  final Color textColor;

  const _SendOptionTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.sublabel,
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    if (sublabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        sublabel!,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
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
