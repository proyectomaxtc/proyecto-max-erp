import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../caja/providers/caja_provider.dart';
import '../../clientes/providers/cliente_provider.dart';
import '../../compras/providers/compra_provider.dart';
import '../../productos/providers/producto_provider.dart';
import '../../servicios/providers/servicio_provider.dart';
import '../../ventas/providers/venta_provider.dart';
import '../models/dashboard_stats.dart';
import '../services/dashboard_service.dart';

final dashboardServiceProvider = Provider<DashboardService>(
  (ref) => DashboardService(),
);

final dashboardProvider =
    FutureProvider<DashboardStats>((ref) async {
  ref.watch(ventaProvider.select((state) => state.ventas));
  ref.watch(cajaProvider.select((state) => state.movimientos));
  ref.watch(cajaProvider.select((state) => state.turnos));
  ref.watch(compraProvider.select((state) => state.compras));
  ref.watch(productoProvider.select((state) => state.productos));
  ref.watch(servicioProvider.select((state) => state.servicios));
  ref.watch(clienteProvider.select((state) => state.clientes));

  final service = ref.read(dashboardServiceProvider);

  return service.loadDashboard(syncCloud: false);
});
