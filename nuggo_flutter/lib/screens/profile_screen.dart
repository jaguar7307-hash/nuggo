import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/theme.dart';
import '../models/card_data.dart';
import '../models/profile.dart';
import '../providers/app_provider.dart';
import '../widgets/digital_card.dart';

/// 내 명함 페이지 (My Card) - 첨부 디자인/HTML 기준
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _selectedProfileId;

  static const Color _bgDark = Color(0xFF101822);
  static const Color _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final profiles = provider.savedProfiles;
        if (profiles.isEmpty) return _buildEmptyState(context);

        final selected = _resolveSelectedProfile(profiles);
        final views = _mockViewCount(selected);
        final sends = _mockSendCount(selected);

        return Container(
          color: _bgDark,
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('PROFILES'),
                  const SizedBox(height: 12),
                  _buildProfilesRow(context, provider, profiles),
                  const SizedBox(height: 24),
                  _buildMainCard(context, provider, selected, views, sends),
                  const SizedBox(height: 32),
                  _buildRecentSendHistory(),
                  const SizedBox(height: 24),
                  _buildInsightAnalysis(views, sends),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      color: _bgDark,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contact_page, size: 96, color: Colors.grey.shade600),
            const SizedBox(height: 20),
            Text(
              '저장된 명함이 없습니다',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '에디터에서 프로필을 생성해 주세요',
              style: GoogleFonts.manrope(fontSize: 14, color: _textMuted),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.read<AppProvider>().setActiveView(ViewType.editor),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('에디터로 이동'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
        color: _textMuted,
      ),
    );
  }

  Widget _buildProfilesRow(BuildContext context, AppProvider provider, List<Profile> profiles) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        children: [
          ...profiles.map((profile) {
            final isSelected = profile.id == _selectedProfileId || (_selectedProfileId == null && profile.id == profiles.first.id);
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _ProfilePill(
                profile: profile,
                isSelected: isSelected,
                onTap: () {
                  setState(() => _selectedProfileId = profile.id);
                  provider.selectProfile(profile.id);
                },
              ),
            );
          }),
          _AddProfilePill(onTap: () {
            provider.createNewProfile();
            provider.requestScrollToBackgroundTheme();
            provider.setActiveView(ViewType.editor);
          }),
        ],
      ),
    );
  }

  Widget _buildMainCard(BuildContext context, AppProvider provider, Profile selected, int views, int sends) {
    final data = selected.data;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth * 0.52;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildCompactCard(context, provider, data),
                      Positioned(
                        bottom: -20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                provider.loadProfile(selected);
                                provider.setActiveView(ViewType.preview);
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey.shade400),
                                ),
                                child: Icon(Icons.visibility_outlined, color: Colors.grey.shade600, size: 18),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ViewsSendsBlock(
                        icon: Icons.visibility,
                        value: _formatCount(views),
                        subtitle: '+12.4%',
                        subtitleColor: Colors.green.shade400,
                        subtitleIcon: Icons.arrow_upward,
                      ),
                      const SizedBox(height: 32),
                      _ViewsSendsBlock(
                        icon: Icons.send,
                        value: _formatCount(sends),
                        subtitle: '89% conv.',
                        subtitleColor: const Color(0xFF94A3B8),
                        subtitleIcon: Icons.trending_up,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SideActionButton(icon: Icons.send, onTap: () {}, filled: true),
                    const SizedBox(height: 16),
                    _SideActionButton(icon: Icons.share, onTap: () => _shareCard(context, provider, selected)),
                    const SizedBox(height: 16),
                    _SideActionButton(icon: Icons.nfc, onTap: () {}, showDot: true),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// 에디터와 동일 비율 (242.55 : 388.08 = 1 : 1.6)
  static const double _cardAspectWidth = 242.55;
  static const double _cardAspectHeight = 388.08;

  /// 에디터 명함(DigitalCard) 레이아웃·내용을 스케일만 맞춰 그대로 표시 (배경/주소/아이콘 동일).
  Widget _buildCompactCard(BuildContext context, AppProvider provider, CardData data) {
    return AspectRatio(
      aspectRatio: _cardAspectWidth / _cardAspectHeight,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 50,
              offset: const Offset(0, 25),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: _cardAspectWidth,
              height: _cardAspectHeight,
              child: DigitalCard(data: data, isLarge: false),
            ),
          ),
        ),
      ),
    );
  }

  static String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  Widget _buildRecentSendHistory() {
    final mockItems = [
      ('David Chen', 'Sent via NFC Tag', '2 mins ago'),
      ('Sarah Jenkins', 'Sent via KakaoTalk', '1 hour ago'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionLabel('RECENT SEND HISTORY'),
            GestureDetector(
              onTap: () {},
              child: Text(
                'VIEW ALL',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...mockItems.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _RecentSendTile(name: e.$1, subtitle: e.$2, time: e.$3),
        )),
      ],
    );
  }

  Widget _buildInsightAnalysis(int views, int sends) {
    const weekHeights = [0.3, 0.45, 0.85, 0.6, 0.55, 0.4, 0.35];
    const weekLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionLabel('INSIGHT ANALYSIS'),
            Icon(Icons.trending_up, size: 18, color: _textMuted),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TOTAL VIEWS', style: _insightLabelStyle()),
                        const SizedBox(height: 4),
                        Text('${views + 16}', style: _insightValueStyle()),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.arrow_upward, size: 12, color: Colors.green.shade400),
                            const SizedBox(width: 2),
                            Text('12%', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade400)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 48, color: Colors.white.withValues(alpha: 0.1)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SUCCESS RATE', style: _insightLabelStyle()),
                        const SizedBox(height: 4),
                        Text('98%', style: _insightValueStyle().copyWith(color: AppTheme.primary)),
                        const SizedBox(height: 4),
                        Text('TOP PERFORMANCE', style: _insightLabelStyle()),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08)))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('WEEKLY ACTIVITY', style: _insightLabelStyle()),
                        Text('Mon - Sun', style: GoogleFonts.manrope(fontSize: 9, color: _textMuted)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 96,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(7, (i) {
                          final isHighlight = i == 2;
                          final barHeight = 96 * 0.25 + (96 * 0.6 * weekHeights[i]);
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    height: barHeight,
                                    decoration: BoxDecoration(
                                      color: isHighlight ? AppTheme.primary : Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    weekLabels[i],
                                    style: GoogleFonts.manrope(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: isHighlight ? Colors.grey.shade400 : _textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  TextStyle _insightLabelStyle() => GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: _textMuted);
  TextStyle _insightValueStyle() => GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white);

  void _shareCard(BuildContext context, AppProvider provider, Profile selected) {
    String url = selected.data.shareLink.trim();
    if (url.isEmpty) url = 'https://nuggo.me';
    if (!url.startsWith('http')) url = 'https://$url';
    final name = selected.data.fullName.isEmpty ? selected.name : selected.data.fullName;
    Share.share(
      url,
      subject: '명함: $name',
    );
  }

  Profile _resolveSelectedProfile(List<Profile> profiles) {
    if (_selectedProfileId != null) {
      for (final p in profiles) {
        if (p.id == _selectedProfileId) return p;
      }
    }
    return profiles.first;
  }

  int _mockViewCount(Profile profile) => (profile.id.hashCode.abs() % 900) + 384;
  int _mockSendCount(Profile profile) => (profile.id.hashCode.abs() % 200) + 252;
}

class _ProfilePill extends StatelessWidget {
  final Profile profile;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProfilePill({
    required this.profile,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final data = profile.data;
    final profileSaveName = profile.name;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: isSelected ? 1 : 0.6,
        child: Container(
          width: 64,
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primary : Colors.white.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: _MiniCardPreview(data: data, profileSaveName: profileSaveName),
          ),
        ),
      ),
    );
  }
}

