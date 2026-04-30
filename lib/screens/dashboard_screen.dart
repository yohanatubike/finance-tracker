import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/app_formatting.dart';
import '../utils/date_window.dart';
import '../models/debt.dart';
import '../models/loan_schedule.dart';
import '../models/outgoing_payment.dart';
import '../providers/fund_provider.dart';
import '../providers/asset_provider.dart';
import '../providers/incoming_payment_provider.dart';
import '../providers/outgoing_payment_provider.dart';
import '../providers/debt_provider.dart';
import '../providers/stock_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final fundProvider = Provider.of<FundProvider>(context);
    final assetProvider = Provider.of<AssetProvider>(context);
    final incomingProvider = Provider.of<IncomingPaymentProvider>(context);
    final outgoingProvider = Provider.of<OutgoingPaymentProvider>(context);
    final debtProvider = Provider.of<DebtProvider>(context);
    final stockProvider = Provider.of<StockProvider>(context);

    final netWorth = fundProvider.totalFunds
        + assetProvider.totalAssets
        + stockProvider.totalPortfolioValue
        - debtProvider.totalIOwe;
    final fmt = currencyFormat(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    const DrawerMenuButton(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.secondaryText,
                                      letterSpacing: 0.3,
                                    ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your Finances',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.brandLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.insights_rounded,
                          color: AppColors.brand, size: 20),
                    ),
                  ],
                ),
              ),
            ),

            // ── Net Worth Card ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _NetWorthCard(
                  netWorth: netWorth,
                  funds: fundProvider.totalFunds,
                  assets: assetProvider.totalAssets,
                  stocks: stockProvider.totalPortfolioValue,
                  debtIOwe: debtProvider.totalIOwe,
                  fmt: fmt,
                ),
              ),
            ),

            // ── Section: Pending Cash Flow ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Text(
                  'PENDING CASH FLOW',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.2,
                        color: AppColors.secondaryText,
                      ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: _CashFlowCard(
                        label: 'Incoming',
                        amount: incomingProvider.totalPending,
                        count: incomingProvider.pendingPayments.length,
                        color: AppColors.income,
                        lightColor: AppColors.incomeLight,
                        icon: Icons.south_rounded,
                        fmt: fmt,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CashFlowCard(
                        label: 'Outgoing',
                        amount: outgoingProvider.totalPending,
                        count: outgoingProvider.pendingPayments.length,
                        color: AppColors.expense,
                        lightColor: AppColors.expenseLight,
                        icon: Icons.north_rounded,
                        fmt: fmt,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _WeekAheadCard(
                  outgoingProvider: outgoingProvider,
                  debtProvider: debtProvider,
                  fmt: fmt,
                ),
              ),
            ),

            // ── Section: Debt Position ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Text(
                  'DEBT POSITION',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.2,
                        color: AppColors.secondaryText,
                      ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: _DebtSummaryCard(
                  totalIOwe: debtProvider.totalIOwe,
                  totalOwedToMe: debtProvider.totalOwedToMe,
                  netPosition: debtProvider.netPosition,
                  activeCount: debtProvider.activeDebts.length,
                  fmt: fmt,
                ),
              ),
            ),

            // ── Section: Portfolio Overview ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Text(
                  'PORTFOLIO OVERVIEW',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.2,
                        color: AppColors.secondaryText,
                      ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverToBoxAdapter(
                child: Card(
                  child: Column(
                    children: [
                      _OverviewRow(
                        icon: Icons.account_balance_wallet_rounded,
                        iconColor: AppColors.income,
                        iconBg: AppColors.incomeLight,
                        label: 'Active Funds',
                        value: fundProvider.funds.length.toString(),
                        sublabel: fmt.format(fundProvider.totalFunds),
                      ),
                      const Divider(indent: 64, endIndent: 0),
                      _OverviewRow(
                        icon: Icons.business_center_rounded,
                        iconColor: AppColors.asset,
                        iconBg: AppColors.assetLight,
                        label: 'Total Assets',
                        value: assetProvider.assets.length.toString(),
                        sublabel: fmt.format(assetProvider.totalAssets),
                      ),
                      const Divider(indent: 64, endIndent: 0),
                      _OverviewRow(
                        icon: Icons.show_chart_rounded,
                        iconColor: const Color(0xFF0891B2),
                        iconBg: const Color(0xFFE0F7FA),
                        label: 'Stock Portfolio',
                        value: stockProvider.holdings.length.toString(),
                        sublabel: fmt.format(stockProvider.totalPortfolioValue),
                      ),
                      const Divider(indent: 64, endIndent: 0),
                      _OverviewRow(
                        icon: Icons.south_rounded,
                        iconColor: AppColors.pending,
                        iconBg: AppColors.pendingLight,
                        label: 'Pending Incoming',
                        value: incomingProvider.pendingPayments.length
                            .toString(),
                        sublabel:
                            fmt.format(incomingProvider.totalPending),
                      ),
                      const Divider(indent: 64, endIndent: 0),
                      _OverviewRow(
                        icon: Icons.north_rounded,
                        iconColor: AppColors.expense,
                        iconBg: AppColors.expenseLight,
                        label: 'Pending Outgoing',
                        value: outgoingProvider.pendingPayments.length
                            .toString(),
                        sublabel:
                            fmt.format(outgoingProvider.totalPending),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekAheadCard extends StatelessWidget {
  final OutgoingPaymentProvider outgoingProvider;
  final DebtProvider debtProvider;
  final NumberFormat fmt;

  const _WeekAheadCard({
    required this.outgoingProvider,
    required this.debtProvider,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final outgoingDue = outgoingProvider.pendingPayments
        .where((p) =>
            p.deadlineAt != null &&
            isWithinNextSevenDays(p.deadlineAt!, now))
        .toList()
      ..sort((a, b) => a.deadlineAt!.compareTo(b.deadlineAt!));

    final debtDue = LoanScheduleCalculator.installmentsDueNextWeek(
      debtProvider.activeDebts,
      now,
    );

    final sumOut =
        outgoingDue.fold<double>(0, (s, p) => s + p.amount);
    final sumDebt =
        debtDue.fold<double>(0, (s, x) => s + x.row.paymentAmount);
    final total = sumOut + sumDebt;
    final count = outgoingDue.length + debtDue.length;

    if (count == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_view_week_rounded,
                color: AppColors.secondaryText.withValues(alpha: 0.85),
                size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Nothing due in the next 7 days (outgoing deadlines & loan installments)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryText,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.date_range_rounded,
                  color: AppColors.brand, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'NEXT 7 DAYS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.2,
                        color: AppColors.secondaryText,
                      ),
                ),
              ),
              Text(
                fmt.format(total),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$count scheduled · outgoing ${fmt.format(sumOut)} · installments ${fmt.format(sumDebt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          ..._weekAheadLines(outgoingDue, debtDue, fmt, context),
        ],
      ),
    );
  }
}

List<Widget> _weekAheadLines(
  List<OutgoingPayment> outgoingDue,
  List<({Debt debt, LoanScheduleRow row})> debtDue,
  NumberFormat fmt,
  BuildContext context,
) {
  final rows = <Widget>[];
  var n = 0;
  const maxLines = 6;
  final totalItems = outgoingDue.length + debtDue.length;

  for (final p in outgoingDue) {
    if (n >= maxLines) break;
    final dl = p.deadlineAt!;
    rows.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.north_rounded,
                size: 16, color: AppColors.expense.withValues(alpha: 0.85)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${p.name} · ${DateFormat.MMMd().format(dl)}',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              fmt.format(p.amount),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.expense,
                  ),
            ),
          ],
        ),
      ),
    );
    n++;
  }
  for (final (:debt, :row) in debtDue) {
    if (n >= maxLines) break;
    rows.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.schedule_rounded,
                size: 16, color: AppColors.pending.withValues(alpha: 0.9)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${debt.personName} · ${LoanScheduleCalculator.formatDue(row.dueDate)}',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              fmt.format(row.paymentAmount),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
    n++;
  }
  final extra = totalItems - maxLines;
  if (extra > 0) {
    rows.add(
      Text(
        '+ $extra more',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.secondaryText,
            ),
      ),
    );
  }
  return rows;
}

