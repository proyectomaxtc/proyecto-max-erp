class DashboardStats {
  final double cash;
  final double sales;
  final double purchases;
  final double profit;
  final DateTime periodStart;
  final DateTime periodEnd;

  final int lowStockProducts;
  final int pendingServices;
  final int todayCustomers;

  const DashboardStats({
    required this.cash,
    required this.sales,
    required this.purchases,
    required this.profit,
    required this.periodStart,
    required this.periodEnd,
    required this.lowStockProducts,
    required this.pendingServices,
    required this.todayCustomers,
  });

  String get periodLabel {
    final month = switch (periodStart.month) {
      1 => 'Enero',
      2 => 'Febrero',
      3 => 'Marzo',
      4 => 'Abril',
      5 => 'Mayo',
      6 => 'Junio',
      7 => 'Julio',
      8 => 'Agosto',
      9 => 'Septiembre',
      10 => 'Octubre',
      11 => 'Noviembre',
      _ => 'Diciembre',
    };

    return '$month ${periodStart.year}';
  }
}
