import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/stock.dart';
import '../providers/stock_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_formatting.dart';
import '../widgets/shared_widgets.dart';
import 'stock_portfolio_summary_screen.dart';
import 'stock_prices_screen.dart';

// Stock-specific accent colour (teal)
const Color _stockColor = Color(0xFF0891B2);
const Color _stockLight = Color(0xFFE0F7FA);

class StocksScreen extends StatefulWidget {
  const StocksScreen({super.key});

  @override
  State<StocksScreen> createState() => _StocksScreenState();
}

class _StocksScreenState extends State<StocksScreen> {
  /// 0 = holdings, 1 = watchlist
  int _segment = 0;

  void _openAddForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _StockForm(addAsWatchlist: _segment == 1),
    );
  }

  void _openUpdatePrices(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StockPricesScreen()),
    );
  }

  void _openInvestmentSummary(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StockPortfolioSummaryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StockProvider>(context);
    final fmt = currencyFormat(context);
    final holdings = provider.holdings;
    final watch = provider.watchlist;
    final list = _segment == 0 ? holdings : watch;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────
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
                            'STOCK PORTFOLIO',
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
                            fmt.format(provider.totalPortfolioValue),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _stockColor,
                                ),
                          ),
                          if (holdings.isNotEmpty) ...[
                            TextButton.icon(
                              onPressed: () =>
                                  _openInvestmentSummary(context),
                              icon: Icon(Icons.insights_outlined,
                                  size: 17, color: _stockColor),
                              label: Text(
                                'Investment summary',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: _stockColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.only(top: 2, bottom: 0),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Update Prices button
                    if (provider.stocks.isNotEmpty)
                      GestureDetector(
                        onTap: () => _openUpdatePrices(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: _stockColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.price_change_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                'Prices',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    AddButton(onTap: () => _openAddForm(context)),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment<int>(
                      value: 0,
                      label: Text('Holdings'),
                      icon: Icon(Icons.account_balance_wallet_outlined, size: 18),
                    ),
                    ButtonSegment<int>(
                      value: 1,
                      label: Text('Watchlist'),
                      icon: Icon(Icons.visibility_outlined, size: 18),
                    ),
                  ],
                  selected: {_segment},
                  onSelectionChanged: (Set<int> s) {
                    final v = s.first;
                    setState(() => _segment = v);
                  },
                ),
              ),
            ),

            // ── Summary cards ────────────────────────────────────────────
            if (holdings.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _SummaryRow(provider: provider, fmt: fmt),
                ),
              ),

            // ── Section label ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Text(
                  _segment == 0
                      ? '${holdings.length} holding${holdings.length == 1 ? '' : 's'}'
                      : '${watch.length} on watchlist',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),

            // ── List ─────────────────────────────────────────────────────
            if (provider.isLoading)
              const SliverFillRemaining(
                child:
                    Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (list.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.show_chart_rounded,
                  message: _segment == 0
                      ? 'No holdings yet'
                      : 'Watchlist is empty',
                  hint: _segment == 0
                      ? 'Tap Add Holding to record your first position'
                      : 'Track prices without entering shares — tap Add to watchlist',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final stock = list[index];
                    return stock.isWatchlist
                        ? _WatchlistTile(
                            stock: stock,
                            fmt: fmt,
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) => _StockForm(
                                  stock: stock,
                                  addAsWatchlist: true,
                                ),
                              );
                            },
                          )
                        : _StockTile(
                            stock: stock,
                            fmt: fmt,
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) => _StockForm(
                                  stock: stock,
                                  addAsWatchlist: false,
                                ),
                              );
                            },
                          );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddForm(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(_segment == 0 ? 'Add holding' : 'Add to watchlist'),
        backgroundColor: _stockColor,
      ),
    );
  }
}

