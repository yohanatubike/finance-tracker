import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../navigation_service.dart';

class DrawerMenuButton extends StatelessWidget {
  const DrawerMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: NavigationService.openDrawer,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.menu_rounded,
          color: AppColors.primaryText,
          size: 20,
        ),
      ),
    );
  }
}

class AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const AddButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.brand,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 4),
            Text(
              'Add',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String hint;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: AppColors.hintText, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.primaryText),
            ),
            const SizedBox(height: 6),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class SheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onDelete;

  const SheetHeader({super.key, required this.title, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (onDelete != null)
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.expense,
            tooltip: 'Delete',
          ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
          color: AppColors.secondaryText,
        ),
      ],
    );
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final String? prefix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.prefix,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        prefixIcon: Icon(icon, size: 20, color: AppColors.secondaryText),
      ),
    );
  }
}

class ConfirmDeleteDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const ConfirmDeleteDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Item'),
      content: const Text(
          'This action cannot be undone. Are you sure you want to delete this item?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.expense,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

class FundPickerSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<dynamic> funds;
  final int? initialFundId;
  final String confirmLabel;
  final Color confirmColor;
  final void Function(int fundId, String ledgerNote, String externalRef)
      onConfirm;

  const FundPickerSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.funds,
    required this.initialFundId,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onConfirm,
  });

  @override
  State<FundPickerSheet> createState() => _FundPickerSheetState();
}

class _FundPickerSheetState extends State<FundPickerSheet> {
  int? _selectedId;
  late final TextEditingController _ledgerCtrl;
  late final TextEditingController _refCtrl;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialFundId;
    _ledgerCtrl = TextEditingController();
    _refCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _ledgerCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: 40 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: widget.title),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            ...widget.funds.map((fund) {
              final isSelected = _selectedId == fund.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedId = fund.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? widget.confirmColor.withValues(alpha: 0.08)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? widget.confirmColor
                          : AppColors.divider,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          fund.name as String,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: isSelected
                                    ? widget.confirmColor
                                    : AppColors.primaryText,
                              ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded,
                            color: widget.confirmColor, size: 20),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            Text(
              'Ledger note (optional)',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _ledgerCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. Salary March, invoice match',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Reference / transaction ID (optional)',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _refCtrl,
              decoration: InputDecoration(
                hintText: 'Bank ref, receipt #, txn id…',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _selectedId != null
                  ? () => widget.onConfirm(
                        _selectedId!,
                        _ledgerCtrl.text.trim(),
                        _refCtrl.text.trim(),
                      )
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.confirmColor,
              ),
              child: Text(widget.confirmLabel),
            ),
          ],
        ),
      ),
    );
  }
}
