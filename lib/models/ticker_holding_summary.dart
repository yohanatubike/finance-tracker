/// Aggregates all lots for one ticker symbol.
class TickerHoldingSummary {
  final String ticker;
  final String companyName;
  final int totalShares;
  final double totalCostBasis;
  final double totalCurrentValue;
  final int lotCount;

  const TickerHoldingSummary({
    required this.ticker,
    required this.companyName,
    required this.totalShares,
    required this.totalCostBasis,
    required this.totalCurrentValue,
    required this.lotCount,
  });

  double get avgBuyPrice =>
      totalShares == 0 ? 0 : totalCostBasis / totalShares;

  double get impliedMarketPrice =>
      totalShares == 0 ? 0 : totalCurrentValue / totalShares;

  double get gainLoss => totalCurrentValue - totalCostBasis;

  double get gainLossPercent =>
      totalCostBasis == 0 ? 0 : (gainLoss / totalCostBasis) * 100;
}
