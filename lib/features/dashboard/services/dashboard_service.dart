import '../models/dashboard_stats.dart';

class DashboardService {
  Future<DashboardStats> loadDashboard() async {
    // Simulación de consulta a base de datos
    await Future.delayed(const Duration(milliseconds: 700));

    return const DashboardStats(
      cash: 253000,
      sales: 1250000,
      purchases: 430000,
      profit: 820000,
      lowStockProducts: 12,
      pendingServices: 5,
      todayCustomers: 18,
    );
  }
}