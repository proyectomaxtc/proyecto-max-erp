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
        bottomNavigationBar: _MobileNav(
          esPropietario: ref.watch(authProvider).esPropietario,
        ),
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
        const _MobileNavItem(
          "Mas",
          Icons.more_horiz_rounded,
          AppRoutes.dashboard,
        ),
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
        onDestinationSelected: (index) => context.go(items[index].route),
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
    return index >= 0 ? index : items.length - 1;
  }
}

class _MobileNavItem {
  final String label;
  final IconData icon;
  final String route;

  const _MobileNavItem(this.label, this.icon, this.route);
}
