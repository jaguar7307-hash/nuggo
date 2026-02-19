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

  Future<void> _handleAction(String type, String value, CardData data) async {
    if (value.isEmpty && type != 'share') return;
    if (type == 'share') {
      String url = data.shareLink.trim().isEmpty ? 'https://nuggo.me' : data.shareLink;
      if (!url.startsWith('http')) url = 'https://$url';
      await Share.share(url, subject: '명함: ${data.fullName.isNotEmpty ? data.fullName : "NUGGO"}');
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
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
                color: isLight ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.2),
              ),
            ),
            // 3. 콘텐츠
            SafeArea(
              child: SizedBox.expand(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SingleChildScrollView(
                    child: Padding(
                      // 전체 중심을 조금 아래로 이동
                      padding: const EdgeInsets.only(top: 56, bottom: 24, left: 0, right: 0),
                    child: Column(
                  children: [
                  // 상단 배지 영역: 높이 고정으로 사라질 때 레이아웃 점프 방지
                  SizedBox(
                    height: 44,
                    child: AnimatedOpacity(
                      opacity: _showNotification ? 1 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 24),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility, size: 12, color: Colors.green.shade300),
                                const SizedBox(width: 6),
                                Text(
                                  lang == 'ko' ? '상대방에게 보이는 화면입니다' : 'This is the public view',
                                  style: const TextStyle(
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
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 24,
                    height: 1,
                    color: (isLight ? Colors.black : Colors.white).withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  // 슬로건/이름/직책 가독성을 위해 하향 조정
                  Transform.translate(
                    offset: const Offset(0, -6),
                    child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      '"${data.slogan}"',
                      style: TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: textColor.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  ),
                  if (data.profileImage != null && data.profileImage!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildPreviewProfileImage(data.profileImage!),
                  ],
                  const SizedBox(height: 24),
                  Transform.translate(
                    offset: const Offset(0, 42), // 현재 기준 +15px 추가 하향
                    child: Column(
                      children: [
                        // 이름 (큼)
                        Text(
                          data.fullName,
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data.jobTitle.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                            color: Color(0xFFd4b98c),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.companyName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 2,
                            color: textColor.withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26), // 32의 약 80%
                  // 에디터 명함과 동일: 3x2 그리드 + 포트폴리오 + 주소
                  Transform.translate(
                    offset: const Offset(0, 54), // 현재 기준 +15px 추가 하향
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 3,
                            // 아이콘 위아래 간격 추가 축소
                            mainAxisSpacing: 0,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.9,
                            children: [
                              Transform.translate(
                                offset: const Offset(0, 12),
                                child: _previewAction(context, data, Icons.phone, 'PHONE', 'call', data.phone, iconBg, subColor),
                              ),
                              Transform.translate(
                                offset: const Offset(0, 12),
                                child: _previewAction(context, data, Icons.chat_bubble, 'MESSAGE', 'sms', data.sms, iconBg, subColor),
                              ),
                              Transform.translate(
                                offset: const Offset(0, 12),
                                child: _previewAction(context, data, Icons.mail, 'EMAIL', 'mail', data.email, iconBg, subColor),
                              ),
                              Transform.translate(
                                offset: const Offset(0, -12), // 현재 대비 절반 수준으로 세로 간격 압축
                                child: _previewAction(context, data, Icons.language, 'WEBSITE', 'language', data.website, iconBg, subColor),
                              ),
                              Transform.translate(
                                offset: const Offset(0, -12),
                                child: _previewAction(context, data, Icons.chat_outlined, 'KAKAO', 'forum', data.kakao, iconBg, subColor),
                              ),
                              Transform.translate(
                                offset: const Offset(0, -12),
                                child: _previewAction(context, data, Icons.share, 'SNS', 'share', data.shareLink, iconBg, subColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 0),
                        _previewAction(context, data, Icons.folder_open, '포트폴리오', 'portfolio', data.portfolioUrl ?? '', iconBg, subColor),
                          if (data.address.isNotEmpty) ...[
                          const SizedBox(height: 8), // 10의 약 80%
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isLight ? Colors.white.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.location_on, size: 10, color: textColor.withValues(alpha: 0.9)),
                                    const SizedBox(width: 6),
                                    Text(
                                      data.address.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
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
                  ),
                  const SizedBox(height: 100),
                  // 하단 CTA (친구추가 버튼과 겹치지 않도록 아래로)
                  Transform.translate(
                    offset: const Offset(0, -4), // 현재 기준 +15px 추가 하향
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Column(
                      children: [
                        Text(
                          lang == 'ko' ? '나의 모든 것을 탑카드 하나로!' : 'All your identity in one Tap Card!',
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: textColor.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(height: 12),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Material(
                          color: createBtn,
                          borderRadius: BorderRadius.circular(28),
                          child: InkWell(
                            onTap: () => provider.setActiveView(ViewType.editor),
                            borderRadius: BorderRadius.circular(28),
                            child: Container(
                              width: double.infinity,
                              height: 56,
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.style, size: 20, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    lang == 'ko' ? '나도 명함 만들기' : 'Create Your Own Card',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ),
                      ],
                    ),
                    ),
                  ),
                ],
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
                          color: isLight ? NuggoLogo.defaultColor : Colors.white,
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
                  color: isLight ? Colors.black.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.1),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () => provider.setActiveView(provider.previousView ?? ViewType.myCards),
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
              // 플로팅 연락처 저장 (우측 하단)
              Positioned(
                right: 24,
                bottom: 160,
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
                            lang == 'ko' ? '연락처 저장 기능은 준비 중입니다.' : 'Save Contact coming soon.',
                          ),
                        ),
                      );
                    },
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.person_add, size: 22),
                    ),
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
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 4),
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
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 4),
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
    const double touchSize = 76;
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
              child: Center(
                child: Icon(icon, size: 26, color: textColor),
              ),
            ),
          ),
        ),
        const SizedBox(height: 0),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
