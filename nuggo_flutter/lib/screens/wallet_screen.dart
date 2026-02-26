import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/theme.dart';

// ─────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────

enum ReceivedCardSource { digital, scanned }

class ReceivedCard {
  final String id;
  final String name;
  final String jobTitle;
  final String company;
  final String? phone;
  final String? email;
  final List<String> tags;
  final ReceivedCardSource source;
  final DateTime receivedAt;
  final String? avatarInitials;
  final Color? avatarColor;
  final String? memo;

  const ReceivedCard({
    required this.id,
    required this.name,
    required this.jobTitle,
    required this.company,
    this.phone,
    this.email,
    required this.tags,
    required this.source,
    required this.receivedAt,
    this.avatarInitials,
    this.avatarColor,
    this.memo,
  });
}

// ─────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────

enum _FilterTab { all, digital, scanned }

enum _SortType { recent, alphabetical, company }

// ─────────────────────────────────────────────
// WalletScreen
// ─────────────────────────────────────────────

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  static const Color _bgDark = Color(0xFF101822);
  static const Color _textMuted = Color(0xFF64748B);

  _FilterTab _activeFilter = _FilterTab.all;
  _SortType _sortType = _SortType.recent;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchFocused = false;

  late final AnimationController _scanAnimController;
  late final Animation<double> _scanPulse;

  final List<ReceivedCard> _mockCards = [
    ReceivedCard(
      id: '1',
      name: '김민준',
      jobTitle: '영업 이사',
      company: '삼성전자',
      phone: '010-1234-5678',
      email: 'minjun.kim@samsung.com',
      tags: ['전자', 'B2B'],
      source: ReceivedCardSource.digital,
      receivedAt: DateTime.now().subtract(const Duration(hours: 2)),
      avatarInitials: '김민',
      avatarColor: Color(0xFF6366F1),
    ),
    ReceivedCard(
      id: '2',
      name: '박서연',
      jobTitle: '마케팅 팀장',
      company: 'LG생활건강',
      phone: '010-2345-6789',
      email: 'seoyeon.park@lg.com',
      tags: ['소비재', 'B2C', 'VIP'],
      source: ReceivedCardSource.scanned,
      receivedAt: DateTime.now().subtract(const Duration(hours: 5)),
      avatarInitials: '박서',
      avatarColor: Color(0xFF10B981),
    ),
    ReceivedCard(
      id: '3',
      name: '이준호',
      jobTitle: '대표이사',
      company: '스타트업 ABC',
      phone: '010-3456-7890',
      email: 'jh.lee@startup-abc.com',
      tags: ['스타트업', 'SaaS'],
      source: ReceivedCardSource.digital,
      receivedAt: DateTime.now().subtract(const Duration(days: 1)),
      avatarInitials: '이준',
      avatarColor: Color(0xFFFF6B35),
    ),
    ReceivedCard(
      id: '4',
      name: '최유진',
      jobTitle: '구매 담당',
      company: 'SK텔레콤',
      phone: '010-4567-8901',
      email: 'youjin.choi@skt.com',
      tags: ['통신', 'B2B'],
      source: ReceivedCardSource.scanned,
      receivedAt: DateTime.now().subtract(const Duration(days: 2)),
      avatarInitials: '최유',
      avatarColor: Color(0xFF8B5CF6),
    ),
    ReceivedCard(
      id: '5',
      name: 'David Chen',
      jobTitle: 'Sales Director',
      company: 'TechCorp USA',
      phone: '+1-555-1234',
      email: 'd.chen@techcorp.com',
      tags: ['해외', 'Tech'],
      source: ReceivedCardSource.digital,
      receivedAt: DateTime.now().subtract(const Duration(days: 3)),
      avatarInitials: 'DC',
      avatarColor: Color(0xFFF59E0B),
    ),
    ReceivedCard(
      id: '6',
      name: '정수현',
      jobTitle: '파트너사 팀장',
      company: '현대자동차',
      phone: '010-5678-9012',
      email: 'sh.jung@hyundai.com',
      tags: ['자동차', '파트너'],
      source: ReceivedCardSource.scanned,
      receivedAt: DateTime.now().subtract(const Duration(days: 5)),
      avatarInitials: '정수',
      avatarColor: Color(0xFF06B6D4),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanPulse = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _scanAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<ReceivedCard> get _filteredCards {
    var cards = _mockCards.where((c) {
      if (_activeFilter == _FilterTab.digital) {
        return c.source == ReceivedCardSource.digital;
      }
      if (_activeFilter == _FilterTab.scanned) {
        return c.source == ReceivedCardSource.scanned;
      }
      return true;
    }).toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      cards = cards
          .where(
            (c) =>
                c.name.toLowerCase().contains(q) ||
                c.company.toLowerCase().contains(q) ||
                c.jobTitle.toLowerCase().contains(q) ||
                c.tags.any((t) => t.toLowerCase().contains(q)),
          )
          .toList();
    }

    switch (_sortType) {
      case _SortType.recent:
        cards.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      case _SortType.alphabetical:
        cards.sort((a, b) => a.name.compareTo(b.name));
      case _SortType.company:
        cards.sort((a, b) => a.company.compareTo(b.company));
    }

    return cards;
  }

  int get _digitalCount =>
      _mockCards.where((c) => c.source == ReceivedCardSource.digital).length;
  int get _scannedCount =>
      _mockCards.where((c) => c.source == ReceivedCardSource.scanned).length;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgDark,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildStats(),
                    const SizedBox(height: 20),
                    _buildScanButton(context),
                    const SizedBox(height: 24),
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    _buildFilterTabs(),
                    const SizedBox(height: 10),
                    _buildSortRow(),
                    const SizedBox(height: 12),
                    _buildCardList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Row(
        children: [
          Text(
            'WALLET',
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: _textMuted,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.tune_rounded,
              color: Colors.white70,
              size: 22,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  // ── Stats ────────────────────────────────────

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.smartphone_rounded,
            iconColor: AppTheme.primary,
            count: _digitalCount,
            label: '디지털 명함',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.document_scanner_rounded,
            iconColor: const Color(0xFF10B981),
            count: _scannedCount,
            label: '스캔 명함',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.group_rounded,
            iconColor: const Color(0xFFFF6B35),
            count: _mockCards.length,
            label: '총 연락처',
          ),
        ),
      ],
    );
  }

  // ── Scan Button ───────────────────────────────

  Widget _buildScanButton(BuildContext context) {
    return AnimatedBuilder(
      animation: _scanPulse,
      builder: (context, child) =>
          Transform.scale(scale: _scanPulse.value, child: child),
      child: GestureDetector(
        onTap: () => _showScanSheet(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primary,
                AppTheme.primary.withValues(alpha: 0.75),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.document_scanner_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '명함 스캔하기',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'AI 인식',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Search Bar ────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isSearchFocused
              ? AppTheme.primary.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(Icons.search, color: _textMuted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              onTap: () => setState(() => _isSearchFocused = true),
              onEditingComplete: () => setState(() => _isSearchFocused = false),
              style: GoogleFonts.manrope(fontSize: 14, color: Colors.white),
              decoration: InputDecoration(
                hintText: '이름, 회사, 태그 검색...',
                hintStyle: GoogleFonts.manrope(
                  fontSize: 14,
                  color: _textMuted,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() {
                _searchController.clear();
                _searchQuery = '';
              }),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(Icons.close, color: _textMuted, size: 18),
              ),
            )
          else
            const SizedBox(width: 14),
        ],
      ),
    );
  }

  // ── Filter Tabs ───────────────────────────────

  Widget _buildFilterTabs() {
    return Row(
      children: [
        _FilterChip(
          label: '전체',
          count: _mockCards.length,
          isSelected: _activeFilter == _FilterTab.all,
          onTap: () => setState(() => _activeFilter = _FilterTab.all),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: '디지털',
          count: _digitalCount,
          isSelected: _activeFilter == _FilterTab.digital,
          onTap: () => setState(() => _activeFilter = _FilterTab.digital),
          dotColor: AppTheme.primary,
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: '스캔',
          count: _scannedCount,
          isSelected: _activeFilter == _FilterTab.scanned,
          onTap: () => setState(() => _activeFilter = _FilterTab.scanned),
          dotColor: const Color(0xFF10B981),
        ),
      ],
    );
  }

  // ── Sort Row ──────────────────────────────────

  Widget _buildSortRow() {
    final label = switch (_sortType) {
      _SortType.recent => '최신순',
      _SortType.alphabetical => '이름순',
      _SortType.company => '회사순',
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${_filteredCards.length}개',
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _textMuted,
          ),
        ),
        GestureDetector(
          onTap: _showSortSheet,
          child: Row(
            children: [
              Icon(Icons.swap_vert_rounded, color: _textMuted, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Card List ─────────────────────────────────

  Widget _buildCardList() {
    final cards = _filteredCards;
    if (cards.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.inbox_rounded,
                size: 56,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty ? '검색 결과가 없습니다' : '명함이 없습니다',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: cards
          .map(
            (card) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CardTile(card: card),
            ),
          )
          .toList(),
    );
  }

  // ── Bottom Sheets ─────────────────────────────

  void _showScanSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _ScanBottomSheet(),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SortBottomSheet(
        current: _sortType,
        onSelect: (t) => setState(() => _sortType = t),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _StatCard
// ─────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final int count;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            count.toString(),
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _FilterChip
// ─────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? dotColor;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null && !isSelected) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _CardTile
// ─────────────────────────────────────────────

class _CardTile extends StatelessWidget {
  final ReceivedCard card;

  const _CardTile({required this.card});

  static const Color _textMuted = Color(0xFF64748B);

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: card.avatarColor ?? AppTheme.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                card.avatarInitials ??
                    (card.name.isNotEmpty ? card.name[0] : '?'),
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        card.name,
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SourceBadge(source: card.source),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${card.jobTitle} · ${card.company}',
                  style: GoogleFonts.manrope(fontSize: 12, color: _textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ...card.tags.take(3).map(
                                  (tag) => Padding(
                                    padding: const EdgeInsets.only(right: 5),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.07),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      child: Text(
                                        tag,
                                        style: GoogleFonts.manrope(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timeAgo(card.receivedAt),
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        color: _textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Quick actions
          Column(
            children: [
              _QuickAction(
                icon: Icons.call_rounded,
                color: const Color(0xFF10B981),
                onTap: () {},
              ),
              const SizedBox(height: 8),
              _QuickAction(
                icon: Icons.mail_outline_rounded,
                color: AppTheme.primary,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _SourceBadge
// ─────────────────────────────────────────────

class _SourceBadge extends StatelessWidget {
  final ReceivedCardSource source;

  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    final isDigital = source == ReceivedCardSource.digital;
    final color = isDigital ? AppTheme.primary : const Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDigital
                ? Icons.smartphone_rounded
                : Icons.document_scanner_rounded,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            isDigital ? '디지털' : '스캔',
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _QuickAction
// ─────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _ScanBottomSheet
// ─────────────────────────────────────────────

class _ScanBottomSheet extends StatelessWidget {
  const _ScanBottomSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2433),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '명함 스캔',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'AI가 명함을 자동으로 인식하여 연락처를 저장합니다',
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _ScanOption(
                  icon: Icons.camera_alt_rounded,
                  label: '카메라 촬영',
                  description: '실시간 스캔',
                  color: AppTheme.primary,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ScanOption(
                  icon: Icons.photo_library_rounded,
                  label: '갤러리 선택',
                  description: '이미지 불러오기',
                  color: const Color(0xFF10B981),
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ScanOption(
            icon: Icons.nfc_rounded,
            label: 'NFC 태그',
            description: '디지털 명함 받기',
            color: const Color(0xFFFF6B35),
            onTap: () => Navigator.pop(context),
            isWide: true,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _ScanOption
// ─────────────────────────────────────────────

class _ScanOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;
  final bool isWide;

  const _ScanOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isWide ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 20 : 16,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: isWide
            ? Row(
                children: [
                  Icon(icon, color: color, size: 26),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        description,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                children: [
                  Icon(icon, color: color, size: 30),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      color: const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _SortBottomSheet
// ─────────────────────────────────────────────

class _SortBottomSheet extends StatelessWidget {
  final _SortType current;
  final ValueChanged<_SortType> onSelect;

  const _SortBottomSheet({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final options = [
      (_SortType.recent, Icons.access_time_rounded, '최신순'),
      (_SortType.alphabetical, Icons.sort_by_alpha_rounded, '이름순'),
      (_SortType.company, Icons.business_rounded, '회사순'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2433),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '정렬 방식',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...options.map((e) {
            final isSelected = current == e.$1;
            return GestureDetector(
              onTap: () {
                onSelect(e.$1);
                Navigator.pop(context);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primary.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      e.$2,
                      color: isSelected
                          ? AppTheme.primary
                          : const Color(0xFF64748B),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      e.$3,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
