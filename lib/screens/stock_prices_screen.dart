import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/stock.dart';
import '../providers/stock_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_formatting.dart';

const Color _stockColor = Color(0xFF0891B2);
const Color _stockLight = Color(0xFFE0F7FA);

/// One row per ticker — editing price applies to every holding with that ticker.
class _TickerPriceRow {
  final String ticker;
  final String companyName;
  final int totalShares;
  final int lotCount;
  final double currentPrice;

  const _TickerPriceRow({
    required this.ticker,
    required this.companyName,
    required this.totalShares,
    required this.lotCount,
    required this.currentPrice,
  });
}

class StockPricesScreen extends StatefulWidget {
  const StockPricesScreen({super.key});

  @override
  State<StockPricesScreen> createState() => _StockPricesScreenState();
}

class _StockPricesScreenState extends State<StockPricesScreen> {
  late final Map<String, TextEditingController> _controllers;
  late final List<_TickerPriceRow> _entries;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final stocks =
        Provider.of<StockProvider>(context, listen: false).stocks;
    final Map<String, List<Stock>> byTicker = {};
    for (final s in stocks) {
      final k = s.ticker.toUpperCase();
      byTicker.putIfAbsent(k, () => []).add(s);
    }
    _entries = byTicker.entries.map((e) {
      final list = e.value;
      final totalShares = list.fold<int>(0, (a, b) => a + b.shares);
      return _TickerPriceRow(
        ticker: e.key,
        companyName: list.first.companyName,
        totalShares: totalShares,
        lotCount: list.length,
        currentPrice: list.first.currentPrice,
      );
    }).toList()
      ..sort((a, b) => a.ticker.compareTo(b.ticker));
    _controllers = {
      for (final row in _entries)
        row.ticker: TextEditingController(
          text: row.currentPrice > 0
              ? row.currentPrice.toStringAsFixed(0)
              : '',
        ),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAll() async {
    final Map<String, double> updates = {};
    for (final entry in _controllers.entries) {
      final text = entry.value.text.trim();
      if (text.isNotEmpty) {
        final val = double.tryParse(text);
        if (val != null && val >= 0) {
          updates[entry.key] = val;
        }
      }
    }
    await Provider.of<StockProvider>(context, listen: false)
        .bulkUpdateTickerPrices(updates);
    setState(() => _saved = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prices updated successfully'),
          backgroundColor: _stockColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyPrefixStr = currencyPrefix(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Update Stock Prices'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _entries.isEmpty
          ? _EmptyPrices()
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
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
                          'One price per ticker — all lots with the same symbol share this price.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: _stockColor,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final row = _entries[index];
                      final ctrl = _controllers[row.ticker]!;
                      return _PriceTile(
                        row: row,
                        controller: ctrl,
                        currencyPrefixStr: currencyPrefixStr,
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _entries.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: ElevatedButton.icon(
                  onPressed: _saved ? null : _saveAll,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save All Prices'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _stockColor,
                    minimumSize: const Size(double.infinity, 52),
                  ),
                ),
              ),
            ),
    );
  }
}

class _PriceTile extends StatelessWidget {
  final _TickerPriceRow row;
  final TextEditingController controller;
  final String currencyPrefixStr;

  const _PriceTile({
    required this.row,
    required this.controller,
    required this.currencyPrefixStr,
  });

  @override
  Widget build(BuildContext context) {
    final lotsLabel =
        row.lotCount > 1 ? '${row.lotCount} lots · ' : '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _stockLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        row.ticker,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: _stockColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        row.companyName,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$lotsLabel${row.totalShares} shares total',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 130,
            child: TextFormField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+\.?\d{0,2}')),
              ],
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                labelText: 'Price',
                prefixText: currencyPrefixStr,
                hintText: '0',
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: _stockColor, width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPrices extends StatelessWidget {
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
              child: const Icon(Icons.price_change_rounded,
                  color: AppColors.hintText, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'No holdings yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Add stock holdings first to update their prices',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
