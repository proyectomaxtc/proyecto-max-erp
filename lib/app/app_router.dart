import 'package:go_router/go_router.dart';

import 'routes.dart';

import '../features/dashboard/pages/dashboard_page.dart';
import '../features/clientes/pages/clientes_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.dashboard,

  routes: [
    GoRoute(
      path: AppRoutes.dashboard,
      builder: (context, state) => const DashboardPage(),
    ),

    GoRoute(
      path: AppRoutes.clientes,
      builder: (context, state) => const ClientesPage(),
    ),
  ],
);