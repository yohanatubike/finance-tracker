import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/fund.dart';
import '../providers/fund_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_formatting.dart';
import '../widgets/shared_widgets.dart';

class FundsScreen extends StatelessWidget {
  const FundsScreen({super.key});

  void _openForm(BuildContext context, {Fund? fund}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _FundForm(fund: fund),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fundProvider = Provider.of<FundProvider>(context);
    final fmt = currencyFormat(context);

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
                            'MY FUNDS',
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
                            fmt.format(fundProvider.totalFunds),
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
                  '${fundProvider.funds.length} account${fundProvider.funds.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            if (fundProvider.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (fundProvider.funds.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.account_balance_wallet_rounded,
                  message: 'No funds yet',
                  hint: 'Tap the button above to add your first fund',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList.separated(
                  itemCount: fundProvider.funds.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final fund = fundProvider.funds[index];
                    return _FundTile(
                      fund: fund,
                      fmt: fmt,
                      onTap: () => _openForm(context, fund: fund),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FundTile extends StatelessWidget {
  final Fund fund;
  final NumberFormat fmt;
  final VoidCallback onTap;

  const _FundTile({
    required this.fund,
    required this.fmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.incomeLight,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.income,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fund.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      fund.description,
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
                    fmt.format(fund.amount),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.income,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 3),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.hintText,
                    size: 18,
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

class _FundForm extends StatefulWidget {
  final Fund? fund;

  const _FundForm({this.fund});

  @override
  State<_FundForm> createState() => _FundFormState();
}

class _FundFormState extends State<_FundForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.fund?.name ?? '');
    _descCtrl = TextEditingController(text: widget.fund?.description ?? '');
    _amountCtrl = TextEditingController(
      text: widget.fund != null ? widget.fund!.amount.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.fund != null;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = Provider.of<FundProvider>(context, listen: false);
    final fund = Fund(
      id: widget.fund?.id,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text),
    );
    if (_isEditing) {
      provider.updateFund(fund);
    } else {
      provider.addFund(fund);
    }
    Navigator.pop(context);
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmDeleteDialog(
        onConfirm: () {
          Provider.of<FundProvider>(context, listen: false)
              .deleteFund(widget.fund!.id!);
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  title: _isEditing ? 'Edit Fund' : 'Add Fund',
                  onDelete: _isEditing ? _delete : null,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _nameCtrl,
                  label: 'Fund Name',
                  hint: 'e.g. Selcom Wallet',
                  icon: Icons.label_outline_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _descCtrl,
                  label: 'Description',
                  hint: 'Short note about this fund',
                  icon: Icons.notes_rounded,
                  maxLines: 2,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Description is required'
                      : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _amountCtrl,
                  label: 'Balance',
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
                        child: Text(_isEditing ? 'Update' : 'Save Fund'),
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
