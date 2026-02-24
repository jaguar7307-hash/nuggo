import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../models/card_data.dart';
import '../models/user.dart';
import '../providers/app_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _sectionBg = Color(0x33000000);
  static const Color _border = Color(0xFF1C1C1E);
  static const Color _title = Color(0xFFF4F4F5);
  static const Color _accent = Color(0xFFF97316);
  static OverlayEntry? _toastEntry;

  static TextStyle _korean({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = _title,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontFamilyFallback: const [
        'Noto Sans KR',
        'Malgun Gothic',
        'Apple SD Gothic Neo',
        'sans-serif',
      ],
    );
  }

  static TextStyle _inter({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = _title,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontFamilyFallback: const ['Inter', 'Noto Sans KR', 'sans-serif'],
    );
  }

  static String _tr(String lang, String ko, String en) {
    return lang == 'en' ? en : ko;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Navigator(
        onGenerateRoute: (settings) {
          return MaterialPageRoute<void>(
            builder: (navContext) {
              return Consumer<AppProvider>(
                  builder: (context, provider, _) {
                    final user = provider.currentUser;
                    final settings = provider.settings;
                    final lang = settings.language;
                    final displayName = (user?.name ?? '').trim().isEmpty
                        ? _tr(lang, '게스트 사용자', 'Guest User')
                        : user!.name;
                    final planName = provider.isPro
                        ? _tr(lang, '프리미엄 플랜 사용 중', 'Premium plan')
                        : _tr(lang, '무료플랜 사용 중', 'Free plan');
                    final isGuest = user?.isGuest ?? true;

                    return Stack(
                      children: [
                        ListView(
                          padding: const EdgeInsets.fromLTRB(24, 18, 24, 280),
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _tr(lang, '설정', 'Settings'),
                                    style: _korean(
                                      size: 22,
                                      weight: FontWeight.w700,
                                      color: _title,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                _RoundIconButton(
                                  icon: Icons.close,
                                  onTap: () => provider.setActiveView(
                                    provider.previousView ?? ViewType.myCards,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 26),
                            _AccountHeader(
                              name: displayName,
                              avatarUrl: user?.avatarUrl,
                              planName: planName,
                            ),
                            const SizedBox(height: 16),
                            _SectionLabel(title: _tr(lang, '내 계정', 'My Account')),
                            const SizedBox(height: 4),
                            _GroupCard(
                              children: [
                                _MenuTile(
                                  icon: Icons.person_outline_rounded,
                                  title: _tr(lang, '프로필 편집', 'Edit Profile'),
                                  subtitle: _tr(
                                    lang,
                                    '이름, 이메일, 전화번호, 프로필 사진',
                                    'Name, email, phone number, profile photo',
                                  ),
                                  onTap: () => _openProfileEditor(navContext, provider),
                                ),
                                _MenuTile(
                                  icon: Icons.verified_user_outlined,
                                  title: _tr(lang, '구독 및 보안', 'Plan & Security'),
                                  subtitle: _tr(lang, '플랜·비밀번호', 'Plan, password'),
                                  onTap: () => _openSubscriptionSecurity(navContext, provider),
                                ),
                                _MenuTile(
                                  icon: Icons.tune_rounded,
                                  title: _tr(lang, '환경설정', 'Preferences'),
                                  subtitle: _tr(lang, '기본 사용 환경', 'Preferences'),
                                  onTap: () => _openPreferences(navContext, provider),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _SectionLabel(title: _tr(lang, '설정', 'Settings')),
                            const SizedBox(height: 4),
                            _GroupCard(
                              children: [
                                _SwitchTile(
                                  icon: Icons.notifications_none_rounded,
                                  title: _tr(lang, '알림설정', 'Notifications'),
                                  subtitle: _tr(lang, '푸시 알림 및 소리', 'Push & sound'),
                                  value: settings.notifications,
                                  activeColor: _accent,
                                  switchScale: 0.86,
                                  onChanged: (v) async {
                                    await provider.setNotificationsEnabled(v);
                                  },
                                ),
                                _MenuTile(
                                  icon: Icons.apps_rounded,
                                  title: _tr(lang, '앱 설정', 'App Settings'),
                                  subtitle: _tr(lang, '앱 전반 동작 설정', 'App behavior'),
                                  onTap: () => _showPlaceholder(
                                    navContext,
                                    _tr(lang, '앱 설정 세부 화면을 준비 중입니다.', 'Detailed app settings are coming soon.'),
                                  ),
                                ),
                                _SwitchTile(
                                  icon: Icons.language_rounded,
                                  title: _tr(lang, '언어 (한국어/영어)', 'Language'),
                                  subtitle: settings.language == 'ko'
                                      ? _tr(lang, '한국어', 'Korean')
                                      : 'English',
                                  value: settings.language == 'en',
                                  activeColor: _accent,
                                  switchScale: 0.92,
                                  titleSize: 14,
                                  onChanged: (v) async {
                                    await _setAppLanguage(navContext, provider, v);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _SectionLabel(title: _tr(lang, '고객지원', 'Support')),
                            const SizedBox(height: 4),
                            _GroupCard(
                              children: [
                                _MenuTile(
                                  icon: Icons.nfc_rounded,
                                  title: _tr(lang, 'NFC 카드 만들기 가이드', 'NFC Card Guide'),
                                  subtitle: _tr(lang, '스마트하게 탭하는 방법', 'NFC tap guide'),
                                  onTap: () => _openNFCGuide(navContext, provider),
                                ),
                                _MenuTile(
                                  icon: Icons.privacy_tip_outlined,
                                  title: _tr(lang, '개인정보 처리방침', 'Privacy Policy'),
                                  subtitle: '',
                                  onTap: () => _showPlaceholder(
                                    navContext,
                                    _tr(lang, '개인정보 처리방침 내용은 추후 입력해 주세요.', 'Privacy policy content will be added soon.'),
                                  ),
                                  isExternal: true,
                                ),
                                _MenuTile(
                                  icon: Icons.description_outlined,
                                  title: _tr(lang, '이용약관', 'Terms of Service'),
                                  subtitle: '',
                                  onTap: () => _showPlaceholder(
                                    navContext,
                                    _tr(lang, '이용약관 내용은 추후 입력해 주세요.', 'Terms content will be added soon.'),
                                  ),
                                  isExternal: true,
                                ),
                                _MenuTile(
                                  icon: Icons.support_agent_rounded,
                                  title: _tr(lang, '고객센터 및 도움말', 'Help & Support'),
                                  subtitle: '',
                                  onTap: () => _showPlaceholder(
                                    navContext,
                                    _tr(lang, '고객센터/도움말 내용은 추후 입력해 주세요.', 'Support content will be added soon.'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _SectionLabel(title: _tr(lang, '데이터 및 저장공간', 'Data & Storage')),
                            const SizedBox(height: 4),
                            _GroupCard(
                              children: [
                                _MenuTile(
                                  icon: Icons.backup_rounded,
                                  title: _tr(lang, '데이터 백업', 'Data Backup'),
                                  subtitle: _tr(lang, '데이터를 안전하게 보관', 'Backup data'),
                                  onTap: () => _showPlaceholder(
                                    navContext,
                                    _tr(lang, '데이터 백업 기능은 준비 중입니다.', 'Data backup is coming soon.'),
                                  ),
                                ),
                                _MenuTile(
                                  icon: Icons.cleaning_services_rounded,
                                  title: _tr(lang, '캐시삭제', 'Clear Cache'),
                                  subtitle: _tr(lang, '임시 데이터를 정리', 'Clear temp'),
                                  onTap: () => _clearImageCache(navContext, provider),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Center(
                              child: Text(
                                'NUGGO v2.4.0 (BUILD 128)',
                                style: _inter(
                                  size: 10,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFF52525B),
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: Text(
                                '© 2024 NUGGO Inc. All Rights Reserved.',
                                style: _inter(
                                  size: 9,
                                  weight: FontWeight.w400,
                                  color: const Color(0xFF3F3F46),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          left: 24,
                          right: 24,
                          bottom: 0,
                          child: _BottomAuthCta(
                            isGuest: isGuest,
                            language: lang,
                            onPrimaryTap: () async {
                              if (isGuest) {
                                _showPlaceholder(
                                  navContext,
                                  _tr(lang, '로그인/회원가입 화면은 곧 연결됩니다.', 'Sign in / sign up is coming soon.'),
                                );
                                return;
                              }
                              await _handleLogout(navContext, provider, lang);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
    );
  }

  static Future<void> _handleLogout(
    BuildContext context,
    AppProvider provider,
    String lang,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(_tr(lang, '로그아웃', 'Log Out')),
          content: Text(_tr(lang, '로그아웃하시겠어요?', 'Log out?')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(_tr(lang, '취소', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(_tr(lang, '로그아웃', 'Log Out')),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;
    await provider.logout();
    if (!context.mounted) return;
    _showToast(context, _tr(lang, '로그아웃되었습니다.', 'Logged out.'));
  }

  static void _showPlaceholder(BuildContext context, String message) {
    _showToast(context, message);
  }

  static void _showToast(BuildContext context, String message) {
    _toastEntry?.remove();
    _toastEntry = null;

    final overlay = Overlay.of(context, rootOverlay: true);
    final targetBox = context.findRenderObject() as RenderBox?;
    final media = MediaQuery.of(context);
    final screen = media.size;
    final safeTop = media.padding.top + 8;
    final safeBottom = media.padding.bottom + 8;

    if (targetBox == null || !targetBox.hasSize) return;
    final targetTopLeft = targetBox.localToGlobal(Offset.zero);
    final targetSize = targetBox.size;
    final targetCenter = Offset(
      targetTopLeft.dx + (targetSize.width / 2),
      targetTopLeft.dy + (targetSize.height / 2),
    );

    const toastHeight = 44.0;
    const gap = 10.0;
    final toastWidth = (screen.width - 32).clamp(160.0, 300.0);
    var top = targetCenter.dy - toastHeight - gap;
    if (top < safeTop) {
      top = targetCenter.dy + gap;
    }
    if (top + toastHeight > screen.height - safeBottom) {
      top = screen.height - safeBottom - toastHeight;
    }
    final left = (targetCenter.dx - (toastWidth / 2)).clamp(
      16.0,
      screen.width - toastWidth - 16,
    );

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: left.toDouble(),
        top: top.toDouble(),
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: toastWidth.toDouble(),
              height: toastHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xC2171724),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: _korean(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );

    _toastEntry = entry;
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (_toastEntry == entry) {
        entry.remove();
        _toastEntry = null;
      }
    });
  }

  static Future<void> _openProfileEditor(
    BuildContext context,
    AppProvider provider,
  ) async {
    final user = provider.currentUser;
    if (user == null) return;
    final currentData = provider.currentCardData;
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => _ProfileEditScreen(
          initialUser: user,
          initialCardData: currentData,
          onSave: (newData) async {
            provider.updateCardData(newData, immediate: true);
            final safeName = newData.fullName.trim().isEmpty
                ? user.name
                : newData.fullName.trim();
            final safeEmail = newData.email.trim().isEmpty
                ? user.email
                : newData.email.trim();
            final safePhone = newData.phone.trim().isEmpty
                ? user.phoneNumber
                : newData.phone.trim();
            await provider.updateCurrentUserProfile(
              name: safeName,
              email: safeEmail,
              phoneNumber: safePhone,
              avatarUrl: newData.profileImage,
            );
          },
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  static Future<void> _openSubscriptionSecurity(
    BuildContext context,
    AppProvider provider,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const _SubscriptionSecurityScreen(),
      ),
    );
  }

  static Future<void> _openNFCGuide(
    BuildContext context,
    AppProvider provider,
  ) async {
    final shareLink = provider.currentCardData.shareLink.trim();
    final exampleUrl = shareLink.isEmpty
        ? 'https://nuggo.me/username'
        : (shareLink.startsWith('http') ? shareLink : 'https://$shareLink');
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => _NFCGuideScreen(exampleUrl: exampleUrl),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  static Future<void> _openPreferences(
    BuildContext context,
    AppProvider provider,
  ) async {
    final lang = provider.settings.language;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111113),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            final settings = provider.settings;
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3F3F46),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _tr(lang, '환경설정', 'Preferences'),
                      style: _korean(size: 16, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: Text(_tr(lang, '사운드', 'Sound'), style: _korean(size: 14, weight: FontWeight.w600)),
                      subtitle: Text(_tr(lang, '효과음 사용', 'Use sound effects'), style: _korean(size: 12, color: const Color(0xFF9CA3AF))),
                      value: settings.sound,
                      onChanged: (v) async {
                        await provider.updateSettings(settings.copyWith(sound: v), notify: false);
                        setLocal(() {});
                      },
                    ),
                    SwitchListTile(
                      title: Text(_tr(lang, '햅틱', 'Haptic'), style: _korean(size: 14, weight: FontWeight.w600)),
                      subtitle: Text(_tr(lang, '진동 피드백 사용', 'Use vibration feedback'), style: _korean(size: 12, color: const Color(0xFF9CA3AF))),
                      value: settings.haptic,
                      onChanged: (v) async {
                        await provider.updateSettings(settings.copyWith(haptic: v), notify: false);
                        setLocal(() {});
                      },
                    ),
                    SwitchListTile(
                      title: Text(_tr(lang, '프라이빗 모드', 'Private Mode'), style: _korean(size: 14, weight: FontWeight.w600)),
                      subtitle: Text(_tr(lang, '개인정보 노출 최소화', 'Reduce personal info exposure'), style: _korean(size: 12, color: const Color(0xFF9CA3AF))),
                      value: settings.privateMode,
                      onChanged: (v) async {
                        await provider.updateSettings(settings.copyWith(privateMode: v), notify: false);
                        setLocal(() {});
                      },
                    ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Future<void> _clearImageCache(
    BuildContext context,
    AppProvider provider,
  ) async {
    final lang = provider.settings.language;
    await provider.clearTemporaryCache();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    if (!context.mounted) return;
    _showToast(context, _tr(lang, '캐시가 삭제되었습니다.', 'Cache cleared.'));
  }

  static Future<void> _setAppLanguage(
    BuildContext context,
    AppProvider provider,
    bool useEnglish,
  ) async {
    final current = provider.settings.language;
    final selected = useEnglish ? 'en' : 'ko';
    if (selected == current) return;
    await provider.setAppLanguage(selected);
    if (!context.mounted) return;
    _showPlaceholder(
      context,
      selected == 'ko'
          ? '언어가 한국어로 변경되었습니다.'
          : 'Language changed to English.',
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: SettingsScreen._inter(
        size: 10,
        weight: FontWeight.w700,
        color: const Color(0xFF52525B),
        letterSpacing: 1.1,
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final List<Widget> children;
  const _GroupCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SettingsScreen._sectionBg,
        borderRadius: BorderRadius.circular(0),
        border: Border.symmetric(
          horizontal: BorderSide(color: SettingsScreen._border),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final String planName;
  const _AccountHeader({
    required this.name,
    this.avatarUrl,
    required this.planName,
  });

  String _initials(String text) {
    final parts = text.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    if (parts.isEmpty) return 'MC';
    if (parts.length == 1) {
      final value = parts.first;
      return value.length >= 2 ? value.substring(0, 2).toUpperCase() : value.toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  ImageProvider<Object>? _avatarProvider() {
    final value = avatarUrl?.trim() ?? '';
    if (value.isEmpty) return null;
    if (value.startsWith('data:image')) {
      final idx = value.indexOf(',');
      if (idx != -1) {
        try {
          final bytes = base64Decode(value.substring(idx + 1));
          return MemoryImage(bytes);
        } catch (_) {
          return null;
        }
      }
    }
    return NetworkImage(value);
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _avatarProvider();
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: SettingsScreen._border),
          ),
          child: Center(
            child: avatar == null
                ? Text(
                    _initials(name),
                    style: SettingsScreen._inter(
                      size: 20,
                      weight: FontWeight.w500,
                      color: const Color(0xFFA1A1AA),
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image(
                      image: avatar,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: SettingsScreen._korean(
                  size: 18,
                  weight: FontWeight.w700,
                  color: SettingsScreen._title,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                planName,
                style: SettingsScreen._korean(
                  size: 12,
                  weight: FontWeight.w400,
                  color: const Color(0xFF71717A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF18181B),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: const Color(0xFFA1A1AA)),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isExternal;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isExternal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: subtitle.isEmpty
                    ? Colors.transparent
                    : const Color(0x801C1C1E),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF71717A), size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SettingsScreen._korean(
                        size: 15,
                        weight: FontWeight.w500,
                        color: SettingsScreen._title,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SettingsScreen._korean(
                          size: 11,
                          weight: FontWeight.w400,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isExternal
                    ? Icons.open_in_new_rounded
                    : Icons.chevron_right_rounded,
                size: 24,
                color: const Color(0xFF3F3F46),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final double switchScale;

  final double? titleSize;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.activeColor,
    this.switchScale = 0.92,
    this.titleSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
      decoration: const BoxDecoration(),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF71717A), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SettingsScreen._korean(
                    size: titleSize ?? 15,
                    weight: FontWeight.w500,
                    color: SettingsScreen._title,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SettingsScreen._korean(
                    size: 11,
                    weight: FontWeight.w400,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: switchScale,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: activeColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileEditScreen extends StatefulWidget {
  final User initialUser;
  final CardData initialCardData;
  final Future<void> Function(CardData data) onSave;

  const _ProfileEditScreen({
    required this.initialUser,
    required this.initialCardData,
    required this.onSave,
  });

  @override
  State<_ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<_ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final TextEditingController _sloganController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsController = TextEditingController();
  final TextEditingController _kakaoController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _portfolioController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();
  final TextEditingController _shareLinkController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _saving = false;
  String? _avatarDataUrl;
  String? _portfolioFile;
  String? _portfolioFileName;

  String _tr(String lang, String ko, String en) => lang == 'en' ? en : ko;

  @override
  void initState() {
    super.initState();
    final data = widget.initialCardData;
    _sloganController.text = data.slogan;
    _nameController.text = data.fullName.isEmpty
        ? widget.initialUser.name
        : data.fullName;
    _jobTitleController.text = data.jobTitle;
    _companyNameController.text = data.companyName;
    _emailController.text = data.email.isEmpty
        ? widget.initialUser.email
        : data.email;
    _phoneController.text = data.phone.isEmpty
        ? (widget.initialUser.phoneNumber ?? '')
        : data.phone;
    _smsController.text = data.sms;
    _kakaoController.text = data.kakao;
    _websiteController.text = data.website;
    _portfolioController.text = data.portfolioUrl ?? '';
    _portfolioFile = data.portfolioFile;
    _portfolioFileName = data.portfolioFileName;
    _linkedinController.text = data.linkedin;
    _shareLinkController.text = data.shareLink;
    _addressController.text = data.address;
    _avatarDataUrl = data.profileImage ?? widget.initialUser.avatarUrl;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _sloganControllerOrNull?.dispose();
    _nameControllerOrNull?.dispose();
    _jobTitleControllerOrNull?.dispose();
    _companyNameControllerOrNull?.dispose();
    _emailControllerOrNull?.dispose();
    _phoneControllerOrNull?.dispose();
    _smsControllerOrNull?.dispose();
    _kakaoControllerOrNull?.dispose();
    _websiteControllerOrNull?.dispose();
    _portfolioControllerOrNull?.dispose();
    _linkedinControllerOrNull?.dispose();
    _shareLinkControllerOrNull?.dispose();
    _addressControllerOrNull?.dispose();
    super.dispose();
  }

  TextEditingController? get _sloganControllerOrNull => _sloganController;
  TextEditingController? get _nameControllerOrNull => _nameController;
  TextEditingController? get _jobTitleControllerOrNull => _jobTitleController;
  TextEditingController? get _companyNameControllerOrNull =>
      _companyNameController;
  TextEditingController? get _emailControllerOrNull => _emailController;
  TextEditingController? get _phoneControllerOrNull => _phoneController;
  TextEditingController? get _smsControllerOrNull => _smsController;
  TextEditingController? get _kakaoControllerOrNull => _kakaoController;
  TextEditingController? get _websiteControllerOrNull => _websiteController;
  TextEditingController? get _portfolioControllerOrNull => _portfolioController;
  TextEditingController? get _linkedinControllerOrNull => _linkedinController;
  TextEditingController? get _shareLinkControllerOrNull => _shareLinkController;
  TextEditingController? get _addressControllerOrNull => _addressController;

  static const int _portfolioMaxBytes = 10 * 1024 * 1024; // 10MB

  Future<void> _pickPortfolioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파일을 읽을 수 없습니다. 다시 선택해 주세요.')),
        );
      }
      return;
    }
    if (file.size > _portfolioMaxBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파일 크기는 10MB 이하여야 합니다.')),
        );
      }
      return;
    }
    final ext = file.extension?.toLowerCase() ?? 'bin';
    String mime = 'application/octet-stream';
    if (ext == 'pdf') {
      mime = 'application/pdf';
    } else if (ext == 'doc') mime = 'application/msword';
    else if (ext == 'docx') mime = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    else if (ext == 'jpg' || ext == 'jpeg') mime = 'image/jpeg';
    else if (ext == 'png') mime = 'image/png';
    setState(() {
      _portfolioFile = 'data:$mime;base64,${base64Encode(file.bytes!)}';
      _portfolioFileName = file.name;
    });
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 90,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    final mime = image.mimeType ?? 'image/jpeg';
    setState(() {
      _avatarDataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
    });
  }

  ImageProvider<Object>? _avatarProvider() {
    final value = _avatarDataUrl?.trim() ?? '';
    if (value.isEmpty) return null;
    if (value.startsWith('data:image')) {
      final idx = value.indexOf(',');
      if (idx != -1) {
        try {
          final bytes = base64Decode(value.substring(idx + 1));
          return MemoryImage(bytes);
        } catch (_) {
          return null;
        }
      }
    }
    return NetworkImage(value);
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    setState(() => _saving = true);
    try {
      final next = widget.initialCardData.copyWith(
        slogan: _sloganController.text.trim(),
        fullName: _nameController.text.trim(),
        jobTitle: _jobTitleController.text.trim(),
        companyName: _companyNameController.text.trim(),
        phone: _phoneController.text.trim(),
        sms: _smsController.text.trim(),
        email: _emailController.text.trim(),
        kakao: _kakaoController.text.trim(),
        website: _websiteController.text.trim(),
        portfolioUrl: _portfolioController.text.trim().isEmpty
            ? null
            : _portfolioController.text.trim(),
        portfolioFile: _portfolioFile ?? '',
        portfolioFileName: _portfolioFileName ?? '',
        linkedin: _linkedinController.text.trim(),
        shareLink: _shareLinkController.text.trim(),
        address: _addressController.text.trim(),
        profileImage: _avatarDataUrl,
      );
      await widget.onSave(next);
      if (!mounted) return;
      final lang = context.read<AppProvider>().settings.language;
      SettingsScreen._showToast(
        context,
        _tr(lang, '프로필 정보가 저장되었습니다.', 'Profile saved successfully.'),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.select<AppProvider, String>((p) => p.settings.language);
    final avatar = _avatarProvider();
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            Text(
              _tr(lang, '프로필 편집', 'Edit Profile'),
              style: SettingsScreen._korean(
                size: 20,
                weight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            Text(
              'Edit Profile',
              style: SettingsScreen._inter(
                size: 9,
                weight: FontWeight.w700,
                color: const Color(0xFF94A3B8),
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saving ? null : _submit,
            child: Text(
              _saving ? _tr(lang, '저장 중...', 'Saving...') : _tr(lang, '저장', 'Save'),
              style: SettingsScreen._korean(
                size: 14,
                weight: FontWeight.w700,
                color: const Color(0xFF4B61D1),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            28 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1F000000),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                        image: avatar == null
                            ? null
                            : DecorationImage(image: avatar, fit: BoxFit.cover),
                      ),
                      child: avatar == null
                          ? const Icon(
                              Icons.person_rounded,
                              size: 46,
                              color: Color(0xFF64748B),
                            )
                          : null,
                    ),
                    Positioned(
                      right: -6,
                      bottom: -6,
                      child: InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4B61D1),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                _buildSectionCard(
                  icon: Icons.person_rounded,
                  iconColor: const Color(0xFF4B61D1),
                  title: 'Basic Information',
                  child: Column(
                    children: [
                      _buildLabeledInput(
                        controller: _sloganController,
                        label: _tr(lang, '한줄 소개', 'Short Intro'),
                        subLabel: 'Short Intro',
                        hint: _tr(lang, '한줄 소개를 입력하세요', 'Enter a short intro'),
                      ),
                      const SizedBox(height: 12),
                      _buildLabeledInput(
                        controller: _nameController,
                        label: _tr(lang, '이름', 'Name'),
                        subLabel: 'Name',
                        hint: _tr(lang, '이름을 입력하세요', 'Enter your name'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildLabeledInput(
                              controller: _jobTitleController,
                              label: _tr(lang, '직함', 'Job Title'),
                              subLabel: 'Job Title',
                              hint: _tr(lang, '직함', 'Job title'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildLabeledInput(
                              controller: _companyNameController,
                              label: _tr(lang, '회사명', 'Company'),
                              subLabel: 'Company',
                              hint: _tr(lang, '회사명', 'Company name'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _buildSectionCard(
                  icon: Icons.contact_phone_rounded,
                  iconColor: const Color(0xFFF58220),
                  title: 'Contact Details',
                  child: Column(
                    children: [
                      _buildLabeledInput(
                        controller: _phoneController,
                        label: _tr(lang, '전화번호', 'Phone'),
                        subLabel: 'Phone',
                        hint: '010-1234-5678',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      _buildLabeledInput(
                        controller: _smsController,
                        label: 'SMS',
                        subLabel: 'SMS',
                        hint: _tr(lang, 'SMS 번호', 'SMS number'),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      _buildLabeledInput(
                        controller: _emailController,
                        label: _tr(lang, '이메일', 'Email'),
                        subLabel: 'Email',
                        hint: 'example@nuggo.me',
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _buildSectionCard(
                  icon: Icons.language_rounded,
                  iconColor: const Color(0xFF64748B),
                  title: 'Links & Social',
                  child: Column(
                    children: [
                      _buildLabeledInput(
                        controller: _websiteController,
                        label: _tr(lang, '웹사이트', 'Website'),
                        subLabel: 'Website',
                        hint: 'www.yourportfolio.com',
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      _buildLabeledInput(
                        controller: _kakaoController,
                        label: _tr(lang, '카카오', 'Kakao'),
                        subLabel: 'KakaoTalk ID',
                        hint: _tr(lang, '카카오 ID', 'Kakao ID'),
                      ),
                      const SizedBox(height: 12),
                      _buildLabeledInput(
                        controller: _shareLinkController,
                        label: _tr(lang, '공유 링크', 'Share Link'),
                        subLabel: 'Share Link',
                        hint: 'nuggo.me/username',
                      ),
                      const SizedBox(height: 12),
                      _buildPortfolioInput(
                        lang: lang,
                        controller: _portfolioController,
                        label: _tr(lang, '포트폴리오', 'Portfolio'),
                        subLabel: 'Portfolio',
                        hint: _tr(lang, '링크 입력', 'Enter link'),
                        hasFile: _portfolioFile != null && _portfolioFile!.isNotEmpty,
                        fileName: _portfolioFileName,
                        onAttach: _pickPortfolioFile,
                        onRemoveFile: () => setState(() {
                          _portfolioFile = null;
                          _portfolioFileName = null;
                        }),
                      ),
                      const SizedBox(height: 12),
                      _buildLabeledInput(
                        controller: _addressController,
                        label: _tr(lang, '주소', 'Address'),
                        subLabel: 'Address',
                        hint: _tr(lang, '주소를 입력하세요', 'Enter your address'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: SettingsScreen._inter(
                  size: 10,
                  weight: FontWeight.w700,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildLabeledInput({
    required TextEditingController controller,
    required String label,
    required String subLabel,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: RichText(
            text: TextSpan(
              style: SettingsScreen._korean(
                size: 11,
                weight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
              children: [
                TextSpan(text: label),
                TextSpan(
                  text: '  $subLabel',
                  style: SettingsScreen._inter(
                    size: 9,
                    weight: FontWeight.w400,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0x334B61D1), width: 2),
            ),
          ),
          style: SettingsScreen._korean(
            size: 14,
            weight: FontWeight.w500,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioInput({
    required String lang,
    required TextEditingController controller,
    required String label,
    required String subLabel,
    required String hint,
    required bool hasFile,
    String? fileName,
    required VoidCallback onAttach,
    required VoidCallback onRemoveFile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: RichText(
            text: TextSpan(
              style: SettingsScreen._korean(
                size: 11,
                weight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
              children: [
                TextSpan(text: label),
                TextSpan(
                  text: '  $subLabel',
                  style: SettingsScreen._inter(
                    size: 9,
                    weight: FontWeight.w400,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: hint,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0x334B61D1), width: 2),
                  ),
                ),
                style: SettingsScreen._korean(
                  size: 14,
                  weight: FontWeight.w500,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(hasFile ? Icons.attach_file : Icons.add_circle_outline, color: const Color(0xFF64748B)),
              onPressed: onAttach,
                tooltip: _tr(lang, '파일 첨부 (PDF,DOC,DOCX,JPG,PNG / 최대 10MB)', 'Attach file (max 10MB)'),
            ),
          ],
        ),
        if (hasFile)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 14, color: Colors.green.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    fileName ?? _tr(lang, '파일 첨부됨', 'File attached'),
                    style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: onRemoveFile,
                  child: Text(_tr(lang, '제거', 'Remove')),
                ),
              ],
            ),
          ),
      ],
    );
  }

}

class _SubscriptionSecurityScreen extends StatelessWidget {
  const _SubscriptionSecurityScreen();

  String _tr(String lang, String ko, String en) => lang == 'en' ? en : ko;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final user = provider.currentUser;
        final lang = provider.settings.language;
        final planText = provider.isPro
            ? _tr(lang, '프리미엄 플랜 사용 중', 'Premium plan')
            : _tr(lang, '무료플랜 사용 중', 'Free plan');
        final providerText = user == null ? '-' : user.provider.name.toUpperCase();

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FC),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF8F9FC),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              children: [
                Text(
                  _tr(lang, '구독 및 보안', 'Subscription & Security'),
                  style: SettingsScreen._korean(
                    size: 20,
                    weight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  'Subscription & Security',
                  style: SettingsScreen._inter(
                    size: 9,
                    weight: FontWeight.w700,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  _SecuritySectionCard(
                    icon: Icons.workspace_premium_rounded,
                    iconColor: const Color(0xFFF58220),
                    title: _tr(lang, '구독', 'Subscription'),
                    child: Column(
                      children: [
                        _SecurityInfoTile(
                          label: _tr(lang, '현재 플랜', 'Current Plan'),
                          value: planText,
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: provider.isPro
                                ? null
                                : () async {
                                    await provider.upgradeToPro();
                                    if (!context.mounted) return;
                                    SettingsScreen._showToast(
                                      context,
                                      _tr(lang, '프리미엄 플랜으로 업그레이드되었습니다.', 'Upgraded to premium plan.'),
                                    );
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF4B61D1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              provider.isPro
                                  ? _tr(lang, '현재 이용 중', 'Current Plan')
                                  : _tr(lang, '프리미엄 업그레이드', 'Upgrade to Premium'),
                              style: SettingsScreen._korean(
                                size: 14,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SecuritySectionCard(
                    icon: Icons.shield_outlined,
                    iconColor: const Color(0xFF4B61D1),
                    title: _tr(lang, '보안', 'Security'),
                    child: Column(
                      children: [
                        _SecurityInfoTile(
                          label: _tr(lang, '로그인 방식', 'Login Method'),
                          value: providerText,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 2,
                            ),
                            title: Text(
                              _tr(lang, '생체 인증 잠금', 'Biometric Lock'),
                              style: SettingsScreen._korean(
                                size: 14,
                                weight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            subtitle: Text(
                              _tr(lang, '앱 진입 시 잠금 확인', 'Require unlock on app entry'),
                              style: SettingsScreen._korean(
                                size: 11,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            value: provider.settings.biometrics,
                            onChanged: (v) async {
                              if (v && provider.currentUser?.lockPin == null) {
                                SettingsScreen._showToast(
                                  context,
                                  _tr(lang, 'PIN 설정 후 생체 인증을 사용할 수 있습니다.', 'Set a PIN to enable biometrics.'),
                                );
                                return;
                              }
                              await provider.updateSettings(
                                provider.settings.copyWith(biometrics: v),
                              );
                            },
                            activeThumbColor: const Color(0xFF4B61D1),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              SettingsScreen._showToast(
                                context,
                                _tr(lang, '비밀번호 변경 화면은 곧 제공됩니다.', 'Password change screen is coming soon.'),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              _tr(lang, '비밀번호 변경', 'Change Password'),
                              style: SettingsScreen._korean(
                                size: 13,
                                weight: FontWeight.w600,
                                color: const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SecuritySectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _SecuritySectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: SettingsScreen._inter(
                  size: 10,
                  weight: FontWeight.w700,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SecurityInfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _SecurityInfoTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: SettingsScreen._korean(
                size: 12,
                weight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SettingsScreen._korean(
                size: 13,
                weight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NFCGuideScreen extends StatefulWidget {
  final String exampleUrl;

  const _NFCGuideScreen({required this.exampleUrl});

  @override
  State<_NFCGuideScreen> createState() => _NFCGuideScreenState();
}

class _NFCGuideScreenState extends State<_NFCGuideScreen> {
  late bool _isIphone;

  @override
  void initState() {
    super.initState();
    _isIphone = defaultTargetPlatform == TargetPlatform.iOS;
  }

  String _tr(String lang, String ko, String en) => lang == 'en' ? en : ko;

  @override
  Widget build(BuildContext context) {
    final lang = context.select<AppProvider, String>((p) => p.settings.language);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            Text(
              _tr(lang, 'NFC 가이드', 'NFC Guide'),
              style: SettingsScreen._korean(
                size: 20,
                weight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            Text(
              _tr(lang, '나만의 NFC 카드 만들기', 'Make your NFC card'),
              style: SettingsScreen._inter(
                size: 9,
                weight: FontWeight.w700,
                color: const Color(0xFF94A3B8),
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _TabChip(
                    label: 'iPhone',
                    isSelected: _isIphone,
                    onTap: () => setState(() => _isIphone = true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _TabChip(
                    label: 'Android',
                    isSelected: !_isIphone,
                    onTap: () => setState(() => _isIphone = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _GuideStep(
              step: 1,
              title: _tr(lang, '앱 설치하기', 'Install the app'),
              body: _isIphone
                  ? _tr(lang, 'App Store에서 \'NFC Tools\' 앱을 검색하여 설치해주세요. 무료 버전으로도 충분합니다.', 'Search and install \'NFC Tools\' from App Store. Free version is enough.')
                  : _tr(lang, 'Play Store에서 \'NFC Tools\' 앱을 검색하여 설치해주세요. 무료 버전으로도 충분합니다.', 'Search and install \'NFC Tools\' from Play Store. Free version is enough.'),
            ),
            const SizedBox(height: 20),
            _GuideStep(
              step: 2,
              title: _tr(lang, '쓰기(Write) 모드', 'Write mode'),
              body: _tr(lang, '앱 메뉴에서 \'Write\' 탭을 선택한 뒤 \'Add a record\' 버튼을 누르세요.', 'Select \'Write\' tab and tap \'Add a record\' button.'),
            ),
            const SizedBox(height: 20),
            _GuideStep(
              step: 3,
              title: _tr(lang, '내 링크 입력', 'Enter your link'),
              body: _tr(lang, '목록에서 \'URL / URI\'를 선택하고 내 명함 링크를 입력합니다.', 'Select \'URL / URI\' and enter your card link.'),
              trailing: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.exampleUrl,
                        style: SettingsScreen._inter(
                          size: 11,
                          weight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _GuideStep(
              step: 4,
              title: _tr(lang, '카드에 쓰기', 'Write to card'),
              body: _isIphone
                  ? _tr(lang, '\'Write / Bytes\' 버튼을 누르고 준비한 공NFC 카드를 휴대폰 상단 뒷면에 갖다 대세요.', 'Tap \'Write / Bytes\' and hold your blank NFC card to the top back of your phone.')
                  : _tr(lang, '\'Write / Bytes\' 버튼을 누르고 준비한 공NFC 카드를 휴대폰 중앙 뒷면에 갖다 대세요.', 'Tap \'Write / Bytes\' and hold your blank NFC card to the center back of your phone.'),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber.shade700),
                      const SizedBox(width: 8),
                      Text(
                        _tr(lang, 'Tip', 'Tip').toUpperCase(),
                        style: SettingsScreen._inter(
                          size: 10,
                          weight: FontWeight.w700,
                          color: Colors.amber.shade800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _tr(lang, '완료 후에는 카드를 휴대폰에 태그하여 링크가 잘 열리는지 확인해보세요. 금속 표면 위에서는 인식이 안될 수 있습니다.', 'After writing, tap the card to your phone to verify. It may not work on metal surfaces.'),
                    style: SettingsScreen._korean(
                      size: 12,
                      weight: FontWeight.w400,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.only(top: 20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.contact_support_outlined, size: 18, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        _tr(lang, '폰끼리 터치해서 보낼 순 없나요?', 'Can phones share via NFC touch?'),
                        style: SettingsScreen._korean(
                          size: 14,
                          weight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tr(lang, '현재 스마트폰 보안 정책상 웹사이트가 실행 중인 폰이 직접 NFC 태그 역할(카드 역할)을 하는 것은 불가능합니다. (HCE 미지원)', 'Phones cannot act as NFC tags (card role) due to security policy. HCE not supported.'),
                          style: SettingsScreen._korean(
                            size: 12,
                            weight: FontWeight.w400,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _tr(lang, '대신 QR코드를 보여주세요.', 'Use QR code instead.'),
                                style: SettingsScreen._korean(
                                  size: 12,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.check_circle, size: 16, color: Colors.blue.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _tr(lang, '공유하기(카카오톡/AirDrop)를 이용하세요.', 'Use Share (KakaoTalk/AirDrop).'),
                                style: SettingsScreen._korean(
                                  size: 12,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF111827),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _tr(lang, '확인 완료', 'Got it'),
                  style: SettingsScreen._korean(size: 14, weight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFF111827) : const Color(0xFFE2E8F0),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: SettingsScreen._korean(
                size: 14,
                weight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  final int step;
  final String title;
  final String body;
  final Widget? trailing;

  const _GuideStep({
    required this.step,
    required this.title,
    required this.body,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '$step',
                  style: SettingsScreen._korean(
                    size: 14,
                    weight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SettingsScreen._korean(
                      size: 15,
                      weight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: SettingsScreen._korean(
                      size: 13,
                      weight: FontWeight.w400,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BottomAuthCta extends StatelessWidget {
  final bool isGuest;
  final String language;
  final VoidCallback onPrimaryTap;

  const _BottomAuthCta({
    required this.isGuest,
    required this.language,
    required this.onPrimaryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xE60A0A0A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1C1C1E)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onPrimaryTap,
          style: FilledButton.styleFrom(
            backgroundColor: SettingsScreen._accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            language == 'en'
                ? (isGuest ? 'Sign In / Sign Up' : 'Log Out')
                : (isGuest ? '로그인 / 회원가입' : '로그아웃'),
            style: SettingsScreen._korean(size: 14, weight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
