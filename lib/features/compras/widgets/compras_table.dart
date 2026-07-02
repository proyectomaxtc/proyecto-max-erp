import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/tables/app_data_table.dart';
import '../providers/compra_provider.dart';

class ComprasTable extends ConsumerWidget {
  const ComprasTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compras = ref.watch(compraProvider).comprasFiltradas;

    if (compras.isEmpty) {
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
            "No hay compras registradas.",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return AppDataTable(
      columns: const [
        DataColumn(label: Text("Numero")),
        DataColumn(label: Text("Fecha")),
        DataColumn(label: Text("Proveedor")),
        DataColumn(label: Text("Items")),
        DataColumn(label: Text("Responsable")),
        DataColumn(label: Text("Total")),
        DataColumn(label: Text("Estado")),
      ],
      rows: compras.map((compra) {
        final color = compra.estado == 'Recibida'
            ? AppColors.success
            : AppColors.warning;

        return DataRow(
          cells: [
            DataCell(Text(compra.numero)),
            DataCell(Text(_fecha(compra.fecha))),
            DataCell(Text(compra.proveedor)),
            DataCell(Text(compra.cantidadItems.toString())),
            DataCell(Text(compra.responsable)),
            DataCell(Text(CurrencyFormatter.format(compra.total))),
            DataCell(
              Chip(
                backgroundColor: color,
                label: Text(
                  compra.estado,
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
