import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import '../constants/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/theme.dart';
import '../providers/app_provider.dart';
import '../models/card_data.dart';
import '../widgets/nuggo_logo.dart';
import '../widgets/send_card_sheet.dart';
import '../widgets/login_bottom_sheet.dart';

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

  static String _normalizePhone(String raw) {
    return raw
        .replaceAll(RegExp(r'[\s\-\(\)\.]'), '')
        .replaceAll(RegExp(r'[^\d+]'), '');
  }

  void _showMailChoice(BuildContext context, CardData data) {
    if (data.email.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Material(
          color: Theme.of(ctx).colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '메일 보내기',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _handleAction('mail', data.email, data);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.mail_outline,
                                size: 40,
                                color: Theme.of(ctx).colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '기본 메일 앱',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _handleAction('mail_naver', data.email, data);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/naver_mail_icon.png',
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '네이버 메일',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePortfolioAction(BuildContext context, CardData data) async {
    final url = (data.portfolioUrl ?? '').trim();
    final fileData = data.portfolioFile;
    if (url.isNotEmpty) {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('링크를 열 수 없습니다.')),
          );
        }
      }
    } else if (fileData != null &&
        fileData.isNotEmpty &&
        fileData.startsWith('data:')) {
      try {
        final parts = fileData.split(',');
        if (parts.length >= 2) {
          final bytes = base64Decode(parts.last);
          final mimeMatch = RegExp(r'data:([^;]+);').firstMatch(fileData);
          final mime = mimeMatch?.group(1) ?? 'application/octet-stream';
          final ext = mime.contains('pdf')
              ? 'pdf'
              : (mime.contains('image') ? 'jpg' : 'bin');
          await SharePlus.instance.share(ShareParams(
            files: [
              XFile.fromData(bytes, mimeType: mime, name: 'portfolio.$ext'),
            ],
          ));
        }
      } catch (_) {}
    }
  }

  Future<void> _handleAction(String type, String value, CardData data) async {
    if (value.isEmpty && type != 'share' && type != 'portfolio') return;
    if (type == 'share') {
      final provider = context.read<AppProvider>();
      final prereq = provider.validateGuestSharePrerequisites(data);
      if (prereq != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(prereq),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: provider.settings.language == 'en' ? 'Edit' : '작성하기',
              onPressed: () => provider.setActiveView(ViewType.editor),
            ),
          ),
        );
        return;
      }
      if (!provider.canAttemptGuestShare()) {
        if (mounted) await LoginBottomSheet.show(context);
        return;
      }
      String url = data.shareLink.trim().isEmpty ? 'https://nuggo.me' : data.shareLink;
      if (!url.startsWith('http')) url = 'https://$url';
      final result = await SharePlus.instance.share(
        ShareParams(
          text: url,
          subject: '명함: ${data.fullName.isNotEmpty ? data.fullName : "NUGGO"}',
        ),
      );
      if (provider.isGuest && (result.status.name == 'success')) {
        await provider.markGuestShareTrialUsed();
      }
      return;
    }
    if (type == 'mail') {
      _showMailChoice(context, data);
      return;
    }
    if (type == 'portfolio') {
      await _handlePortfolioAction(context, data);
      return;
    }
    final Uri? uri;
    switch (type) {
      case 'call':
        final tel = _normalizePhone(value);
        uri = tel.isNotEmpty ? Uri(scheme: 'tel', path: tel) : null;
        break;
      case 'sms':
        final sms = _normalizePhone(value);
        uri = sms.isNotEmpty ? Uri(scheme: 'sms', path: sms) : null;
        break;
      case 'mail_naver':
        uri = Uri.parse(
          'https://mail.naver.com/write?to=${Uri.encodeComponent(value)}',
        );
        break;
      case 'language':
      case 'website':
        uri = Uri.parse(value.startsWith('http') ? value : 'https://$value');
        break;
      case 'kakao':
        if (value.startsWith('http') || value.contains('open.kakao.com')) {
          uri = Uri.parse(value.startsWith('http') ? value : 'https://$value');
        } else if (value.trim().isNotEmpty) {
          uri = Uri.parse(
            'https://open.kakao.com/me/${Uri.encodeComponent(value.trim())}',
          );
        } else {
          uri = null;
        }
        break;
      default:
        uri = null;
    }
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크를 열 수 없습니다.')),
        );
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
                          image: theme.startsWith('http')
                              ? NetworkImage(theme)
                              : (File(theme).existsSync()
                                  ? FileImage(File(theme))
                                  : NetworkImage(
                                      AppConstants.initialCardData.theme))
                                  as ImageProvider,
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
                child: Column(
                  children: [
                    // ── 상단 바: 로고 + 보내기/QR/닫기 (겹침 없음) ──
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Opacity(
                            opacity: 0.9,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                NuggoLogo(
                                  size: 18,
                                  color: AppTheme.logoPrimary,
                                ),
                                const SizedBox(width: 5),
                                const NuggoTextLogo(
                                  fontSize: 13,
                                  variant: LogoVariant.brand,
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          _previewTopBtn(
                            icon: Icons.send,
                            isLight: isLight,
                            onTap: () async {
                              final prereq =
                                  provider.validateGuestSharePrerequisites(data);
                              if (prereq != null) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(prereq),
                                    behavior: SnackBarBehavior.floating,
                                    action: SnackBarAction(
                                      label: provider.settings.language == 'en'
                                          ? 'Edit'
                                          : '작성하기',
                                      onPressed: () => provider
                                          .setActiveView(ViewType.editor),
                                    ),
                                  ),
                                );
                                return;
                              }
                              if (!provider.canAttemptGuestShare()) {
                                if (context.mounted) {
                                  await LoginBottomSheet.show(context);
                                }
                                return;
                              }
                              String url = data.shareLink.trim().isEmpty
                                  ? 'https://nuggo.me'
                                  : data.shareLink;
                              if (!url.startsWith('http')) {
                                url = 'https://$url';
                              }
                              final name = data.fullName.isEmpty
                                  ? 'NUGGO'
                                  : data.fullName;
                              SendCardSheet.show(
                                context,
                                url: url,
                                name: name,
                                language: provider.settings.language,
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                          _previewTopBtn(
                            icon: Icons.qr_code_2,
                            isLight: isLight,
                            onTap: () => _showQrDialog(context, data),
                          ),
                          const SizedBox(width: 4),
                          _previewTopBtn(
                            icon: Icons.close,
                            isLight: isLight,
                            onTap: () => provider.setActiveView(
                              provider.previousView ?? ViewType.myCards,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 260),
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
                                'kakao',
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
                        ],   // Stack.children
                      ),     // Stack
                    ),       // Expanded
                  ],         // Column.children
                ),           // Column
              ),             // DefaultTextStyle.merge
            ),               // SafeArea
          ],
        );
      },
    );
  }

  Widget _previewTopBtn({
    required IconData icon,
    required bool isLight,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isLight
          ? Colors.black.withValues(alpha: 0.1)
          : Colors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 20,
            color: isLight ? Colors.black87 : Colors.white,
          ),
        ),
      ),
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
