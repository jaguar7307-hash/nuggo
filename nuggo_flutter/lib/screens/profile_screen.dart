import 'dart:io';

import 'package:flutter/material.dart';
import '../constants/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/theme.dart';
import '../models/card_data.dart';
import '../models/profile.dart';
import '../providers/app_provider.dart';
import '../widgets/digital_card.dart';
import '../widgets/business_card.dart' show kBusinessCardAspectRatio;
import '../widgets/card_display.dart';
import '../widgets/send_card_sheet.dart';
import '../widgets/login_bottom_sheet.dart';
import '../services/card_url_generator.dart';

/// ?? ?? ?? (CRM?)
class _RecentSendItem {
  final String id;
  final String name;
  final String method;
  String time;
  final int revisitCount;
  final int viewCount;
  final String phone;
  bool viewedWithin24h;
  bool downloadedPdfWithin24h;
  String memo;

  _RecentSendItem({
    required this.id,
    required this.name,
    required this.method,
    required this.time,
    this.revisitCount = 0,
    this.viewCount = 0,
    this.phone = '',
    this.viewedWithin24h = false,
    this.downloadedPdfWithin24h = false,
    this.memo = '',
  });

  bool get isContractImminent => viewedWithin24h && downloadedPdfWithin24h;
}

/// ? ?? ??? (My Card) - ???? ??
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _selectedProfileId;

  static const Color _bgDark = Color(0xFF101822);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _deepBlue = Color(0xFF1A237E);
  static const Color _gold = Color(0xFFD4AF37);

  /// ?? 7? ?? ?? (?? ?????)
  static const List<double> _weekTrend = [12, 18, 14, 22, 28, 24, 30];
  /// ?? 1시간 전 ?? ?? ?? (??? ?? ??)
  final bool _hasRecentView = true;

  late List<_RecentSendItem> _recentSends;

  @override
  void initState() {
    super.initState();
    _recentSends = [
      _RecentSendItem(
        id: '1',
        name: 'David Chen',
        method: 'NFC 공유 시도',
        time: '2시간 전',
        revisitCount: 4,
        viewCount: 37,
        phone: '010-1234-5678',
        viewedWithin24h: true,
        downloadedPdfWithin24h: true,
        memo: 'A사 거래 임박',
      ),
      _RecentSendItem(
        id: '2',
        name: 'Sarah Jenkins',
        method: '카카오톡 공유',
        time: '1시간 전',
        revisitCount: 2,
        viewCount: 31,
        phone: '010-9876-5432',
        viewedWithin24h: true,
      ),
      _RecentSendItem(
        id: '3',
        name: '홍길동',
        method: '공유 시도',
        time: '방금 전',
        revisitCount: 5,
        viewCount: 29,
        phone: '010-2222-3333',
        memo: '미팅 메모 작성',
      ),
    ];
  }

  String _tr(String language, String ko, String en) {
    return language == 'en' ? en : ko;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final language = provider.settings.language;
        final profiles = provider.savedProfiles;
        if (profiles.isEmpty) return _buildEmptyState(context, language);

        final selected = _resolveSelectedProfile(profiles);
        final views = _mockViewCount(selected);
        final sends = _mockSendCount(selected);

        return Container(
          color: _bgDark,
          child: SafeArea(
            bottom: false,
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                return false;
              },
              child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel(_tr(language, '프로필', 'PROFILES')),
                  const SizedBox(height: 12),
                  _buildProfilesRow(context, provider, profiles),
                  const SizedBox(height: 20),
                  _buildTopSection(context, provider, selected, views, sends, language),
                  const SizedBox(height: 28),
                  _buildInsightSection(views, sends, language),
                  const SizedBox(height: 24),
                  _buildCrmSection(language),
                  const SizedBox(height: 24),
                  _buildPrintSection(context, provider, selected, language),
                ],
              ),
            ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String language) {
    return Container(
      color: _bgDark,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contact_page, size: 96, color: Colors.grey.shade600),
            const SizedBox(height: 20),
            Text(
              _tr(language, '저장된 명함이 없습니다', 'No saved cards yet'),
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _tr(
                language,
                '에디터에서 명함을 만들어 보세요',
                'Create a profile in the editor',
              ),
              style: GoogleFonts.manrope(fontSize: 14, color: _textMuted),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () =>
                  context.read<AppProvider>().setActiveView(ViewType.editor),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(_tr(language, '에디터로 가기', 'Go to Editor')),
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
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildProfilesRow(
    BuildContext context,
    AppProvider provider,
    List<Profile> profiles,
  ) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        children: [
          ...profiles.map((profile) {
            final isSelected =
                profile.id == _selectedProfileId ||
                (_selectedProfileId == null && profile.id == profiles.first.id);
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
          _AddProfilePill(
            onTap: () {
              provider.createNewProfile();
              provider.requestScrollToBackgroundTheme();
              provider.setActiveView(ViewType.editor);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection(
    BuildContext context,
    AppProvider provider,
    Profile selected,
    int views,
    int sends,
    String language,
  ) {
    final data = selected.data;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final cardW = (maxWidth - 20).clamp(240.0, 340.0);
        final cardH = cardW / kBusinessCardAspectRatio;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SizedBox(
                width: cardW,
                height: cardH,
                child: CardDisplay(
                  width: cardW,
                  height: cardH,
                  data: data,
                  interactive: false, // ? ??: ??? (??? ???????)
                  forceActionIconsEnabled: true, // ?? ????? ??? ??
                ),
              ),
            ),
            const SizedBox(height: 12),
            // ???? (???? ?? ???, ?? ??)
            Center(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    provider.loadProfile(selected);
                    provider.setActiveView(ViewType.preview);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 84,
                    height: 48,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade400,
                              ),
                            ),
                            child: Icon(
                              Icons.visibility_outlined,
                              size: 24,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // ??? / ?? / NFC
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  _TopActionButton(
                    icon: Icons.send,
                    label: _tr(language, '보내기', 'Send'),
                    filled: true,
                    onTap: () =>
                        _showSendSheet(context, provider, selected, language),
                  ),
                  _TopActionButton(
                    icon: Icons.share,
                    label: _tr(language, '공유', 'Share'),
                    onTap: () => _shareCard(context, provider, selected),
                  ),
                  _TopActionButton(
                    icon: Icons.nfc,
                    label: 'NFC',
                    onTap: () => _showNfcComingSoon(context, language),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ViewsSendsBlock(
                    icon: Icons.visibility,
                    label: _tr(language, '조회', 'Views'),
                    value: _formatCount(views),
                    subtitle: _tr(
                      language,
                      '최근 24h ↑ 즉시 팔로업',
                      'Last 24h ? Follow up',
                    ),
                    subtitleColor: Colors.green.shade400,
                    subtitleIcon: Icons.arrow_upward,
                    compact: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ViewsSendsBlock(
                    icon: Icons.send,
                    label: _tr(language, '공유', 'Sends'),
                    value: _formatCount(sends),
                    subtitle: _tr(language, '공유전파 추적', 'Share tracking'),
                    subtitleColor: const Color(0xFF94A3B8),
                    subtitleIcon: Icons.trending_up,
                    compact: true,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// BusinessCard(DigitalCard)? ?? AspectRatio? ???? width? ??.
  Widget _buildCompactCard(
    BuildContext context,
    AppProvider provider,
    CardData data,
  ) {
    return Container(
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
        child: AspectRatio(
          aspectRatio: kBusinessCardAspectRatio,
          child: DigitalCard(data: data, isLarge: false),
        ),
      ),
    );
  }

  static String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  Widget _buildInsightSection(int views, int sends, String language) {
    final weekLabels = language == 'en'
        ? const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
        : const ['월', '화', '수', '목', '금', '토', '일'];
    final maxY = _weekTrend.reduce((a, b) => a > b ? a : b).toDouble();
    final spots = _weekTrend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildSectionLabel(_tr(language, '인사이트 대시', 'INSIGHT DASHBOARD')),
            ),
            if (_hasRecentView)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _gold.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('닫기', style: GoogleFonts.manrope(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      _tr(language, '반응 뜨거워!', 'Hot reaction!'),
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _gold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _deepBlue.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _deepBlue.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInsightDashboardRow(
                language,
                dataLabel: _tr(language, '최근 24h 조회', '24h views'),
                dataValue: '${views ~/ 10 + 8}',
                meaning: _tr(language, '핫 리드 발견', 'Hot leads'),
                action: _tr(language, '즉시 팔로업', 'Follow up'),
              ),
              const SizedBox(height: 10),
              _buildInsightDashboardRow(
                language,
                dataLabel: _tr(language, 'PDF 다운로드', 'PDF downloads'),
                dataValue: '${sends ~/ 5 + 3}',
                meaning: _tr(language, '제안 관심', 'Proposal interest'),
                action: _tr(language, '맞춤 제안서', 'Custom proposal'),
              ),
              const SizedBox(height: 10),
              _buildInsightDashboardRow(
                language,
                dataLabel: _tr(language, '공유 전파', 'Shares'),
                dataValue: '${sends ~/ 8 + 2}',
                meaning: _tr(language, '바이럴 가능성', 'Viral potential'),
                action: _tr(language, '감사 보내기', 'Thank & reward'),
              ),
              const SizedBox(height: 10),
              _buildInsightDashboardRow(
                language,
                dataLabel: _tr(language, '체류시간·클릭', 'Dwell & clicks'),
                dataValue: _tr(language, '포트폴리오 1위', 'Portfolio #1'),
                meaning: _tr(language, '인사이트 필요', 'Need insight'),
                action: _tr(language, '콘텐츠 개선', 'Improve content'),
              ),
              const SizedBox(height: 16),
              Text(
                _tr(language, '최근 7일 트렌드', 'Last 7 days trend'),
                style: _insightLabelStyle(),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i >= 0 && i < 7) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  weekLabels[i],
                                  style: GoogleFonts.manrope(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: _textMuted,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          reservedSize: 16,
                          interval: 1,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: 6,
                    minY: 0,
                    maxY: maxY * 1.1,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: _gold,
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) =>
                              FlDotCirclePainter(
                                radius: 3,
                                color: _gold,
                                strokeWidth: 1,
                                strokeColor: _gold.withValues(alpha: 0.5),
                              ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [_gold.withValues(alpha: 0.15), _gold.withValues(alpha: 0.02)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                  duration: const Duration(milliseconds: 200),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                ),
                child: _buildFollowUpSection(language),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ??? ?? | ??? ?? | ?? ?? ? ?
  Widget _buildInsightDashboardRow(
    String language, {
    required String dataLabel,
    required String dataValue,
    required String meaning,
    required String action,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dataLabel,
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: _textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  dataValue,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _gold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              meaning,
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              action,
              style: GoogleFonts.manrope(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary.withValues(alpha: 0.9),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpSection(String language) {
    final topLeads = [..._recentSends]
      ..sort((a, b) => b.viewCount.compareTo(a.viewCount));
    final leads = topLeads.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _tr(language, '오늘 팔로업 추천', 'Today follow-up picks'),
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        ...leads.map((lead) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${lead.name} 님 ${lead.viewCount}회 조회',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => _launchCall(lead.phone),
                  icon: const Icon(Icons.phone, size: 18, color: _gold),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  onPressed: () => _launchSms(lead.phone),
                  icon: const Icon(Icons.sms_outlined, size: 18, color: _gold),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCrmSection(String language) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(_tr(language, '스마트 CRM', 'SMART CRM')),
        const SizedBox(height: 12),
        ..._recentSends.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _CrmExpansionTile(
            item: item,
            language: language,
            onViewed: () {
              setState(() {
                item.viewedWithin24h = true;
                item.time = '방금 전';
              });
            },
            onMemoSaved: (memo) {
              setState(() => item.memo = memo);
            },
          ),
        )),
      ],
    );
  }

  Widget _buildPrintSection(
    BuildContext context,
    AppProvider provider,
    Profile selected,
    String language,
  ) {
    String url = selected.data.shareLink.trim();
    if (url.isEmpty) url = 'https://nuggo.me';
    if (!url.startsWith('http')) url = 'https://$url';
    final data = selected.data;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(_tr(language, 'QR & 인쇄', 'QR & PRINT')),
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: url,
                  version: QrVersions.auto,
                  size: 140,
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
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _generateAndShowPdf(context, provider, selected, data, url, language),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                label: Text(_tr(language, '인쇄용 PDF 생성', 'Generate PDF for Print')),
                style: FilledButton.styleFrom(
                  backgroundColor: _deepBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _generateAndShowPdf(
    BuildContext context,
    AppProvider provider,
    Profile selected,
    CardData data,
    String url,
    String language,
  ) async {
    final doc = pw.Document();
    final name = data.fullName.isEmpty ? selected.name : data.fullName;
    final company = data.companyName;
    final contact = [data.phone, data.email].where((e) => e.isNotEmpty).join(' � ');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              _tr(language, '매장 미니 배너 (A4)', 'Store Mini Banner (A4)'),
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(24),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 100,
                        height: 100,
                        color: PdfColors.grey300,
                        child: pw.Center(child: pw.Text('QR', style: const pw.TextStyle(fontSize: 12))),
                      ),
                      pw.SizedBox(width: 20),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(name, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                            if (company.isNotEmpty) pw.Text(company, style: const pw.TextStyle(fontSize: 12)),
                            if (contact.isNotEmpty) pw.Text(contact, style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(url, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
                ],
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Text(
              _tr(language, '명함 시트', 'Card Sheet'),
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(name, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  if (data.jobTitle.isNotEmpty) pw.Text(data.jobTitle, style: const pw.TextStyle(fontSize: 11)),
                  if (company.isNotEmpty) pw.Text(company, style: const pw.TextStyle(fontSize: 11)),
                  if (contact.isNotEmpty) pw.Text(contact, style: const pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 8),
                  pw.Text(url, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Text(
                _tr(
                  language,
                  '명함 QR 코드를 공유해 보세요',
                  'Scan this QR to view full details',
                ),
                style: pw.TextStyle(
                  fontSize: 11,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.blueGrey700,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (context.mounted) {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'nuggo_print_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      if (_recentSends.isNotEmpty) {
        setState(() {
          _recentSends.first.downloadedPdfWithin24h = true;
          _recentSends.first.time = '방금 전';
        });
      }
    }
  }

  TextStyle _insightLabelStyle() => GoogleFonts.manrope(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
    color: _textMuted,
  );
  TextStyle _insightValueStyle() => GoogleFonts.manrope(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  void _showQrDialog(BuildContext context, Profile selected, String language) {
    String url = selected.data.shareLink.trim();
    if (url.isEmpty) url = 'https://nuggo.me';
    if (!url.startsWith('http')) url = 'https://$url';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr(language, '명함 QR 코드', 'Card QR Code')),
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
                  style: GoogleFonts.manrope(fontSize: 12, color: _textMuted),
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
            child: Text(_tr(language, '닫기', 'Close')),
          ),
        ],
      ),
    );
  }

  void _showNfcComingSoon(BuildContext context, String language) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _tr(language, 'NFC 기능은 준비 중입니다 🔮', 'NFC feature coming soon 🔮'),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showSendSheet(
    BuildContext context,
    AppProvider provider,
    Profile selected,
    String language,
  ) async {
    final prereq = provider.validateGuestSharePrerequisites(selected.data);
    if (prereq != null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prereq),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: _tr(language, '작성하기', 'Edit'),
            onPressed: () => provider.setActiveView(ViewType.editor),
          ),
        ),
      );
      return;
    }
    if (!provider.canAttemptGuestShare()) {
      if (context.mounted) await LoginBottomSheet.show(context);
      return;
    }
    String url = selected.data.shareLink.trim();
    if (url.isEmpty) url = 'https://nuggo.me';
    if (!url.startsWith('http')) url = 'https://$url';

    final name = selected.data.fullName.isEmpty
        ? selected.name
        : selected.data.fullName;

    void recordSend(String method) {
      setState(() {
        _recentSends.insert(
          0,
          _RecentSendItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: name,
            method: method,
            time: '방금 전',
            revisitCount: 0,
            viewCount: 0,
            phone: selected.data.phone,
          ),
        );
      });
    }

    SendCardSheet.show(
      context,
      url: url,
      name: name,
      language: language,
      cardData: selected.data,
      onRecordSend: recordSend,
    );
  }

  Future<void> _shareCard(
    BuildContext context,
    AppProvider provider,
    Profile selected,
  ) async {
    final prereq = provider.validateGuestSharePrerequisites(selected.data);
    if (prereq != null) {
      if (!context.mounted) return;
      final lang = provider.settings.language;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prereq),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: _tr(lang, '작성하기', 'Edit'),
            onPressed: () => provider.setActiveView(ViewType.editor),
          ),
        ),
      );
      return;
    }
    if (!provider.canAttemptGuestShare()) {
      if (context.mounted) await LoginBottomSheet.show(context);
      return;
    }
    setState(() {
      _recentSends.insert(
        0,
        _RecentSendItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: selected.data.fullName.isEmpty ? selected.name : selected.data.fullName,
          method: '공유 시도',
          time: '방금 전',
          revisitCount: 0,
          viewCount: 0,
          phone: selected.data.phone,
        ),
      );
    });
    final displayName = selected.data.fullName.isEmpty
        ? selected.name
        : selected.data.fullName;
    final language = provider.settings.language;
    final subject = _tr(language, '$displayName 명함', '$displayName\'s Card');

    if (!context.mounted) return;
    SendCardSheet.show(
      context,
      url: CardUrlGenerator.generate(selected.data),
      name: displayName,
      language: language,
      cardData: selected.data,
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

  int _mockViewCount(Profile profile) =>
      (profile.id.hashCode.abs() % 900) + 384;
  int _mockSendCount(Profile profile) =>
      (profile.id.hashCode.abs() % 200) + 252;

  Future<void> _launchCall(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _launchSms(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri(scheme: 'sms', path: phone);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// CRM ?? ?? ExpansionTile: ?? ? ?? ?? ??, 3? ?? ??? ? ? ??
class _CrmExpansionTile extends StatefulWidget {
  final _RecentSendItem item;
  final String language;
  final VoidCallback onViewed;
  final ValueChanged<String> onMemoSaved;

  const _CrmExpansionTile({
    required this.item,
    required this.language,
    required this.onViewed,
    required this.onMemoSaved,
  });

  @override
  State<_CrmExpansionTile> createState() => _CrmExpansionTileState();
}

class _CrmExpansionTileState extends State<_CrmExpansionTile> {
  late TextEditingController _memoController;

  @override
  void initState() {
    super.initState();
    _memoController = TextEditingController(text: widget.item.memo);
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    final item = widget.item;
    final showStar = item.revisitCount >= 3;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (expanded) {
            if (expanded) widget.onViewed();
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: Colors.white.withValues(alpha: 0.4), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showStar) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.star_rounded, size: 16, color: gold),
                        ],
                        if (item.isContractImminent) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              widget.language == 'en' ? 'Deal close' : '거래 임박',
                              style: GoogleFonts.manrope(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFFFA2A2),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      item.method,
                      style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF64748B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                item.time,
                style: GoogleFonts.manrope(fontSize: 10, color: const Color(0xFF64748B)),
              ),
            ],
          ),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _quickTagChip('거래임박'),
                _quickTagChip('거래임박'),
                _quickTagChip('거래임박'),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _memoController,
              maxLines: 3,
              style: GoogleFonts.manrope(fontSize: 13, color: Colors.white),
              decoration: InputDecoration(
                hintText: widget.language == 'en'
                    ? 'Short meeting note...'
                    : '짧은 미팅 메모를 입력해 주세요',
                hintStyle: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF64748B)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  widget.onMemoSaved(_memoController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(widget.language == 'en' ? 'Memo saved.' : '메모가 저장되었습니다.'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppTheme.primary,
                    ),
                  );
                },
                child: Text(
                  widget.language == 'en' ? 'Save memo' : '메모 저장',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickTagChip(String tag) {
    return ActionChip(
      onPressed: () {
        final hasText = _memoController.text.trim().isNotEmpty;
        final next = hasText ? '${_memoController.text}\n[$tag]' : '[$tag] ';
        setState(() {
          _memoController.text = next;
          _memoController.selection = TextSelection.fromPosition(
            TextPosition(offset: _memoController.text.length),
          );
        });
      },
      label: Text(
        tag,
        style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600),
      ),
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      labelStyle: const TextStyle(color: Colors.white),
    );
  }
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

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(12),
          child: Opacity(
            opacity: isSelected ? 1 : 0.6,
            child: Container(
              width: 64,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primary
                      : Colors.white.withValues(alpha: 0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: _MiniCardPreview(
                  data: data,
                  profileSaveName: profileSaveName,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ??? ???: ????? ?? ?? ??(??) + ??? ?? ??? ??? ??
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
                image: theme.startsWith('http')
                    ? ResizeImage(NetworkImage(theme), width: 128, height: 192)
                    : (File(theme).existsSync()
                        ? FileImage(File(theme))
                        : NetworkImage(AppConstants.initialCardData.theme))
                        as ImageProvider,
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
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.7),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 64,
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
            color: Colors.white.withValues(alpha: 0.05),
          ),
          child: Icon(
            Icons.add,
            size: 32,
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}

/// ??/?? ?? ?? (?? ???, ?? ???)
class _ViewsSendsBlock extends StatelessWidget {
  static const Color _textMuted = Color(0xFF64748B);
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color subtitleColor;
  final IconData subtitleIcon;
  final bool compact;

  const _ViewsSendsBlock({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.subtitleColor,
    required this.subtitleIcon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueSize = compact ? 22.0 : 28.0;
    final labelSize = compact ? 10.0 : 11.0;
    final subtitleSize = compact ? 8.5 : 9.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: AppTheme.primary),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: labelSize,
                  fontWeight: FontWeight.w600,
                  color: _textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: valueSize,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(subtitleIcon, size: 10, color: subtitleColor),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                subtitle,
                style: GoogleFonts.manrope(
                  fontSize: subtitleSize,
                  fontWeight: FontWeight.w600,
                  color: subtitleColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TopActionButton extends StatelessWidget {
  static const Color _accentOrange = Color(0xFFFF8A3D);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _TopActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled
        ? _accentOrange
        : const Color(0xFF101822).withValues(alpha: 0.4);
    final border = filled
        ? null
        : Border.all(color: Colors.white.withValues(alpha: 0.2));

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 74,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: border,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: Colors.white),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.95),
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentSendTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final String time;

  const _RecentSendTile({
    required this.name,
    required this.subtitle,
    required this.time,
  });

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
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: Colors.white.withValues(alpha: 0.4),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Flexible(
            child: Text(
              time,
              style: GoogleFonts.manrope(
                fontSize: 10,
                color: const Color(0xFF64748B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
