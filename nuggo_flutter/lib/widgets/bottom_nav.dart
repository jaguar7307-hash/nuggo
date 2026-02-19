import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../providers/app_provider.dart';

class BottomNav extends StatelessWidget {
  final ViewType activeView;
  final Function(ViewType) onViewChange;

  const BottomNav({
    super.key,
    required this.activeView,
    required this.onViewChange,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(view: ViewType.myCards, icon: Icons.contact_page),
      _NavItem(view: ViewType.editor, icon: Icons.edit_note),
      _NavItem(view: ViewType.wallet, icon: Icons.wallet),
    ];

    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: AppTheme.barBackground,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppTheme.barHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((item) {
              final isActive = activeView == item.view;
              final color = isActive ? primary : AppTheme.barIconInactive;
              return SizedBox(
                width: 80,
                child: GestureDetector(
                  onTap: () => onViewChange(item.view),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    child: Icon(item.icon, size: 26, color: color),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final ViewType view;
  final IconData icon;

  _NavItem({required this.view, required this.icon});
}
