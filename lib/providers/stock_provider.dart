import 'package:flutter/foundation.dart';
import '../models/stock.dart';
import '../models/ticker_holding_summary.dart';
import '../database/database_helper.dart';

class UserTicker {
  final int id;
  final String ticker;
  final String companyName;

  const UserTicker({
    required this.id,
    required this.ticker,
    required this.companyName,
  });
}

class StockProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Stock> _stocks = [];
  List<UserTicker> _userTickers = [];
  bool _isLoading = false;

  List<Stock> get stocks => _stocks;

  List<Stock> get holdings =>
      _stocks.where((s) => !s.isWatchlist).toList();

  List<Stock> get watchlist =>
      _stocks.where((s) => s.isWatchlist).toList();

  List<UserTicker> get userTickers => _userTickers;
  bool get isLoading => _isLoading;

  static int _sortStock(Stock a, Stock b) {
    if (a.isWatchlist != b.isWatchlist) {
      return a.isWatchlist ? 1 : -1;
    }
    return a.ticker.compareTo(b.ticker);
  }

  /// All tickers available for selection (pre-seeded DSE + user-added).
  List<Map<String, String>> get allTickers {
    final custom = _userTickers
        .map((t) => {'ticker': t.ticker, 'name': t.companyName})
        .toList();
    final combined = [...dseTickers, ...custom];
    combined.sort((a, b) => a['ticker']!.compareTo(b['ticker']!));
    return combined;
  }

  double get totalPortfolioValue =>
      holdings.fold(0.0, (sum, s) => sum + s.currentValue);

  double get totalCostBasis =>
      holdings.fold(0.0, (sum, s) => sum + s.costBasis);

  double get totalGainLoss => totalPortfolioValue - totalCostBasis;

  double get totalGainLossPercent =>
      totalCostBasis == 0 ? 0 : (totalGainLoss / totalCostBasis) * 100;

  /// One row per ticker: shares and values summed across all lots.
  List<TickerHoldingSummary> get tickerSummaries {
    final byTicker = <String, List<Stock>>{};
    for (final s in holdings) {
      final key = s.ticker.toUpperCase();
      byTicker.putIfAbsent(key, () => []).add(s);
    }
    final keys = byTicker.keys.toList()..sort();
    return keys.map((key) {
      final lots = byTicker[key]!;
      final totalShares = lots.fold<int>(0, (a, b) => a + b.shares);
      final totalCost =
          lots.fold<double>(0, (a, b) => a + b.costBasis);
      final totalVal =
          lots.fold<double>(0, (a, b) => a + b.currentValue);
      final first = lots.first;
      return TickerHoldingSummary(
        ticker: first.ticker,
        companyName: first.companyName,
        totalShares: totalShares,
        totalCostBasis: totalCost,
        totalCurrentValue: totalVal,
        lotCount: lots.length,
      );
    }).toList();
  }

  Future<void> loadStocks() async {
    _isLoading = true;
    notifyListeners();
    _stocks = await _dbHelper.getAllStocks();
    _stocks.sort(_sortStock);
    final rows = await _dbHelper.getAllUserTickers();
    _userTickers = rows
        .map((r) => UserTicker(
              id: r['id'] as int,
              ticker: r['ticker'] as String,
              companyName: r['companyName'] as String,
            ))
        .toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addUserTicker(String ticker, String companyName) async {
    final id = await _dbHelper.insertUserTicker(ticker, companyName);
    _userTickers.add(
        UserTicker(id: id, ticker: ticker, companyName: companyName));
    _userTickers.sort((a, b) => a.ticker.compareTo(b.ticker));
    notifyListeners();
  }

  Future<void> removeUserTicker(int id) async {
    await _dbHelper.deleteUserTicker(id);
    _userTickers.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<void> addStock(Stock stock) async {
    final id = await _dbHelper.insertStock(stock);
    _stocks.add(stock.copyWith(id: id));
    _stocks.sort(_sortStock);
    notifyListeners();
  }

  Future<void> updateStock(Stock stock) async {
    await _dbHelper.updateStock(stock);
    final index = _stocks.indexWhere((s) => s.id == stock.id);
    if (index != -1) {
      _stocks[index] = stock;
      notifyListeners();
    }
  }

  Future<void> deleteStock(int id) async {
    await _dbHelper.deleteStock(id);
    _stocks.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  /// Updates market price for [ticker]; all holdings with that ticker reflect it.
  Future<void> updateTickerPrice(String ticker, double price) async {
    await _dbHelper.upsertTickerPrices({ticker: price});
    final upper = ticker.toUpperCase();
    _stocks = _stocks
        .map((s) =>
            s.ticker.toUpperCase() == upper ? s.copyWith(currentPrice: price) : s)
        .toList();
    notifyListeners();
  }

  Future<void> bulkUpdateTickerPrices(Map<String, double> tickerToPrice) async {
    await _dbHelper.upsertTickerPrices(tickerToPrice);
    final normalized = {
      for (final e in tickerToPrice.entries)
        e.key.toUpperCase(): e.value,
    };
    _stocks = _stocks
        .map((s) => normalized.containsKey(s.ticker.toUpperCase())
            ? s.copyWith(currentPrice: normalized[s.ticker.toUpperCase()]!)
            : s)
        .toList();
    notifyListeners();
  }
}
