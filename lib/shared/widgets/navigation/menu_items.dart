import 'package:flutter/material.dart';

import '../../../app/routes.dart';

class MenuItemData {
  final String title;
  final IconData icon;
  final String route;

  const MenuItemData({
    required this.title,
    required this.icon,
    required this.route,
  });
}

const List<MenuItemData> menuItems = [

  MenuItemData(
    title: "Dashboard",
    icon: Icons.dashboard_rounded,
    route: AppRoutes.dashboard,
  ),

  MenuItemData(
    title: "Clientes",
    icon: Icons.people_alt_rounded,
    route: AppRoutes.clientes,
  ),

  MenuItemData(
    title: "Caja",
    icon: Icons.point_of_sale_rounded,
    route: AppRoutes.caja,
  ),

  MenuItemData(
    title: "Inventario",
    icon: Icons.inventory_2_rounded,
    route: AppRoutes.inventario,
  ),

  MenuItemData(
    title: "Compras",
    icon: Icons.shopping_cart_rounded,
    route: AppRoutes.compras,
  ),

  MenuItemData(
    title: "Ventas",
    icon: Icons.sell_rounded,
    route: AppRoutes.ventas,
  ),

  MenuItemData(
    title: "Servicios",
    icon: Icons.key_rounded,
    route: AppRoutes.servicios,
  ),

  MenuItemData(
    title: "Reportes",
    icon: Icons.bar_chart_rounded,
    route: AppRoutes.reportes,
  ),

  MenuItemData(
    title: "Configuración",
    icon: Icons.settings_rounded,
    route: AppRoutes.configuracion,
  ),
];