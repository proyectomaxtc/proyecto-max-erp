class DashboardStats {
  final double cash;
  final double sales;
  final double purchases;
  final double profit;
  final int salesCount;
  final double averageTicket;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<EmployeePerformance> employeePerformance;
  final List<BranchPerformance> branchPerformance;

  final int lowStockProducts;
  final int pendingServices;
  final int todayCustomers;

  const DashboardStats({
    required this.cash,
    required this.sales,
    required this.purchases,
    required this.profit,
    required this.salesCount,
    required this.averageTicket,
    required this.periodStart,
    required this.periodEnd,
    required this.employeePerformance,
    required this.branchPerformance,
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

class EmployeePerformance {
  final String name;
  final String branch;
  final int salesCount;
  final double salesTotal;
  final double profitTotal;

  const EmployeePerformance({
    required this.name,
    required this.branch,
    required this.salesCount,
    required this.salesTotal,
    required this.profitTotal,
  });

  double get averageTicket => salesCount == 0 ? 0 : salesTotal / salesCount;
}

class BranchPerformance {
  final String branch;
  final int salesCount;
  final double salesTotal;
  final double profitTotal;

  const BranchPerformance({
    required this.branch,
    required this.salesCount,
    required this.salesTotal,
    required this.profitTotal,
  });
}
