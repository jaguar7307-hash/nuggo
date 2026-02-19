import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../providers/app_provider.dart';
import 'nuggo_logo.dart';

class Header extends StatelessWidget {
  final ViewType activeView;
  final VoidCallback onLogoClick;
  final VoidCallback onSettingsClick;

  const Header({
    super.key,
    required this.activeView,
    required this.onLogoClick,
    required this.onSettingsClick,
  });

  IconData _iconForView(ViewType view) {
    switch (view) {
      case ViewType.myCards:
        return Icons.contact_page;
      case ViewType.editor:
        return Icons.edit_note;
      case ViewType.wallet:
        return Icons.wallet;
      case ViewType.account:
        return Icons.account_circle;
      case ViewType.settings:
        return Icons.settings;
      default:
        return Icons.contact_page;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      color: AppTheme.barBackground,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: AppTheme.barHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onLogoClick,
                    child: Icon(
                      _iconForView(activeView),
                      size: 28,
                      color: primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onLogoClick,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            NuggoLogo(size: 28, color: AppTheme.logoPrimary),
                            const SizedBox(width: 8),
                            NuggoTextLogo(
                              fontSize: 20,
                              variant: LogoVariant.brand,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings, size: 28),
                  onPressed: onSettingsClick,
                  color: AppTheme.barIconInactive,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
