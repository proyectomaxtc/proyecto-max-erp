import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/cards/kpi_card.dart';
import '../providers/caja_provider.dart';

class CajaSummary extends ConsumerWidget {
  const CajaSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cajaProvider);
    final turno = state.turnoAbierto;
    final compact = MediaQuery.sizeOf(context).width < 760;

    final cards = [
      KpiCard(
        title: "Saldo de caja",
        value: CurrencyFormatter.format(state.saldoSistemaTurno),
        icon: Icons.account_balance_wallet_outlined,
        color: state.saldoSistemaTurno >= 0
            ? AppColors.success
            : AppColors.error,
        subtitle: turno == null
            ? "Caja cerrada"
            : "Responsable: ${turno.responsable}",
      ),
      KpiCard(
        title: "Ingresos",
        value: CurrencyFormatter.format(state.ingresos),
        icon: Icons.south_west_rounded,
        color: AppColors.success,
        subtitle: "Ventas y entradas manuales",
      ),
      KpiCard(
        title: "Egresos",
        value: CurrencyFormatter.format(state.egresos),
        icon: Icons.north_east_rounded,
        color: AppColors.error,
        subtitle: "Salidas registradas",
      ),
      KpiCard(
        title: "Efectivo",
        value: CurrencyFormatter.format(state.totalPorMedio('Efectivo')),
        icon: Icons.payments_outlined,
        color: AppColors.primary,
        subtitle: turno == null
            ? "Sin turno abierto"
            : "Apertura ${_hora(turno.apertura)}",
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
      height: 148,
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

  String _hora(DateTime fecha) {
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$hora:$minuto';
  }
}
