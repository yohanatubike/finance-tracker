import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../navigation_service.dart';
import '../providers/asset_provider.dart';
import '../providers/debt_provider.dart';
import '../providers/fund_provider.dart';
import '../providers/incoming_payment_provider.dart';
import '../providers/outgoing_payment_provider.dart';
import '../providers/stock_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/main_bottom_navigation.dart';
import 'assets_screen.dart';
import 'dashboard_screen.dart';
import 'debt_screen.dart';
import 'funds_screen.dart';
import 'incoming_payments_screen.dart';
import 'outgoing_payments_screen.dart';
import 'stock_portfolio_summary_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const FundsScreen(),
    const AssetsScreen(),
    const IncomingPaymentsScreen(),
    const OutgoingPaymentsScreen(),
    const DebtScreen(),
    const StockPortfolioSummaryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final fundProvider = Provider.of<FundProvider>(context, listen: false);
    final assetProvider = Provider.of<AssetProvider>(context, listen: false);
    final incomingProvider =
        Provider.of<IncomingPaymentProvider>(context, listen: false);
    final outgoingProvider =
        Provider.of<OutgoingPaymentProvider>(context, listen: false);
    final debtProvider = Provider.of<DebtProvider>(context, listen: false);
    final stockProvider = Provider.of<StockProvider>(context, listen: false);

    await Future.wait([
      fundProvider.loadFunds(),
      assetProvider.loadAssets(),
      incomingProvider.loadPayments(),
      outgoingProvider.loadPayments(),
      debtProvider.loadDebts(),
      stockProvider.loadStocks(),
    ]);
  }

  void _navigate(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: NavigationService.scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: AppDrawer(
        currentIndex: _currentIndex,
        onNavigate: (i) {
          Navigator.pop(context);
          _navigate(i);
        },
      ),
      bottomNavigationBar: MainBottomNavigation(
        currentIndex: _currentIndex,
        onNavigate: _navigate,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
    );
  }
}
