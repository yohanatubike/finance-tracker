import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/incoming_payment.dart';
import '../providers/incoming_payment_provider.dart';
import '../providers/fund_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../utils/app_formatting.dart';

bool _incomingMatches(IncomingPayment p, String q) {
  final t = q.trim().toLowerCase();
  if (t.isEmpty) return true;
  return p.name.toLowerCase().contains(t) ||
      p.description.toLowerCase().contains(t);
}

class IncomingPaymentsScreen extends StatefulWidget {
  const IncomingPaymentsScreen({super.key});

  @override
  State<IncomingPaymentsScreen> createState() =>
      _IncomingPaymentsScreenState();
}

class _IncomingPaymentsScreenState extends State<IncomingPaymentsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openForm(BuildContext context, {IncomingPayment? payment}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _IncomingPaymentForm(payment: payment),
    );
  }

  void _showFundPicker(
    BuildContext context,
    IncomingPayment payment,
    IncomingPaymentProvider paymentProvider,
    FundProvider fundProvider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => FundPickerSheet(
        title: 'Select Target Fund',
        subtitle: 'Which fund should receive this payment?',
        funds: fundProvider.funds,
        initialFundId: payment.targetFundId,
        confirmLabel: 'Complete Payment',
        confirmColor: AppColors.income,
        onConfirm: (selectedFundId, ledgerNote, externalRef) {
          final updated = payment.copyWith(
            targetFundId: selectedFundId,
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
    final paymentProvider = Provider.of<IncomingPaymentProvider>(context);
    final fundProvider = Provider.of<FundProvider>(context);
    final fmt = currencyFormat(context);

    final pendingRaw = paymentProvider.pendingPayments;
    final completedRaw =
        paymentProvider.payments.where((p) => p.isCompleted).toList();
    final q = _searchCtrl.text;
    final pending =
        pendingRaw.where((p) => _incomingMatches(p, q)).toList();
    final completed =
        completedRaw.where((p) => _incomingMatches(p, q)).toList();
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
                            'INCOMING',
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
                                  color: AppColors.income,
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
                  '${pending.length} pending · ${completed.length} received',
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
                  icon: Icons.south_rounded,
                  message: 'No incoming payments',
                  hint: 'Tap the button above to track expected payments',
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
                    child: Text(
                      'PENDING',
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: pending.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final payment = pending[index];
                      final fund =
                          fundProvider.getFundById(payment.targetFundId);
                      return _PaymentTile(
                        payment: payment,
                        fundName: fund?.name,
                        fmt: fmt,
                        accentColor: AppColors.income,
                        accentLight: AppColors.incomeLight,
                        directionIcon: Icons.south_rounded,
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
                      'RECEIVED',
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
                          fundProvider.getFundById(payment.targetFundId);
                      return _PaymentTile(
                        payment: payment,
                        fundName: fund?.name,
                        fmt: fmt,
                        accentColor: AppColors.income,
                        accentLight: AppColors.incomeLight,
                        directionIcon: Icons.south_rounded,
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

class _PaymentTile extends StatelessWidget {
  final IncomingPayment payment;
  final String? fundName;
  final NumberFormat fmt;
  final Color accentColor;
  final Color accentLight;
  final IconData directionIcon;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _PaymentTile({
    required this.payment,
    required this.fundName,
    required this.fmt,
    required this.accentColor,
    required this.accentLight,
    required this.directionIcon,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = payment.isCompleted;

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
                  : accentColor.withValues(alpha: 0.25),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDone ? accentColor : accentLight,
                    borderRadius: BorderRadius.circular(12),
                    border: isDone
                        ? null
                        : Border.all(
                            color: accentColor.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                  ),
                  child: Icon(
                    isDone ? Icons.check_rounded : directionIcon,
                    color: isDone ? Colors.white : accentColor,
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
                                    color: accentColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
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
                      color: isDone ? AppColors.secondaryText : accentColor,
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

class _IncomingPaymentForm extends StatefulWidget {
  final IncomingPayment? payment;

  const _IncomingPaymentForm({this.payment});

  @override
  State<_IncomingPaymentForm> createState() => _IncomingPaymentFormState();
}

class _IncomingPaymentFormState extends State<_IncomingPaymentForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;
  int? _selectedFundId;

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
    _selectedFundId = widget.payment?.targetFundId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.payment != null;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider =
        Provider.of<IncomingPaymentProvider>(context, listen: false);
    final payment = IncomingPayment(
      id: widget.payment?.id,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text),
      targetFundId: _selectedFundId!,
      isCompleted: widget.payment?.isCompleted ?? false,
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
          Provider.of<IncomingPaymentProvider>(context, listen: false)
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
                  title: _isEditing ? 'Edit Incoming' : 'Add Incoming',
                  onDelete: _isEditing ? _delete : null,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _nameCtrl,
                  label: 'Payment Name',
                  hint: 'e.g. Salary',
                  icon: Icons.label_outline_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _descCtrl,
                  label: 'Description',
                  hint: 'Short note about this payment',
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
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  value: _selectedFundId,
                  decoration: const InputDecoration(
                    labelText: 'Target Fund',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined,
                        size: 20, color: AppColors.secondaryText),
                  ),
                  items: fundProvider.funds
                      .map((f) =>
                          DropdownMenuItem(value: f.id, child: Text(f.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedFundId = v),
                  validator: (v) =>
                      v == null ? 'Select a target fund' : null,
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
                          backgroundColor: AppColors.income,
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
