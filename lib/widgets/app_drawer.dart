import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_formatting.dart';
import '../providers/fund_provider.dart';
import '../providers/asset_provider.dart';
import '../providers/debt_provider.dart';
import '../providers/stock_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/pin_session_provider.dart';
import '../theme/app_theme.dart';
import '../screens/profile_screen.dart';
import '../screens/stocks_screen.dart';
import '../screens/stock_prices_screen.dart';
import '../screens/stock_tickers_screen.dart';

String _profileInitials(String raw) {
  final parts =
      raw.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
  return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
}

class AppDrawer extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onNavigate;

  const AppDrawer({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final fundProvider = Provider.of<FundProvider>(context);
    final assetProvider = Provider.of<AssetProvider>(context);
    final debtProvider = Provider.of<DebtProvider>(context);
    final stockProvider = Provider.of<StockProvider>(context);
    final fmt = currencyFormat(context);

    final netWorth = fundProvider.totalFunds +
        assetProvider.totalAssets +
        stockProvider.totalPortfolioValue -
        debtProvider.totalIOwe;

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer<ProfileProvider>(
                    builder: (context, profile, _) {
                      final initials =
                          _profileInitials(profile.profile.displayName);
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.22),
                              child: initials.isEmpty
                                  ? const Icon(Icons.person_rounded,
                                      color: Colors.white, size: 22)
                                  : Text(
                                      initials,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.shortDisplayLine,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Personal Finance · Profile',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                          alpha: 0.72),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color: Colors.white.withValues(alpha: 0.75),
                                size: 22),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'NET WORTH',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fmt.format(netWorth),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            // ── Navigation items ───────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // MAIN section
                  _SectionLabel('MAIN'),
                  _DrawerItem(
                    icon: Icons.grid_view_rounded,
                    label: 'Overview',
                    selected: currentIndex == 0,
                    onTap: () => onNavigate(0),
                  ),
                  _DrawerItem(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Funds',
                    selected: currentIndex == 1,
                    onTap: () => onNavigate(1),
                  ),
                  _DrawerItem(
                    icon: Icons.business_center_rounded,
                    label: 'Assets',
                    selected: currentIndex == 2,
                    onTap: () => onNavigate(2),
                  ),
                  _DrawerItem(
                    icon: Icons.south_rounded,
                    label: 'Incoming',
                    selected: currentIndex == 3,
                    onTap: () => onNavigate(3),
                  ),
                  _DrawerItem(
                    icon: Icons.north_rounded,
                    label: 'Outgoing',
                    selected: currentIndex == 4,
                    onTap: () => onNavigate(4),
                  ),
                  _DrawerItem(
                    icon: Icons.handshake_rounded,
                    label: 'Debts',
                    selected: currentIndex == 5,
                    onTap: () => onNavigate(5),
                  ),

                  const SizedBox(height: 8),
                  const Divider(indent: 16, endIndent: 16),
                  const SizedBox(height: 4),

                  _SectionLabel('ACCOUNT'),
                  _DrawerItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Profile',
                    selected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.lock_outline_rounded,
                    label: 'Lock app',
                    selected: false,
                    onTap: () {
                      Navigator.pop(context);
                      context.read<PinSessionProvider>().lock();
                    },
                  ),

                  const SizedBox(height: 8),
                  const Divider(indent: 16, endIndent: 16),
                  const SizedBox(height: 4),

                  // INVESTMENTS section
                  _SectionLabel('INVESTMENTS'),
                  _DrawerItem(
                    icon: Icons.insights_rounded,
                    label: 'Investment summary',
                    selected: currentIndex == 6,
                    onTap: () => onNavigate(6),
                    color: const Color(0xFF0891B2),
                  ),
                  _DrawerItem(
                    icon: Icons.show_chart_rounded,
                    label: 'Stock holdings',
                    selected: false,
                    color: const Color(0xFF0891B2),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const StocksScreen()),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.price_change_rounded,
                    label: 'Update Stock Prices',
                    selected: false,
                    color: const Color(0xFF0891B2),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StockPricesScreen(),
                        ),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.format_list_bulleted_rounded,
                    label: 'Manage Tickers',
                    selected: false,
                    color: const Color(0xFF0891B2),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StockTickersScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Footer ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'Personal Finance',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.hintText,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: AppColors.hintText,
            ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.brand;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: selected
            ? activeColor.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? activeColor : AppColors.secondaryText,
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: selected ? activeColor : AppColors.primaryText,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                ),
                if (selected) ...[
                  const Spacer(),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
