import '../models/dashboard_stats.dart';
import '../services/dashboard_service.dart';

class DashboardRepository {
  final DashboardService service;

  DashboardRepository(this.service);

  Future<DashboardStats> getDashboard() {
    return service.loadDashboard();
  }
}