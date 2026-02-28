import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../models/card_data.dart';
import '../providers/app_provider.dart';
import '../services/card_url_generator.dart';
import 'business_card_web_view.dart';
import 'login_bottom_sheet.dart';

/// 공통 명함 보내기 바텀시트
/// 전송 방식: 웹 카드 URL 링크 공유
/// 수신자가 링크를 탭하면 → docs/index.html(GitHub Pages) → 아이콘 실제 동작
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

  /// 웹 카드 URL (GitHub Pages 인터랙티브 명함)
  String _cardUrl() => widget.cardData != null
      ? CardUrlGenerator.generate(widget.cardData!)
      : widget.url;

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
            Text(_tr('명함 링크를 보냈습니다!', 'Card link sent!')),
          ]),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ── 카카오톡: OS 공유시트 → 링크 전송
  //    수신자: 링크 미리보기(OG 이미지) → 탭 → 웹 명함 오픈 → 아이콘 실제 동작
  Future<void> _handleKakao(AppProvider provider) async {
    final url = _cardUrl();
    final name = _displayName();
    bool success = false;
    try {
      final result = await SharePlus.instance.share(
        ShareParams(text: '$name 님의 디지털 명함\n$url'),
      );
      success = result.status == ShareResultStatus.success;
    } catch (_) {}
    if (mounted) _showResult(success, '카카오톡', provider);
    if (mounted) Navigator.of(context).pop();
  }

  // ── 문자(SMS): sms: 스킴으로 URL 포함 전송
  Future<void> _handleSms(AppProvider provider) async {
    final url = _cardUrl();
    final name = _displayName();
    final body = Uri.encodeComponent('[$name 님의 디지털 명함]\n$url');
    bool launched = false;
    try {
      final uri = Uri.parse('sms:?body=$body');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        launched = true;
      }
    } catch (_) {}
    if (!launched) {
      try {
        final result = await SharePlus.instance.share(
          ShareParams(text: '[$name 님의 디지털 명함]\n$url'),
        );
        launched = result.status == ShareResultStatus.success;
      } catch (_) {
        await Clipboard.setData(ClipboardData(text: url));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_tr('링크가 클립보드에 복사됐습니다', 'Link copied to clipboard')),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
    if (mounted) _showResult(launched, '문자(SMS)', provider);
    if (mounted) Navigator.of(context).pop();
  }

  // ── 이메일: mailto: 스킴으로 URL 포함 전송
  Future<void> _handleEmail(AppProvider provider) async {
    final url = _cardUrl();
    final name = _displayName();
    final subject = Uri.encodeComponent(
        _tr('$name 님의 디지털 명함', "$name's Digital Business Card"));
    final body = Uri.encodeComponent(
        '$name 님의 명함을 공유합니다.\n\n아래 링크를 탭하면 전화·이메일·카카오 바로 연결됩니다.\n\n$url');
    bool launched = false;
    try {
      final uri = Uri.parse('mailto:?subject=$subject&body=$body');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        launched = true;
      }
    } catch (_) {}
    if (!launched) {
      try {
        final result = await SharePlus.instance.share(
          ShareParams(text: '[$name 님의 디지털 명함]\n$url'),
        );
        launched = result.status == ShareResultStatus.success;
      } catch (_) {
        await Clipboard.setData(ClipboardData(text: url));
      }
    }
    if (mounted) _showResult(launched, '이메일', provider);
    if (mounted) Navigator.of(context).pop();
  }

  // ── 인터랙티브 웹 명함 미리보기 (앱 내 WebView)
  Future<void> _handleWebPreview() async {
    Navigator.of(context).pop();
    if (!mounted || widget.cardData == null) return;
    await BusinessCardWebView.show(context, widget.cardData!);
  }

  Future<void> _doShare(String channel) async {
    if (_isLoading) return;
    final provider = context.read<AppProvider>();
    if (!_guestCheck(provider)) return;

    setState(() => _isLoading = true);
    try {
      switch (channel) {
        case '카카오톡':
          await _handleKakao(provider);
        case '문자(SMS)':
          await _handleSms(provider);
        case '이메일':
          await _handleEmail(provider);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              const SizedBox(height: 4),
              Text(
                _tr('링크 탭하면 전화·이메일·카카오 바로 연결', 'Tap link → call·email·kakao instantly'),
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: textColor.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: CircularProgressIndicator(
                    color: Color(0xFF6366F1),
                    strokeWidth: 2.5,
                  ),
                )
              else ...[
                _SendOptionTile(
                  icon: Icons.chat_bubble_outline,
                  iconColor: const Color(0xFFFFE000),
                  iconBg: const Color(0xFF3A1F00),
                  label: _tr('카카오톡으로 보내기', 'Send via KakaoTalk'),
                  sublabel: _tr('링크 미리보기 → 탭 → 인터랙티브 명함', 'Link preview → tap → interactive card'),
                  onTap: () => _doShare('카카오톡'),
                  textColor: textColor,
                ),
                Divider(height: 1, color: dividerColor, indent: 72, endIndent: 24),
                _SendOptionTile(
                  icon: Icons.sms_outlined,
                  iconColor: const Color(0xFF34D399),
                  iconBg: const Color(0xFF052E16),
                  label: _tr('문자(SMS)로 보내기', 'Send via SMS'),
                  sublabel: _tr('링크 포함 문자 전송', 'Send text with card link'),
                  onTap: () => _doShare('문자(SMS)'),
                  textColor: textColor,
                ),
                Divider(height: 1, color: dividerColor, indent: 72, endIndent: 24),
                _SendOptionTile(
                  icon: Icons.email_outlined,
                  iconColor: const Color(0xFFF87171),
                  iconBg: const Color(0xFF2D0F0F),
                  label: _tr('이메일로 보내기', 'Send via Email'),
                  sublabel: _tr('링크 포함 이메일 전송', 'Send email with card link'),
                  onTap: () => _doShare('이메일'),
                  textColor: textColor,
                ),
                if (widget.cardData != null) ...[
                  Divider(height: 1, color: dividerColor, indent: 72, endIndent: 24),
                  _SendOptionTile(
                    icon: Icons.preview_outlined,
                    iconColor: const Color(0xFF818CF8),
                    iconBg: const Color(0xFF1E1B4B),
                    label: _tr('인터랙티브 카드 미리보기', 'Interactive Card Preview'),
                    sublabel: _tr('앱 내 웹뷰로 명함 열기', 'Open card in in-app browser'),
                    onTap: _handleWebPreview,
                    textColor: textColor,
                  ),
                ],
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
  final Color iconBg;
  final String label;
  final String sublabel;
  final VoidCallback onTap;
  final Color textColor;

  const _SendOptionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.sublabel,
    required this.onTap,
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(11),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      sublabel,
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        color: textColor.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: textColor.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
