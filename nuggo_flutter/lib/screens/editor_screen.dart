import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:image_cropper/image_cropper.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/app_provider.dart';
import '../models/card_data.dart';
import '../models/profile.dart';
import '../constants/constants.dart';
import '../constants/theme.dart';
import '../widgets/business_card.dart';
import '../widgets/card_display.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/login_bottom_sheet.dart';
import '../services/card_url_generator.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with WidgetsBindingObserver {
  static const Color _accentOrange = Color(0xFFFF8A3D);
  ThemeType _activeThemeTab = ThemeType.professional;
  final ScrollController _editorScrollController = ScrollController();
  final ScrollController _profilesScrollController = ScrollController();
  double _prevKeyboardH = 0.0;
  final GlobalKey _backgroundSectionKey = GlobalKey();
  final GlobalKey _languageModeToggleKey = GlobalKey();
  final GlobalKey _cardRepaintKey = GlobalKey();
  OverlayEntry? _languageModeOverlay;

  // 플로팅 저장 버튼을 카드 우측 상단(추가 버튼 위)에 고정 배치하기 위한 계산 상수
  static const double _profilesTopGap = 4.0;
  static const double _profilesRowHeight = 52.0;
  static const double _gapProfilesToPreview = 6.0;
  static const double _previewLabelApproxHeight = 11.0;
  static const double _previewLabelGap = 6.0;
  static const double _previewIconGap = 12.0;
  static const double _previewIconHeight = 48.0;
  static const double _plusBtnHeight = 56.0;
  static const double _sendBtnHeight = 44.0;
  static const double _sendBtnGap = 10.0;
  static const double _qrBtnHeight = 44.0;
  static const double _qrBtnGap = 8.0;
  static const double _saveBtnHeight = 64.0;
  static const double _saveGapAbovePlus = 14.0;
  bool _scrollToBackgroundScheduled = false;
  bool _sloganDefaultSet = false;
  String? _pendingDefaultSlogan;
  bool _aiSloganLoading = false;
  bool _aiBackgroundLoading = false;
  List<String> _aiRecommendedImages = [];
  bool _sloganKoreanMode = true;
  bool _formReady = true;
  bool _basicProfileToastShown = false;
  final TextEditingController _sloganController = TextEditingController();
  final Map<String, TextEditingController> _formControllers = {};
  String? _cachedLanguage;
  late Map<String, String> _cachedTexts;
  static final TextInputFormatter _koreanOnlySloganFormatter =
      FilteringTextInputFormatter.allow(
        RegExp(r'[ㄱ-ㅎㅏ-ㅣ가-힣0-9\s\.,!\?\-\(\)~"]'),
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _precacheThemeImages();
    });
  }

  Future<void> _precacheThemeImages() async {
    final urls = <String>{};
    for (final group in AppConstants.themeTemplates.values) {
      for (final theme in group) {
        if (theme.startsWith('http')) urls.add(theme);
      }
    }
    for (final url in urls) {
      try {
        await precacheImage(NetworkImage(url), context);
      } catch (_) {
        // 네트워크 실패는 조용히 무시
      }
    }
  }

  /// 배경 테마 섹션이 상단에 보이도록 스크롤
  void _scrollToBackgroundSection() {
    final targetContext = _backgroundSectionKey.currentContext;
    if (targetContext == null ||
        !mounted ||
        !_editorScrollController.hasClients) {
      return;
    }

    final renderObject = targetContext.findRenderObject();
    if (renderObject != null) {
      final viewport = RenderAbstractViewport.of(renderObject);
      final revealTop = viewport.getOffsetToReveal(renderObject, 0.0).offset;
      final position = _editorScrollController.position;
      final targetOffset = (revealTop - 2).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      _editorScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      return;
    }

    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.0,
    );
  }

  bool _isBackgroundSectionAligned() {
    final targetContext = _backgroundSectionKey.currentContext;
    if (targetContext == null) return false;
    final box = targetContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;
    final top = box.localToGlobal(Offset.zero).dy;
    return top >= 0 && top <= 8;
  }

  void _scrollToBackgroundSectionUntilAligned(
    AppProvider provider, {
    int attempt = 0,
    int maxAttempts = 4,
  }) {
    _scrollToBackgroundSection();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final aligned = _isBackgroundSectionAligned();
      if (aligned || attempt >= maxAttempts) {
        provider.consumeScrollToBackgroundTheme();
        _scrollToBackgroundScheduled = false;
        return;
      }
      _scrollToBackgroundSectionUntilAligned(
        provider,
        attempt: attempt + 1,
        maxAttempts: maxAttempts,
      );
    });
  }

  /// 저장/업데이트 이후 에디터 기본(정상) 화면 위치로 복원
  void _resetEditorToNormalView() {
    if (!_editorScrollController.hasClients) return;
    _editorScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  TextEditingController _getFormController(String key, String value) {
    final c = _formControllers[key] ??= TextEditingController(text: value);
    if (c.text != value) {
      c.text = value;
      c.selection = TextSelection.collapsed(offset: value.length);
    }
    return c;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _languageModeOverlay?.remove();
    _languageModeOverlay = null;
    _editorScrollController.dispose();
    _profilesScrollController.dispose();
    _sloganController.dispose();
    for (final c in _formControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // 키보드가 올라오는 타이밍에 포커스된 입력창이 부드럽게 보이도록 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final keyboardH = MediaQuery.of(context).viewInsets.bottom;
      if (keyboardH > _prevKeyboardH + 50) {
        // 키보드가 의미있게 상승 → 포커스된 필드로 부드럽게 스크롤
        final focusCtx = FocusManager.instance.primaryFocus?.context;
        if (focusCtx != null && focusCtx.mounted) {
          Scrollable.ensureVisible(
            focusCtx,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            alignment: 0.3,
            alignmentPolicy:
                ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          );
        }
      }
      _prevKeyboardH = keyboardH;
    });
  }

  void _showLanguageModeToastNearToggle(String text) {
    final targetContext = _languageModeToggleKey.currentContext;
    if (targetContext == null || !mounted) return;
    final overlay = Overlay.of(context);
    final box = targetContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    _languageModeOverlay?.remove();
    _languageModeOverlay = null;

    final targetTopLeft = box.localToGlobal(Offset.zero);
    final targetSize = box.size;
    final entry = OverlayEntry(
      builder: (ctx) {
        final screen = MediaQuery.of(ctx).size;
        const toastW = 78.0;
        const toastH = 30.0;
        final left = (targetTopLeft.dx + ((targetSize.width - toastW) / 2))
            .clamp(8.0, screen.width - toastW - 8.0);
        final top = (targetTopLeft.dy - toastH - 8.0).clamp(
          8.0,
          screen.height - toastH - 8.0,
        );
        return Positioned(
          left: left.toDouble(),
          top: top.toDouble(),
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: toastW,
                height: toastH,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF111827).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade600),
                ),
                child: Text(
                  text,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    _languageModeOverlay = entry;
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (_languageModeOverlay == entry) {
        entry.remove();
        _languageModeOverlay = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final data = provider.currentCardData;
        final t = _getTexts(provider.settings.language);

        // 내 명함에서 프로필 추가 후 에디터로 온 경우 배경 테마 섹션으로 스크롤
        if ((provider.scrollToBackgroundThemeOnNextBuild == true) &&
            !_scrollToBackgroundScheduled) {
          _scrollToBackgroundScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _scrollToBackgroundSectionUntilAligned(provider);
            }
          });
        }

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
          color: const Color(0xFF0B0B0B),
          width: double.infinity,
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  return SingleChildScrollView(
                    controller: _editorScrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: width),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 4),
                          _buildProfilesSection(context, provider, t),
                          const SizedBox(height: 6),
                          _buildPreviewSection(context, provider, data, t),
                          // 미리보기 아이콘과 백그라운드 헤더가 겹치지 않도록 섹션 시작점을 소폭 하향
                          const SizedBox(height: 28),
                          KeyedSubtree(
                            key: _backgroundSectionKey,
                            child: _buildBackgroundSection(
                              context,
                              provider,
                              data,
                              t,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_formReady)
                            _buildFormSections(context, provider, data, t)
                          else
                            const SizedBox(height: 100),
                          const SizedBox(height: 150),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // 스크롤과 무관하게 화면 고정, 미리보기 아이콘과 나란히 (같은 세로 라인)
              Positioned(
                top: _computeSaveButtonTop(),
                right: 24,
                child: RepaintBoundary(
                  child: _buildSaveFloatingButton(context, provider),
                ),
              ),
            ],
          ),
        ),
        );
      },
    );
  }

  Widget _buildPreviewSection(
    BuildContext context,
    AppProvider provider,
    CardData data,
    Map<String, String> t,
  ) {
    const cardW = kBusinessCardAspectWidth;
    final previewLabelStyle = GoogleFonts.notoSansKr(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      color: Colors.grey.shade200,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const rightBlockWidth = 56.0 + 24.0;
            final totalW = constraints.maxWidth;
            final cardAreaW = totalW - rightBlockWidth;
            final sideMargin = (cardAreaW - cardW) / 2;
            final safeMargin = sideMargin.isNegative ? 0.0 : sideMargin;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: safeMargin),
                SizedBox(
                  width: cardW,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(t['livePreview']!, style: previewLabelStyle),
                      const SizedBox(height: 6),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RepaintBoundary(
                            key: _cardRepaintKey,
                            child: SizedBox(
                              width: cardW,
                              height: kBusinessCardAspectHeight,
                              child: CardDisplay(
                                width: cardW,
                                height: kBusinessCardAspectHeight,
                                data: data,
                                interactive: false,
                                forceActionIconsEnabled: true,
                                showShadow: false,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => provider.setActiveView(
                                ViewType.preview,
                              ),
                              behavior: HitTestBehavior.opaque,
                              child: SizedBox(
                                width: 84,
                                height: 48,
                                child: Center(
                                  child: Container(
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
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: safeMargin),
                Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _actionButton(
                          icon: Icons.add,
                          color: _accentOrange,
                          size: 56,
                          iconSize: 32,
                          borderWidth: 3,
                          borderColor: const Color(0xFF0B0B0B),
                          onTap: () {
                            provider.createNewProfile();
                            WidgetsBinding.instance.addPostFrameCallback(
                              (_) => _scrollToBackgroundSection(),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        _actionButton(
                          icon: Icons.send,
                          color: const Color(0xCC161B22),
                          iconColor: AppTheme.primary,
                          shapeRadius: 12,
                          size: 44,
                          onTap: () => _shareCardFromEditor(context, provider),
                        ),
                        const SizedBox(height: 8),
                        _actionButton(
                          icon: Icons.qr_code_2,
                          color: const Color(0xCC161B22),
                          iconColor: const Color(0xFFCBD5E1),
                          shapeRadius: 12,
                          size: 44,
                          onTap: () => _showQrDialogFromEditor(context, provider),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    Color? iconColor,
    double size = 40,
    double iconSize = 18,
    double? shapeRadius,
    double borderWidth = 0,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    final radius = shapeRadius ?? (size / 2);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(radius),
            border: borderWidth > 0
                ? Border.all(
                    color: borderColor ?? Colors.white,
                    width: borderWidth,
                  )
                : Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor ?? Colors.white, size: iconSize),
        ),
      ),
    );
  }

  Future<void> _shareCardFromEditor(BuildContext context, AppProvider provider) async {
    final data = provider.selectedProfile?.data ?? provider.currentCardData;
    final prereq = provider.validateGuestSharePrerequisites(data);
    if (prereq != null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(prereq), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (!provider.canAttemptGuestShare()) {
      if (context.mounted) await LoginBottomSheet.show(context);
      return;
    }
    // 에디터에 렌더링된 카드 이미지로 캡처 후 OS 공유
    try {
      final boundary = _cardRepaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null) {
        final img = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null && context.mounted) {
          final bytes = byteData.buffer.asUint8List();
          final dir = await getTemporaryDirectory();
          final safeName = data.fullName.trim().isEmpty
              ? 'card'
              : data.fullName.trim().replaceAll(RegExp(r'[^\w가-힣]'), '_');
          final file = File('${dir.path}/${safeName}_nuggo.png');
          await file.writeAsBytes(bytes);
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path, mimeType: 'image/png')],
            ),
          );
          return;
        }
      }
    } catch (_) {}
    // 캡처 실패 시 URL 폴백
    if (!context.mounted) return;
    final name = data.fullName.isEmpty ? 'NUGGO' : data.fullName;
    final webUrl = CardUrlGenerator.generate(data);
    await SharePlus.instance.share(ShareParams(text: '$name 님의 디지털 명함\n$webUrl'));
  }

  void _showQrDialogFromEditor(BuildContext context, AppProvider provider) {
    final data = provider.selectedProfile?.data ?? provider.currentCardData;
    final prereq = provider.validateGuestSharePrerequisites(data);
    if (prereq != null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prereq),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
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

  Widget _buildBackgroundSection(
    BuildContext context,
    AppProvider provider,
    CardData data,
    Map<String, String> t,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Background Theme',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w300,
              fontStyle: FontStyle.italic,
              letterSpacing: 2.5,
              color: const Color(0xFFD4AF37),
            ),
          ),
          const SizedBox(height: 10),

          // Theme Type Tabs
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey.shade100.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: ThemeType.values.map((type) {
                final isActive = _activeThemeTab == type;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _activeThemeTab = type),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white.withValues(alpha: 0.6)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          type.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: isActive
                                ? Colors.black87
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Theme Templates + AI 추천 카드 + 내 사진 올리기 (순서대로 맨 끝)
          SizedBox(
            height: 97,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: AppConstants.themeTemplates[_activeThemeTab]!.length + 2,
              itemBuilder: (context, index) {
                final templateCount =
                    AppConstants.themeTemplates[_activeThemeTab]!.length;
                if (index == templateCount) {
                  return _buildAiRecommendCard(context, provider, data);
                }
                if (index == templateCount + 1) {
                  return _buildUploadPhotoCard(context, provider, data);
                }
                final theme =
                    AppConstants.themeTemplates[_activeThemeTab]![index];
                final isSelected = data.theme == theme;
                final isHex = theme.startsWith('#');

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    final newData = data.copyWith(theme: theme);
                    provider.updateCardData(newData);
                  },
                  child: Container(
                    width: 62,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      color: isHex ? _parseHexColor(theme) : null,
                      image: !isHex
                          ? DecorationImage(
                              image: ResizeImage(
                                NetworkImage(theme),
                                width: 124,
                                height: 194,
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: isSelected
                        ? Center(
                            child: Icon(
                              Icons.check_circle_outline,
                              color: Theme.of(context).colorScheme.primary,
                              size: 28,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),

          // AI 추천 이미지 결과 (3장)
          if (_aiRecommendedImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildAiImageResults(context, provider, data),
          ],
        ],
      ),
    );
  }

  Widget _buildAiRecommendCard(
    BuildContext context,
    AppProvider provider,
    CardData data,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _aiBackgroundLoading
          ? null
          : () => _onAiBackgroundTap(context, provider, data),
      child: Container(
        width: 62,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6366F1), Color(0xFFA78BFA)],
          ),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: _aiBackgroundLoading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, size: 22, color: Colors.white),
                  const SizedBox(height: 4),
                  Text(
                    'AI 추천',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildUploadPhotoCard(
    BuildContext context,
    AppProvider provider,
    CardData data,
  ) {
    final rawPath = data.theme.replaceFirst('file://', '');
    final isLocalSelected = (data.theme.startsWith('/') || data.theme.startsWith('file://')) &&
        File(rawPath).existsSync();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _pickBackgroundImage(context, provider, data),
      child: Container(
        width: 62,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLocalSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade400,
            width: isLocalSelected ? 2 : 1.5,
            style: isLocalSelected ? BorderStyle.solid : BorderStyle.solid,
          ),
          color: Colors.grey.shade50,
          image: isLocalSelected
              ? DecorationImage(
                  image: FileImage(File(rawPath)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: isLocalSelected
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.check_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 24, color: Colors.grey.shade500),
                  const SizedBox(height: 4),
                  Text(
                    '내 사진',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAiImageResults(
    BuildContext context,
    AppProvider provider,
    CardData data,
  ) {
    const labels = ['일반', '비즈니스', '패턴'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, size: 13, color: AppTheme.primary),
            const SizedBox(width: 4),
            Text(
              'AI 추천 배경',
              style: GoogleFonts.notoSansKr(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _aiRecommendedImages = []),
              child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 97,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _aiRecommendedImages.length,
            itemBuilder: (context, index) {
              final url = _aiRecommendedImages[index];
              final isSelected = data.theme == url;
              return GestureDetector(
                onTap: () => provider.updateCardData(data.copyWith(theme: url)),
                child: Container(
                  width: 62,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    image: DecorationImage(
                      image: ResizeImage(
                        NetworkImage(url),
                        width: 124,
                        height: 194,
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (isSelected)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.black.withValues(alpha: 0.3),
                          ),
                        ),
                      if (isSelected)
                        Center(
                          child: Icon(
                            Icons.check_circle_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                        )
                      else
                        Positioned(
                          left: 4,
                          right: 4,
                          bottom: 4,
                          child: Center(
                            child: Text(
                              labels[index],
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                shadows: const [
                                  Shadow(color: Colors.black54, blurRadius: 2),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _pickBackgroundImage(
    BuildContext context,
    AppProvider provider,
    CardData data,
  ) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(
        ratioX: kBusinessCardAspectWidth,
        ratioY: kBusinessCardAspectHeight,
      ),
      uiSettings: [
        IOSUiSettings(
          title: '',
          doneButtonTitle: '저장',
          cancelButtonTitle: '취소',
          aspectRatioPresets: const [CropAspectRatioPreset.original],
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          rotateButtonsHidden: false,
          hidesNavigationBar: false,
        ),
        AndroidUiSettings(
          toolbarTitle: '',
          toolbarColor: const Color(0xFF1A1C2E),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: AppTheme.primary,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: true,
          aspectRatioPresets: const [CropAspectRatioPreset.original],
        ),
      ],
    );

    if (cropped == null || !mounted) return;

    final docsDir = await getApplicationDocumentsDirectory();
    final bgDir = Directory('${docsDir.path}/bg_images');
    if (!await bgDir.exists()) await bgDir.create(recursive: true);
    final fileName = 'bg_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final destFile = File('${bgDir.path}/$fileName');
    await File(cropped.path).copy(destFile.path);
    if (!mounted) return;
    provider.updateCardData(data.copyWith(theme: destFile.path));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('배경이 현재 편집 중인 명함에 적용됐어요. 저장 버튼을 눌러야 영구 저장됩니다.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _onAiBackgroundTap(
    BuildContext context,
    AppProvider provider,
    CardData data,
  ) async {
    setState(() {
      _aiBackgroundLoading = true;
      _aiRecommendedImages = [];
    });
    try {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      final pool = AppConstants.backgroundRecommendPool;
      final rand = Random();
      final results = <String>[
        pool['general']![rand.nextInt(pool['general']!.length)],
        pool['business']![rand.nextInt(pool['business']!.length)],
        pool['pattern']![rand.nextInt(pool['pattern']!.length)],
      ];
      if (mounted) {
        setState(() => _aiRecommendedImages = results);
      }
    } finally {
      if (mounted) setState(() => _aiBackgroundLoading = false);
    }
  }

  static const Color _profileActionRed = Color(0xFFE57373);

  static const List<String> _jobTitleSuggestions = [
    '대표이사', '대표', 'CEO', 'COO', 'CTO', 'CFO', 'CMO',
    '부사장', '전무이사', '전무', '상무이사', '상무',
    '이사', '본부장', '실장', '팀장',
    '부장', '차장', '과장', '대리', '주임', '사원', '인턴',
    '프리랜서', '1인 기업',
  ];

  Widget _buildProfilesSection(
    BuildContext context,
    AppProvider provider,
    Map<String, String> t,
  ) {
    final profiles = provider.savedProfiles;
    final hasActiveToDelete =
        provider.activeProfileId != null &&
        profiles.any((p) => p.id == provider.activeProfileId) &&
        profiles.length > 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: ListView.builder(
                controller: _profilesScrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: profiles.isEmpty ? 1 : profiles.length + 1,
                itemBuilder: (context, index) {
                  // 맨 오른쪽: 새 프로필 추가 버튼 (프로필이 없을 때만 index 0, 있으면 마지막에 표시)
                  final isAddButton = profiles.isEmpty
                      ? index == 0
                      : index == profiles.length;
                  if (isAddButton) {
                    final isNewActive =
                        profiles.isEmpty || provider.activeProfileId == null;
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          provider.createNewProfile();
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _scrollToBackgroundSection(),
                          );
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          margin: const EdgeInsets.only(left: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isNewActive
                                  ? AppTheme.primary
                                  : const Color(0xFF252B35),
                              width: isNewActive ? 2 : 1,
                            ),
                            color: const Color(0xFF161B22),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white70,
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  }
                  final profile = profiles[index];
                  final isActive = provider.activeProfileId == profile.id;
                  return Transform.translate(
                    offset: Offset(-12.0 * index, 0),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => provider.loadProfile(profile),
                      child: Container(
                        width: 52,
                        height: 52,
                        margin: const EdgeInsets.only(right: 2),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive
                                ? AppTheme.primary
                                : const Color(0xFF252B35),
                            width: isActive ? 2 : 1,
                          ),
                          color: const Color(0xFF161B22),
                        ),
                        child: ClipOval(child: _buildProfileAvatar(profile)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: _profileActionRed.withValues(alpha: 0.7),
                ),
                onPressed: hasActiveToDelete
                    ? () async {
                        final id = provider.activeProfileId;
                        if (id != null) await provider.deleteProfile(id);
                      }
                    : null,
                style: IconButton.styleFrom(
                  minimumSize: const Size(28, 28),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.undo_outlined,
                  size: 18,
                  color: _profileActionRed.withValues(alpha: 0.7),
                ),
                onPressed: provider.canRestoreProfile
                    ? () => provider.restoreLastDeletedProfile()
                    : null,
                style: IconButton.styleFrom(
                  minimumSize: const Size(28, 28),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 프로필 제목(이름)에서 이니셜 추출
  static String _profileInitial(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    final runes = t.runes.toList();
    if (runes.isEmpty) return '?';
    if (runes.first > 0x7F) return String.fromCharCodes([runes.first]);
    final words = t.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (words.length >= 2) {
      final a = words.first.runes.first;
      final b = words.last.runes.first;
      return String.fromCharCodes([a]).toUpperCase() +
          String.fromCharCodes([b]).toUpperCase();
    }
    return String.fromCharCodes([runes.first]).toUpperCase();
  }

  static Color _parseThemeColor(String theme) {
    if (!theme.startsWith('#')) return const Color(0xFF1a1c1e);
    final h = theme.replaceAll('#', '');
    final full = h.length == 3 ? h.split('').map((c) => '$c$c').join() : h;
    if (full.length < 6) return const Color(0xFF1a1c1e);
    return Color(int.parse('FF$full', radix: 16));
  }

  Widget _buildFormSections(
    BuildContext context,
    AppProvider provider,
    CardData data,
    Map<String, String> t,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton(
            onPressed: _scrollToBackgroundSection,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              t['cardInfoInput']!,
              style: GoogleFonts.notoSansKr(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Slogan (기본 슬로건 + AI 추천)
          _buildSectionHeader('1. ${t['slogan']}'),
          const SizedBox(height: 8),
          _buildSloganField(context, provider, data, t),

          const SizedBox(height: 24),

          // Profile Info
          _buildSectionHeader('2. ${t['profileInfo']}'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  fieldKey: 'fullName',
                  label: t['fullName']!,
                  value: data.fullName,
                  onChanged: (value) =>
                      provider.updateCardData(data.copyWith(fullName: value)),
                  onTap: () => _maybeShowBasicProfileToast(context, provider, t),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildJobTitleField(context, provider, data, t),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            fieldKey: 'companyName',
            label: t['companyName']!,
            value: data.companyName,
            onChanged: (value) =>
                provider.updateCardData(data.copyWith(companyName: value)),
            onTap: () => _maybeShowBasicProfileToast(context, provider, t),
          ),

          const SizedBox(height: 24),

          // 3. 사진 및 로고 (프로필 이미지)
          _buildSectionHeader('3. ${t['media']}'),
          const SizedBox(height: 12),
          _buildProfileImageSection(context, provider, data, t),

          const SizedBox(height: 24),

          // 4. 연락처
          _buildSectionHeader('4. ${t['contactInfo']}'),
          const SizedBox(height: 16),
          _buildPillInput(
            fieldKey: 'phone',
            icon: Icons.phone,
            value: data.phone,
            placeholder: t['placeholders.phone']!,
            keyboardType: TextInputType.phone,
            onChanged: (value) =>
                provider.updateCardData(data.copyWith(phone: value)),
            onTap: () => _maybeShowBasicProfileToast(context, provider, t),
          ),
          const SizedBox(height: 12),
          _buildPillInput(
            fieldKey: 'sms',
            icon: Icons.sms,
            value: data.sms,
            placeholder: t['placeholders.sms']!,
            keyboardType: TextInputType.phone,
            onChanged: (value) =>
                provider.updateCardData(data.copyWith(sms: value)),
            onTap: () {
              _maybeShowBasicProfileToast(context, provider, t);
              // SMS 비어있을 때 전화번호 자동 복사 (단방향: SMS만 변경)
              final smsCtrl = _getFormController('sms', data.sms);
              if (smsCtrl.text.isEmpty && data.phone.isNotEmpty) {
                smsCtrl.text = data.phone;
                provider.updateCardData(data.copyWith(sms: data.phone));
              }
            },
          ),
          const SizedBox(height: 12),
          _buildPillInput(
            fieldKey: 'email',
            icon: Icons.email,
            value: data.email,
            placeholder: t['placeholders.email']!,
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) =>
                provider.updateCardData(data.copyWith(email: value)),
            onTap: () => _maybeShowBasicProfileToast(context, provider, t),
          ),

          const SizedBox(height: 24),

          // 5. 링크 및 SNS
          _buildSectionHeader('5. ${t['links']}'),
          const SizedBox(height: 16),
          _buildPillInput(
            fieldKey: 'website',
            icon: Icons.language,
            value: data.website,
            placeholder: t['placeholders.website']!,
            keyboardType: TextInputType.url,
            onChanged: (value) =>
                provider.updateCardData(data.copyWith(website: value)),
            onTap: () => _maybeShowBasicProfileToast(context, provider, t),
          ),
          const SizedBox(height: 12),
          _buildPillInput(
            fieldKey: 'kakao',
            icon: Icons.chat_bubble_outline,
            value: data.kakao,
            placeholder: t['placeholders.kakao']!,
            onChanged: (value) =>
                provider.updateCardData(data.copyWith(kakao: value)),
            onTap: () => _maybeShowBasicProfileToast(context, provider, t),
          ),
          const SizedBox(height: 12),
          _buildPillInput(
            fieldKey: 'shareLink',
            icon: Icons.share,
            value: data.shareLink,
            placeholder: t['placeholders.shareLink']!,
            keyboardType: TextInputType.url,
            onChanged: (value) =>
                provider.updateCardData(data.copyWith(shareLink: value)),
            onTap: () => _maybeShowBasicProfileToast(context, provider, t),
          ),
          const SizedBox(height: 12),
          _buildPortfolioInput(
            context,
            provider,
            data,
            t['placeholders.portfolio']!,
            onTap: () => _maybeShowBasicProfileToast(context, provider, t),
          ),

          const SizedBox(height: 24),

          // 6. 주소
          _buildSectionHeader('6. ${t['address']}'),
          const SizedBox(height: 16),
          _buildPillInput(
            fieldKey: 'address',
            icon: Icons.location_on,
            value: data.address,
            placeholder: t['placeholders.address']!,
            onChanged: (value) =>
                provider.updateCardData(data.copyWith(address: value)),
            onTap: () => _maybeShowBasicProfileToast(context, provider, t),
          ),
          const SizedBox(height: 150),
        ],
      ),
    );
  }

  /// 완전 원형 반투명 플로팅 SAVE 버튼 (스크롤과 무관하게 화면 고정)
  Widget _buildSaveFloatingButton(BuildContext context, AppProvider provider) {
    const size = 64.0;
    return Material(
      color: _accentOrange.withValues(alpha: 0.6),
      elevation: 8,
      shadowColor: Colors.black45,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () {
          // 입력 포커스를 먼저 정리해 키보드 재상승/다이얼로그 찌그러짐을 방지
          FocusManager.instance.primaryFocus?.unfocus();
          _showSaveDialog(context, provider, _getTexts(provider.settings.language));
        },
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.save,
                color: Colors.white.withValues(alpha: 0.95),
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                'SAVE',
                style: GoogleFonts.notoSansKr(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _computeSaveButtonTop() {
    final previewColumnHeight =
        _previewLabelApproxHeight +
        _previewLabelGap +
        kBusinessCardAspectHeight +
        _previewIconGap +
        _previewIconHeight;
    final rightActionColumnHeight =
        _plusBtnHeight + _sendBtnGap + _sendBtnHeight + _qrBtnGap + _qrBtnHeight;
    final addButtonTopInsidePreview =
        ((previewColumnHeight - rightActionColumnHeight) / 2).clamp(0.0, 200.0);

    return _profilesTopGap +
        _profilesRowHeight +
        _gapProfilesToPreview +
        addButtonTopInsidePreview -
        _saveBtnHeight -
        _saveGapAbovePlus;
  }

  TextStyle get _inputTextStyle => GoogleFonts.notoSansKr(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  /// 플레이스홀더(또는 이미지...)와 동일한 굵기
  TextStyle get _inputHintStyle => GoogleFonts.notoSansKr(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.grey.shade500,
  );
  TextStyle get _inputLabelStyle => GoogleFonts.notoSansKr(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 1,
    color: Colors.grey.shade300,
  );

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.notoSansKr(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: Colors.grey.shade200,
      ),
    );
  }

  /// 빈 슬로건이면 기본 슬로건 한 번 설정
  void _ensureDefaultSlogan(AppProvider provider, CardData data) {
    if (data.slogan.isNotEmpty || _sloganDefaultSet) return;
    _sloganDefaultSet = true;
    _pendingDefaultSlogan = AppConstants
        .defaultSlogans[Random().nextInt(AppConstants.defaultSlogans.length)];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          provider.currentCardData.slogan.isEmpty &&
          _pendingDefaultSlogan != null) {
        provider.updateCardData(
          provider.currentCardData.copyWith(slogan: _pendingDefaultSlogan!),
        );
      }
    });
  }

  Widget _buildSloganField(
    BuildContext context,
    AppProvider provider,
    CardData data,
    Map<String, String> t,
  ) {
    _ensureDefaultSlogan(provider, data);
    const assistControlYOffset = -10.0;
    final displayValue = data.slogan.isEmpty
        ? (_pendingDefaultSlogan ?? '')
        : data.slogan;
    if (_sloganController.text != displayValue) {
      _sloganController.text = displayValue;
      _sloganController.selection = TextSelection.collapsed(
        offset: displayValue.length,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _sloganController,
                inputFormatters: [_koreanOnlySloganFormatter],
                onTap: () => _maybeShowBasicProfileToast(context, provider, t),
                onChanged: (value) => provider.updateCardData(
                  provider.currentCardData.copyWith(slogan: value),
                ),
                decoration: InputDecoration(
                  hintText: displayValue.isEmpty
                      ? t['placeholders.slogan']
                      : null,
                  hintStyle: GoogleFonts.notoSansKr(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade500,
                  ),
                  border: const UnderlineInputBorder(),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade600),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
                  ),
                  filled: false,
                ),
                style: GoogleFonts.notoSansKr(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 6),
            // 한/영 구분 표시 (작게)
            Transform.translate(
              offset: const Offset(0, assistControlYOffset),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() => _sloganKoreanMode = !_sloganKoreanMode);
                    _showLanguageModeToastNearToggle(
                      _sloganKoreanMode
                          ? t['koreanModeOn']!
                          : t['englishModeOn']!,
                    );
                  },
                  child: SizedBox(
                    key: _languageModeToggleKey,
                    width: 29, // 기존 약 22px 칩 대비 약 1.3배 탭 영역
                    height: 26, // 기존 약 20px 칩 대비 약 1.3배 탭 영역
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade600),
                        ),
                        child: Text(
                          _sloganKoreanMode ? '한' : '영',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Transform.translate(
              offset: const Offset(0, assistControlYOffset),
              child: OutlinedButton.icon(
                onPressed: _aiSloganLoading
                    ? null
                    : () async {
                        setState(() => _aiSloganLoading = true);
                        try {
                          final suggested = await _fetchAiSlogan(
                            provider.currentCardData,
                            koreanMode: _sloganKoreanMode,
                          );
                          if (mounted &&
                              suggested != null &&
                              suggested.isNotEmpty) {
                            provider.updateCardData(
                              provider.currentCardData.copyWith(
                                slogan: suggested,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _aiSloganLoading = false);
                        }
                      },
                icon: _aiSloganLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: AppTheme.primary,
                      ),
                label: Text(
                  t['aiRecommend']!,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// AI(또는 기본 목록)로 슬로건 추천. API 키 없으면 기본 슬로건 중 하나 반환.
  Future<String?> _fetchAiSlogan(
    CardData data, {
    required bool koreanMode,
  }) async {
    const fallbackEnglishSlogans = <String>[
      'Your next story starts here.',
      'Connect beyond first impressions.',
      'One tap, lasting impact.',
      'Small intro, big presence.',
      'Turn hello into opportunity.',
    ];

    if (AppConstants.geminiApiKey.isNotEmpty) {
      try {
        final model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: AppConstants.geminiApiKey,
        );
        final job = data.jobTitle.isNotEmpty ? data.jobTitle : '직무';
        final company = data.companyName.isNotEmpty ? data.companyName : '회사';
        final prompt = koreanMode
            ? '다음 직무와 회사/소속에 어울리는 명함 한줄 소개(슬로건)를 한국어로 딱 한 문장만 추천해줘. 20자 이내로 짧고 임팩트 있게. 직무: $job, 회사/소속: $company. 답은 따옴표 없이 슬로건 한 문장만 출력.'
            : 'Recommend exactly one short English business card slogan (max 25 characters), impactful and professional. Job: $job, Company/Org: $company. Output only one sentence without quotes.';
        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text?.trim();
        if (text != null && text.isNotEmpty) return text;
      } catch (_) {}
    }
    if (koreanMode) {
      if (AppConstants.defaultSlogans.isEmpty) return null;
      return AppConstants.defaultSlogans[Random().nextInt(
        AppConstants.defaultSlogans.length,
      )];
    }
    return fallbackEnglishSlogans[Random().nextInt(
      fallbackEnglishSlogans.length,
    )];
  }

  Widget _buildJobTitleField(
    BuildContext context,
    AppProvider provider,
    CardData data,
    Map<String, String> t,
  ) {
    final controller = _getFormController('jobTitle', data.jobTitle);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t['jobTitle']!.toUpperCase(), style: _inputLabelStyle),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: (value) =>
              provider.updateCardData(data.copyWith(jobTitle: value)),
          onTap: () => _maybeShowBasicProfileToast(context, provider, t),
          textInputAction: TextInputAction.next,
          enableInteractiveSelection: true,
          decoration: InputDecoration(
            border: const UnderlineInputBorder(),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade600),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            isDense: true,
            filled: false,
            suffixIcon: GestureDetector(
              onTap: () => _showJobTitlePicker(context, controller, provider, data, t),
              child: Icon(Icons.expand_more_rounded, size: 20, color: Colors.grey.shade400),
            ),
          ),
          style: _inputTextStyle,
        ),
      ],
    );
  }

  void _showJobTitlePicker(
    BuildContext context,
    TextEditingController controller,
    AppProvider provider,
    CardData data,
    Map<String, String> t,
  ) {
    FocusScope.of(context).unfocus();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                t['jobTitlePickerTitle'] ?? '직함 / 직책 선택',
                style: GoogleFonts.notoSansKr(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Divider(color: Colors.grey.shade200, height: 1),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.5,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _jobTitleSuggestions.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: Colors.grey.shade100, height: 1),
                  itemBuilder: (_, index) {
                    final title = _jobTitleSuggestions[index];
                    final isSelected = controller.text == title;
                    return ListTile(
                      title: Text(
                        title,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 15,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? AppTheme.primary
                              : Colors.black87,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check, color: AppTheme.primary, size: 18)
                          : null,
                      onTap: () {
                        controller.text = title;
                        provider.updateCardData(
                          data.copyWith(jobTitle: title),
                        );
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required String fieldKey,
    required String label,
    required String value,
    required Function(String) onChanged,
    VoidCallback? onTap,
  }) {
    final controller = _getFormController(fieldKey, value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: _inputLabelStyle),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: (value) => onChanged(value),
          onTap: onTap,
          textInputAction: TextInputAction.next,
          enableInteractiveSelection: true,
          decoration: InputDecoration(
            border: const UnderlineInputBorder(),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade600),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            isDense: true,
            filled: false,
          ),
          style: _inputTextStyle,
        ),
      ],
    );
  }

  /// 원형 프로필 목록: 명함 이미지(테마) + 프로필 제목 이니셜만 표시
  Widget _buildProfileAvatar(Profile profile) {
    final data = profile.data;
    final theme = data.theme;
    final isHex = theme.startsWith('#');
    final initial = _profileInitial(profile.name);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isHex ? _parseThemeColor(theme) : const Color(0xFF1a1c1e),
        image: !isHex && theme.isNotEmpty
            ? DecorationImage(
                image: theme.startsWith('http')
                    ? ResizeImage(NetworkImage(theme), width: 104, height: 104)
                    : (File(theme).existsSync()
                        ? FileImage(File(theme))
                        : NetworkImage(AppConstants.initialCardData.theme))
                        as ImageProvider,
                fit: BoxFit.cover,
                onError: (_, _) {},
              )
            : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!isHex && theme.isNotEmpty)
            Container(color: Colors.black.withValues(alpha: 0.25)),
          Center(
            child: Text(
              initial,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageThumb(String url) {
    try {
      if (url.startsWith('data:')) {
        final bytes = base64Decode(url.split(',').last);
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200),
            image: DecorationImage(
              image: MemoryImage(bytes),
              fit: BoxFit.cover,
            ),
          ),
        );
      }
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200),
          image: DecorationImage(
            image: ResizeImage(NetworkImage(url), width: 80, height: 80),
            fit: BoxFit.cover,
          ),
        ),
      );
    } catch (_) {
      return Icon(Icons.person, size: 40, color: Colors.grey.shade400);
    }
  }

  Widget _buildProfileImageSection(
    BuildContext context,
    AppProvider provider,
    CardData data,
    Map<String, String> t,
  ) {
    final hasImage = data.profileImage != null && data.profileImage!.isNotEmpty;
    final displayUrl = hasImage && !data.profileImage!.startsWith('data:')
        ? data.profileImage!
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 프로필/로고 미리보기 + 변경 버튼 (아웃라인, 배경 없음)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade600),
          ),
          child: Row(
            children: [
              if (hasImage)
                _buildProfileImageThumb(data.profileImage!)
              else
                Icon(
                  Icons.add_photo_alternate,
                  size: 40,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.7),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Logo or Photo',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade200,
                  ),
                ),
              ),
              if (hasImage)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () =>
                      provider.updateCardData(data.copyWith(profileImage: '')),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (hasImage) const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  final t = _getTexts(provider.settings.language);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t['imageUploadComingSoon']!),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                ),
                child: Text(t['uploadBtn']!),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // URL 입력 (이미지 링크 붙여넣기) - 배경 없이 깔끔
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade600),
          ),
          child: Row(
            children: [
              Icon(Icons.link, size: 20, color: Colors.grey.shade400),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: displayUrl)
                    ..selection = TextSelection.collapsed(
                      offset: displayUrl.length,
                    ),
                  onTap: () => _maybeShowBasicProfileToast(context, provider, t),
                  onChanged: (value) => provider.updateCardData(
                    data.copyWith(profileImage: value),
                  ),
                  decoration: InputDecoration(
                    hintText: t['placeholders.hotlink'],
                    hintStyle: _inputHintStyle,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    filled: false,
                  ),
                  style: _inputTextStyle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static const int _portfolioMaxBytes = 10 * 1024 * 1024; // 10MB

  Future<void> _pickPortfolioFile(AppProvider provider, CardData data) async {
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
    final mime = _mimeForExtension(file.extension ?? 'bin');
    final base64 = base64Encode(file.bytes!);
    provider.updateCardData(data.copyWith(
      portfolioFile: 'data:$mime;base64,$base64',
      portfolioFileName: file.name,
    ));
    if (mounted) setState(() {});
  }

  String _mimeForExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf': return 'application/pdf';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      default: return 'application/octet-stream';
    }
  }

  Widget _buildPortfolioInput(
    BuildContext context,
    AppProvider provider,
    CardData data,
    String placeholder, {
    VoidCallback? onTap,
  }) {
    final urlController = _getFormController('portfolioUrl', data.portfolioUrl ?? '');
    final hasFile = (data.portfolioFile ?? '').isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            children: [
              Icon(Icons.folder_open, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                '포트폴리오',
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '  Portfolio',
                style: GoogleFonts.notoSansKr(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: urlController,
                onTap: onTap,
                onChanged: (v) => provider.updateCardData(data.copyWith(portfolioUrl: v)),
                decoration: InputDecoration(
                  hintText: placeholder,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3), width: 2),
                  ),
                ),
                style: GoogleFonts.notoSansKr(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(hasFile ? Icons.attach_file : Icons.add_circle_outline, size: 24, color: Colors.grey.shade600),
              onPressed: () => _pickPortfolioFile(provider, data),
              tooltip: '파일 첨부 (PDF, DOC, DOCX, JPG, PNG / 최대 10MB)',
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
                    data.portfolioFileName ?? '파일 첨부됨',
                    style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => provider.updateCardData(data.copyWith(portfolioFile: '', portfolioFileName: '')),
                  child: const Text('제거'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPillInput({
    required String fieldKey,
    required IconData icon,
    required String value,
    required String placeholder,
    required Function(String) onChanged,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
  }) {
    final controller = _getFormController(fieldKey, value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade600),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (value) => onChanged(value),
              onTap: onTap,
              textInputAction: TextInputAction.next,
              keyboardType: keyboardType,
              enableInteractiveSelection: true,
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: _inputHintStyle,
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
              style: _inputTextStyle,
            ),
          ),
        ],
      ),
    );
  }

  void _showSaveDialog(
    BuildContext context,
    AppProvider provider,
    Map<String, String> t,
  ) {
    final activeId = provider.activeProfileId;
    final activeProfile = activeId == null
        ? null
        : provider.savedProfiles.where((p) => p.id == activeId).firstOrNull;
    final isUpdateMode = activeProfile != null;

    // 기존 프로필명 OR 이름 OR '내 명함' 순으로 기본값 자동 입력
    final defaultName = activeProfile?.name
        ?? (provider.currentCardData.fullName.trim().isNotEmpty
            ? provider.currentCardData.fullName.trim()
            : '내 명함');
    final nameController = TextEditingController(text: defaultName)
      ..selection = TextSelection(
        baseOffset: 0, extentOffset: defaultName.length,
      );

    Future<void> saveAs(
      BuildContext dialogContext, {
      required bool updateCurrent,
    }) async {
      final name = nameController.text.trim();
      if (name.isEmpty) return;
      final targetId = updateCurrent && activeProfile != null
          ? activeProfile.id
          : 'p_${DateTime.now().millisecondsSinceEpoch}';
      await provider.saveProfile(
        Profile(id: targetId, name: name, data: provider.currentCardData),
      );
      if (!dialogContext.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(dialogContext);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _resetEditorToNormalView();
      });
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              updateCurrent
                  ? t['profileUpdatedToast']!
                  : t['profileSavedAsNewToast']!,
            ),
          ),
        );
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        final mq = MediaQuery.of(dialogContext);
        final maxW = (mq.size.width - 56).clamp(240.0, 300.0);
        return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            scrollable: true,
            title: Text(
              isUpdateMode
                  ? t['saveDialogTitleUpdateOrNew']!
                  : t['saveDialogTitleNew']!,
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUpdateMode
                        ? t['saveDialogDescUpdateOrNew']!
                        : t['saveDialogDescNewOnly']!,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: t['profileNameLabel'],
                      hintText: t['profileNameHint'],
                      labelStyle: GoogleFonts.notoSansKr(),
                      hintStyle: GoogleFonts.notoSansKr(color: Colors.grey),
                    ),
                    style: GoogleFonts.notoSansKr(fontSize: 14),
                    autofocus: false,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) =>
                        saveAs(dialogContext, updateCurrent: isUpdateMode),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(t['cancel']!),
              ),
              if (isUpdateMode)
                OutlinedButton(
                  onPressed: () => saveAs(dialogContext, updateCurrent: false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                  ),
                  child: Text(t['saveAsNew']!),
                ),
              OutlinedButton(
                onPressed: () =>
                    saveAs(dialogContext, updateCurrent: isUpdateMode),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                ),
                child: Text(
                  isUpdateMode ? t['updateCurrentProfile']! : t['saveAsNew']!,
                ),
              ),
            ],
        );
    },
    );
  }

  Color _parseHexColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  Map<String, String> _getTexts(String language) {
    if (_cachedLanguage == language) return _cachedTexts;
    _cachedLanguage = language;
    if (language == 'ko') {
      _cachedTexts = {
        'backgrounds': '배경 테마',
        'profiles': '프로필 목록',
        'newProfile': '새 프로필',
        'slogan': '한줄 소개',
        'profileInfo': '기본 정보',
        'media': '사진 및 로고',
        'fullName': '이름',
        'jobTitle': '직함 / 직책',
        'companyName': '회사 / 소속',
        'contactInfo': '연락처',
        'links': '링크 및 SNS',
        'address': '주소',
        'livePreview': '실시간 미리보기',
        'cardInfoInput': '명함 정보 입력',
        'aiRecommend': 'AI 추천',
        'koreanModeOn': '한글 모드',
        'englishModeOn': '영문 모드',
        'imageUploadComingSoon': '이미지 업로드 기능은 준비 중입니다. URL로 입력해주세요.',
        'profileUpdatedToast': '현재 프로필이 업데이트되었습니다.',
        'profileSavedAsNewToast': '새 프로필로 저장되었습니다.',
        'saveDialogTitleUpdateOrNew': '프로필 업데이트 또는 새 저장',
        'saveDialogTitleNew': '새 프로필 저장',
        'saveDialogDescUpdateOrNew': '현재 프로필을 덮어쓸지, 새 프로필로 저장할지 선택하세요.',
        'saveDialogDescNewOnly': '프로필 이름을 입력하고 새로 저장하세요.',
        'profileNameLabel': '프로필 이름',
        'profileNameHint': '예: Work V2',
        'cancel': '취소',
        'saveAsNew': '새 프로필로 저장',
        'updateCurrentProfile': '현재 프로필 업데이트',
        'uploadBtn': '변경',
        'placeholders.slogan': '당신의 이야기를 들려주세요...',
        'placeholders.phone': '전화번호',
        'placeholders.sms': '문자 수신 번호',
        'placeholders.email': '이메일 주소',
        'placeholders.kakao': '카카오톡 ID',
        'placeholders.website': '웹사이트 URL',
        'placeholders.linkedin': 'LinkedIn 프로필',
        'placeholders.shareLink': '커스텀 공유 링크',
        'placeholders.portfolio': '링크 입력 (예: www.example.com)',
        'placeholders.address': '주소 입력',
        'placeholders.hotlink': '또는 이미지 URL 붙여넣기...',
        'basicProfileToastLine1': '입력 내용이 기본 프로필로 저장됩니다.',
        'basicProfileToastLine2': '입력 중 변경사항은 자동으로 반영됩니다.',
        'basicProfileToastAction': '확인',
        'jobTitlePickerTitle': '직함 / 직책 선택',
      };
      return _cachedTexts;
    } else {
      _cachedTexts = {
        'backgrounds': 'Backgrounds',
        'profiles': 'Profiles',
        'newProfile': 'New',
        'slogan': 'Personal Slogan',
        'profileInfo': 'Profile Information',
        'media': 'Media',
        'fullName': 'Full Name',
        'jobTitle': 'Job Title',
        'companyName': 'Company Name',
        'contactInfo': 'Contact Info',
        'links': 'Links & SNS',
        'address': 'Address',
        'livePreview': 'Live Preview',
        'cardInfoInput': 'Edit Card Info',
        'aiRecommend': 'AI Suggest',
        'koreanModeOn': 'Korean mode',
        'englishModeOn': 'English mode',
        'imageUploadComingSoon': 'Image upload is coming soon. Please use URL input.',
        'profileUpdatedToast': 'Current profile has been updated.',
        'profileSavedAsNewToast': 'Saved as a new profile.',
        'saveDialogTitleUpdateOrNew': 'Update current profile or save as new',
        'saveDialogTitleNew': 'Save as New Profile',
        'saveDialogDescUpdateOrNew': 'Choose whether to overwrite current profile or save as a new one.',
        'saveDialogDescNewOnly': 'Enter a profile name and save as new.',
        'profileNameLabel': 'Profile Name',
        'profileNameHint': 'e.g. Work V2',
        'cancel': 'Cancel',
        'saveAsNew': 'Save as New',
        'updateCurrentProfile': 'Update Current Profile',
        'uploadBtn': 'Change',
        'placeholders.slogan': 'Your story begins here...',
        'placeholders.phone': 'Phone Number',
        'placeholders.sms': 'Message Number',
        'placeholders.email': 'Email Address',
        'placeholders.kakao': 'KakaoTalk ID',
        'placeholders.website': 'Website URL',
        'placeholders.linkedin': 'LinkedIn Profile',
        'placeholders.shareLink': 'Custom Share Link',
        'placeholders.portfolio': 'Enter link (e.g. www.example.com)',
        'placeholders.address': 'Physical Address',
        'placeholders.hotlink': 'Or paste image URL (Hotlink)...',
        'basicProfileToastLine1': 'Your input will be saved as the basic profile.',
        'basicProfileToastLine2': 'Changes are applied automatically while you type.',
        'basicProfileToastAction': 'OK',
        'jobTitlePickerTitle': 'Select Job Title',
      };
      return _cachedTexts;
    }
  }

  void _maybeShowBasicProfileToast(
    BuildContext context,
    AppProvider provider,
    Map<String, String> t,
  ) {
    if (provider.hasBasicProfile || _basicProfileToastShown) return;
    _basicProfileToastShown = true;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(t['basicProfileToastLine1']!),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 92),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
