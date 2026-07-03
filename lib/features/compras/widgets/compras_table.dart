import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/tables/app_data_table.dart';
import '../models/compra_model.dart';
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
        DataColumn(label: Text("Transporte")),
        DataColumn(label: Text("Pagado")),
        DataColumn(label: Text("Saldo")),
        DataColumn(label: Text("Estado")),
        DataColumn(label: Text("Acciones")),
      ],
      rows: compras.map((compra) {
        final color = compra.estado == 'Recibida'
            ? AppColors.success
            : AppColors.warning;
        final saldoColor = compra.tieneDeuda
            ? AppColors.error
            : AppColors.success;

        return DataRow(
          cells: [
            DataCell(Text(compra.numero)),
            DataCell(Text(_fecha(compra.fecha))),
            DataCell(Text(compra.proveedor)),
            DataCell(Text(compra.cantidadItems.toString())),
            DataCell(Text(compra.responsable)),
            DataCell(Text(CurrencyFormatter.format(compra.total))),
            DataCell(
              Text(
                compra.transporteCosto > 0
                    ? CurrencyFormatter.format(compra.transporteCosto)
                    : '-',
              ),
            ),
            DataCell(Text(CurrencyFormatter.format(compra.pagado))),
            DataCell(
              Text(
                CurrencyFormatter.format(compra.saldoPendiente),
                style: TextStyle(
                  color: saldoColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
            DataCell(
              compra.tieneDeuda
                  ? FilledButton.icon(
                      onPressed: () => _mostrarPagoDialog(context, ref, compra),
                      icon: const Icon(Icons.payments_outlined, size: 18),
                      label: const Text("Pagar"),
                    )
                  : const Chip(
                      avatar: Icon(Icons.check, color: Colors.white, size: 16),
                      backgroundColor: AppColors.success,
                      label: Text(
                        "Pagada",
                        style: TextStyle(
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

  Future<void> _mostrarPagoDialog(
    BuildContext context,
    WidgetRef ref,
    CompraModel compra,
  ) async {
    final pago = await showDialog<CompraPagoModel>(
      context: context,
      builder: (context) => _PagoProveedorDialog(compra: compra),
    );

    if (pago == null) {
      return;
    }

    await ref
        .read(compraProvider.notifier)
        .registrarPago(compraId: compra.id, pago: pago);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Pago registrado correctamente'),
      ),
    );
  }
}

class _PagoProveedorDialog extends StatefulWidget {
  final CompraModel compra;

  const _PagoProveedorDialog({required this.compra});

  @override
  State<_PagoProveedorDialog> createState() => _PagoProveedorDialogState();
}

class _PagoProveedorDialogState extends State<_PagoProveedorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController montoController;
  final responsableController = TextEditingController();
  final observacionesController = TextEditingController();
  String medioPago = 'Efectivo';

  @override
  void initState() {
    super.initState();
    montoController = TextEditingController(
      text: widget.compra.saldoPendiente.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    montoController.dispose();
    responsableController.dispose();
    observacionesController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final monto = double.tryParse(montoController.text) ?? 0;
    Navigator.pop(
      context,
      CompraPagoModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        monto: monto,
        medioPago: medioPago,
        responsable: responsableController.text.trim(),
        observaciones: observacionesController.text.trim(),
        fecha: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Registrar pago a proveedor'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.compra.proveedor,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Saldo pendiente: ${CurrencyFormatter.format(widget.compra.saldoPendiente)}',
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: montoController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _decoration('Monto pagado'),
                validator: (value) {
                  final monto = double.tryParse(value ?? '') ?? 0;
                  if (monto <= 0) {
                    return 'Ingrese un monto valido';
                  }
                  if (monto > widget.compra.saldoPendiente) {
                    return 'El pago no puede superar el saldo pendiente';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: medioPago,
                decoration: _decoration('Medio de pago'),
                dropdownColor: AppColors.surface,
                items: const [
                  DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
                  DropdownMenuItem(
                    value: 'Transferencia',
                    child: Text('Transferencia'),
                  ),
                  DropdownMenuItem(
                    value: 'Mercado Pago',
                    child: Text('Mercado Pago'),
                  ),
                  DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                  DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                ],
                onChanged: (value) {
                  setState(() {
                    medioPago = value ?? medioPago;
                  });
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: responsableController,
                decoration: _decoration('Responsable'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Ingrese responsable'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: observacionesController,
                maxLines: 3,
                decoration: _decoration('Observaciones'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          label: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _confirmar,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Confirmar pago'),
        ),
      ],
    );
  }
}
