import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/company.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: const Color(0xFF151515),
      child: Column(
        children: [

          //========================
          // CABECERA
          //========================

          Container(
            padding: const EdgeInsets.symmetric(vertical: 25),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: .08),
                ),
              ),
            ),

            child: Column(
              children: [

                Image.asset(
                  Company.logo,
                  height: 80,
                ),

                const SizedBox(height: 12),

                const Text(
                  Company.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  Company.system,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: const [

                _MenuItem(
                  icon: Icons.dashboard_rounded,
                  title: "Dashboard",
                  selected: true,
                ),

                _MenuItem(
                  icon: Icons.people_alt_rounded,
                  title: "Clientes",
                ),

                _MenuItem(
                  icon: Icons.point_of_sale_rounded,
                  title: "Caja",
                ),

                _MenuItem(
                  icon: Icons.inventory_2_rounded,
                  title: "Inventario",
                ),

                _MenuItem(
                  icon: Icons.shopping_cart_rounded,
                  title: "Compras",
                ),

                _MenuItem(
                  icon: Icons.sell_rounded,
                  title: "Ventas",
                ),

                _MenuItem(
                  icon: Icons.key_rounded,
                  title: "Servicios",
                ),

                _MenuItem(
                  icon: Icons.bar_chart_rounded,
                  title: "Reportes",
                ),

                _MenuItem(
                  icon: Icons.settings_rounded,
                  title: "Configuración",
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(15),

            child: Column(
              children: [

                SizedBox(
                  width: double.infinity,

                  child: OutlinedButton.icon(
                    onPressed: () {},

                    icon: const Icon(Icons.logout),

                    label: const Text("Cerrar Sesión"),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  "Versión 1.0.0",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  "Powered by Proyecto MAX",
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),

      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: .15)
            : Colors.transparent,

        borderRadius: BorderRadius.circular(14),

        child: InkWell(
          borderRadius: BorderRadius.circular(14),

          onTap: () {},

          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
            ),

            child: Row(
              children: [

                Icon(
                  icon,
                  color: selected
                      ? AppColors.primary
                      : Colors.white70,
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: selected
                          ? AppColors.primary
                          : Colors.white70,
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