import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_formatting.dart';
import '../widgets/shared_widgets.dart';

class AssetsScreen extends StatelessWidget {
  const AssetsScreen({super.key});

  void _openForm(BuildContext context, {Asset? asset}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _AssetForm(asset: asset),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assetProvider = Provider.of<AssetProvider>(context);
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
                            'MY ASSETS',
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
                            fmt.format(assetProvider.totalAssets),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.asset,
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
                  '${assetProvider.assets.length} asset${assetProvider.assets.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            if (assetProvider.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (assetProvider.assets.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.business_center_rounded,
                  message: 'No assets yet',
                  hint: 'Tap the button above to track your first asset',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList.separated(
                  itemCount: assetProvider.assets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final asset = assetProvider.assets[index];
                    return _AssetTile(
                      asset: asset,
                      fmt: fmt,
                      onTap: () => _openForm(context, asset: asset),
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

class _AssetTile extends StatelessWidget {
  final Asset asset;
  final NumberFormat fmt;
  final VoidCallback onTap;

  const _AssetTile({
    required this.asset,
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
                  color: AppColors.assetLight,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.business_center_rounded,
                  color: AppColors.asset,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      asset.description,
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
                    fmt.format(asset.amount),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.asset,
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

class _AssetForm extends StatefulWidget {
  final Asset? asset;

  const _AssetForm({this.asset});

  @override
  State<_AssetForm> createState() => _AssetFormState();
}

class _AssetFormState extends State<_AssetForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.asset?.name ?? '');
    _descCtrl = TextEditingController(text: widget.asset?.description ?? '');
    _amountCtrl = TextEditingController(
      text: widget.asset != null ? widget.asset!.amount.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.asset != null;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = Provider.of<AssetProvider>(context, listen: false);
    final asset = Asset(
      id: widget.asset?.id,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text),
    );
    if (_isEditing) {
      provider.updateAsset(asset);
    } else {
      provider.addAsset(asset);
    }
    Navigator.pop(context);
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmDeleteDialog(
        onConfirm: () {
          Provider.of<AssetProvider>(context, listen: false)
              .deleteAsset(widget.asset!.id!);
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
                  title: _isEditing ? 'Edit Asset' : 'Add Asset',
                  onDelete: _isEditing ? _delete : null,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _nameCtrl,
                  label: 'Asset Name',
                  hint: 'e.g. Land Plot',
                  icon: Icons.label_outline_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _descCtrl,
                  label: 'Description',
                  hint: 'Short note about this asset',
                  icon: Icons.notes_rounded,
                  maxLines: 2,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Description is required'
                      : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _amountCtrl,
                  label: 'Estimated Value',
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
                    if (v == null || v.isEmpty) return 'Value is required';
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.asset,
                        ),
                        child: Text(_isEditing ? 'Update' : 'Save Asset'),
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
