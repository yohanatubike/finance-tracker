class Stock {
  final int? id;
  final String ticker;
  final String companyName;
  final int shares;
  final double buyPrice;
  final double currentPrice;

  /// Price tracking only — excluded from portfolio cost/P&L totals.
  final bool isWatchlist;

  const Stock({
    this.id,
    required this.ticker,
    required this.companyName,
    required this.shares,
    required this.buyPrice,
    this.currentPrice = 0.0,
    this.isWatchlist = false,
  });

  double get costBasis => shares * buyPrice;
  double get currentValue => shares * currentPrice;
  double get gainLoss => currentValue - costBasis;
  double get gainLossPercent =>
      costBasis == 0 ? 0 : (gainLoss / costBasis) * 100;

  Map<String, dynamic> toMap() => {
        'id': id,
        'ticker': ticker,
        'companyName': companyName,
        'shares': shares,
        'buyPrice': buyPrice,
        'currentPrice': currentPrice,
        'isWatchlist': isWatchlist ? 1 : 0,
      };

  factory Stock.fromMap(Map<String, dynamic> map) => Stock(
        id: map['id'] as int?,
        ticker: map['ticker'] as String,
        companyName: map['companyName'] as String,
        shares: map['shares'] as int,
        buyPrice: (map['buyPrice'] as num).toDouble(),
        currentPrice: (map['currentPrice'] as num).toDouble(),
        isWatchlist: (map['isWatchlist'] as int?) == 1,
      );

  Stock copyWith({
    int? id,
    String? ticker,
    String? companyName,
    int? shares,
    double? buyPrice,
    double? currentPrice,
    bool? isWatchlist,
  }) =>
      Stock(
        id: id ?? this.id,
        ticker: ticker ?? this.ticker,
        companyName: companyName ?? this.companyName,
        shares: shares ?? this.shares,
        buyPrice: buyPrice ?? this.buyPrice,
        currentPrice: currentPrice ?? this.currentPrice,
        isWatchlist: isWatchlist ?? this.isWatchlist,
      );
}

/// Pre-seeded DSE (Dar es Salaam Stock Exchange) ticker list.
const List<Map<String, String>> dseTickers = [
  {'ticker': 'AFRIPRISE', 'name': 'Afriprise Investment'},
  {'ticker': 'CRDB', 'name': 'CRDB Bank'},
  {'ticker': 'DCB', 'name': 'DCB Commercial Bank'},
  {'ticker': 'DSE', 'name': 'Dar es Salaam Stock Exchange'},
  {'ticker': 'IEACLC-ETF', 'name': 'IEACLC ETF'},
  {'ticker': 'JHL', 'name': 'Jubilee Holdings'},
  {'ticker': 'KA', 'name': 'Kenya Airways'},
  {'ticker': 'KCB', 'name': 'KCB Group'},
  {'ticker': 'MCB', 'name': 'MCB Bank'},
  {'ticker': 'MBP', 'name': 'Maendeleo Bank'},
  {'ticker': 'MKCB', 'name': 'Mkombozi Commercial Bank'},
  {'ticker': 'MUCOBA', 'name': 'Mufindi Community Bank'},
  {'ticker': 'NICO', 'name': 'NICO Holdings'},
  {'ticker': 'NMB', 'name': 'NMB Bank'},
  {'ticker': 'PAL', 'name': 'Precision Air'},
  {'ticker': 'SWIS', 'name': 'Swissport Tanzania'},
  {'ticker': 'TBL', 'name': 'Tanzania Breweries'},
  {'ticker': 'TCC', 'name': 'Tanzania Cigarette Company'},
  {'ticker': 'TCCL', 'name': 'Tatepa Limited'},
  {'ticker': 'TOL', 'name': 'TOL Gases'},
  {'ticker': 'TPCC', 'name': 'Twiga Cement'},
  {'ticker': 'TTP', 'name': 'Tatepa'},
  {'ticker': 'VERTEX-ETF', 'name': 'Vertex ETF'},
  {'ticker': 'VODA', 'name': 'Vodacom Tanzania'},
];
