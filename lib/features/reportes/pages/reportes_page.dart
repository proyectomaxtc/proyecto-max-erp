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
import '../../compras/providers/compra_provider.dart';
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
      ref.read(compraProvider.notifier).cargarCompras();
      ref.read(cajaProvider.notifier).cargarMovimientos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ventas = ref.watch(ventaProvider);
    final compras = ref.watch(compraProvider);
    final caja = ref.watch(cajaProvider);
    final ahora = DateTime.now();
    final inicioMes = DateTime(ahora.year, ahora.month);
    final finMes = DateTime(ahora.year, ahora.month + 1);
    final ventasDelMes = ventas.ventas.where(
      (venta) =>
          venta.estado == 'Completada' &&
          _inPeriod(venta.fecha, inicioMes, finMes),
    );
    final comprasDelMes = compras.compras.where(
      (compra) =>
          compra.estado == 'Recibida' &&
          _inPeriod(compra.fecha, inicioMes, finMes),
    );
    final totalVentasMes = ventasDelMes.fold<double>(
      0,
      (total, venta) => total + venta.total,
    );
    final utilidadMes = ventasDelMes.fold<double>(
      0,
      (total, venta) => total + venta.rentabilidad,
    );
    final totalComprasMes = comprasDelMes.fold<double>(
      0,
      (total, compra) => total + compra.total,
    );

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
                    title: "Ventas del mes",
                    value: CurrencyFormatter.format(totalVentasMes),
                    icon: Icons.sell_outlined,
                    color: AppColors.success,
                    subtitle: "${ventasDelMes.length} operaciones",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCard(
                    title: "Compras del mes",
                    value: CurrencyFormatter.format(totalComprasMes),
                    icon: Icons.shopping_cart_outlined,
                    color: AppColors.purchases,
                    subtitle: "Compras recibidas",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCard(
                    title: "Utilidad del mes",
                    value: CurrencyFormatter.format(utilidadMes),
                    icon: Icons.trending_up,
                    color: AppColors.success,
                    subtitle: _periodLabel(inicioMes),
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

  bool _inPeriod(DateTime date, DateTime start, DateTime end) {
    return !date.isBefore(start) && date.isBefore(end);
  }

  String _periodLabel(DateTime periodStart) {
    final month = switch (periodStart.month) {
      1 => 'Enero',
      2 => 'Febrero',
      3 => 'Marzo',
      4 => 'Abril',
      5 => 'Mayo',
      6 => 'Junio',
      7 => 'Julio',
      8 => 'Agosto',
      9 => 'Septiembre',
      10 => 'Octubre',
      11 => 'Noviembre',
      _ => 'Diciembre',
    };

    return '$month ${periodStart.year}';
  }
}
