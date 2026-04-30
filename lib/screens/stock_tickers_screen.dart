import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/stock.dart';
import '../providers/stock_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

const Color _stockColor = Color(0xFF0891B2);
const Color _stockLight = Color(0xFFE0F7FA);

class StockTickersScreen extends StatelessWidget {
  const StockTickersScreen({super.key});

  void _openAddForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _AddTickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StockProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Tickers'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AddButton(onTap: () => _openAddForm(context)),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Info Banner ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _stockLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: _stockColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'These tickers appear in the dropdown when adding holdings. Pre-seeded DSE tickers are built-in and cannot be removed.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _stockColor,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── User-added tickers ───────────────────────────────────────
          if (provider.userTickers.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  'MY CUSTOM TICKERS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.2,
                        color: AppColors.secondaryText,
                      ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: provider.userTickers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final t = provider.userTickers[index];
                  return _TickerTile(
                    ticker: t.ticker,
                    name: t.companyName,
                    isCustom: true,
                    onDelete: () => _confirmDelete(context, provider, t.id,
                        t.ticker),
                  );
                },
              ),
            ),
          ],

          // ── Built-in DSE tickers ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'BUILT-IN DSE TICKERS (${dseTickers.length})',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      color: AppColors.secondaryText,
                    ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList.separated(
              itemCount: dseTickers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final t = dseTickers[index];
                return _TickerTile(
                  ticker: t['ticker']!,
                  name: t['name']!,
                  isCustom: false,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Ticker'),
        backgroundColor: _stockColor,
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    StockProvider provider,
    int id,
    String ticker,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Ticker'),
        content: Text(
            'Remove "$ticker" from your custom ticker list? This won\'t affect existing holdings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.removeUserTicker(id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// ── Ticker Tile ──────────────────────────────────────────────────────────────

class _TickerTile extends StatelessWidget {
  final String ticker;
  final String name;
  final bool isCustom;
  final VoidCallback? onDelete;

  const _TickerTile({
    required this.ticker,
    required this.name,
    required this.isCustom,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _stockLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              ticker,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _stockColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isCustom && onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.expense, size: 20),
              onPressed: onDelete,
              tooltip: 'Remove',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            )
          else
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'DSE',
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

// ── Add Ticker Sheet ─────────────────────────────────────────────────────────

class _AddTickerSheet extends StatefulWidget {
  const _AddTickerSheet();

  @override
  State<_AddTickerSheet> createState() => _AddTickerSheetState();
}

class _AddTickerSheetState extends State<_AddTickerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _tickerCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _tickerCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final ticker = _tickerCtrl.text.trim().toUpperCase();
    final name = _nameCtrl.text.trim();

    final provider = Provider.of<StockProvider>(context, listen: false);

    // Check for duplicates
    final allTickers = provider.allTickers;
    if (allTickers.any((t) => t['ticker'] == ticker)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$ticker" already exists in the ticker list'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    provider.addUserTicker(ticker, name);
    Navigator.pop(context);
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
                const SheetHeader(title: 'Add Custom Ticker'),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _tickerCtrl,
                  label: 'Ticker Symbol',
                  hint: 'e.g. XYZ',
                  icon: Icons.show_chart_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ticker symbol is required'
                      : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _nameCtrl,
                  label: 'Company Name',
                  hint: 'e.g. XYZ Corporation',
                  icon: Icons.business_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Company name is required'
                      : null,
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
                          backgroundColor: _stockColor,
                        ),
                        child: const Text('Add Ticker'),
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
