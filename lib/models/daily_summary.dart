/// Daily summary snapshot used by the reports screen.
/// Computed client-side from Firestore queries (doc §7.4).
class DailySummary {
  final DateTime date;
  final int orderCount;
  final double totalSales;
  final double totalExpenses;
  final int desktopOrders;
  final int mobileOrders;
  final Map<String, int> topItems; // itemName -> qty sold

  const DailySummary({
    required this.date,
    required this.orderCount,
    required this.totalSales,
    required this.totalExpenses,
    required this.desktopOrders,
    required this.mobileOrders,
    required this.topItems,
  });

  double get profitLoss => totalSales - totalExpenses;
  bool get isProfit => profitLoss >= 0;
}
