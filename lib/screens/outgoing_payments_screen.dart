import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/outgoing_payment.dart';
import '../providers/outgoing_payment_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/fund_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../utils/app_formatting.dart';

bool _outgoingMatches(OutgoingPayment p, String q) {
  final t = q.trim().toLowerCase();
  if (t.isEmpty) return true;
  return p.name.toLowerCase().contains(t) ||
      p.description.toLowerCase().contains(t);
}

class OutgoingPaymentsScreen extends StatefulWidget {
  const OutgoingPaymentsScreen({super.key});

  @override
  State<OutgoingPaymentsScreen> createState() =>
      _OutgoingPaymentsScreenState();
}

class _OutgoingPaymentsScreenState extends State<OutgoingPaymentsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openForm(BuildContext context, {OutgoingPayment? payment}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _OutgoingPaymentForm(payment: payment),
    );
  }

  void _showFundPicker(
    BuildContext context,
    OutgoingPayment payment,
    OutgoingPaymentProvider paymentProvider,
    FundProvider fundProvider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => FundPickerSheet(
        title: 'Select Source Fund',
        subtitle: 'Which fund should this payment be deducted from?',
        funds: fundProvider.funds,
        initialFundId: payment.sourceFundId,
        confirmLabel: 'Complete Payment',
        confirmColor: AppColors.expense,
        onConfirm: (selectedFundId, ledgerNote, externalRef) {
          final updated = payment.copyWith(
            sourceFundId: selectedFundId,
            ledgerNote: ledgerNote,
            externalRef: externalRef,
          );
          paymentProvider.toggleCompletion(updated);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = Provider.of<OutgoingPaymentProvider>(context);
    final fundProvider = Provider.of<FundProvider>(context);
    final fmt = currencyFormat(context);

    final pendingRaw = paymentProvider.pendingPayments;
    final completedRaw =
        paymentProvider.payments.where((p) => p.isCompleted).toList();
    final q = _searchCtrl.text;
    final pending =
        pendingRaw.where((p) => _outgoingMatches(p, q)).toList();
    final completed =
        completedRaw.where((p) => _outgoingMatches(p, q)).toList();
    final noMatches = paymentProvider.payments.isNotEmpty &&
        q.trim().isNotEmpty &&
        pending.isEmpty &&
        completed.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
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
                            'OUTGOING',
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
                            fmt.format(paymentProvider.totalPending),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.expense,
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                child: Text(
                  '${pending.length} pending · ${completed.length} paid',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            if (!paymentProvider.isLoading &&
                paymentProvider.payments.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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
            if (paymentProvider.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (paymentProvider.payments.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.north_rounded,
                  message: 'No outgoing payments',
                  hint: 'Tap the button above to track expected expenses',
                ),
              )
            else if (noMatches)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No payments match your search',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.secondaryText,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else ...[
              if (pending.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PENDING',
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
                          'Soonest deadlines first · set date & time when editing',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.secondaryText,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: pending.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final payment = pending[index];
                      final fund =
                          fundProvider.getFundById(payment.sourceFundId);
                      return _OutgoingTile(
                        payment: payment,
                        fundName: fund?.name,
                        fmt: fmt,
                        emphasizeDeadline: true,
                        onTap: () => _openForm(context, payment: payment),
                        onToggle: () => _showFundPicker(
                          context,
                          payment,
                          paymentProvider,
                          fundProvider,
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (completed.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Text(
                      'PAID',
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
                    itemCount: completed.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final payment = completed[index];
                      final fund =
                          fundProvider.getFundById(payment.sourceFundId);
                      return _OutgoingTile(
                        payment: payment,
                        fundName: fund?.name,
                        fmt: fmt,
                        emphasizeDeadline: false,
                        onTap: () => _openForm(context, payment: payment),
                        onToggle: () =>
                            paymentProvider.toggleCompletion(payment),
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

class _OutgoingTile extends StatelessWidget {
  final OutgoingPayment payment;
  final String? fundName;
  final NumberFormat fmt;
  final bool emphasizeDeadline;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _OutgoingTile({
    required this.payment,
    required this.fundName,
    required this.fmt,
    this.emphasizeDeadline = false,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = payment.isCompleted;
    final dl = payment.deadlineAt;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isDone
                  ? AppColors.divider
                  : AppColors.expense.withValues(alpha: 0.25),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDone ? AppColors.expense : AppColors.expenseLight,
                    borderRadius: BorderRadius.circular(12),
                    border: isDone
                        ? null
                        : Border.all(
                            color: AppColors.expense.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                  ),
                  child: Icon(
                    isDone ? Icons.check_rounded : Icons.north_rounded,
                    color: isDone ? Colors.white : AppColors.expense,
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
                      payment.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            decoration:
                                isDone ? TextDecoration.lineThrough : null,
                            color: isDone
                                ? AppColors.secondaryText
                                : AppColors.primaryText,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            payment.description,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (fundName != null) ...[
                          Text(
                            ' · ',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.hintText,
                                ),
                          ),
                          Flexible(
                            child: Text(
                              fundName!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.expense,
                                    fontWeight: FontWeight.w500,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (dl != null) ...[
                      const SizedBox(height: 8),
                      _DeadlineRow(
                        deadline: dl,
                        isPaid: isDone,
                        emphasize: emphasizeDeadline,
                      ),
                    ],
                    if (isDone &&
                        (payment.ledgerNote.isNotEmpty ||
                            payment.externalRef.isNotEmpty)) ...[
                      const SizedBox(height: 8),
                      if (payment.ledgerNote.isNotEmpty)
                        Text(
                          payment.ledgerNote,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.secondaryText,
                                    fontStyle: FontStyle.italic,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (payment.externalRef.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Ref: ${payment.externalRef}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: AppColors.secondaryText),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                fmt.format(payment.amount),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: isDone ? AppColors.secondaryText : AppColors.expense,
                      fontWeight: FontWeight.w700,
                      decoration:
                          isDone ? TextDecoration.lineThrough : null,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeadlineRow extends StatelessWidget {
  final DateTime deadline;
  final bool isPaid;
  final bool emphasize;

  const _DeadlineRow({
    required this.deadline,
    required this.isPaid,
    required this.emphasize,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formatted = formatAppDateTime(deadline, context);

    Color accent;
    String line;
    if (isPaid) {
      accent = AppColors.secondaryText;
      line = 'Was due $formatted';
    } else if (deadline.isBefore(now)) {
      accent = AppColors.expense;
      line = 'Overdue · $formatted';
    } else if (DateUtils.isSameDay(deadline, now)) {
      accent = AppColors.pending;
      final use24 =
          context.watch<ProfileProvider>().profile.use24HourTime;
      final timeOnly =
          use24 ? DateFormat.Hm().format(deadline) : DateFormat.jm().format(deadline);
      line = 'Due today · $timeOnly';
    } else {
      accent =
          emphasize ? AppColors.primaryText : AppColors.secondaryText;
      line = 'Due $formatted';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 16,
          color: accent,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            line,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: accent,
                  fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
                  height: 1.25,
                ),
          ),
        ),
      ],
    );
  }
}

class _OutgoingPaymentForm extends StatefulWidget {
  final OutgoingPayment? payment;

  const _OutgoingPaymentForm({this.payment});

  @override
  State<_OutgoingPaymentForm> createState() => _OutgoingPaymentFormState();
}

class _OutgoingPaymentFormState extends State<_OutgoingPaymentForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;
  int? _selectedFundId;
  DateTime? _deadlineAt;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.payment?.name ?? '');
    _descCtrl =
        TextEditingController(text: widget.payment?.description ?? '');
    _amountCtrl = TextEditingController(
      text: widget.payment != null
          ? widget.payment!.amount.toStringAsFixed(0)
          : '',
    );
    _selectedFundId = widget.payment?.sourceFundId;
    _deadlineAt = widget.payment?.deadlineAt;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.payment != null;

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final base = _deadlineAt ?? now;
    final d = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadlineAt ?? DateTime(now.year, now.month, now.day, 17)),
    );
    if (t == null || !mounted) return;
    setState(() {
      _deadlineAt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  void _clearDeadline() => setState(() => _deadlineAt = null);

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider =
        Provider.of<OutgoingPaymentProvider>(context, listen: false);
    final payment = OutgoingPayment(
      id: widget.payment?.id,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text),
      sourceFundId: _selectedFundId!,
      isCompleted: widget.payment?.isCompleted ?? false,
      deadlineAt: _deadlineAt,
    );
    if (_isEditing) {
      provider.updatePayment(payment);
    } else {
      provider.addPayment(payment);
    }
    Navigator.pop(context);
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmDeleteDialog(
        onConfirm: () {
          Provider.of<OutgoingPaymentProvider>(context, listen: false)
              .deletePayment(widget.payment!.id!);
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fundProvider = Provider.of<FundProvider>(context);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SheetHeader(
                  title: _isEditing ? 'Edit Outgoing' : 'Add Outgoing',
                  onDelete: _isEditing ? _delete : null,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _nameCtrl,
                  label: 'Payment Name',
                  hint: 'e.g. Rent',
                  icon: Icons.label_outline_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _descCtrl,
                  label: 'Description',
                  hint: 'Short note about this expense',
                  icon: Icons.notes_rounded,
                  maxLines: 2,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Description is required'
                      : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _amountCtrl,
                  label: 'Amount',
                  hint: '0',
                  icon: Icons.attach_money_rounded,
                  prefix: currencyPrefix(context),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Amount is required';
                    if (double.tryParse(v) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'Deadline',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Optional · pending items sort by soonest deadline',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_rounded),
                  title: Text(
                    _deadlineAt == null
                        ? 'No deadline'
                        : formatAppDateTime(_deadlineAt!, context),
                  ),
                  subtitle: Text(
                    _deadlineAt == null
                        ? 'Tap to choose date & time'
                        : 'Tap to change',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onTap: _pickDeadline,
                ),
                if (_deadlineAt != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _clearDeadline,
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      label: const Text('Clear deadline'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.secondaryText,
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  value: _selectedFundId,
                  decoration: const InputDecoration(
                    labelText: 'Source Fund',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined,
                        size: 20, color: AppColors.secondaryText),
                  ),
                  items: fundProvider.funds
                      .map((f) =>
                          DropdownMenuItem(value: f.id, child: Text(f.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedFundId = v),
                  validator: (v) =>
                      v == null ? 'Select a source fund' : null,
                ),
                if (fundProvider.funds.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Please add a fund first',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.expense),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: fundProvider.funds.isEmpty ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.expense,
                        ),
                        child: Text(_isEditing ? 'Update' : 'Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
