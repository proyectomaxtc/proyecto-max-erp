import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/tables/app_data_table.dart';
import '../providers/caja_provider.dart';
import 'owner_authorization_dialog.dart';

class CajaTable extends ConsumerWidget {
  const CajaTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cajaProvider);
    final movimientos = state.movimientosFiltrados;

    if (!state.cajaAbierta) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, color: AppColors.textDisabled, size: 56),
            SizedBox(height: 16),
            Text(
              "Caja cerrada",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Abra un turno indicando responsable y saldo inicial para operar.",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (movimientos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.point_of_sale_outlined,
              color: AppColors.textDisabled,
              size: 56,
            ),
            SizedBox(height: 16),
            Text(
              "No hay movimientos de caja",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Registra un movimiento o carga una venta completada.",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return AppDataTable(
      columns: const [
        DataColumn(label: Text("Fecha")),
        DataColumn(label: Text("Tipo")),
        DataColumn(label: Text("Concepto")),
        DataColumn(label: Text("Medio")),
        DataColumn(label: Text("Origen")),
        DataColumn(label: Text("Monto")),
        DataColumn(label: Text("Acciones")),
      ],
      rows: movimientos.map((movimiento) {
        final color = movimiento.esIngreso
            ? AppColors.success
            : AppColors.error;

        return DataRow(
          cells: [
            DataCell(Text(_fecha(movimiento.fecha))),
            DataCell(
              Chip(
                backgroundColor: color,
                label: Text(
                  movimiento.tipo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            DataCell(Text(movimiento.concepto)),
            DataCell(Text(movimiento.medioPago)),
            DataCell(Text(movimiento.origen)),
            DataCell(
              Text(
                CurrencyFormatter.format(movimiento.monto),
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
            DataCell(
              movimiento.origen == 'Manual'
                  ? IconButton(
                      tooltip: "Eliminar",
                      onPressed: () async {
                        final autorizado = await OwnerAuthorizationDialog.request(
                          context,
                          reason:
                              "Eliminar movimientos de caja requiere autorizacion del propietario.",
                        );

                        if (!autorizado) {
                          return;
                        }

                        if (!context.mounted) {
                          return;
                        }

                        final eliminar = await showDialog<bool>(
                          context: context,
                          builder: (_) {
                            return AlertDialog(
                              title: const Text("Eliminar Movimiento"),
                              content: Text(
                                "Desea eliminar ${movimiento.concepto}?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("Cancelar"),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Eliminar"),
                                ),
                              ],
                            );
                          },
                        );

                        if (eliminar == true) {
                          await ref
                              .read(cajaProvider.notifier)
                              .eliminarMovimiento(movimiento.id);
                        }
                      },
                      icon: const Icon(Icons.delete_outline),
                    )
                  : const Tooltip(
                      message:
                          "Movimiento vinculado. Corregir desde ventas o servicios.",
                      child: Icon(Icons.lock_outline),
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
