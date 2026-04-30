import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/ticker_holding_summary.dart';
import '../providers/stock_provider.dart';
import '../utils/app_formatting.dart';
import '../theme/app_theme.dart';

const Color _stockColor = Color(0xFF0891B2);
const Color _stockLight = Color(0xFFE0F7FA);

class StockPortfolioSummaryScreen extends StatelessWidget {
  const StockPortfolioSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fmt = currencyFormat(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Investment summary'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<StockProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          final rows = provider.tickerSummaries;
          final totalLots = provider.holdings.length;

          if (rows.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.insights_outlined,
                        size: 56, color: AppColors.hintText.withValues(alpha: 0.8)),
                    const SizedBox(height: 16),
                    Text(
                      'No stock holdings yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add holdings from Stock holdings (app menu) to see totals here.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          }

          final hasPrices =
              rows.any((r) => r.totalCurrentValue > 0 || r.impliedMarketPrice > 0);

          return RefreshIndicator(
            color: _stockColor,
            onRefresh: () => provider.loadStocks(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                _DashboardHero(
                  fmt: fmt,
                  provider: provider,
                  symbolCount: rows.length,
                  totalLots: totalLots,
                ),
                if (!hasPrices)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _stockLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: _stockColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Update prices via the menu: Update Stock Prices — so values reflect live quotes.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: _stockColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'BY SYMBOL',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.2,
                          color: AppColors.secondaryText,
                        ),
                  ),
                ),
                ...rows.map(
                  (row) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TickerSummaryTile(
                      row: row,
                      fmt: fmt,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  final NumberFormat fmt;
  final StockProvider provider;
  final int symbolCount;
  final int totalLots;

  const _DashboardHero({
    required this.fmt,
    required this.provider,
    required this.symbolCount,
    required this.totalLots,
  });

  @override
  Widget build(BuildContext context) {
    final tv = provider.totalPortfolioValue;
    final tc = provider.totalCostBasis;
    final gl = provider.totalGainLoss;
    final glp = provider.totalGainLossPercent;
    final positive = gl >= 0;
    final glColor = positive ? AppColors.income : AppColors.expense;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _stockColor.withValues(alpha: 0.92),
            const Color(0xFF0E7490),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _stockColor.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL STOCKS VALUE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            fmt.format(tv),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              _HeroChip(
                label: '$symbolCount symbol${symbolCount == 1 ? '' : 's'}',
              ),
              _HeroChip(
                label:
                    '$totalLots holding${totalLots == 1 ? '' : 's'}',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.22)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroMini(
                  label: 'Invested',
                  value: fmt.format(tc),
                  alignEnd: false,
                ),
              ),
              Expanded(
                child: _HeroMini(
                  label: 'P&L',
                  value:
                      '${gl >= 0 ? '+' : ''}${fmt.format(gl)} (${positive ? '+' : ''}${glp.toStringAsFixed(1)}%)',
                  alignEnd: true,
                  accentColor: glColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String label;

  const _HeroChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _HeroMini extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;
  final Color? accentColor;

  const _HeroMini({
    required this.label,
    required this.value,
    required this.alignEnd,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.72),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: accentColor ?? Colors.white.withValues(alpha: 0.98),
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _TickerSummaryTile extends StatelessWidget {
  final TickerHoldingSummary row;
  final NumberFormat fmt;

  const _TickerSummaryTile({
    required this.row,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final gl = row.gainLoss;
    final positive = gl >= 0;
    final glColor = positive ? AppColors.income : AppColors.expense;
    final lotsNote =
        row.lotCount > 1 ? ' · ${row.lotCount} lots' : '';

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _stockLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  row.ticker.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: _stockColor,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.companyName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${row.totalShares} shares$lotsNote',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.secondaryText,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmt.format(row.totalCurrentValue),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _stockColor,
                        ),
                  ),
                  Text(
                    'market value',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.hintText,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _MetricRow(
            label: 'Invested',
            value: fmt.format(row.totalCostBasis),
          ),
          const SizedBox(height: 8),
          _MetricRow(
            label: 'Avg buy / share',
            value: fmt.format(row.avgBuyPrice),
          ),
          const SizedBox(height: 8),
          _MetricRow(
            label: 'Market / share',
            value: fmt.format(row.impliedMarketPrice),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Unrealized P&L',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryText,
                    ),
              ),
              Text(
                '${positive ? '+' : ''}${fmt.format(gl)} (${positive ? '+' : ''}${row.gainLossPercent.toStringAsFixed(1)}%)',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: glColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.secondaryText,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
