import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/company.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: const Color(0xFF151515),
      child: Column(
        children: [
          const _CompanyHeader(),

          const Divider(
            color: AppColors.divider,
            height: 1,
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 20,
              ),
              children: const [

                _MenuTile(
                  icon: Icons.dashboard_rounded,
                  title: "Dashboard",
                  route: "/",
                  selected: true,
                ),

                _MenuTile(
                  icon: Icons.people_alt_rounded,
                  title: "Clientes",
                  route: "/clientes",
                ),

                _MenuTile(
                  icon: Icons.point_of_sale_rounded,
                  title: "Caja",
                  route: "/",
                ),

                _MenuTile(
                  icon: Icons.inventory_2_rounded,
                  title: "Inventario",
                  route: "/",
                ),

                _MenuTile(
                  icon: Icons.shopping_cart_rounded,
                  title: "Compras",
                  route: "/",
                ),

                _MenuTile(
                  icon: Icons.sell_rounded,
                  title: "Ventas",
                  route: "/",
                ),

                _MenuTile(
                  icon: Icons.key_rounded,
                  title: "Servicios",
                  route: "/",
                ),

                _MenuTile(
                  icon: Icons.bar_chart_rounded,
                  title: "Reportes",
                  route: "/",
                ),

                _MenuTile(
                  icon: Icons.settings_rounded,
                  title: "Configuración",
                  route: "/",
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.logout),
                label: const Text("Cerrar sesión"),
              ),
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            "Versión 1.0.0",
            style: TextStyle(
              color: AppColors.textDisabled,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            "Powered by Proyecto MAX",
            style: TextStyle(
              color: AppColors.textDisabled,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _CompanyHeader extends StatelessWidget {
  const _CompanyHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          Image.asset(
            Company.logo,
            height: 80,
            fit: BoxFit.contain,
          ),

          const SizedBox(height: 18),

          const Text(
            Company.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            Company.system,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            Company.slogan,
            style: TextStyle(
              color: AppColors.textDisabled,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;
  final bool selected;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.route,
    this.selected = false,
    
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            context.go(route);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}