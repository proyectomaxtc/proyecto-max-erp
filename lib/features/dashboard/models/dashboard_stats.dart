class DashboardStats {
  final double cash;
  final double sales;
  final double purchases;
  final double profit;

  final int lowStockProducts;
  final int pendingServices;
  final int todayCustomers;

  const DashboardStats({
    required this.cash,
    required this.sales,
    required this.purchases,
    required this.profit,
    required this.lowStockProducts,
    required this.pendingServices,
    required this.todayCustomers,
  });
}