import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/debt.dart';
import '../models/debt_payment.dart';
import '../models/loan_schedule.dart';
import '../database/database_helper.dart';
import '../providers/debt_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_formatting.dart';
import '../widgets/debt_form_sheet.dart';
import '../widgets/shared_widgets.dart';

class DebtDetailScreen extends StatefulWidget {
  final int debtId;

  const DebtDetailScreen({super.key, required this.debtId});

  @override
  State<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<DebtDetailScreen> {
  Future<List<DebtPayment>>? _paymentsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _paymentsFuture ??=
        DatabaseHelper.instance.getDebtPayments(widget.debtId);
  }

  void _reloadPayments() {
    setState(() {
      _paymentsFuture =
          DatabaseHelper.instance.getDebtPayments(widget.debtId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = currencyFormat(context);
    final provider = Provider.of<DebtProvider>(context);

    final debt = provider.debtById(widget.debtId);
    if (debt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Debt')),
        body: const Center(child: Text('This debt was removed')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(debt.personName),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => DebtFormSheet(debt: debt),
              );
            },
          ),
        ],
      ),
      floatingActionButton: !debt.isPaid
          ? FloatingActionButton.extended(
              onPressed: () => _openRecordPayment(context, debt, _reloadPayments),
              backgroundColor:
                  debt.isOwedByMe ? AppColors.expense : AppColors.pending,
              icon: const Icon(Icons.payment_rounded),
              label: const Text('Record payment'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => provider.loadDebts(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BalanceCard(debt: debt, fmt: fmt),
              if (debt.hasLoanScheduleData) ...[
                const SizedBox(height: 16),
                _LoanSummaryCard(debt: debt, fmt: fmt),
                const SizedBox(height: 16),
                _ScheduleCard(debt: debt, fmt: fmt),
              ],
              const SizedBox(height: 20),
              Text(
                'PAYMENT HISTORY',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      color: AppColors.secondaryText,
                    ),
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<DebtPayment>>(
                future: _paymentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        'No payments recorded yet. Tap Record payment after each installment or extra payment.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }
                  return Column(
                    children: items
                        .map((p) => _PaymentTile(payment: p, fmt: fmt))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openRecordPayment(
    BuildContext context,
    Debt debt,
    VoidCallback onRecorded,
  ) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _RecordPaymentSheet(debt: debt),
    );
    if (ok == true) onRecorded();
  }
}

class _BalanceCard extends StatelessWidget {
  final Debt debt;
  final NumberFormat fmt;

  const _BalanceCard({required this.debt, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final color = debt.isOwedByMe ? AppColors.expense : AppColors.pending;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            debt.isOwedByMe ? 'Outstanding balance' : 'They owe you',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(
            fmt.format(debt.amount),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: debt.isPaid ? AppColors.secondaryText : color,
                  decoration:
                      debt.isPaid ? TextDecoration.lineThrough : null,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            debt.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (debt.isPaid)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Settled',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.income,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LoanSummaryCard extends StatelessWidget {
  final Debt debt;
  final NumberFormat fmt;

  const _LoanSummaryCard({required this.debt, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final mi = debt.monthlyInstallment!;
    final estPayoff =
        LoanScheduleCalculator.payoffFromRemaining(
      remainingBalance: debt.amount,
      monthlyInstallment: mi,
    );
    final origEnd = LoanScheduleCalculator.originalTermEnd(debt);

    return Container(
      padding: const EdgeInsets.all(18),
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
              Icon(Icons.schedule_rounded,
                  color: AppColors.expense.withValues(alpha: 0.85), size: 22),
              const SizedBox(width: 10),
              Text(
                'Monthly loan',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _LoanRow(
              label: 'Installment',
              value: '${fmt.format(mi)} / month'),
          _LoanRow(
              label: 'Loan started',
              value: LoanScheduleCalculator.formatDue(debt.loanStartDate!)),
          _LoanRow(
              label: 'Default method',
              value: debt.defaultPaymentMethod.isEmpty
                  ? '—'
                  : debt.defaultPaymentMethod),
          const Divider(height: 22),
          _LoanRow(
            label: 'Est. payoff (from balance)',
            value: estPayoff != null
                ? LoanScheduleCalculator.formatDue(estPayoff)
                : '—',
          ),
          if (origEnd != null)
            _LoanRow(
              label: 'Original term end',
              value: LoanScheduleCalculator.formatDue(origEnd),
            ),
        ],
      ),
    );
  }
}

class _LoanRow extends StatelessWidget {
  final String label;
  final String value;

  const _LoanRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText,
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final Debt debt;
  final NumberFormat fmt;

  const _ScheduleCard({required this.debt, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final rows = LoanScheduleCalculator.remainingSchedule(debt: debt);

    return ExpansionTile(
      initiallyExpanded: true,
      tilePadding: EdgeInsets.zero,
      title: Row(
        children: [
          Icon(Icons.table_rows_rounded,
              color: AppColors.expense.withValues(alpha: 0.85)),
          const SizedBox(width: 10),
          Text(
            'Payment schedule (projected)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          'Monthly cadence from loan start; balances update after each payment.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      children: rows.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Balance cleared or installment amount exceeds remaining.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ]
          : rows
              .map((r) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            LoanScheduleCalculator.formatDue(r.dueDate),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            fmt.format(r.paymentAmount),
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            fmt.format(r.remainingAfter),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.secondaryText,
                                ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final DebtPayment payment;
  final NumberFormat fmt;

  const _PaymentTile({required this.payment, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final isExtra = payment.kind == DebtPaymentKind.extra;
    final badgeColor =
        isExtra ? AppColors.pending.withValues(alpha: 0.15) : AppColors.income.withValues(alpha: 0.12);
    final badgeFg =
        isExtra ? AppColors.pending : AppColors.income;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isExtra ? 'Extra payment' : 'Installment',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: badgeFg,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const Spacer(),
              Text(
                fmt.format(payment.amount),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat.yMMMMd().format(payment.paidAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (payment.paymentMethod.isNotEmpty)
            Text(
              'via ${payment.paymentMethod}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText,
                  ),
            ),
          if (payment.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                payment.note,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (payment.externalRef.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Ref: ${payment.externalRef}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.secondaryText,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecordPaymentSheet extends StatefulWidget {
  final Debt debt;

  const _RecordPaymentSheet({required this.debt});

  @override
  State<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<_RecordPaymentSheet> {
  final _amountCtrl = TextEditingController();
  DateTime _paidAt = DateTime.now();
  DebtPaymentKind _kind = DebtPaymentKind.installment;
  late String _method;
  final _noteCtrl = TextEditingController();
  final _refCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _method = widget.debt.defaultPaymentMethod.isNotEmpty
        ? widget.debt.defaultPaymentMethod
        : kDebtPaymentMethods.first;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _paidAt = picked);
  }

  Future<void> _submit() async {
    final raw = _amountCtrl.text.trim();
    final amt = double.tryParse(raw);
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    final latest = Provider.of<DebtProvider>(context, listen: false)
        .debtById(widget.debt.id);
    final owed = latest?.amount ?? widget.debt.amount;
    if (amt > owed + 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Amount exceeds remaining ${currencyFormat(context).format(owed)}'),
        ),
      );
      return;
    }

    await Provider.of<DebtProvider>(context, listen: false).recordDebtPayment(
      debt: latest ?? widget.debt,
      amount: amt,
      paidAt: _paidAt,
      kind: _kind,
      paymentMethod: _method,
      note: _noteCtrl.text.trim(),
      externalRef: _refCtrl.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment recorded')),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = currencyFormat(context);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHeader(
              title: 'Record payment',
            ),
            Builder(
              builder: (context) {
                final live = context
                    .watch<DebtProvider>()
                    .debtById(widget.debt.id);
                final rem = live?.amount ?? widget.debt.amount;
                return Text(
                  'Remaining ${fmt.format(rem)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Amount paid',
                prefixText: currencyPrefix(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<DebtPaymentKind>(
              segments: const [
                ButtonSegment(
                  value: DebtPaymentKind.installment,
                  label: Text('Monthly installment'),
                  icon: Icon(Icons.calendar_month_rounded, size: 18),
                ),
                ButtonSegment(
                  value: DebtPaymentKind.extra,
                  label: Text('Extra payment'),
                  icon: Icon(Icons.add_circle_outline_rounded, size: 18),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) =>
                  setState(() => _kind = s.first),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_rounded),
              title: const Text('Payment date'),
              subtitle: Text(DateFormat.yMMMMd().format(_paidAt)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickDate,
            ),
            DropdownButtonFormField<String>(
              value: _method,
              decoration: InputDecoration(
                labelText: 'Payment method',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: kDebtPaymentMethods
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _method = v ?? _method),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _refCtrl,
              decoration: InputDecoration(
                labelText: 'Reference / transaction ID (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expense,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Save payment'),
            ),
          ],
        ),
      ),
    );
  }
}
