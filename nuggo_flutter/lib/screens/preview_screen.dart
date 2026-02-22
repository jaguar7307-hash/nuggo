import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(
        const AssetImage('assets/images/naver_mail_icon.png'),
        context,
      );
    });
  }

  bool _isHexTheme(String theme) => theme.startsWith('#');
  bool _isLightBg(String theme) {
    if (!_isHexTheme(theme)) return false;
    final hex = theme.replaceAll('#', '');
    final fullHex = hex.length == 3
        ? hex.split('').map((c) => '$c$c').join('')
        : hex;
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

  /// 전화번호 정규화: 공백·하이픈·괄호 제거 (tel: URI 호환)
  String _normalizePhone(String raw) {
    return raw.replaceAll(RegExp(r'[\s\-\(\)\.]'), '').replaceAll(RegExp(r'[^\d+]'), '');
  }

  Future<void> _handlePortfolioAction(CardData data) async {
    final url = (data.portfolioUrl ?? '').trim();
    final fileData = data.portfolioFile;
    if (url.isNotEmpty) {
      await _handleAction('portfolio', url.startsWith('http') ? url : 'https://$url', data);
    } else if (fileData != null && fileData.isNotEmpty && fileData.startsWith('data:')) {
      try {
        final parts = fileData.split(',');
        if (parts.length >= 2) {
          final bytes = base64Decode(parts.last);
          final mimeMatch = RegExp(r'data:([^;]+);').firstMatch(fileData);
          final mime = mimeMatch?.group(1) ?? 'application/octet-stream';
          final ext = mime.contains('pdf') ? 'pdf' : (mime.contains('image') ? 'jpg' : 'bin');
          await SharePlus.instance.share(ShareParams(
            files: [XFile.fromData(bytes, mimeType: mime, name: 'portfolio.$ext')],
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('파일을 열 수 없습니다.')),
          );
        }
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('포트폴리오 링크 또는 파일을 입력해주세요.')),
      );
    }
  }

  Future<void> _handleAction(String type, String value, CardData data) async {
    if (value.isEmpty && type != 'share') {
      if (mounted && type == 'forum') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카카오톡 오픈채팅 ID 또는 링크를 입력해 주세요.')),
        );
      }
      return;
    }
    if (type == 'share') {
      String url = data.shareLink.trim().isEmpty
          ? 'https://nuggo.me'
          : data.shareLink;
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
        final tel = _normalizePhone(value);
        uri = tel.isNotEmpty ? Uri(scheme: 'tel', path: tel) : null;
        break;
      case 'sms':
        final sms = _normalizePhone(value);
        uri = sms.isNotEmpty ? Uri(scheme: 'sms', path: sms) : null;
        break;
      case 'mail':
        uri = Uri(scheme: 'mailto', path: value);
        break;
      case 'mail_naver':
        uri = Uri.parse(
          'https://mail.naver.com/write?to=${Uri.encodeComponent(value)}',
        );
        break;
      case 'language':
        uri = Uri.parse(value.startsWith('http') ? value : 'https://$value');
        break;
      case 'portfolio':
        final url = value.trim();
        uri = url.isNotEmpty
            ? Uri.parse(url.startsWith('http') ? url : 'https://$url')
            : null;
        break;
      case 'forum':
        if (value.startsWith('http') || value.contains('open.kakao.com')) {
          uri = Uri.parse(value.startsWith('http') ? value : 'https://$value');
        } else if (value.trim().isNotEmpty) {
          uri = Uri.parse('https://open.kakao.com/me/${Uri.encodeComponent(value.trim())}');
        } else {
          uri = null;
        }
        break;
      case 'map':
        uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(value)}',
        );
        break;
      default:
        uri = null;
    }
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('열 수 없는 링크입니다.')),
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
            // 1. 풀스크린 배경 (명함 테마) - 상대방 폰 화면에 꽉 차게
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
            // 2. 오버레이
            Positioned.fill(
              child: Container(
                color: isLight
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.2),
              ),
            ),
            // 3. 콘텐츠 - 스크롤 없이 한 화면에 맞춤
            SafeArea(
              child: SizedBox.expand(
                child: LayoutBuilder(
                builder: (context, constraints) {
                  final h = constraints.maxHeight;
                  final w = constraints.maxWidth;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 56, left: 16, right: 16, bottom: 80),
                          child: RepaintBoundary(
                            child: FittedBox(
                              fit: BoxFit.contain,
                              alignment: const Alignment(0, 0.15),
                              child: SizedBox(
                              width: w - 32,
                              height: h - 128,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  if (data.slogan.isNotEmpty)
                                    Text(
                                      '"${data.slogan}"',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                        height: 1.0,
                                        decoration: TextDecoration.none,
                                        color: textColor.withValues(alpha: 0.9),
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (data.profileImage != null && data.profileImage!.isNotEmpty)
                                    SizedBox(
                                      width: 72,
                                      height: 72,
                                      child: FittedBox(
                                        fit: BoxFit.contain,
                                        child: SizedBox(
                                          width: 128,
                                          height: 128,
                                          child: _buildPreviewProfileImage(data.profileImage!),
                                        ),
                                      ),
                                    ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        data.fullName,
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          height: 1.0,
                                          decoration: TextDecoration.none,
                                          color: textColor,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        data.jobTitle.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                          height: 1.0,
                                          decoration: TextDecoration.none,
                                          color: Color(0xFFd4b98c),
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        data.companyName.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 7,
                                          letterSpacing: 1.5,
                                          height: 1.0,
                                          decoration: TextDecoration.none,
                                          color: textColor.withValues(alpha: 0.6),
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              GridView.count(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          crossAxisCount: 3,
                                          mainAxisSpacing: 1,
                                          crossAxisSpacing: 3,
                                          childAspectRatio: 1.05,
                                          children: [
                                            _previewAction(context, data, Icons.phone, 'PHONE', 'call', data.phone, iconBg, subColor),
                                            _previewAction(context, data, Icons.chat_bubble, 'MESSAGE', 'sms', data.sms.isNotEmpty ? data.sms : data.phone, iconBg, subColor),
                                            _previewMailAction(context, data, data.email, iconBg, subColor),
                                            _previewAction(context, data, Icons.language, 'WEBSITE', 'language', data.website, iconBg, subColor),
                                            _previewAction(context, data, Icons.chat_outlined, 'KAKAO', 'forum', data.kakao, iconBg, subColor),
                                            _previewAction(context, data, Icons.share, 'SNS', 'share', data.shareLink, iconBg, subColor),
                                          ],
                                        ),
                                              const SizedBox(height: 2),
                                              _previewPortfolioAction(context, data, iconBg, subColor),
                                              if (data.address.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                GestureDetector(
                                                  onTap: () => _handleAction('map', data.address, data),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: isLight
                                                          ? Colors.white.withValues(alpha: 0.4)
                                                          : Colors.black.withValues(alpha: 0.2),
                                                      borderRadius: BorderRadius.circular(16),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.location_on, size: 8, color: textColor.withValues(alpha: 0.9)),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          data.address.toUpperCase(),
                                                          style: TextStyle(
                                                            fontSize: 6,
                                                            fontWeight: FontWeight.bold,
                                                            letterSpacing: 1,
                                                            height: 1.0,
                                                            decoration: TextDecoration.none,
                                                            color: textColor.withValues(alpha: 0.9),
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ),
                          ),
                        ),
                      ),
                    // 상단 중앙 심볼/로고 (에디터 상단 메뉴바 위치감, 작게/투명도 0.7)
                    Positioned(
                      top: 14,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Opacity(
                          opacity: 0.7,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              NuggoLogo(
                                size: 24,
                                color: isLight
                                    ? NuggoLogo.defaultColor
                                    : Colors.white,
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
                    // 닫기 버튼 (우측 상단, 로고와 나란히)
                    Positioned(
                      top: 14,
                      right: 20,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Material(
                          color: isLight
                              ? Colors.black.withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.1),
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () => provider.setActiveView(
                              provider.previousView ?? ViewType.myCards,
                            ),
                            customBorder: const CircleBorder(),
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: Icon(
                                Icons.close,
                                size: 22,
                                color: isLight ? Colors.black87 : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // '나의 모든 것을...' - CTA 버튼 바로 위 (8px 간격)
                    Positioned(
                      left: 24,
                      right: 72,
                      bottom: 72,
                      child: Text(
                        lang == 'ko' ? '나의 모든 것을 탑카드 하나로!' : 'All your identity in one Tap Card!',
                        style: TextStyle(
                          fontSize: 8,
                          fontStyle: FontStyle.italic,
                          height: 1.0,
                          decoration: TextDecoration.none,
                          color: textColor.withValues(alpha: 0.4),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // 하단 CTA 버튼
                    Positioned(
                      left: 24,
                      right: 72,
                      bottom: 16,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Material(
                          color: createBtn,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: () => provider.setActiveView(ViewType.editor),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              height: 48,
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.style, size: 18, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    lang == 'ko' ? '나도 명함 만들기' : 'Create Your Own Card',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
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
                    // 플로팅 연락처 저장 (우측 하단)
                    Positioned(
                      right: 24,
                      bottom: 16,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
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
                    ),
                  ],
                );
                },
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
            ),
          ],
          image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  void _showMailChoice(BuildContext context, CardData data, String email) {
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
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _handleAction('mail', email, data);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.mail_outline, size: 40, color: Theme.of(ctx).colorScheme.primary),
                            const SizedBox(height: 8),
                            const Text('기본 메일 앱', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
                        _handleAction('mail_naver', email, data);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Image.asset('assets/images/naver_mail_icon.png', width: 40, height: 40, fit: BoxFit.contain),
                            const SizedBox(height: 8),
                            const Text('네이버 메일', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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

  Widget _previewPortfolioAction(
    BuildContext context,
    CardData data,
    Color bgColor,
    Color textColor,
  ) {
    const double touchSize = 52;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: touchSize,
          height: touchSize,
          child: Material(
            color: bgColor,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => _handlePortfolioAction(data),
              customBorder: const CircleBorder(),
              splashColor: textColor.withValues(alpha: 0.2),
              highlightColor: textColor.withValues(alpha: 0.1),
              child: Center(child: Icon(Icons.folder_open, size: 20, color: textColor)),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '포트폴리오',
            style: TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              height: 1.0,
              decoration: TextDecoration.none,
              color: textColor,
            ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _previewMailAction(
    BuildContext context,
    CardData data,
    String email,
    Color bgColor,
    Color textColor,
  ) {
    const double touchSize = 52;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: touchSize,
          height: touchSize,
          child: Material(
            color: bgColor,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () {
                if (email.isEmpty) return;
                _showMailChoice(context, data, email);
              },
              customBorder: const CircleBorder(),
              splashColor: textColor.withValues(alpha: 0.2),
              highlightColor: textColor.withValues(alpha: 0.1),
              child: Center(child: Icon(Icons.mail, size: 20, color: textColor)),
            ),
          ),
        ),
        const SizedBox(height: 0),
        Text(
          'EMAIL',
          style: TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            height: 1.0,
            decoration: TextDecoration.none,
            color: textColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
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
    const double touchSize = 52;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: touchSize,
          height: touchSize,
          child: Material(
            color: bgColor,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => _handleAction(type, value, data),
              customBorder: const CircleBorder(),
              splashColor: textColor.withValues(alpha: 0.2),
              highlightColor: textColor.withValues(alpha: 0.1),
              child: Center(child: Icon(icon, size: 20, color: textColor)),
            ),
          ),
        ),
        const SizedBox(height: 0),
        Text(
          label,
          style: TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            height: 1.0,
            decoration: TextDecoration.none,
            color: textColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
