import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/debt.dart';
import '../providers/debt_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_formatting.dart';
import 'shared_widgets.dart';

const List<String> kDebtPaymentMethods = [
  'Cash',
  'Bank transfer',
  'Mobile money',
  'Card',
  'Other',
];

class DebtFormSheet extends StatefulWidget {
  final Debt? debt;

  const DebtFormSheet({super.key, this.debt});

  @override
  State<DebtFormSheet> createState() => _DebtFormSheetState();
}

class _DebtFormSheetState extends State<DebtFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _monthlyCtrl;
  late bool _isOwedByMe;
  late bool _trackLoan;
  DateTime? _loanStart;
  String _paymentMethod = 'Bank transfer';

  @override
  void initState() {
    super.initState();
    final d = widget.debt;
    _nameCtrl = TextEditingController(text: d?.personName ?? '');
    _descCtrl = TextEditingController(text: d?.description ?? '');
    _amountCtrl = TextEditingController(
      text: d != null ? d.amount.toStringAsFixed(0) : '',
    );
    _monthlyCtrl = TextEditingController(
      text: d?.monthlyInstallment != null && d!.monthlyInstallment! > 0
          ? d.monthlyInstallment!.toStringAsFixed(0)
          : '',
    );
    _isOwedByMe = d?.isOwedByMe ?? true;
    _trackLoan = d?.hasInstallmentSchedule ?? false;
    _loanStart = d?.loanStartDate;
    if (d?.defaultPaymentMethod.isNotEmpty == true) {
      _paymentMethod = d!.defaultPaymentMethod;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _monthlyCtrl.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.debt != null;

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final initial = _loanStart ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) setState(() => _loanStart = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final loan = _isOwedByMe && _trackLoan;
    if (loan) {
      final m = double.tryParse(_monthlyCtrl.text.trim());
      if (m == null || m <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid monthly installment')),
        );
        return;
      }
      if (_loanStart == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose the loan start date')),
        );
        return;
      }
    }

    final amt = double.parse(_amountCtrl.text.trim());
    final provider = Provider.of<DebtProvider>(context, listen: false);

    double? monthly;
    DateTime? start;
    String method = '';
    double origPrincipal = 0;

    if (loan) {
      monthly = double.parse(_monthlyCtrl.text.trim());
      start = _loanStart;
      method = _paymentMethod;
      origPrincipal = widget.debt?.originalPrincipal ?? amt;
    }

    final debt = Debt(
      id: widget.debt?.id,
      personName: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      amount: amt,
      isOwedByMe: _isOwedByMe,
      isPaid: widget.debt?.isPaid ?? false,
      monthlyInstallment: monthly,
      loanStartDate: start,
      defaultPaymentMethod: method,
      hasInstallmentSchedule: loan,
      originalPrincipal: origPrincipal,
    );

    if (_isEditing) {
      provider.updateDebt(debt);
    } else {
      provider.addDebt(debt);
    }
    Navigator.pop(context);
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmDeleteDialog(
        onConfirm: () {
          Provider.of<DebtProvider>(context, listen: false)
              .deleteDebt(widget.debt!.id!);
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd();

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
                  title: _isEditing ? 'Edit Debt' : 'Add Debt',
                  onDelete: _isEditing ? _delete : null,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      _TypeOption(
                        label: 'I Owe',
                        sublabel: 'Money I borrowed',
                        icon: Icons.north_rounded,
                        color: AppColors.expense,
                        isSelected: _isOwedByMe,
                        onTap: () => setState(() => _isOwedByMe = true),
                      ),
                      const SizedBox(width: 4),
                      _TypeOption(
                        label: 'They Owe Me',
                        sublabel: 'Money I lent',
                        icon: Icons.south_rounded,
                        color: AppColors.pending,
                        isSelected: !_isOwedByMe,
                        onTap: () => setState(() {
                          _isOwedByMe = false;
                          _trackLoan = false;
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _nameCtrl,
                  label: 'Person / Institution',
                  hint: 'e.g. John Msigwa',
                  icon: Icons.person_outline_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _descCtrl,
                  label: 'Description',
                  hint: 'What is this debt for?',
                  icon: Icons.notes_rounded,
                  maxLines: 2,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Description is required'
                      : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _amountCtrl,
                  label: _isOwedByMe
                      ? 'Amount you still owe'
                      : 'Amount they owe you',
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
                if (_isOwedByMe) ...[
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Loan with monthly installments'),
                    subtitle: Text(
                      'Track payment schedule, methods, and extra payments',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    value: _trackLoan,
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.expense;
                      }
                      return null;
                    }),
                    onChanged: (v) => setState(() => _trackLoan = v),
                  ),
                  if (_trackLoan) ...[
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _monthlyCtrl,
                      label: 'Monthly installment',
                      hint: '0',
                      icon: Icons.calendar_view_month_rounded,
                      prefix: currencyPrefix(context),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (v) {
                        if (!_trackLoan) return null;
                        if (v == null || v.trim().isEmpty) {
                          return 'Required for installment loan';
                        }
                        final n = double.tryParse(v.trim());
                        if (n == null || n <= 0) return 'Enter a positive amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.event_outlined,
                          color: AppColors.secondaryText, size: 22),
                      title: const Text('Loan start date'),
                      subtitle: Text(
                        _loanStart != null
                            ? fmt.format(_loanStart!)
                            : 'First payment is one month after this',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _pickStartDate,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.divider),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: InputDecoration(
                        labelText: 'Default payment method',
                        prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: kDebtPaymentMethods
                          .map((e) =>
                              DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _paymentMethod = v ?? 'Cash'),
                    ),
                  ],
                ],
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
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isOwedByMe
                              ? AppColors.expense
                              : AppColors.pending,
                        ),
                        child: Text(_isEditing ? 'Update' : 'Save Debt'),
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

class _TypeOption extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: color, width: 1.5)
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: isSelected ? color : AppColors.secondaryText,
                  size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? color : AppColors.primaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      sublabel,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
