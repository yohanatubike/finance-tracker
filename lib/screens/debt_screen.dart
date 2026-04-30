import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/debt.dart';
import '../providers/debt_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_formatting.dart';
import '../widgets/debt_form_sheet.dart';
import '../widgets/shared_widgets.dart';

import 'debt_detail_screen.dart';

bool _debtMatchesQuery(Debt d, String q) {
  final t = q.trim().toLowerCase();
  if (t.isEmpty) return true;
  return d.personName.toLowerCase().contains(t) ||
      d.description.toLowerCase().contains(t);
}

class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openForm(BuildContext context, {Debt? debt}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DebtFormSheet(debt: debt),
    );
  }

  void _openDetail(BuildContext context, Debt debt) {
    final id = debt.id;
    if (id == null) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DebtDetailScreen(debtId: id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DebtProvider>(context);
    final fmt = currencyFormat(context);
    final net = provider.netPosition;
    final isPositive = net >= 0;
    final q = _searchCtrl.text;
    final iOwe =
        provider.iOwe.where((d) => _debtMatchesQuery(d, q)).toList();
    final owed =
        provider.owedToMe.where((d) => _debtMatchesQuery(d, q)).toList();
    final settled =
        provider.settledDebts.where((d) => _debtMatchesQuery(d, q)).toList();
    final noMatches = provider.debts.isNotEmpty &&
        q.trim().isNotEmpty &&
        iOwe.isEmpty &&
        owed.isEmpty &&
        settled.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ───────────────────────────────────────────────────
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
                            'DEBT TRACKER',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  letterSpacing: 1.2,
                                  color: AppColors.secondaryText,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fmt.format(net.abs()),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isPositive
                                      ? AppColors.income
                                      : AppColors.expense,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isPositive
                                ? 'Net: more is owed to you'
                                : 'Net: you owe more',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: isPositive
                                      ? AppColors.income
                                      : AppColors.expense,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                    AddButton(onTap: () => _openForm(context)),
                  ],
                ),
              ),
            ),

            // ── Summary chips ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    _SummaryChip(
                      label: 'I owe',
                      amount: fmt.format(provider.totalIOwe),
                      color: AppColors.expense,
                      lightColor: AppColors.expenseLight,
                      icon: Icons.north_rounded,
                    ),
                    const SizedBox(width: 10),
                    _SummaryChip(
                      label: 'Owed to me',
                      amount: fmt.format(provider.totalOwedToMe),
                      color: AppColors.pending,
                      lightColor: AppColors.pendingLight,
                      icon: Icons.south_rounded,
                    ),
                  ],
                ),
              ),
            ),

            if (!provider.isLoading && provider.debts.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by name or description',
                      prefixIcon:
                          const Icon(Icons.search_rounded, size: 22),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.divider),
                      ),
                    ),
                  ),
                ),
              ),

            if (provider.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (provider.debts.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.handshake_outlined,
                  message: 'No debts recorded',
                  hint: 'Tap the button above to track money you owe or are owed',
                ),
              )
            else if (noMatches)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No debts match your search',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.secondaryText,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else ...[
              // ── I Owe section ────────────────────────────────────────────
              if (iOwe.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.expense,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'I OWE',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                letterSpacing: 1.2,
                                color: AppColors.expense,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${iOwe.length} item${iOwe.length == 1 ? '' : 's'}',
                          style:
                              Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: iOwe.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final debt = iOwe[index];
                      return _DebtTile(
                        debt: debt,
                        fmt: fmt,
                        onTap: () => _openDetail(context, debt),
                        onToggle: () => provider.togglePaid(debt),
                      );
                    },
                  ),
                ),
              ],

              // ── Owed to Me section ───────────────────────────────────────
              if (owed.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.pending,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'OWED TO ME',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                letterSpacing: 1.2,
                                color: AppColors.pending,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${owed.length} item${owed.length == 1 ? '' : 's'}',
                          style:
                              Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: owed.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final debt = owed[index];
                      return _DebtTile(
                        debt: debt,
                        fmt: fmt,
                        onTap: () => _openDetail(context, debt),
                        onToggle: () => provider.togglePaid(debt),
                      );
                    },
                  ),
                ),
              ],

              // ── Settled section ──────────────────────────────────────────
              if (settled.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                    child: Text(
                      'SETTLED',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                            letterSpacing: 1.2,
                            color: AppColors.secondaryText,
                          ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverList.separated(
                    itemCount: settled.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final debt = settled[index];
                      return _DebtTile(
                        debt: debt,
                        fmt: fmt,
                        onTap: () => _openDetail(context, debt),
                        onToggle: () => provider.togglePaid(debt),
                      );
                    },
                  ),
                ),
              ] else
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Summary Chip ───────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final Color lightColor;
  final IconData icon;

  const _SummaryChip({
    required this.label,
    required this.amount,
    required this.color,
    required this.lightColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: lightColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    amount,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Debt Tile ──────────────────────────────────────────────────────────────────

class _DebtTile extends StatelessWidget {
  final Debt debt;
  final NumberFormat fmt;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _DebtTile({
    required this.debt,
    required this.fmt,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isSettled = debt.isPaid;
    final color = debt.isOwedByMe ? AppColors.expense : AppColors.pending;
    final lightColor =
        debt.isOwedByMe ? AppColors.expenseLight : AppColors.pendingLight;
    final directionIcon =
        debt.isOwedByMe ? Icons.north_rounded : Icons.south_rounded;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isSettled
                  ? AppColors.divider
                  : color.withValues(alpha: 0.25),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Toggle button
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSettled ? color : lightColor,
                    borderRadius: BorderRadius.circular(12),
                    border: isSettled
                        ? null
                        : Border.all(
                            color: color.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                  ),
                  child: Icon(
                    isSettled ? Icons.check_rounded : directionIcon,
                    color: isSettled ? Colors.white : color,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.personName,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                            decoration: isSettled
                                ? TextDecoration.lineThrough
                                : null,
                            color: isSettled
                                ? AppColors.secondaryText
                                : AppColors.primaryText,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      debt.description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmt.format(debt.amount),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isSettled ? AppColors.secondaryText : color,
                          fontWeight: FontWeight.w700,
                          decoration: isSettled
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSettled
                          ? AppColors.surfaceVariant
                          : lightColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isSettled
                          ? 'Settled'
                          : (debt.isOwedByMe ? 'I owe' : 'They owe'),
                      style: TextStyle(
                        color: isSettled ? AppColors.secondaryText : color,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
