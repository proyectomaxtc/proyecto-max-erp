import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notificaciones/providers/notification_provider.dart';
import '../models/caja_movimiento_model.dart';
import '../providers/caja_provider.dart';

class CajaForm extends ConsumerStatefulWidget {
  const CajaForm({super.key});

  @override
  ConsumerState<CajaForm> createState() => _CajaFormState();
}

class _CajaFormState extends ConsumerState<CajaForm> {
  final _formKey = GlobalKey<FormState>();
  final conceptoController = TextEditingController();
  final montoController = TextEditingController();
  final observacionesController = TextEditingController();

  String tipo = 'Ingreso';
  String medioPago = 'Efectivo';

  @override
  void dispose() {
    conceptoController.dispose();
    montoController.dispose();
    observacionesController.dispose();
    super.dispose();
  }

  InputDecoration decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Future<void> guardarMovimiento() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ahora = DateTime.now();
    final turno = ref.read(cajaProvider).turnoAbierto;
    final usuario = ref.read(authProvider).usuario;

    if (turno == null) {
      return;
    }

    final movimiento = CajaMovimientoModel(
      id: ahora.microsecondsSinceEpoch.toString(),
      tipo: tipo,
      concepto: conceptoController.text.trim(),
      monto: double.tryParse(montoController.text) ?? 0,
      medioPago: medioPago,
      referenciaId: '',
      origen: 'Manual',
      turnoId: turno.id,
      responsable: turno.responsable,
      bloqueado: false,
      fecha: ahora,
      observaciones: observacionesController.text.trim(),
    );

    await ref.read(cajaProvider.notifier).agregarMovimiento(movimiento);
    await ref
        .read(notificationProvider.notifier)
        .registrar(
          usuario: usuario,
          tipo: 'Caja',
          titulo: '$tipo de caja',
          detalle:
              '${conceptoController.text.trim()} - ${CurrencyFormatter.format(movimiento.monto)}',
          ruta: AppRoutes.caja,
          monto: movimiento.monto,
        );

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Movimiento de caja registrado'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: tipo,
                  decoration: decoration("Tipo"),
                  dropdownColor: AppColors.surface,
                  items: const [
                    DropdownMenuItem(value: 'Ingreso', child: Text('Ingreso')),
                    DropdownMenuItem(value: 'Egreso', child: Text('Egreso')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      tipo = value ?? tipo;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: medioPago,
                  decoration: decoration("Medio de pago"),
                  dropdownColor: AppColors.surface,
                  items: const [
                    DropdownMenuItem(
                      value: 'Efectivo',
                      child: Text('Efectivo'),
                    ),
                    DropdownMenuItem(
                      value: 'Transferencia',
                      child: Text('Transferencia'),
                    ),
                    DropdownMenuItem(value: 'Tarjeta', child: Text('Tarjeta')),
                    DropdownMenuItem(
                      value: 'Cuenta corriente',
                      child: Text('Cuenta corriente'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      medioPago = value ?? medioPago;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: conceptoController,
            decoration: decoration("Concepto"),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Ingrese un concepto";
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: montoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: decoration("Monto"),
            validator: (value) {
              final monto = double.tryParse(value ?? '');
              if (monto == null || monto <= 0) {
                return "Ingrese un monto valido";
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: observacionesController,
            maxLines: 4,
            decoration: decoration("Observaciones"),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close),
                label: const Text("Cancelar"),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: guardarMovimiento,
                icon: const Icon(Icons.save_outlined),
                label: const Text("Guardar Movimiento"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
