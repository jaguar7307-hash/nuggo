import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/theme.dart';

// ═══════════════════════════════════════════════════════════
// 모델
// ═══════════════════════════════════════════════════════════
enum WalletCardType { digital, scanned }

enum WalletBadge { none, vip, newCard, followUp }

class WalletCard {
  final String id;
  final String name;
  final String company;
  final String jobTitle;
  final String phone;
  final String email;
  final WalletCardType type;
  WalletBadge badge;
  final List<String> tags;
  final DateTime scannedAt;
  String memo;
  String? location;
  bool isFavorite;

  WalletCard({
    required this.id,
    required this.name,
    required this.company,
    required this.jobTitle,
    required this.phone,
    required this.email,
    required this.type,
    this.badge = WalletBadge.none,
    this.tags = const [],
    required this.scannedAt,
    this.memo = '',
    this.location,
    this.isFavorite = false,
  });

  int get daysSinceContact =>
      DateTime.now().difference(scannedAt).inDays;

  bool get isLongInactive => daysSinceContact > 90;
}

// ═══════════════════════════════════════════════════════════
// 더미 데이터
// ═══════════════════════════════════════════════════════════
final List<WalletCard> _sampleCards = [
  WalletCard(
    id: '1',
    name: '김민준',
    company: '삼성전자',
    jobTitle: '구매팀 과장',
    phone: '010-1234-5678',
    email: 'minjun@samsung.com',
    type: WalletCardType.scanned,
    badge: WalletBadge.vip,
    tags: ['#A사_구매팀', '#25년_상반기_전시회'],
    scannedAt: DateTime.now().subtract(const Duration(days: 2)),
    memo: '반도체 부품 담당. 다음 달 미팅 예정.',
    location: '코엑스 전시장',
    isFavorite: true,
  ),
  WalletCard(
    id: '2',
    name: '이지은',
    company: 'LG에너지솔루션',
    jobTitle: '영업본부장',
    phone: '010-9876-5432',
    email: 'jieun@lges.com',
    type: WalletCardType.digital,
    badge: WalletBadge.followUp,
    tags: ['#배터리_사업부', '#VIP'],
    scannedAt: DateTime.now().subtract(const Duration(days: 5)),
    memo: '신규 배터리 공급 계약 건으로 연락 필요.',
    isFavorite: false,
  ),
  WalletCard(
    id: '3',
    name: '박성호',
    company: '현대자동차',
    jobTitle: '기술연구소 책임연구원',
    phone: '010-5555-7777',
    email: 'sungho@hyundai.com',
    type: WalletCardType.scanned,
    badge: WalletBadge.newCard,
    tags: ['#R&D', '#전기차'],
    scannedAt: DateTime.now().subtract(const Duration(hours: 3)),
    memo: '오늘 세미나에서 만남. 전기차 배터리 협업 가능성 논의.',
    location: '서울 강남구 테헤란로',
  ),
  WalletCard(
    id: '4',
    name: '최유진',
    company: 'SK하이닉스',
    jobTitle: 'B2B 영업 대리',
    phone: '010-2222-3333',
    email: 'yujin@skhynix.com',
    type: WalletCardType.digital,
    tags: ['#반도체', '#거래처'],
    scannedAt: DateTime.now().subtract(const Duration(days: 30)),
    isFavorite: true,
  ),
  WalletCard(
    id: '5',
    name: '정현우',
    company: '포스코',
    jobTitle: '소재사업부 차장',
    phone: '010-4444-8888',
    email: 'hyunwoo@posco.com',
    type: WalletCardType.scanned,
    tags: ['#철강', '#협력사'],
    scannedAt: DateTime.now().subtract(const Duration(days: 125)),
    memo: '작년 전시회에서 만남. 한동안 연락 없음.',
  ),
  WalletCard(
    id: '6',
    name: '윤서연',
    company: '카카오',
    jobTitle: '비즈니스 파트너십 매니저',
    phone: '010-3333-6666',
    email: 'seoyeon@kakao.com',
    type: WalletCardType.digital,
    badge: WalletBadge.followUp,
    tags: ['#플랫폼', '#광고', '#제휴'],
    scannedAt: DateTime.now().subtract(const Duration(days: 10)),
    memo: '광고 플랫폼 제휴 건 검토 중.',
    isFavorite: true,
  ),
];

