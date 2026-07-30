import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/cards/kpi_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../caja/providers/caja_provider.dart';
import '../../productos/providers/producto_provider.dart';
import '../providers/venta_provider.dart';

class VentasSummary extends ConsumerWidget {
  const VentasSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ventaProvider);
    final auth = ref.watch(authProvider);
    final usuario = auth.usuario;
    final esPropietario = auth.esPropietario;
    final compact = MediaQuery.sizeOf(context).width < 760;
    final ticketPromedio = state.ventas.isEmpty
        ? 0
        : state.totalVendido / state.ventas.length;
    final sucursalEmpleado = usuario?.sucursal ?? state.filtroSucursal;
    final ventasSucursal = state.ventas.where(
      (venta) => venta.sucursal == sucursalEmpleado,
    );
    final ventasHoy = ventasSucursal.any(
      (venta) => _esHoy(venta.fecha) && venta.estado == 'Completada',
    );
    final hayPendientes = ventasSucursal.any(
      (venta) => venta.estado == 'Pendiente',
    );
    final productosSucursal = ref.watch(productoProvider).productos.where(
      (producto) => producto.activo,
    );
    final haySinStock = productosSucursal.any(
      (producto) => producto.stockEnSucursal(sucursalEmpleado) <= 0,
    );
    final hayStockBajo = productosSucursal.any((producto) {
      final stock = producto.stockEnSucursal(sucursalEmpleado);
      final minimo = producto.stockMinimoEnSucursal(sucursalEmpleado);
      return stock > 0 && minimo > 0 && stock <= minimo;
    });
    final cajaAbierta = ref
        .watch(cajaProvider)
        .cajaAbiertaParaSucursal(sucursalEmpleado);
    final cards = esPropietario
        ? [
            KpiCard(
              title: "Ventas totales",
              value: CurrencyFormatter.format(state.totalVendido),
              icon: Icons.payments_outlined,
              color: AppColors.success,
              subtitle: "${state.ventasPorSucursal.length} operaciones",
            ),
            KpiCard(
              title: "Completadas",
              value: state.ventasCompletadas.toString(),
              icon: Icons.check_circle_outline,
              color: AppColors.info,
              subtitle: "Ventas confirmadas",
            ),
            KpiCard(
              title: "Ticket promedio",
              value: CurrencyFormatter.format(ticketPromedio),
              icon: Icons.receipt_long_outlined,
              color: AppColors.primary,
              subtitle: "Promedio por venta",
            ),
            KpiCard(
              title: "Rentabilidad",
              value: CurrencyFormatter.format(state.rentabilidad),
              icon: Icons.trending_up_rounded,
              color: AppColors.warning,
              subtitle: "Venta menos costo",
            ),
          ]
        : [
            KpiCard(
              title: "Ventas del dia",
              value: ventasHoy ? "Cargadas" : "Sin ventas",
              icon: Icons.payments_outlined,
              color: AppColors.success,
              subtitle: "Sin mostrar importes",
            ),
            KpiCard(
              title: "Stock a reponer",
              value: haySinStock || hayStockBajo ? "Reponer" : "OK",
              icon: Icons.inventory_2_outlined,
              color: haySinStock || hayStockBajo
                  ? AppColors.warning
                  : AppColors.success,
              subtitle: "Revisar catalogo",
            ),
            KpiCard(
              title: "Caja",
              value: cajaAbierta ? "Abierta" : "Cerrada",
              icon: cajaAbierta ? Icons.lock_open : Icons.lock_outline,
              color: AppColors.primary,
              subtitle: cajaAbierta ? "Turno activo" : "Abrir para operar",
            ),
            KpiCard(
              title: "Pendientes",
              value: hayPendientes ? "Revisar" : "Al dia",
              icon: Icons.pending_actions_outlined,
              color: AppColors.warning,
              subtitle: "Sin mostrar cantidades",
            ),
          ];

    if (compact) {
      return SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: cards.length,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            return SizedBox(width: 148, child: cards[index]);
          },
        ),
      );
    }

    return SizedBox(
      height: 164,
      child: Row(
        children: [
          for (var index = 0; index < cards.length; index++) ...[
            Expanded(child: cards[index]),
            if (index < cards.length - 1) const SizedBox(width: 16),
          ],
        ],
      ),
    );
  }

  bool _esHoy(DateTime fecha) {
    final hoy = DateTime.now();
    return fecha.year == hoy.year &&
        fecha.month == hoy.month &&
        fecha.day == hoy.day;
  }
}