// ── Summary Row ──────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final StockProvider provider;
  final NumberFormat fmt;

  const _SummaryRow({required this.provider, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final isPositive = provider.totalGainLoss >= 0;
    final pnlColor =
        isPositive ? AppColors.income : AppColors.expense;
    final pnlBg = isPositive ? AppColors.incomeLight : AppColors.expenseLight;
    final pnlSign = isPositive ? '+' : '';

    return Row(
      children: [
        Expanded(
          child: _MiniCard(
            label: 'Cost Basis',
            value: fmt.format(provider.totalCostBasis),
            valueColor: AppColors.secondaryText,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniCard(
            label: 'P&L',
            value:
                '$pnlSign${fmt.format(provider.totalGainLoss)} ($pnlSign${provider.totalGainLossPercent.toStringAsFixed(1)}%)',
            valueColor: pnlColor,
            bgColor: pnlBg,
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final Color? bgColor;

  const _MiniCard({
    required this.label,
    required this.value,
    required this.valueColor,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w700,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Watchlist Tile ───────────────────────────────────────────────────────────

class _WatchlistTile extends StatelessWidget {
  final Stock stock;
  final NumberFormat fmt;
  final VoidCallback onTap;

  const _WatchlistTile({
    required this.stock,
    required this.fmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPrice = stock.currentPrice > 0;

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _stockLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  stock.ticker,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: _stockColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.companyName,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Watchlist · price only',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.secondaryText,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                hasPrice ? fmt.format(stock.currentPrice) : '—',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color:
                          hasPrice ? _stockColor : AppColors.secondaryText,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stock Tile ───────────────────────────────────────────────────────────────

class _StockTile extends StatelessWidget {
  final Stock stock;
  final NumberFormat fmt;
  final VoidCallback onTap;

  const _StockTile({
    required this.stock,
    required this.fmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasCurrentPrice = stock.currentPrice > 0;
    final isPositive = stock.gainLoss >= 0;
    final pnlColor =
        !hasCurrentPrice ? AppColors.secondaryText : (isPositive ? AppColors.income : AppColors.expense);
    final pnlBg = !hasCurrentPrice
        ? AppColors.surfaceVariant
        : (isPositive ? AppColors.incomeLight : AppColors.expenseLight);
    final pnlSign = isPositive ? '+' : '';

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Ticker badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _stockLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      stock.ticker,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: _stockColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stock.companyName,
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${stock.shares} shares',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  // P&L chip
                  if (hasCurrentPrice)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: pnlBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$pnlSign${stock.gainLossPercent.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: pnlColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'No price',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.secondaryText,
                            ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  _PriceCol(
                    context: context,
                    label: 'Buy Price',
                    value: fmt.format(stock.buyPrice),
                  ),
                  _PriceCol(
                    context: context,
                    label: 'Current Price',
                    value: hasCurrentPrice
                        ? fmt.format(stock.currentPrice)
                        : '—',
                    valueColor: hasCurrentPrice ? pnlColor : AppColors.hintText,
                  ),
                  _PriceCol(
                    context: context,
                    label: 'Total P&L',
                    value: hasCurrentPrice
                        ? '$pnlSign${fmt.format(stock.gainLoss)}'
                        : '—',
                    valueColor: hasCurrentPrice ? pnlColor : AppColors.hintText,
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

class _PriceCol extends StatelessWidget {
  final BuildContext context;
  final String label;
  final String value;
  final Color? valueColor;

  const _PriceCol({
    required this.context,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.primaryText,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Add / Edit Stock Form ────────────────────────────────────────────────────

class _StockForm extends StatefulWidget {
  final Stock? stock;
  final bool addAsWatchlist;

  const _StockForm({this.stock, this.addAsWatchlist = false});

  @override
  State<_StockForm> createState() => _StockFormState();
}

class _StockFormState extends State<_StockForm> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedTicker;
  String? _selectedName;
  bool _useCustomTicker = false;
  late bool _watchlistOnly;

  late final TextEditingController _customTickerCtrl;
  late final TextEditingController _customNameCtrl;
  late final TextEditingController _sharesCtrl;
  late final TextEditingController _buyPriceCtrl;

  @override
  void initState() {
    super.initState();
    _watchlistOnly = widget.stock?.isWatchlist ?? widget.addAsWatchlist;
    final s = widget.stock;
    _customTickerCtrl = TextEditingController(text: s?.ticker ?? '');
    _customNameCtrl = TextEditingController(text: s?.companyName ?? '');
    _sharesCtrl = TextEditingController(
      text: s != null ? s.shares.toString() : (_watchlistOnly ? '0' : ''),
    );
    _buyPriceCtrl = TextEditingController(
      text: s != null
          ? s.buyPrice.toStringAsFixed(0)
          : (_watchlistOnly ? '0' : ''),
    );

    if (s != null) {
      // Check if it's in the combined ticker list
      final provider =
          Provider.of<StockProvider>(context, listen: false);
      final known =
          provider.allTickers.any((t) => t['ticker'] == s.ticker);
      if (known) {
        _selectedTicker = s.ticker;
        _selectedName = s.companyName;
      } else {
        _useCustomTicker = true;
        _customTickerCtrl.text = s.ticker;
        _customNameCtrl.text = s.companyName;
      }
    }
  }

  @override
  void dispose() {
    _customTickerCtrl.dispose();
    _customNameCtrl.dispose();
    _sharesCtrl.dispose();
    _buyPriceCtrl.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.stock != null;

  String get _resolvedTicker => _useCustomTicker
      ? _customTickerCtrl.text.trim().toUpperCase()
      : (_selectedTicker ?? '');

  String get _resolvedName => _useCustomTicker
      ? _customNameCtrl.text.trim()
      : (_selectedName ?? '');

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_resolvedTicker.isEmpty) return;

    final provider = Provider.of<StockProvider>(context, listen: false);
    final wl = _watchlistOnly;
    final stock = Stock(
      id: widget.stock?.id,
      ticker: _resolvedTicker,
      companyName: _resolvedName,
      shares: wl ? 0 : int.parse(_sharesCtrl.text),
      buyPrice: wl ? 0 : double.parse(_buyPriceCtrl.text),
      currentPrice: widget.stock?.currentPrice ?? 0,
      isWatchlist: wl,
    );

    if (_isEditing) {
      provider.updateStock(stock);
    } else {
      provider.addStock(stock);
    }
    Navigator.pop(context);
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmDeleteDialog(
        onConfirm: () {
          Provider.of<StockProvider>(context, listen: false)
              .deleteStock(widget.stock!.id!);
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
                  title: _isEditing
                      ? (widget.stock!.isWatchlist
                          ? 'Edit watchlist'
                          : 'Edit Holding')
                      : (_watchlistOnly ? 'Add to watchlist' : 'Add Holding'),
                  onDelete: _isEditing ? _delete : null,
                ),
                const SizedBox(height: 20),
                if (!_isEditing) ...[
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Holding'),
                        icon: Icon(Icons.stacked_line_chart_rounded, size: 18),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Watchlist'),
                        icon: Icon(Icons.visibility_outlined, size: 18),
                      ),
                    ],
                    selected: {_watchlistOnly},
                    onSelectionChanged: (Set<bool> sel) {
                      setState(() {
                        _watchlistOnly = sel.first;
                        if (_watchlistOnly) {
                          _sharesCtrl.text = '0';
                          _buyPriceCtrl.text = '0';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                if (_watchlistOnly)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      'Follow a ticker and update its price without recording shares or cost.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.secondaryText,
                          ),
                    ),
                  ),

                // ── Ticker selector ──────────────────────────────────
                if (!_useCustomTicker) ...[
                  Consumer<StockProvider>(
                    builder: (context, stockProvider, _) {
                      final tickers = stockProvider.allTickers;
                      return DropdownButtonFormField<String>(
                        value: _selectedTicker,
                        decoration: InputDecoration(
                          labelText: 'Select Stock',
                          prefixIcon: const Icon(Icons.show_chart_rounded,
                              size: 20, color: AppColors.secondaryText),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.divider),
                          ),
                        ),
                        isExpanded: true,
                        hint: const Text('Select a stock'),
                        items: tickers
                            .map((t) => DropdownMenuItem<String>(
                                  value: t['ticker'],
                                  child:
                                      Text('${t['ticker']} — ${t['name']}'),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() {
                            _selectedTicker = val;
                            _selectedName = tickers.firstWhere(
                                (t) => t['ticker'] == val)['name'];
                          });
                        },
                        validator: (_) => _selectedTicker == null
                            ? 'Please select a stock'
                            : null,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          setState(() => _useCustomTicker = true),
                      child: const Text('Enter custom ticker instead'),
                    ),
                  ),
                ] else ...[
                  AppTextField(
                    controller: _customTickerCtrl,
                    label: 'Ticker Symbol',
                    hint: 'e.g. XYZ',
                    icon: Icons.show_chart_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Ticker is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _customNameCtrl,
                    label: 'Company Name',
                    hint: 'e.g. XYZ Corporation',
                    icon: Icons.business_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Company name is required'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          setState(() => _useCustomTicker = false),
                      child: const Text('Pick from DSE list instead'),
                    ),
                  ),
                ],

                const SizedBox(height: 6),

                if (!_watchlistOnly) ...[
                  AppTextField(
                    controller: _sharesCtrl,
                    label: 'Number of Shares',
                    hint: '0',
                    icon: Icons.confirmation_number_rounded,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Shares required';
                      if (int.tryParse(v) == null || int.parse(v) <= 0) {
                        return 'Enter a valid number of shares';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _buyPriceCtrl,
                    label: 'Buy Price per Share',
                    hint: '0',
                    icon: Icons.price_check_rounded,
                    prefix: currencyPrefix(context),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Buy price required';
                      if (double.tryParse(v) == null) {
                        return 'Enter a valid price';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                ] else
                  const SizedBox(height: 8),
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
                        child: Text(_isEditing ? 'Update' : 'Save Holding'),
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

