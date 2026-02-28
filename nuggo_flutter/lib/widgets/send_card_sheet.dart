import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../models/card_data.dart';
import '../providers/app_provider.dart';
import '../services/card_url_generator.dart';
import 'login_bottom_sheet.dart';

/// 공통 명함 보내기 바텀시트
/// 전송 포맷: 웹 링크 (카카오 FeedTemplate / SMS / Email)
/// 상대방은 링크 미리보기 이미지(썸네일)를 보고 탭하면 인터랙티브 웹 명함이 열림
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

  String _cardUrl() => widget.cardData != null
      ? CardUrlGenerator.generate(widget.cardData!)
      : widget.url;

  // ── 카카오톡: FeedTemplate → 썸네일 이미지 + [명함 열기] 버튼 ──────────────
  Future<void> _handleKakao(AppProvider provider) async {
    Navigator.of(context).pop();
    final url = _cardUrl();
    final name = _displayName();
    final data = widget.cardData;
    final desc = [data?.jobTitle, data?.companyName]
        .where((s) => s != null && s.trim().isNotEmpty)
        .join(' · ');

    bool success = false;
    try {
      final feed = FeedTemplate(
        content: Content(
          title: '$name 님의 디지털 명함',
          description: desc.isNotEmpty ? desc : '탭하면 전화·이메일·카카오 바로 연결!',
          imageUrl: Uri.parse(
            'https://jaguar7307-hash.github.io/nuggo-card/og.png',
          ),
          link: Link(
            webUrl: Uri.parse(url),
            mobileWebUrl: Uri.parse(url),
          ),
        ),
        buttons: [
          Button(
            title: '명함 열기 →',
            link: Link(
              webUrl: Uri.parse(url),
              mobileWebUrl: Uri.parse(url),
            ),
          ),
        ],
      );

      final available =
          await ShareClient.instance.isKakaoTalkSharingAvailable();
      if (available) {
        final uri = await ShareClient.instance.shareDefault(template: feed);
        await ShareClient.instance.launchKakaoTalk(uri);
        success = true;
      } else {
        final shareUrl =
            await WebSharerClient.instance.makeDefaultUrl(template: feed);
        if (await canLaunchUrl(shareUrl)) {
          await launchUrl(shareUrl, mode: LaunchMode.externalApplication);
        }
        success = true;
      }
    } catch (_) {
      // SDK 실패 → OS 공유시트로 URL 공유
      try {
        final result = await SharePlus.instance.share(
          ShareParams(text: '$name 님의 디지털 명함\n$url'),
        );
        success = result.status == ShareResultStatus.success;
      } catch (_) {
        await Clipboard.setData(ClipboardData(text: url));
      }
    }
    if (mounted) _showResult(success, '카카오톡', provider);
  }

  // ── 문자(SMS): URL 포함 텍스트 → 받는 사람이 링크 미리보기(썸네일) 확인 후 탭 ──
  Future<void> _handleSms(AppProvider provider) async {
    Navigator.of(context).pop();
    final name = _displayName();
    final url = _cardUrl();
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
      }
    }
    if (mounted) _showResult(launched, '문자(SMS)', provider);
  }

  // ── 이메일: mailto 직접 실행 ──────────────────────────────────────────
  Future<void> _handleEmail(AppProvider provider) async {
    Navigator.of(context).pop();
    final name = _displayName();
    final url = _cardUrl();
    final subject = Uri.encodeComponent(
        _tr('$name 님의 디지털 명함', "$name's Digital Card"));
    final body = Uri.encodeComponent(
        '$name 님의 명함을 공유합니다.\n\n아래 링크를 탭하면 전화·이메일·카카오 바로 연결됩니다.\n$url');
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
              const SizedBox(height: 4),
              Text(
                _tr('받는 분이 명함 이미지를 보고 탭하면 바로 연결돼요', 'Recipient sees a preview and taps to connect'),
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
                  onTap: () => _doShare('카카오톡'),
                  textColor: textColor,
                ),
                Divider(height: 1, color: dividerColor, indent: 72, endIndent: 24),
                _SendOptionTile(
                  icon: Icons.sms_outlined,
                  iconColor: const Color(0xFF34D399),
                  iconBg: const Color(0xFF052E16),
                  label: _tr('문자(SMS)로 보내기', 'Send via SMS'),
                  onTap: () => _doShare('문자(SMS)'),
                  textColor: textColor,
                ),
                Divider(height: 1, color: dividerColor, indent: 72, endIndent: 24),
                _SendOptionTile(
                  icon: Icons.email_outlined,
                  iconColor: const Color(0xFFF87171),
                  iconBg: const Color(0xFF2D0F0F),
                  label: _tr('이메일로 보내기', 'Send via Email'),
                  onTap: () => _doShare('이메일'),
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
  final Color iconBg;
  final String label;
  final VoidCallback onTap;
  final Color textColor;

  const _SendOptionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
                color: textColor.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
