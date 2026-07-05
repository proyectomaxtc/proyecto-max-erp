import 'package:go_router/go_router.dart';

import 'routes.dart';

import '../features/auth/pages/login_page.dart';
import '../features/dashboard/pages/dashboard_page.dart';
import '../features/clientes/pages/clientes_page.dart';
import '../features/productos/pages/productos_page.dart';
import '../features/caja/pages/caja_page.dart';
import '../features/inventario/pages/inventario_page.dart';
import '../features/compras/pages/compras_page.dart';
import '../features/proveedores/pages/proveedores_page.dart';
import '../features/ventas/pages/ventas_page.dart';
import '../features/servicios/pages/servicios_page.dart';
import '../features/reportes/pages/reportes_page.dart';
import '../features/comprobantes/pages/comprobantes_page.dart';
import '../features/mayorista/pages/mayorista_page.dart';
import '../features/configuracion/pages/configuracion_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.login,

  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginPage(),
    ),

    GoRoute(
      path: AppRoutes.dashboard,
      builder: (context, state) => const DashboardPage(),
    ),

    GoRoute(
      path: AppRoutes.clientes,
      builder: (context, state) => const ClientesPage(),
    ),

    GoRoute(
      path: AppRoutes.productos,
      builder: (context, state) => const ProductosPage(),
    ),

    GoRoute(
      path: AppRoutes.caja,
      builder: (context, state) => const CajaPage(),
    ),

    GoRoute(
      path: AppRoutes.inventario,
      builder: (context, state) => const InventarioPage(),
    ),

    GoRoute(
      path: AppRoutes.compras,
      builder: (context, state) => const ComprasPage(),
    ),

    GoRoute(
      path: AppRoutes.proveedores,
      builder: (context, state) => const ProveedoresPage(),
    ),

    GoRoute(
      path: AppRoutes.ventas,
      builder: (context, state) => const VentasPage(),
    ),

    GoRoute(
      path: AppRoutes.servicios,
      builder: (context, state) => const ServiciosPage(),
    ),

    GoRoute(
      path: AppRoutes.reportes,
      builder: (context, state) => const ReportesPage(),
    ),

    GoRoute(
      path: AppRoutes.comprobantes,
      builder: (context, state) => const ComprobantesPage(),
    ),

    GoRoute(
      path: AppRoutes.mayorista,
      builder: (context, state) => const MayoristaPage(),
    ),

    GoRoute(
      path: AppRoutes.configuracion,
      builder: (context, state) => const ConfiguracionPage(),
    ),
  ],
);
