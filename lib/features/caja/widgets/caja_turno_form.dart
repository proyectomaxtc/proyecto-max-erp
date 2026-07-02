import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/caja_provider.dart';
import 'owner_authorization_dialog.dart';

class CajaTurnoForm extends ConsumerStatefulWidget {
  final bool cierre;

  const CajaTurnoForm({super.key, this.cierre = false});

  @override
  ConsumerState<CajaTurnoForm> createState() => _CajaTurnoFormState();
}

class _CajaTurnoFormState extends ConsumerState<CajaTurnoForm> {
  final _formKey = GlobalKey<FormState>();
  final responsableController = TextEditingController();
  final saldoController = TextEditingController();
  final observacionesController = TextEditingController();

  @override
  void dispose() {
    responsableController.dispose();
    saldoController.dispose();
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

  Future<void> guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.cierre) {
      final autorizado = await OwnerAuthorizationDialog.request(
        context,
        reason:
            "El cierre de caja requiere autorizacion del propietario para validar el saldo declarado.",
      );

      if (!autorizado) {
        return;
      }

      await ref
          .read(cajaProvider.notifier)
          .cerrarCaja(
            saldoFinalDeclarado: double.tryParse(saldoController.text) ?? 0,
            observaciones: observacionesController.text.trim(),
          );
    } else {
      await ref
          .read(cajaProvider.notifier)
          .abrirCaja(
            sucursal: ref.read(cajaProvider).sucursalSeleccionada,
            responsable: responsableController.text.trim(),
            saldoInicial: double.tryParse(saldoController.text) ?? 0,
            observaciones: observacionesController.text.trim(),
          );
    }

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text(widget.cierre ? 'Caja cerrada' : 'Caja abierta'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cajaProvider);
    final turno = state.turnoAbierto;
    final saldoDeclarado = double.tryParse(saldoController.text) ?? 0;
    final diferencia = saldoDeclarado - state.saldoSistemaTurno;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (widget.cierre && turno != null) ...[
            _InfoBox(
              responsable: turno.responsable,
              saldoSistema: state.saldoSistemaTurno,
              diferencia: diferencia,
            ),
            const SizedBox(height: 18),
          ],
          if (!widget.cierre) ...[
            _SucursalBox(sucursal: state.sucursalSeleccionada),
            const SizedBox(height: 18),
            TextFormField(
              controller: responsableController,
              decoration: decoration("Empleado responsable"),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Ingrese el responsable del turno";
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
          ],
          TextFormField(
            controller: saldoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: decoration(
              widget.cierre ? "Saldo final declarado" : "Saldo inicial",
            ),
            validator: (value) {
              final saldo = double.tryParse(value ?? '');
              if (saldo == null || saldo < 0) {
                return "Ingrese un importe valido";
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
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text("Cancelar"),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: guardar,
                icon: Icon(
                  widget.cierre ? Icons.lock_outline : Icons.lock_open,
                ),
                label: Text(widget.cierre ? "Cerrar Caja" : "Abrir Caja"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SucursalBox extends StatelessWidget {
  final String sucursal;

  const _SucursalBox({required this.sucursal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        'Sucursal: $sucursal',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String responsable;
  final double saldoSistema;
  final double diferencia;

  const _InfoBox({
    required this.responsable,
    required this.saldoSistema,
    required this.diferencia,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: .4)),
      ),
      child: Text(
        "Responsable: $responsable\nSaldo esperado: ${CurrencyFormatter.format(saldoSistema)}\nDiferencia declarada: ${CurrencyFormatter.format(diferencia)}",
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
