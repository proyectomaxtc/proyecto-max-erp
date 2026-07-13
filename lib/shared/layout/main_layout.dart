import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/constants/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../widgets/navigation/side_menu.dart';
import '../widgets/navigation/top_bar.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;
  final String title;

  const MainLayout({super.key, required this.child, this.title = "Dashboard"});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    final auth = ref.watch(authProvider);

    if (auth.cargandoSesion) {
      return const Scaffold(
        backgroundColor: Color(0xFF111111),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.autenticado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(AppRoutes.login);
        }
      });

      return const Scaffold(
        backgroundColor: Color(0xFF111111),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (compact) {
      return Scaffold(
        backgroundColor: const Color(0xFF111111),
        body: SafeArea(
          child: Column(
            children: [
              TopBar(title: title, compact: true),
              Expanded(
                child: Padding(padding: const EdgeInsets.all(8), child: child),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _MobileNav(esPropietario: auth.esPropietario),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: Row(
          children: [
            const SideMenu(),
            Expanded(
              child: Column(
                children: [
                  TopBar(title: title),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileNav extends StatelessWidget {
  final bool esPropietario;

  const _MobileNav({required this.esPropietario});

  @override
  Widget build(BuildContext context) {
    final route = GoRouterState.of(context).uri.toString();
    final items = [
      const _MobileNavItem("Ventas", Icons.sell_rounded, AppRoutes.ventas),
      const _MobileNavItem(
        "Productos",
        Icons.inventory_rounded,
        AppRoutes.productos,
      ),
      const _MobileNavItem("Caja", Icons.point_of_sale_rounded, AppRoutes.caja),
      const _MobileNavItem("Servicios", Icons.key_rounded, AppRoutes.servicios),
      if (esPropietario)
        const _MobileNavItem("Mas", Icons.more_horiz_rounded, ''),
    ];

    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: .18),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      child: NavigationBar(
        height: 62,
        selectedIndex: _selectedIndex(items, route),
        onDestinationSelected: (index) {
          final item = items[index];
          if (item.route.isEmpty) {
            _showMoreMenu(context, route);
            return;
          }

          context.go(item.route);
        },
        destinations: items
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }

  int _selectedIndex(List<_MobileNavItem> items, String route) {
    final index = items.indexWhere((item) => item.route == route);
    if (index >= 0) {
      return index;
    }

    final moreIndex = items.indexWhere((item) => item.route.isEmpty);
    return moreIndex >= 0 ? moreIndex : 0;
  }

  void _showMoreMenu(BuildContext context, String currentRoute) {
    final items = [
      const _MoreMenuItem(
        "Dashboard",
        Icons.dashboard_rounded,
        AppRoutes.dashboard,
      ),
      const _MoreMenuItem(
        "Clientes",
        Icons.people_alt_rounded,
        AppRoutes.clientes,
      ),
      const _MoreMenuItem(
        "Inventario",
        Icons.inventory_2_rounded,
        AppRoutes.inventario,
      ),
      const _MoreMenuItem(
        "Compras",
        Icons.shopping_cart_rounded,
        AppRoutes.compras,
      ),
      const _MoreMenuItem(
        "Proveedores",
        Icons.local_shipping_rounded,
        AppRoutes.proveedores,
      ),
      const _MoreMenuItem(
        "Reportes",
        Icons.bar_chart_rounded,
        AppRoutes.reportes,
      ),
      const _MoreMenuItem(
        "Comprobantes",
        Icons.picture_as_pdf_rounded,
        AppRoutes.comprobantes,
      ),
      const _MoreMenuItem(
        "Mayorista",
        Icons.price_change_rounded,
        AppRoutes.mayorista,
      ),
      const _MoreMenuItem(
        "Configuracion",
        Icons.settings_rounded,
        AppRoutes.configuracion,
      ),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Mas modulos",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.8,
                  children: items.map((item) {
                    final selected = currentRoute == item.route;
                    return OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.go(item.route);
                      },
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        foregroundColor: selected
                            ? Colors.black
                            : AppColors.textPrimary,
                        backgroundColor: selected
                            ? AppColors.primary
                            : AppColors.card,
                        side: BorderSide(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      icon: Icon(item.icon),
                      label: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MobileNavItem {
  final String label;
  final IconData icon;
  final String route;

  const _MobileNavItem(this.label, this.icon, this.route);
}

class _MoreMenuItem {
  final String label;
  final IconData icon;
  final String route;

  const _MoreMenuItem(this.label, this.icon, this.route);
}
