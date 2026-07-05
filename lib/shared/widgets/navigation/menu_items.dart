import 'package:flutter/material.dart';

import '../../../app/routes.dart';

class MenuItemData {
  final String title;
  final IconData icon;
  final String route;
  final bool visibleParaEmpleado;

  const MenuItemData({
    required this.title,
    required this.icon,
    required this.route,
    this.visibleParaEmpleado = false,
  });
}

const List<MenuItemData> menuItems = [
  MenuItemData(
    title: "Ventas",
    icon: Icons.sell_rounded,
    route: AppRoutes.ventas,
    visibleParaEmpleado: true,
  ),
  MenuItemData(
    title: "Productos",
    icon: Icons.inventory_rounded,
    route: AppRoutes.productos,
    visibleParaEmpleado: true,
  ),
  MenuItemData(
    title: "Caja",
    icon: Icons.point_of_sale_rounded,
    route: AppRoutes.caja,
    visibleParaEmpleado: true,
  ),
  MenuItemData(
    title: "Servicios",
    icon: Icons.key_rounded,
    route: AppRoutes.servicios,
    visibleParaEmpleado: true,
  ),
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
    title: "Proveedores",
    icon: Icons.local_shipping_rounded,
    route: AppRoutes.proveedores,
  ),
  MenuItemData(
    title: "Reportes",
    icon: Icons.bar_chart_rounded,
    route: AppRoutes.reportes,
  ),
  MenuItemData(
    title: "Comprobantes",
    icon: Icons.picture_as_pdf_rounded,
    route: AppRoutes.comprobantes,
  ),
  MenuItemData(
    title: "Mayorista",
    icon: Icons.price_change_rounded,
    route: AppRoutes.mayorista,
  ),
  MenuItemData(
    title: "Configuracion",
    icon: Icons.settings_rounded,
    route: AppRoutes.configuracion,
  ),
];
