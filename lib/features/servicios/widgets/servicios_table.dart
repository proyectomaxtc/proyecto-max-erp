import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/tables/app_data_table.dart';
import '../providers/servicio_provider.dart';

class ServiciosTable extends ConsumerWidget {
  const ServiciosTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicios = ref.watch(servicioProvider).serviciosFiltrados;

    if (servicios.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            "No hay servicios registrados.",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return AppDataTable(
      columns: const [
        DataColumn(label: Text("Numero")),
        DataColumn(label: Text("Fecha")),
        DataColumn(label: Text("Cliente")),
        DataColumn(label: Text("Tecnico")),
        DataColumn(label: Text("Total")),
        DataColumn(label: Text("Cobro")),
        DataColumn(label: Text("Estado")),
      ],
      rows: servicios.map((servicio) {
        final color = switch (servicio.estado) {
          'Entregado' => AppColors.success,
          'Listo' => AppColors.info,
          'En proceso' => AppColors.warning,
          _ => AppColors.textDisabled,
        };

        return DataRow(
          cells: [
            DataCell(Text(servicio.numero)),
            DataCell(Text(_fecha(servicio.creado))),
            DataCell(Text(servicio.clienteNombre)),
            DataCell(Text(servicio.tecnico)),
            DataCell(Text(CurrencyFormatter.format(servicio.total))),
            DataCell(Text(servicio.cobrado ? servicio.medioPago : "Pendiente")),
            DataCell(
              Chip(
                backgroundColor: color,
                label: Text(
                  servicio.estado,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _fecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();
    return '$dia/$mes/$anio';
  }
}
