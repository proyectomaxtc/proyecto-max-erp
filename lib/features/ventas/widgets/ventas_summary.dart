import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/cards/kpi_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/venta_provider.dart';

class VentasSummary extends ConsumerWidget {
  const VentasSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ventaProvider);
    final esPropietario = ref.watch(authProvider).esPropietario;
    final compact = MediaQuery.sizeOf(context).width < 760;
    final ticketPromedio = state.ventas.isEmpty
        ? 0
        : state.totalVendido / state.ventas.length;
    final ventasPendientes = state.ventas
        .where((venta) => venta.estado == 'Pendiente')
        .length;

    final cards = [
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
        title: esPropietario ? "Rentabilidad" : "Pendientes",
        value: esPropietario
            ? CurrencyFormatter.format(state.rentabilidad)
            : ventasPendientes.toString(),
        icon: esPropietario
            ? Icons.trending_up_rounded
            : Icons.pending_actions_outlined,
        color: AppColors.warning,
        subtitle: esPropietario ? "Venta menos costo" : "Ventas por confirmar",
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
}
