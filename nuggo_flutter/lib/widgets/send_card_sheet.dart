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
/// 핵심: URL 공유 (GitHub Pages 인터랙티브 카드) + 채널별 직접 실행
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

  bool _guestCheck(AppProvider provider) {
    if (!provider.canAttemptGuestShare()) {
      LoginBottomSheet.show(context);
      return false;
    }
    return true;
  }

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

  // ── 공통: URL 생성 + 공유 텍스트 ──────────────────────────────────────
  String _cardUrl() {
    if (widget.cardData != null) return CardUrlGenerator.generate(widget.cardData!);
    return widget.url.isNotEmpty ? widget.url : 'https://github.com/jaguar7307-hash/nuggo';
  }

  String _shareBody() {
    if (widget.cardData != null) return CardUrlGenerator.shareText(widget.cardData!);
    return _buildCardText();
  }

  String _displayName() => widget.cardData?.fullName.trim().isNotEmpty == true
      ? widget.cardData!.fullName.trim()
      : widget.name;

  // ── 카카오톡: URL + 인터랙티브 링크 텍스트 → OS 공유시트 ─────────────
  Future<void> _handleKakao(AppProvider provider) async {
    Navigator.of(context).pop();
    final url = _cardUrl();
    final name = _displayName();
    final text = '${name} 님의 디지털 명함\n탭하면 전화/이메일/카카오 바로 연결!\n$url';

    ShareResult? result;
    try {
      result = await SharePlus.instance.share(
        ShareParams(text: text, subject: '$name 명함'),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      return;
    }
    _showResult(result.status == ShareResultStatus.success, '카카오톡', provider);
  }

  // ── 문자(SMS): sms: URL → Messages 앱 직접 열기 ──────────────────────
  Future<void> _handleSms(AppProvider provider) async {
    Navigator.of(context).pop();
    final body = Uri.encodeComponent(_shareBody());
    final uri = Uri.parse('sms:?body=$body');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showResult(true, '문자(SMS)', provider);
        return;
      }
    } catch (_) {}
    // 실패 → 클립보드 복사
    await Clipboard.setData(ClipboardData(text: _shareBody()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr('명함 링크를 복사했어요. 문자에 붙여넣기 하세요.', 'Card link copied!')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── 이메일: mailto: URL → 메일 앱 직접 열기 ──────────────────────────
  Future<void> _handleEmail(AppProvider provider) async {
    Navigator.of(context).pop();
    final name = _displayName();
    final subject = Uri.encodeComponent(_tr('$name 명함', '$name\'s Card'));
    final body = Uri.encodeComponent(_shareBody());
    final uri = Uri.parse('mailto:?subject=$subject&body=$body');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showResult(true, '이메일', provider);
        return;
      }
    } catch (_) {}
    // 실패 → share_plus OS 공유시트 대체
    try {
      await SharePlus.instance.share(
        ShareParams(text: _shareBody(), subject: '$name 명함'),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: _shareBody()));
    }
  }

  // ── 웹카드 미리보기 (인터랙티브 WebView) ─────────────────────────────
  Future<void> _handleWebPreview() async {
    Navigator.of(context).pop();
    if (!mounted) return;
    if (widget.cardData != null) {
      await BusinessCardWebView.show(context, widget.cardData!);
    }
  }

  // ── 링크 복사 ──────────────────────────────────────────────────────────
  Future<void> _handleCopyLink(AppProvider provider) async {
    Navigator.of(context).pop();
    final url = _cardUrl();
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.link, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(_tr('링크를 복사했어요!', 'Link copied!')),
          ]),
          backgroundColor: const Color(0xFF6366F1),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
    _showResult(true, '링크복사', provider);
  }

  Future<void> _doShare(String channel) async {
    final provider = context.read<AppProvider>();
    if (!_guestCheck(provider)) return;

    switch (channel) {
      case '카카오톡':
        await _handleKakao(provider);
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
                // ① 웹카드 미리보기 (앱 내 인터랙티브 확인)
                if (widget.cardData != null) ...[
                  _SendOptionTile(
                    icon: Icons.preview_outlined,
                    iconColor: const Color(0xFF6366F1),
                    label: _tr('인터랙티브 카드 미리보기', 'Interactive Card Preview'),
                    sublabel: _tr('탭하면 전화/이메일/카카오 바로 연결', 'Tap icons to call, email, kakao'),
                    onTap: _handleWebPreview,
                    bgColor: bgColor,
                    textColor: textColor,
                  ),
                  Divider(height: 1, color: dividerColor, indent: 72, endIndent: 24),
                ],
                // ② 링크 복사 (URL 복사해서 아무 앱에나 붙여넣기)
                _SendOptionTile(
                  icon: Icons.link,
                  iconColor: const Color(0xFF6366F1),
                  label: _tr('링크 복사', 'Copy Link'),
                  sublabel: _tr('받는 분이 탭하면 인터랙티브 명함 열림', 'Recipient taps to open interactive card'),
                  onTap: () {
                    final provider = context.read<AppProvider>();
                    if (_guestCheck(provider)) _handleCopyLink(provider);
                  },
                  bgColor: bgColor,
                  textColor: textColor,
                ),
                Divider(height: 1, color: dividerColor, indent: 72, endIndent: 24),
                // ③ 카카오톡
                _SendOptionTile(
                  icon: Icons.chat_bubble_outline,
                  iconColor: const Color(0xFFFFE000),
                  label: _tr('카카오톡으로 보내기', 'Send via KakaoTalk'),
                  onTap: () => _doShare('카카오톡'),
                  bgColor: bgColor,
                  textColor: textColor,
                ),
                Divider(height: 1, color: dividerColor, indent: 72, endIndent: 24),
                // ④ 문자
                _SendOptionTile(
                  icon: Icons.sms_outlined,
                  iconColor: Colors.green.shade600,
                  label: _tr('문자(SMS)로 보내기', 'Send via SMS'),
                  onTap: () => _doShare('문자(SMS)'),
                  bgColor: bgColor,
                  textColor: textColor,
                ),
                Divider(height: 1, color: dividerColor, indent: 72, endIndent: 24),
                // ⑤ 이메일
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
