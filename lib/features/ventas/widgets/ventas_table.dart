import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/dialogs/app_dialog.dart';
import '../../../../shared/widgets/tables/app_data_table.dart';
import '../../caja/widgets/owner_authorization_dialog.dart';
import '../models/venta_model.dart';
import '../providers/venta_provider.dart';
import 'venta_form.dart';

class VentasTable extends ConsumerWidget {
  const VentasTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ventas = ref.watch(ventaProvider).ventasFiltradas;

    if (ventas.isEmpty) {
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
              Icons.receipt_long_outlined,
              color: AppColors.textDisabled,
              size: 56,
            ),
            SizedBox(height: 16),
            Text(
              "No hay ventas para mostrar",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Registra una nueva venta o ajusta los filtros.",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return AppDataTable(
      columns: const [
        DataColumn(label: Text("Numero")),
        DataColumn(label: Text("Fecha")),
        DataColumn(label: Text("Sucursal")),
        DataColumn(label: Text("Cliente")),
        DataColumn(label: Text("Items")),
        DataColumn(label: Text("Pago")),
        DataColumn(label: Text("Total")),
        DataColumn(label: Text("Estado")),
        DataColumn(label: Text("Acciones")),
      ],
      rows: ventas.map((venta) {
        final status = _status(venta);

        return DataRow(
          cells: [
            DataCell(
              Text(
                venta.numero,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            DataCell(Text(_fecha(venta.fecha))),
            DataCell(Text(venta.sucursal)),
            DataCell(Text(venta.clienteNombre)),
            DataCell(Text(venta.cantidadItems.toString())),
            DataCell(Text(venta.medioPago)),
            DataCell(
              Text(
                CurrencyFormatter.format(venta.total),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataCell(
              Chip(
                backgroundColor: status.color,
                label: Text(
                  status.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: "Editar",
                    onPressed: () => _editarVenta(context, venta),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: "Eliminar",
                    onPressed: () => _eliminarVenta(context, ref, venta),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Future<void> _editarVenta(BuildContext context, VentaModel venta) async {
    final autorizado = await OwnerAuthorizationDialog.request(
      context,
      reason:
          "Modificar ventas registradas requiere autorizacion del propietario.",
    );

    if (!autorizado || !context.mounted) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AppDialog(
          title: "Editar Venta",
          maxWidth: 980,
          maxHeight: 760,
          child: VentaForm(venta: venta),
        );
      },
    );
  }

  Future<void> _eliminarVenta(
    BuildContext context,
    WidgetRef ref,
    VentaModel venta,
  ) async {
    final autorizado = await OwnerAuthorizationDialog.request(
      context,
      reason:
          "Modificar o eliminar ventas registradas requiere autorizacion del propietario.",
    );

    if (!autorizado || !context.mounted) {
      return;
    }

    final eliminar = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Eliminar Venta"),
          content: Text("Desea eliminar la venta ${venta.numero}?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
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
      await ref.read(ventaProvider.notifier).eliminarVenta(venta.id);
    }
  }

  String _fecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();

    return '$dia/$mes/$anio';
  }

  _VentaStatus _status(VentaModel venta) {
    return switch (venta.estado) {
      'Pendiente' => const _VentaStatus(
        label: 'Pendiente',
        color: AppColors.warning,
      ),
      'Anulada' => const _VentaStatus(label: 'Anulada', color: AppColors.error),
      _ => const _VentaStatus(label: 'Completada', color: AppColors.success),
    };
  }
}

class _VentaStatus {
  final String label;
  final Color color;

  const _VentaStatus({required this.label, required this.color});
}