// ═══════════════════════════════════════════════════════════
// 색상 헬퍼
// ═══════════════════════════════════════════════════════════
const _bizBlue = Color(0xFF1D4ED8);
const _bizBlueLight = Color(0xFF3B82F6);
const _vipGold = Color(0xFFF59E0B);
const _newTeal = Color(0xFF10B981);
const _followOrange = Color(0xFFFF8A3D);
const _scanGreen = Color(0xFF22C55E);
const _digitalPurple = Color(0xFF8B5CF6);

Color _badgeColor(WalletBadge b) {
  switch (b) {
    case WalletBadge.vip:
      return _vipGold;
    case WalletBadge.newCard:
      return _newTeal;
    case WalletBadge.followUp:
      return _followOrange;
    case WalletBadge.none:
      return Colors.transparent;
  }
}

String _badgeLabel(WalletBadge b) {
  switch (b) {
    case WalletBadge.vip:
      return 'VIP';
    case WalletBadge.newCard:
      return 'NEW';
    case WalletBadge.followUp:
      return '팔로업';
    case WalletBadge.none:
      return '';
  }
}

// ═══════════════════════════════════════════════════════════
// WalletScreen
// ═══════════════════════════════════════════════════════════
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  int _filterIndex = 0; // 0=전체, 1=디지털, 2=스캔, 3=즐겨찾기
  String _searchQuery = '';
  final List<WalletCard> _cards = List.from(_sampleCards);

  static const _filters = ['전체', '디지털', '스캔', '즐겨찾기'];

  // ── Stats ─────────────────────────────────
  int get _totalCards => _cards.length;

  int get _thisMonthCards {
    final now = DateTime.now();
    return _cards
        .where(
          (c) =>
              c.scannedAt.year == now.year && c.scannedAt.month == now.month,
        )
        .length;
  }

  int get _followUpCount =>
      _cards.where((c) => c.badge == WalletBadge.followUp).length;

  // ── 필터링 ────────────────────────────────
  List<WalletCard> get _filteredCards {
    var list = _cards.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.company.toLowerCase().contains(q) ||
          c.jobTitle.toLowerCase().contains(q) ||
          c.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();

    switch (_filterIndex) {
      case 1:
        list = list.where((c) => c.type == WalletCardType.digital).toList();
        break;
      case 2:
        list = list.where((c) => c.type == WalletCardType.scanned).toList();
        break;
      case 3:
        list = list.where((c) => c.isFavorite).toList();
        break;
    }
    list.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return list;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ColoredBox(
      color: isDark ? const Color(0xFF020617) : const Color(0xFFF8F9FA),
      child: GestureDetector(
      // 배경 탭 시 키보드 내리기
      onTap: () => FocusScope.of(context).unfocus(),
      // 아래로 스와이프 시 키보드 내리기
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 200) {
          FocusScope.of(context).unfocus();
        }
      },
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          Column(
            children: [
              _buildSearchBar(isDark),
              _buildFilterChips(isDark),
              _buildStatsRow(isDark),
              Expanded(
                child: _filteredCards.isEmpty
                    ? _buildEmptyState(isDark)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: _filteredCards.length,
                        itemBuilder: (_, i) =>
                            _buildCardTile(_filteredCards[i], isDark),
                      ),
              ),
            ],
          ),
          // ── 스캔 FAB (최하단 중앙) ─────────────────
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(child: _buildScanFab()),
          ),
        ],
      ),
    ), // GestureDetector
    ); // ColoredBox
  }

  // ═══════════════════════════════════════════
  // 검색바
  // ═══════════════════════════════════════════
  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        autofocus: false,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: '이름, 회사, 키워드 검색',
          hintStyle: TextStyle(
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.withValues(alpha: 0.15),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _bizBlueLight, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 필터 칩
  // ═══════════════════════════════════════════
  Widget _buildFilterChips(bool isDark) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final selected = _filterIndex == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filterIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primary
                      : isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? AppTheme.primary
                        : isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  _filters[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? Colors.white
                        : isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 통계 대시보드 (참조 ①에서 추가)
  // ═══════════════════════════════════════════
  Widget _buildStatsRow(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          _statCard('전체 명함', '$_totalCards장', Icons.style_outlined,
              AppTheme.primary, isDark),
          const SizedBox(width: 8),
          _statCard('이번 달 추가', '+$_thisMonthCards', Icons.add_circle_outline,
              _newTeal, isDark),
          const SizedBox(width: 8),
          _statCard('팔로업 예정', '$_followUpCount건',
              Icons.notifications_active_outlined, _followOrange, isDark),
        ],
      ),
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 명함 카드 타일
  // ═══════════════════════════════════════════
  Widget _buildCardTile(WalletCard card, bool isDark) {
    final typeColor =
        card.type == WalletCardType.digital ? _digitalPurple : _scanGreen;
    final typeLabel =
        card.type == WalletCardType.digital ? '디지털' : '스캔';

    return GestureDetector(
      onTap: () => _showCardDetail(context, card),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: card.isLongInactive
                ? _vipGold.withValues(alpha: 0.4)
                : isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 아바타 + 타입 뱃지 ───────────────
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: typeColor.withValues(alpha: 0.15),
                    child: Text(
                      card.name[0],
                      style: TextStyle(
                        color: typeColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: typeColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        typeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // ── 텍스트 정보 ───────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                card.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              if (card.badge != WalletBadge.none) ...[
                                const SizedBox(width: 6),
                                _buildBadge(card.badge),
                              ],
                            ],
                          ),
                        ),
                        // 즐겨찾기
                        GestureDetector(
                          onTap: () => setState(
                              () => card.isFavorite = !card.isFavorite),
                          child: Icon(
                            card.isFavorite
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 20,
                            color: card.isFavorite
                                ? _vipGold
                                : isDark
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      card.jobTitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      card.company,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // 태그
                    if (card.tags.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: card.tags
                            .map(
                              (t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  t,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    // ── 오랫동안 연락 안 한 경고 ─────────
                    if (card.isLongInactive) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.schedule,
                              size: 11, color: _vipGold),
                          const SizedBox(width: 3),
                          Text(
                            '${card.daysSinceContact}일간 연락 없음',
                            style: const TextStyle(
                              fontSize: 10,
                              color: _vipGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // 메모 미리보기
                    if (card.memo.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        card.memo,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // ── 퀵 액션 ───────────────────────────
              Column(
                children: [
                  _quickAction(
                    Icons.phone_rounded,
                    '전화',
                    _bizBlueLight,
                    () => _makeCall(card.phone),
                  ),
                  const SizedBox(height: 6),
                  _quickAction(
                    Icons.chat_bubble_outline_rounded,
                    '문자',
                    _newTeal,
                    () => _sendSms(card.phone),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(WalletBadge badge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _badgeColor(badge),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _badgeLabel(badge),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _quickAction(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 빈 상태
  // ═══════════════════════════════════════════
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.contact_page_outlined,
            size: 64,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '명함이 없습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '아래 + 버튼으로 명함을 스캔해보세요',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 스캔 FAB
  // ═══════════════════════════════════════════
  Widget _buildScanFab() {
    return GestureDetector(
      onTap: () => _showScanFlow(context),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.document_scanner_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 명함 상세 (슬라이드 앞면/뒷면)
  // ═══════════════════════════════════════════
  void _showCardDetail(BuildContext context, WalletCard card) {
    // 시트 열기 전 포커스 해제 (시트 닫힐 때 검색창 자동 활성화 방지)
    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => _CardDetailSheet(
        card: card,
        onReminderTap: () {
          Navigator.pop(context);
          _showReminderDialog(context, card);
        },
        onNearbyTap: () {
          Navigator.pop(context);
          _showNearbyContacts(context);
        },
        onSyncTap: () {
          Navigator.pop(context);
          _showSyncDialog(context, card);
        },
        onMemoSaved: (newMemo) {
          setState(() => card.memo = newMemo);
        },
        onDelete: () {
          Navigator.pop(context);
          final deletedIndex = _cards.indexOf(card);
          setState(() => _cards.remove(card));

          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${card.name}님 명함이 삭제되었습니다.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red.shade600,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: '되돌기',
                textColor: Colors.white,
                onPressed: () {
                  setState(() {
                    final insertAt = deletedIndex.clamp(0, _cards.length);
                    _cards.insert(insertAt, card);
                  });
                },
              ),
            ),
          );
        },
      ),
    ).then((_) {
      // 시트 닫힌 뒤 포커스가 검색창으로 복원되는 것 방지 (한 프레임 뒤에 해제)
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _searchFocusNode.unfocus();
        FocusScope.of(context).unfocus();
      });
    });
  }

  // ═══════════════════════════════════════════
  // 스캔 플로우 (OCR 4단계)
  // ═══════════════════════════════════════════
  void _showScanFlow(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ScanFlowDialog(
        onCardSaved: (card) {
          setState(() {
            _cards.insert(0, card);
          });
        },
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 리마인더 설정
  // ═══════════════════════════════════════════
  void _showReminderDialog(BuildContext context, WalletCard card) {
    showDialog(
      context: context,
      builder: (ctx) => _ReminderDialog(card: card),
    );
  }

  // ═══════════════════════════════════════════
  // 근처 인맥 보기
  // ═══════════════════════════════════════════
  void _showNearbyContacts(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor:
              isDark ? const Color(0xFF1E293B) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.location_on, color: _bizBlueLight),
              SizedBox(width: 8),
              Text('근처 인맥 보기', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Container(
            height: 200,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 48, color: _bizBlueLight),
                  SizedBox(height: 8),
                  Text(
                    '위치 기반 인맥 지도',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '주소 데이터가 있는 명함을\n지도에 표시합니다',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
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
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  // 연락처 동기화
  // ═══════════════════════════════════════════
  void _showSyncDialog(BuildContext context, WalletCard card) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor:
              isDark ? const Color(0xFF1E293B) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.sync, color: _newTeal),
              SizedBox(width: 8),
              Text('연락처 저장', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Text(
            '${card.name}님의 정보를\n휴대폰 연락처 앱에 저장할까요?',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('취소',
                  style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${card.name}님이 연락처에 저장되었습니다.'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: _newTeal,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: _newTeal),
              child: const Text('저장', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  // 퀵 액션 핸들러
  // ═══════════════════════════════════════════
  void _makeCall(String phone) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$phone 에 전화 걸기'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: _bizBlueLight,
      ),
    );
  }

  void _sendSms(String phone) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$phone 에 문자 보내기'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: _newTeal,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 명함 상세 시트 (PageView 앞면/뒷면 슬라이드)
// ═══════════════════════════════════════════════════════════
class _CardDetailSheet extends StatefulWidget {
  final WalletCard card;
  final VoidCallback onReminderTap;
  final VoidCallback onNearbyTap;
  final VoidCallback onSyncTap;
  final ValueChanged<String> onMemoSaved;
  final VoidCallback onDelete;

  const _CardDetailSheet({
    required this.card,
    required this.onReminderTap,
    required this.onNearbyTap,
    required this.onSyncTap,
    required this.onMemoSaved,
    required this.onDelete,
  });

  @override
  State<_CardDetailSheet> createState() => _CardDetailSheetState();
}

class _CardDetailSheetState extends State<_CardDetailSheet> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late TextEditingController _memoController;

  @override
  void initState() {
    super.initState();
    _memoController = TextEditingController(text: widget.card.memo);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = widget.card;
    final typeColor =
        card.type == WalletCardType.digital ? _digitalPurple : _scanGreen;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.25,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // 드래그 핸들 (아래로 스와이프하여 내리기)
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              // 페이지 인디케이터 + 삭제 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _pageIndicator(0, '앞면', isDark),
                    const SizedBox(width: 8),
                    _pageIndicator(1, '뒷면(메모)', isDark),
                    const Spacer(),
                    // 삭제 버튼
                    IconButton(
                      onPressed: () => _showDeleteConfirm(context),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 22,
                        color: Colors.red.shade400,
                      ),
                      tooltip: '명함 삭제',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 8),
          // PageView
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (p) => setState(() => _currentPage = p),
              children: [
                // ── 앞면 ────────────────────────
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    children: [
                      // 명함 카드 비주얼
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: card.type == WalletCardType.digital
                                ? [
                                    const Color(0xFF1E1B4B),
                                    const Color(0xFF312E81),
                                  ]
                                : [
                                    const Color(0xFF064E3B),
                                    const Color(0xFF065F46),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: typeColor.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  card.company,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (card.badge != WalletBadge.none)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _badgeColor(card.badge),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _badgeLabel(card.badge),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              card.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              card.jobTitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _contactRow(Icons.phone_outlined, card.phone),
                            const SizedBox(height: 6),
                            _contactRow(Icons.email_outlined, card.email),
                            if (card.location != null) ...[
                              const SizedBox(height: 6),
                              _contactRow(
                                  Icons.location_on_outlined, card.location!),
                            ],
                            const SizedBox(height: 16),
                            // 스캔 날짜
                            Text(
                              '${_formatDate(card.scannedAt)} 저장',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 태그
                      if (card.tags.isNotEmpty) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '태그',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: card.tags
                              .map(
                                (t) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          AppTheme.primary.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    t,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // 액션 버튼들
                      Row(
                        children: [
                          Expanded(
                            child: _actionButton(
                              Icons.notifications_active_outlined,
                              '리마인더',
                              _followOrange,
                              widget.onReminderTap,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _actionButton(
                              Icons.location_on_outlined,
                              '근처 인맥',
                              _bizBlueLight,
                              widget.onNearbyTap,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _actionButton(
                              Icons.sync,
                              '연락처 저장',
                              _newTeal,
                              widget.onSyncTap,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // ── 뒷면 (메모 영역) ────────────────
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.grey.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.edit_note,
                                    size: 18, color: _bizBlueLight),
                                const SizedBox(width: 6),
                                Text(
                                  '미팅 메모',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _memoController,
                              maxLines: 6,
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    '어디서 만났나요? 미팅 내용을 기록하세요.\n예) 25년 상반기 전시회, 잠재 고객, B2B 협력 가능성 논의',
                                hintStyle: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade400,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  widget.onMemoSaved(_memoController.text);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('메모가 저장되었습니다.'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: _newTeal,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('메모 저장',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 미팅 정보
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.grey.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '만난 정보',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _infoRow(Icons.calendar_today_outlined,
                                _formatDate(card.scannedAt), isDark),
                            if (card.location != null) ...[
                              const SizedBox(height: 4),
                              _infoRow(Icons.location_on_outlined,
                                  card.location!, isDark),
                            ],
                            const SizedBox(height: 4),
                            _infoRow(
                              Icons.schedule_outlined,
                              card.isLongInactive
                                  ? '${card.daysSinceContact}일 전 (연락 필요)'
                                  : '${card.daysSinceContact}일 전',
                              isDark,
                              color: card.isLongInactive ? _vipGold : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red.shade400, size: 22),
            const SizedBox(width: 8),
            const Text('명함 삭제', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(
          '${widget.card.name}님 명함을 삭제할까요?\n삭제된 명함은 복구할 수 없습니다.',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              '취소',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('삭제', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _pageIndicator(int page, String label, bool isDark) {
    final isActive = _currentPage == page;
    return GestureDetector(
      onTap: () => _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary
              : isDark
                  ? const Color(0xFF1E293B)
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppTheme.primary
                : isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              page == 0 ? Icons.credit_card : Icons.edit_note,
              size: 14,
              color: isActive
                  ? Colors.white
                  : isDark
                      ? Colors.grey.shade400
                      : Colors.grey.shade500,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? Colors.white
                    : isDark
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _actionButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, bool isDark,
      {Color? color}) {
    final c = color ??
        (isDark ? Colors.grey.shade400 : Colors.grey.shade600);
    return Row(
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: c),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 스캔 플로우 다이얼로그 (4단계 OCR)
// ═══════════════════════════════════════════════════════════
class _ScanFlowDialog extends StatefulWidget {
  final ValueChanged<WalletCard> onCardSaved;

  const _ScanFlowDialog({required this.onCardSaved});

  @override
  State<_ScanFlowDialog> createState() => _ScanFlowDialogState();
}

class _ScanFlowDialogState extends State<_ScanFlowDialog>
    with TickerProviderStateMixin {
  int _step = 0; // 0:뷰파인더, 1:OCR중, 2:데이터확인, 3:메모
  late AnimationController _scanLineCtrl;
  late Animation<double> _scanLineAnim;
  late AnimationController _typeCtrl;

  // 시뮬레이션 OCR 결과
  final _fields = <String, String>{
    '성함': '홍길동',
    '직함': '마케팅팀 팀장',
    '회사': 'ABC코퍼레이션',
    '전화': '010-7777-9999',
    '이메일': 'hong@abc.co.kr',
  };
  final Map<String, String> _revealed = {};
  final TextEditingController _memoCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scanLineAnim =
        Tween<double>(begin: 0.0, end: 1.0).animate(_scanLineCtrl);

    _typeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _scanLineCtrl.dispose();
    _typeCtrl.dispose();
    _memoCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _onCapture() async {
    setState(() => _step = 1);
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    setState(() => _step = 2);
    for (final key in _fields.keys) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      setState(() => _revealed[key] = _fields[key]!);
    }
  }

  void _onSave() {
    final card = WalletCard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _revealed['성함'] ?? '이름 없음',
      company: _revealed['회사'] ?? '',
      jobTitle: _revealed['직함'] ?? '',
      phone: _revealed['전화'] ?? '',
      email: _revealed['이메일'] ?? '',
      type: WalletCardType.scanned,
      badge: WalletBadge.newCard,
      tags: [],
      scannedAt: DateTime.now(),
      memo: _memoCtrl.text,
      location: _locationCtrl.text.isEmpty ? null : _locationCtrl.text,
    );
    widget.onCardSaved(card);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('명함이 저장되었습니다!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _newTeal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360, maxHeight: 560),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
              child: Row(
                children: [
                  Icon(Icons.document_scanner_rounded,
                      color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _stepTitle(),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            // 스텝 인디케이터
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: List.generate(4, (i) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                      decoration: BoxDecoration(
                        color: i <= _step
                            ? AppTheme.primary
                            : isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            // 본문
            Flexible(
              child: SingleChildScrollView(
                child: _buildStepContent(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _stepTitle() {
    switch (_step) {
      case 0:
        return '명함을 프레임에 맞춰주세요';
      case 1:
        return 'OCR 인식 중...';
      case 2:
        return '정보 확인';
      case 3:
        return '메모 입력';
      default:
        return '';
    }
  }

  Widget _buildStepContent(bool isDark) {
    switch (_step) {
      case 0:
        return _buildViewfinder();
      case 1:
        return _buildOcrLoading(isDark);
      case 2:
        return _buildDataConfirm(isDark);
      case 3:
        return _buildMemoInput(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 0: 뷰파인더 ─────────────────────────
  Widget _buildViewfinder() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                // 스캔 라인 애니메이션
                AnimatedBuilder(
                  animation: _scanLineAnim,
                  builder: (_, __) {
                    return Positioned(
                      top: _scanLineAnim.value * 180,
                      left: 16,
                      right: 16,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppTheme.primary.withValues(alpha: 0.8),
                              AppTheme.primary,
                              AppTheme.primary.withValues(alpha: 0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // 코너 가이드
                ..._buildCornerGuides(),
                Center(
                  child: Text(
                    '명함을 여기에 놓으세요',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '밝은 곳에서 명함 전체가 보이도록 촬영하세요',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _onCapture,
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              label: const Text('촬영',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerGuides() {
    const size = 20.0;
    const thick = 3.0;
    const color = _bizBlueLight;
    return [
      Positioned(
          top: 12,
          left: 12,
          child: _corner(size, thick, color, top: true, left: true)),
      Positioned(
          top: 12,
          right: 12,
          child: _corner(size, thick, color, top: true, left: false)),
      Positioned(
          bottom: 12,
          left: 12,
          child: _corner(size, thick, color, top: false, left: true)),
      Positioned(
          bottom: 12,
          right: 12,
          child: _corner(size, thick, color, top: false, left: false)),
    ];
  }

  Widget _corner(double size, double thick, Color color,
      {required bool top, required bool left}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
            color: color, thick: thick, top: top, left: left),
      ),
    );
  }

  // ── Step 1: OCR 로딩 ─────────────────────────
  Widget _buildOcrLoading(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: _bizBlueLight,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'AI OCR 인식 중...',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '명함의 텍스트를 자동으로 추출하고 있습니다',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Step 2: 데이터 확인 (텍스트 자동 채우기 애니메이션) ──
  Widget _buildDataConfirm(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '인식된 정보를 확인하세요',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          ...(_fields.keys.map((key) {
            final isRevealed = _revealed.containsKey(key);
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: isRevealed ? 1.0 : 0.3,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isRevealed
                        ? AppTheme.primary.withValues(alpha: 0.08)
                        : isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isRevealed
                          ? AppTheme.primary.withValues(alpha: 0.3)
                          : isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(
                          key,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          isRevealed ? _revealed[key]! : '─────',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isRevealed
                                ? (isDark ? Colors.white : Colors.black87)
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),
                      if (isRevealed)
                        Icon(Icons.check_circle,
                            size: 14, color: _newTeal),
                    ],
                  ),
                ),
              ),
            );
          })),
          const SizedBox(height: 12),
          if (_revealed.length == _fields.length)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(() => _step = 3),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('다음 → 메모 입력',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
        ],
      ),
    );
  }

  // ── Step 3: 메모 입력 ────────────────────────
  Widget _buildMemoInput(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '미팅 성격과 메모를 남겨두세요\n(영업맨의 가장 중요한 기록)',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _memoCtrl,
            maxLines: 4,
            autofocus: true,
            style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText:
                  '예) 잠재 고객 / 협력사 / A 전시회에서 만남\n전기차 부품 공급 가능성 논의...',
              hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? Colors.grey.shade600
                      : Colors.grey.shade400),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _locationCtrl,
            style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: '만난 장소 (예: 코엑스 전시장)',
              hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? Colors.grey.shade600
                      : Colors.grey.shade400),
              prefixIcon: const Icon(Icons.location_on_outlined,
                  size: 16, color: _bizBlueLight),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: _newTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('명함 저장 완료',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 리마인더 다이얼로그
// ═══════════════════════════════════════════════════════════
class _ReminderDialog extends StatefulWidget {
  final WalletCard card;

  const _ReminderDialog({required this.card});

  @override
  State<_ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<_ReminderDialog> {
  int _selectedDays = 3;
  final _options = [1, 3, 7, 14, 30];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: const [
          Icon(Icons.notifications_active, color: _followOrange, size: 20),
          SizedBox(width: 8),
          Text('리마인더 설정', style: TextStyle(fontSize: 16)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.card.name}님께 안부 연락할 날짜를 설정하세요',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _options.map((days) {
              final selected = _selectedDays == days;
              return GestureDetector(
                onTap: () => setState(() => _selectedDays = days),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? _followOrange
                        : isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? _followOrange
                          : isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    '$days일 후',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? Colors.white
                          : isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _followOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 14, color: _followOrange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$_selectedDays일 후 "${widget.card.name}님께 안부 연락하기" 알림이 울립니다',
                    style: const TextStyle(
                        fontSize: 11, color: _followOrange),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('취소',
              style: TextStyle(
                  color:
                      isDark ? Colors.grey.shade400 : Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '${_selectedDays}일 후 ${widget.card.name}님 연락 알림이 설정되었습니다'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: _followOrange,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _followOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('설정 완료',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 코너 가이드 페인터
// ═══════════════════════════════════════════════════════════
class _CornerPainter extends CustomPainter {
  final Color color;
  final double thick;
  final bool top;
  final bool left;

  _CornerPainter({
    required this.color,
    required this.thick,
    required this.top,
    required this.left,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thick
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final h = size.height;
    final w = size.width;

    if (top && left) {
      canvas.drawLine(Offset.zero, Offset(w, 0), paint);
      canvas.drawLine(Offset.zero, Offset(0, h), paint);
    } else if (top && !left) {
      canvas.drawLine(Offset(0, 0), Offset(w, 0), paint);
      canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
    } else if (!top && left) {
      canvas.drawLine(Offset(0, 0), Offset(0, h), paint);
      canvas.drawLine(Offset(0, h), Offset(w, h), paint);
    } else {
      canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
      canvas.drawLine(Offset(0, h), Offset(w, h), paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter old) =>
      old.color != color || old.thick != thick;
}

// ═══════════════════════════════════════════════════════════
// 유틸
// ═══════════════════════════════════════════════════════════
String _formatDate(DateTime dt) {
  return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
}

// math 패키지 사용 참조 (unused import 방지)
final _unusedMath = math.pi;