class _NetWorthCard extends StatelessWidget {
  final double netWorth;
  final double funds;
  final double assets;
  final double stocks;
  final double debtIOwe;
  final NumberFormat fmt;

  const _NetWorthCard({
    required this.netWorth,
    required this.funds,
    required this.assets,
    required this.stocks,
    required this.debtIOwe,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.account_balance_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Total Net Worth',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            fmt.format(netWorth),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.15),
          ),
          const SizedBox(height: 16),
          // Row 1: Funds + Assets
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: 'Liquid Funds',
                  value: fmt.format(funds),
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: Colors.white.withOpacity(0.2),
              ),
              Expanded(
                child: _HeroStat(
                  label: 'Fixed Assets',
                  value: fmt.format(assets),
                  alignRight: true,
                ),
              ),
            ],
          ),
          // Row 2: Stocks + Debt (only if either is non-zero)
          if (stocks > 0 || debtIOwe > 0) ...[
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.white.withOpacity(0.10),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (stocks > 0)
                  Expanded(
                    child: _HeroStat(
                      label: 'Stock Portfolio',
                      value: fmt.format(stocks),
                      icon: Icons.show_chart_rounded,
                    ),
                  ),
                if (stocks > 0 && debtIOwe > 0)
                  Container(
                    width: 1,
                    height: 32,
                    color: Colors.white.withOpacity(0.2),
                  ),
                if (debtIOwe > 0)
                  Expanded(
                    child: _HeroStat(
                      label: 'Less: Debt',
                      value: '− ${fmt.format(debtIOwe)}',
                      alignRight: stocks > 0,
                      valueColor: const Color(0xFFFFCDD2),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final bool alignRight;
  final Color? valueColor;

  const _HeroStat({
    required this.label,
    required this.value,
    this.icon,
    this.alignRight = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: alignRight ? 16 : 0,
        right: alignRight ? 0 : 16,
      ),
      child: Column(
        crossAxisAlignment: alignRight
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 9,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CashFlowCard extends StatelessWidget {
  final String label;
  final double amount;
  final int count;
  final Color color;
  final Color lightColor;
  final IconData icon;
  final NumberFormat fmt;

  const _CashFlowCard({
    required this.label,
    required this.amount,
    required this.count,
    required this.color,
    required this.lightColor,
    required this.icon,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: lightColor,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 15),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: lightColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count pending',
                  style: TextStyle(
                    color: color,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            fmt.format(amount),
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DebtSummaryCard extends StatelessWidget {
  final double totalIOwe;
  final double totalOwedToMe;
  final double netPosition;
  final int activeCount;
  final NumberFormat fmt;

  const _DebtSummaryCard({
    required this.totalIOwe,
    required this.totalOwedToMe,
    required this.netPosition,
    required this.activeCount,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = netPosition >= 0;
    final netColor = isPositive ? AppColors.income : AppColors.expense;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: netColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.handshake_rounded,
                    color: netColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isPositive ? 'You\'re owed more' : 'You owe more',
                  style:
                      Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: netColor,
                            fontWeight: FontWeight.w600,
                          ),
                ),
              ),
              Text(
                '$activeCount active',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.secondaryText),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DebtStatCol(
                  label: 'I Owe',
                  value: fmt.format(totalIOwe),
                  color: AppColors.expense,
                ),
              ),
              Container(
                  width: 1, height: 32, color: AppColors.divider),
              Expanded(
                child: _DebtStatCol(
                  label: 'Owed to Me',
                  value: fmt.format(totalOwedToMe),
                  color: AppColors.pending,
                  alignRight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DebtStatCol extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool alignRight;

  const _DebtStatCol({
    required this.label,
    required this.value,
    required this.color,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: alignRight ? 16 : 0,
        right: alignRight ? 0 : 16,
      ),
      child: Column(
        crossAxisAlignment: alignRight
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final String sublabel;

  const _OverviewRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
