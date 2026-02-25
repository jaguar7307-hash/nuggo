import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/rendering.dart'
    show debugPaintBaselinesEnabled, debugPaintSizeEnabled;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'providers/app_provider.dart';
import 'constants/theme.dart';
import 'screens/editor_screen.dart';
import 'screens/preview_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/account_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/header.dart';
import 'widgets/bottom_nav.dart';

void _showQrDialog(BuildContext context, AppProvider provider) {
  final profile =
      provider.selectedProfile ??
      (provider.savedProfiles.isNotEmpty ? provider.savedProfiles.first : null);
  String url = profile?.data.shareLink.trim() ?? '';
  if (url.isEmpty) url = 'https://nuggo.me';
  if (!url.startsWith('http')) url = 'https://$url';

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('명함 QR 코드'),
      content: SizedBox(
        width: 280,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: url,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
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

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SharedPreferences.getInstance();
    debugPaintBaselinesEnabled = false;
    debugPaintSizeEnabled = false;
    GoogleFonts.config.allowRuntimeFetching = true;
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exception}');
    };
    runApp(
      ChangeNotifierProvider(
        create: (_) => AppProvider()..initialize(),
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('Zone error: $error\n$stack');
  });
}

/// 첫 프레임이 폰에서 그려지는지 확인용 — 밝은 배경이면 Flutter 동작, 검정이면 엔진/설정 이슈
class _FirstFrameGate extends StatefulWidget {
  final Widget child;

  const _FirstFrameGate({required this.child});

  @override
  State<_FirstFrameGate> createState() => _FirstFrameGateState();
}

class _FirstFrameGateState extends State<_FirstFrameGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFFF5F5F7),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('NUGGO', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                const SizedBox(height: 16),
                Text('로딩 중...', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ),
      );
    }
    return widget.child;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPaintBaselinesEnabled = false;
    debugPaintSizeEnabled = false;
    final darkMode = context.select<AppProvider, bool>(
      (p) => p.settings.darkMode,
    );
    return _FirstFrameGate(
      child: MaterialApp(
        title: 'NUGGO',
        debugShowCheckedModeBanner: false,
        theme: darkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
        builder: (context, child) {
          return Container(
            color: darkMode ? const Color(0xFF101822) : const Color(0xFFF8F9FA),
            child: child,
          );
        },
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const Color _accentOrange = Color(0xFFFF8A3D);
  final Set<int> _builtTabIndices = <int>{};

  List<Widget> _buildLazyTabChildren(int activeIndex) {
    _builtTabIndices.add(activeIndex);
    return [
      _builtTabIndices.contains(0)
          ? const ProfileScreen()
          : const SizedBox.shrink(),
      _builtTabIndices.contains(1)
          ? const EditorScreen()
          : const SizedBox.shrink(),
      _builtTabIndices.contains(2)
          ? const WalletScreen()
          : const SizedBox.shrink(),
      _builtTabIndices.contains(3)
          ? const AccountScreen()
          : const SizedBox.shrink(),
      _builtTabIndices.contains(4)
          ? const SettingsScreen()
          : const SizedBox.shrink(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final ui = context
        .select<
          AppProvider,
          ({ViewType activeView, bool isPhoneFrameMode, bool darkMode})
        >(
          (p) => (
            activeView: p.activeView,
            isPhoneFrameMode: p.isPhoneFrameMode,
            darkMode: p.settings.darkMode,
          ),
        );
    if (!kIsWeb) {
      return _buildAppContent(
        context,
        provider,
        activeView: ui.activeView,
        maxWidth: null,
        maxHeight: null,
      );
    }

    final isPhone = ui.isPhoneFrameMode;
    // iPhone 16 Pro 논리 해상도 (pt): 402 × 874
    const double iphone16ProWidth = 402.0;
    const double iphone16ProHeight = 874.0;
    final frameWidth = isPhone ? iphone16ProWidth : 800.0;
    final frameHeight = isPhone ? iphone16ProHeight : 900.0;

    return Container(
      color: ui.darkMode ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '보기 모드:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                _DisplayModeChip(
                  label: '📱 iPhone 16 Pro',
                  selected: isPhone,
                  onTap: () => provider.setPhoneFrameMode(true),
                ),
                const SizedBox(width: 8),
                _DisplayModeChip(
                  label: '🖥 PC',
                  selected: !isPhone,
                  onTap: () => provider.setPhoneFrameMode(false),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: frameWidth,
                  maxHeight: frameHeight,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(56),
                  border: Border.all(color: const Color(0xFF2d2d2d), width: 8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(48),
                  child: _buildAppContent(
                    context,
                    provider,
                    activeView: ui.activeView,
                    maxWidth: frameWidth,
                    maxHeight: frameHeight,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppContent(
    BuildContext context,
    AppProvider provider, {
    required ViewType activeView,
    double? maxWidth,
    double? maxHeight,
  }) {
    final content = activeView == ViewType.preview
        ? _buildCurrentScreen(ViewType.preview)
        : Scaffold(
            body: Stack(
              children: [
                Column(
                  children: [
                    Header(
                      activeView: activeView,
                      onLogoClick: () =>
                          provider.setActiveView(ViewType.myCards),
                      onSettingsClick: () =>
                          provider.setActiveView(ViewType.settings),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom:
                              AppTheme.barHeight +
                              MediaQuery.of(context).padding.bottom,
                        ),
                        child: IndexedStack(
                          index: _tabIndex(activeView),
                          children: _buildLazyTabChildren(
                            _tabIndex(activeView),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (activeView == ViewType.myCards)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom:
                        AppTheme.barHeight +
                        MediaQuery.of(context).padding.bottom +
                        16,
                    child: Center(
                      child: Material(
                        elevation: 8,
                        shadowColor: Colors.black54,
                        borderRadius: BorderRadius.circular(28),
                        color: _accentOrange,
                        child: InkWell(
                          onTap: () => _showQrDialog(context, provider),
                          borderRadius: BorderRadius.circular(28),
                          child: const SizedBox(
                            width: 56,
                            height: 56,
                            child: Icon(
                              Icons.qr_code_2,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: BottomNav(
                    activeView: activeView,
                    onViewChange: provider.setActiveView,
                  ),
                ),
              ],
            ),
          );

    if (maxWidth != null && maxHeight != null) {
      return SizedBox(width: maxWidth, height: maxHeight, child: content);
    }
    return content;
  }

  /// 하단 탭 5개 순서: 내 명함, 에디터, 지갑, 계정, 설정. (preview는 풀스크린으로 별도)
  static int _tabIndex(ViewType view) {
    switch (view) {
      case ViewType.myCards:
        return 0;
      case ViewType.editor:
        return 1;
      case ViewType.wallet:
        return 2;
      case ViewType.account:
        return 3;
      case ViewType.settings:
        return 4;
      case ViewType.preview:
        return 0;
    }
  }

  Widget _buildCurrentScreen(ViewType activeView) {
    if (activeView == ViewType.preview) return const PreviewScreen();
    return const SizedBox.shrink();
  }
}

class _DisplayModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DisplayModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primary
          : Colors.grey.shade300,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}
