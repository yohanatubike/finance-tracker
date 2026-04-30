import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Matches [MainNavigation] IndexedStack indices used by the bottom bar.
abstract final class MainBottomNavRoutes {
  static const overview = 0;
  static const funds = 1;
  static const assets = 2;
  static const outgoing = 4;
  static const stocks = 6;
}

class MainBottomNavigation extends StatelessWidget {
  /// Current root screen index (same as drawer / IndexedStack).
  final int currentIndex;
  final ValueChanged<int> onNavigate;

  const MainBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
          child: Row(
            children: [
              Expanded(
                child: _BottomItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Overview',
                  selected: currentIndex == MainBottomNavRoutes.overview,
                  accent: scheme.primary,
                  onTap: () => onNavigate(MainBottomNavRoutes.overview),
                ),
              ),
              Expanded(
                child: _BottomItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Funds',
                  selected: currentIndex == MainBottomNavRoutes.funds,
                  accent: scheme.primary,
                  onTap: () => onNavigate(MainBottomNavRoutes.funds),
                ),
              ),
              Expanded(
                child: _BottomItem(
                  icon: Icons.business_center_rounded,
                  label: 'Assets',
                  selected: currentIndex == MainBottomNavRoutes.assets,
                  accent: scheme.tertiary,
                  onTap: () => onNavigate(MainBottomNavRoutes.assets),
                ),
              ),
              Expanded(
                child: _BottomItem(
                  icon: Icons.north_rounded,
                  label: 'Outgoing',
                  selected: currentIndex == MainBottomNavRoutes.outgoing,
                  accent: scheme.error,
                  onTap: () => onNavigate(MainBottomNavRoutes.outgoing),
                ),
              ),
              Expanded(
                child: _BottomItem(
                  icon: Icons.show_chart_rounded,
                  label: 'Stocks',
                  selected: currentIndex == MainBottomNavRoutes.stocks,
                  accent: const Color(0xFF0891B2),
                  onTap: () => onNavigate(MainBottomNavRoutes.stocks),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _BottomItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? accent : AppColors.secondaryText;
    final bg = selected ? accent.withValues(alpha: 0.12) : Colors.transparent;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: accent.withValues(alpha: 0.12),
          highlightColor: accent.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: fg),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: fg,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        height: 1.1,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