/// 프로필 썸네일: 에디터에서 만든 명함 배경(테마) + 프로필 저장 이름만 간단히 표시
class _MiniCardPreview extends StatelessWidget {
  final CardData data;
  final String profileSaveName;

  const _MiniCardPreview({required this.data, required this.profileSaveName});

  static Color _parseThemeColor(String theme) {
    if (!theme.startsWith('#')) return const Color(0xFF1a1c1e);
    final h = theme.replaceAll('#', '');
    final full = h.length == 3 ? h.split('').map((c) => '$c$c').join() : h;
    if (full.length < 6) return const Color(0xFF1a1c1e);
    return Color(int.parse('FF$full', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final theme = data.theme;
    final isHex = theme.startsWith('#');
    final name = profileSaveName.trim().isEmpty ? '명함' : profileSaveName;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isHex ? _parseThemeColor(theme) : null,
        image: !isHex && theme.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(theme),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!isHex && theme.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
              child: Text(
                name,
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Colors.black.withValues(alpha: 0.7), blurRadius: 4, offset: const Offset(0, 1)),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddProfilePill extends StatelessWidget {
  final VoidCallback onTap;

  const _AddProfilePill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 64,
        height: 96,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
          color: Colors.white.withValues(alpha: 0.05),
        ),
        child: Icon(Icons.add, size: 32, color: Colors.white.withValues(alpha: 0.3)),
      ),
    );
  }
}

/// 조회수/발송수 블록 (카드 오른쪽)
class _ViewsSendsBlock extends StatelessWidget {
  final IconData icon;
  final String value;
  final String subtitle;
  final Color subtitleColor;
  final IconData subtitleIcon;

  const _ViewsSendsBlock({
    required this.icon,
    required this.value,
    required this.subtitle,
    required this.subtitleColor,
    required this.subtitleIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: AppTheme.primary),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(subtitleIcon, size: 12, color: subtitleColor),
            const SizedBox(width: 4),
            Text(
              subtitle,
              style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: subtitleColor),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecentSendTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final String time;

  const _RecentSendTile({required this.name, required this.subtitle, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: Colors.grey.shade800, shape: BoxShape.circle),
            child: Icon(Icons.person, color: Colors.white.withValues(alpha: 0.4), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                Text(subtitle, style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF64748B))),
              ],
            ),
          ),
          Text(time, style: GoogleFonts.manrope(fontSize: 10, color: const Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _SideActionButton extends StatelessWidget {
  static const Color _accentOrange = Color(0xFFFF8A3D);
  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;
  final bool filled;

  const _SideActionButton({required this.icon, required this.onTap, this.showDot = false, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? _accentOrange : const Color(0xFF101822).withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: filled ? null : Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 30, color: Colors.white),
              if (showDot)
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF101822).withValues(alpha: 0.5)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

