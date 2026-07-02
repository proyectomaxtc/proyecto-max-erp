import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/layout/main_layout.dart';
import '../../../shared/widgets/cards/kpi_card.dart';
import '../../../shared/widgets/layout/operational_card.dart';
import '../../caja/providers/caja_provider.dart';
import '../../clientes/providers/cliente_provider.dart';
import '../../productos/providers/producto_provider.dart';
import '../../ventas/providers/venta_provider.dart';

class ReportesPage extends ConsumerStatefulWidget {
  const ReportesPage({super.key});

  @override
  ConsumerState<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends ConsumerState<ReportesPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(ventaProvider.notifier).cargarVentas();
      ref.read(cajaProvider.notifier).cargarMovimientos();
      ref.read(clienteProvider.notifier).cargarClientes();
      ref.read(productoProvider.notifier).cargarProductos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ventas = ref.watch(ventaProvider);
    final caja = ref.watch(cajaProvider);
    final clientes = ref.watch(clienteProvider).clientes;
    final productos = ref.watch(productoProvider).productos;
    final activos = clientes.where((cliente) => cliente.activo).length;
    final stockBajo = productos
        .where(
          (producto) =>
              producto.stock > 0 && producto.stock <= producto.stockMinimo,
        )
        .length;

    return MainLayout(
      title: "Reportes",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 148,
            child: Row(
              children: [
                Expanded(
                  child: KpiCard(
                    title: "Ventas",
                    value: CurrencyFormatter.format(ventas.totalVendido),
                    icon: Icons.sell_outlined,
                    color: AppColors.success,
                    subtitle: "${ventas.ventas.length} operaciones",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCard(
                    title: "Caja",
                    value: CurrencyFormatter.format(caja.saldoSistemaTurno),
                    icon: Icons.point_of_sale_outlined,
                    color: AppColors.primary,
                    subtitle: caja.cajaAbierta
                        ? "Turno abierto"
                        : "Caja cerrada",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCard(
                    title: "Clientes activos",
                    value: activos.toString(),
                    icon: Icons.people_alt_outlined,
                    color: AppColors.info,
                    subtitle: "${clientes.length} clientes cargados",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCard(
                    title: "Stock bajo",
                    value: stockBajo.toString(),
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.warning,
                    subtitle: "Productos a revisar",
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OperationalCard(
                  title: "Reportes comerciales",
                  icon: Icons.bar_chart_rounded,
                  description:
                      "Vista preparada para ventas por periodo, rentabilidad y ticket promedio.",
                  items: const [
                    "Ventas",
                    "Rentabilidad",
                    "Clientes",
                    "Productos",
                  ],
                  actions: {
                    "Ventas": () => context.go(AppRoutes.ventas),
                    "Rentabilidad": () => context.go(AppRoutes.reportes),
                    "Clientes": () => context.go(AppRoutes.clientes),
                    "Productos": () => context.go(AppRoutes.productos),
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OperationalCard(
                  title: "Auditoria operativa",
                  icon: Icons.verified_user_outlined,
                  description:
                      "Control de caja, turnos, autorizaciones y movimientos sensibles.",
                  items: const ["Caja", "Turnos", "Autorizaciones", "Stock"],
                  actions: {
                    "Caja": () => context.go(AppRoutes.caja),
                    "Turnos": () => context.go(AppRoutes.caja),
                    "Autorizaciones": () => context.go(AppRoutes.configuracion),
                    "Stock": () => context.go(AppRoutes.productos),
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
