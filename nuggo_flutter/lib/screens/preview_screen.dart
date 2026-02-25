import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_provider.dart';
import '../models/card_data.dart';
import '../widgets/nuggo_logo.dart';

/// 원본 React PreviewView와 동일: 풀스크린 명함 배경 + 로고/슬로건/이름/3x2 액션/주소/하단 CTA
class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool _showNotification = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showNotification = false);
    });
  }

  bool _isHexTheme(String theme) => theme.startsWith('#');
  bool _isLightBg(String theme) {
    if (!_isHexTheme(theme)) return false;
    final hex = theme.replaceAll('#', '');
    final fullHex = hex.length == 3 ? hex.split('').map((c) => '$c$c').join('') : hex;
    final r = int.tryParse(fullHex.substring(0, 2), radix: 16) ?? 0;
    final g = int.tryParse(fullHex.substring(2, 4), radix: 16) ?? 0;
    final b = int.tryParse(fullHex.substring(4, 6), radix: 16) ?? 0;
    final yiq = ((r * 299) + (g * 587) + (b * 114)) / 1000;
    return yiq >= 128;
  }

  Color _parseHex(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  void _showQrDialog(BuildContext context, CardData data) {
    String url = data.shareLink.trim();
    if (url.isEmpty) url = 'https://nuggo.me';
    if (!url.startsWith('http')) url = 'https://$url';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('명함 QR 코드'),
        content: SizedBox(
          width: 300,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: url,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF1A237E),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  url,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(String type, String value, CardData data) async {
    if (value.isEmpty && type != 'share') return;
    if (type == 'share') {
      String url = data.shareLink.trim().isEmpty ? 'https://nuggo.me' : data.shareLink;
      if (!url.startsWith('http')) url = 'https://$url';
      await SharePlus.instance.share(
        ShareParams(
          text: url,
          subject: '명함: ${data.fullName.isNotEmpty ? data.fullName : "NUGGO"}',
        ),
      );
      return;
    }
    final Uri? uri;
    switch (type) {
      case 'call':
        uri = Uri(scheme: 'tel', path: value);
        break;
      case 'sms':
        uri = Uri(scheme: 'sms', path: value);
        break;
      case 'mail':
        uri = Uri(scheme: 'mailto', path: value);
        break;
      case 'language':
        uri = Uri.parse(value.startsWith('http') ? value : 'https://$value');
        break;
      case 'portfolio':
        uri = Uri.parse(value.startsWith('http') ? value : 'https://$value');
        break;
      case 'forum':
        uri = Uri.parse('https://search.naver.com/search.naver?query=$value');
        break;
      default:
        uri = null;
    }
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('링크를 열 수 없습니다.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final data = provider.currentCardData;
        final theme = data.theme;
        final isHex = _isHexTheme(theme);
        final isLight = _isLightBg(theme);
        final textColor = isLight ? Colors.black87 : Colors.white;
        final subColor = isLight ? Colors.grey.shade600 : Colors.white70;
        final iconBg = isLight
            ? Colors.black.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.1);
        final createBtn = const Color(0xFFFF8A3D).withValues(alpha: 0.6);
        const lang = 'ko';

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: isHex ? _parseHex(theme) : const Color(0xFF1a1c1e),
                  image: !isHex
                      ? DecorationImage(
                          image: NetworkImage(theme),
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        )
                      : null,
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                color: isLight
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.2),
              ),
            ),
            SafeArea(
              child: DefaultTextStyle.merge(
                style: const TextStyle(
                  decoration: TextDecoration.none,
                  decorationColor: Colors.transparent,
                ),
                child: Stack(
                children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 56, 20, 260),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 36,
                            child: AnimatedOpacity(
                              opacity: _showNotification ? 1 : 0,
                              duration: const Duration(milliseconds: 300),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.visibility,
                                        size: 11,
                                        color: Colors.green.shade300,
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        '상대방에게 보이는 화면입니다',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 24,
                            height: 1,
                            color: (isLight ? Colors.black : Colors.white)
                                .withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '"${data.slogan}"',
                            style: GoogleFonts.songMyung(
                              fontSize: 19,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.2,
                              color: textColor.withValues(alpha: 0.92),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (data.profileImage != null &&
                              data.profileImage!.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _buildPreviewProfileImage(data.profileImage!),
                          ],
                          const SizedBox(height: 14),
                          Text(
                            data.fullName,
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            data.jobTitle.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                              color: Color(0xFFd4b98c),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            data.companyName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 2,
                              color: textColor.withValues(alpha: 0.65),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 3,
                            mainAxisSpacing: 2,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.82,
                            children: [
                              _previewAction(
                                context,
                                data,
                                Icons.phone,
                                'PHONE',
                                'call',
                                data.phone,
                                iconBg,
                                subColor,
                              ),
                              _previewAction(
                                context,
                                data,
                                Icons.chat_bubble,
                                'MESSAGE',
                                'sms',
                                data.sms,
                                iconBg,
                                subColor,
                              ),
                              _previewAction(
                                context,
                                data,
                                Icons.mail,
                                'EMAIL',
                                'mail',
                                data.email,
                                iconBg,
                                subColor,
                              ),
                              _previewAction(
                                context,
                                data,
                                Icons.language,
                                'WEBSITE',
                                'language',
                                data.website,
                                iconBg,
                                subColor,
                              ),
                              _previewAction(
                                context,
                                data,
                                Icons.chat_outlined,
                                'KAKAO',
                                'forum',
                                data.kakao,
                                iconBg,
                                subColor,
                              ),
                              _previewAction(
                                context,
                                data,
                                Icons.share,
                                'SNS',
                                'share',
                                data.shareLink,
                                iconBg,
                                subColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          _previewAction(
                            context,
                            data,
                            Icons.folder_open,
                            '포트폴리오',
                            'portfolio',
                            data.portfolioUrl ?? '',
                            iconBg,
                            subColor,
                          ),
                          if (data.address.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 300),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isLight
                                      ? Colors.white.withValues(alpha: 0.42)
                                      : Colors.black.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 10,
                                      color: textColor.withValues(alpha: 0.9),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        data.address.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                          color: textColor.withValues(alpha: 0.9),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Opacity(
                        opacity: 0.75,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            NuggoLogo(
                              size: 24,
                              color:
                                  isLight ? NuggoLogo.defaultColor : Colors.white,
                            ),
                            const SizedBox(width: 6),
                            const NuggoTextLogo(
                              fontSize: 16,
                              variant: LogoVariant.brand,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    right: 20,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          color: isLight
                              ? Colors.black.withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.12),
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () async {
                              String url = data.shareLink.trim().isEmpty
                                  ? 'https://nuggo.me'
                                  : data.shareLink;
                              if (!url.startsWith('http')) url = 'https://$url';
                              await SharePlus.instance.share(
                                ShareParams(
                                  text: url,
                                  subject:
                                      '명함: ${data.fullName.isNotEmpty ? data.fullName : "NUGGO"}',
                                ),
                              );
                            },
                            customBorder: const CircleBorder(),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: Icon(
                                Icons.send,
                                size: 22,
                                color: isLight ? Colors.black87 : Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: isLight
                              ? Colors.black.withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.12),
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () => _showQrDialog(context, data),
                            customBorder: const CircleBorder(),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: Icon(
                                Icons.qr_code_2,
                                size: 22,
                                color: isLight ? Colors.black87 : Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: isLight
                              ? Colors.black.withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.12),
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () => provider.setActiveView(
                              provider.previousView ?? ViewType.myCards,
                            ),
                            customBorder: const CircleBorder(),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: Icon(
                                Icons.close,
                                size: 24,
                                color: isLight ? Colors.black87 : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 72,
                    bottom: 72,
                    child: Text(
                      lang == 'ko'
                          ? '나의 모든 것을 탑카드 하나로!'
                          : 'All your identity in one Tap Card!',
                      style: GoogleFonts.songMyung(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                        color: textColor.withValues(alpha: 0.45),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 72,
                    bottom: 8,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Material(
                        color: createBtn,
                        borderRadius: BorderRadius.circular(28),
                        child: InkWell(
                          onTap: () => provider.setActiveView(ViewType.editor),
                          borderRadius: BorderRadius.circular(28),
                          child: SizedBox(
                            height: 52,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.style, size: 20, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  lang == 'ko'
                                      ? '나도 명함 만들기'
                                      : 'Create Your Own Card',
                                  style: const TextStyle(
                                      fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 24,
                    bottom: 16,
                    child: Material(
                      color: iconBg,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                lang == 'ko'
                                    ? '연락처 저장 기능은 준비 중입니다.'
                                    : 'Save Contact coming soon.',
                              ),
                            ),
                          );
                        },
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(Icons.person_add, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreviewProfileImage(String url) {
    try {
      if (url.startsWith('data:')) {
        final bytes = base64Decode(url.split(',').last);
        return Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.2), width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
              ),
            ],
            image: DecorationImage(
              image: MemoryImage(bytes),
              fit: BoxFit.cover,
            ),
          ),
        );
      }
      return Container(
        width: 128,
        height: 128,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.2), width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
            ),
          ],
          image: DecorationImage(
            image: NetworkImage(url),
            fit: BoxFit.cover,
          ),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Widget _previewAction(
    BuildContext context,
    CardData data,
    IconData icon,
    String label,
    String type,
    String value,
    Color bgColor,
    Color textColor,
  ) {
    const double touchSize = 68;
    final bool enabled = value.isNotEmpty || type == 'share';
    final double opacity = enabled ? 1.0 : 0.3;
    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: touchSize,
            height: touchSize,
            child: Material(
              color: bgColor,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: enabled ? () => _handleAction(type, value, data) : null,
                customBorder: const CircleBorder(),
                splashColor: textColor.withValues(alpha: 0.2),
                highlightColor: textColor.withValues(alpha: 0.1),
                child: Center(
                  child: Icon(icon, size: 24, color: textColor),
                ),
              ),
            ),
          ),
          const SizedBox(height: 0),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
