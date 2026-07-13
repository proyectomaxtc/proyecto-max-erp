import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/caja_movimiento_model.dart';
import '../providers/caja_provider.dart';
import 'owner_authorization_dialog.dart';

class CajaRetiroForm extends ConsumerStatefulWidget {
  const CajaRetiroForm({super.key});

  @override
  ConsumerState<CajaRetiroForm> createState() => _CajaRetiroFormState();
}

class _CajaRetiroFormState extends ConsumerState<CajaRetiroForm> {
  final _formKey = GlobalKey<FormState>();
  final retiroController = TextEditingController();
  final vueltoController = TextEditingController(text: '0');
  final observacionesController = TextEditingController();

  @override
  void dispose() {
    retiroController.dispose();
    vueltoController.dispose();
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

  double _parseMonto(String value) {
    return double.tryParse(value.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
  }

  void _usarRetiroSugerido() {
    final saldo = ref.read(cajaProvider).saldoSistemaTurno;
    final vuelto = _parseMonto(vueltoController.text);
    final sugerido = saldo - vuelto;

    retiroController.text = sugerido > 0 ? sugerido.toStringAsFixed(0) : '0';
  }

  Future<void> guardarRetiro() async {
    final caja = ref.read(cajaProvider);
    final usuario = ref.read(authProvider).usuario;
    final turno = caja.turnoAbierto;

    if (turno == null || usuario == null || !usuario.esPropietario) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final autorizado = await OwnerAuthorizationDialog.request(
      context,
      reason:
          'Confirme el retiro de dinero de caja. Esta accion quedara bloqueada y solo podra auditarla el propietario.',
    );

    if (!autorizado || !mounted) {
      return;
    }

    final ahora = DateTime.now();
    final montoRetiro = _parseMonto(retiroController.text);
    final fondoVueltos = _parseMonto(vueltoController.text);

    final movimiento = CajaMovimientoModel(
      id: 'retiro-${ahora.microsecondsSinceEpoch}',
      tipo: 'Egreso',
      concepto: 'Retiro de caja',
      monto: montoRetiro,
      medioPago: 'Efectivo',
      referenciaId: '',
      origen: 'Retiro',
      turnoId: turno.id,
      responsable: usuario.nombre,
      bloqueado: true,
      fecha: ahora,
      observaciones:
          'Fondo para vueltos: ${CurrencyFormatter.format(fondoVueltos)}. ${observacionesController.text.trim()}',
    );

    await ref.read(cajaProvider.notifier).agregarMovimiento(movimiento);

    if (!mounted) return;

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text(
          'Retiro registrado. Queda en caja ${CurrencyFormatter.format(fondoVueltos)} para vueltos.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final caja = ref.watch(cajaProvider);
    final saldo = caja.saldoSistemaTurno;
    final vuelto = _parseMonto(vueltoController.text);
    final retiroSugerido = saldo - vuelto;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saldo disponible',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  CurrencyFormatter.format(saldo),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: vueltoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
            ],
            decoration: decoration('Dejar en caja para vueltos'),
            onChanged: (_) => setState(() {}),
            validator: (value) {
              final monto = _parseMonto(value ?? '');
              if (monto < 0) {
                return 'Ingrese un monto valido';
              }
              if (monto > saldo) {
                return 'El fondo no puede superar el saldo de caja';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Retiro sugerido: ${CurrencyFormatter.format(retiroSugerido > 0 ? retiroSugerido : 0)}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              TextButton.icon(
                onPressed: _usarRetiroSugerido,
                icon: const Icon(Icons.auto_fix_high_outlined),
                label: const Text('Usar sugerido'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: retiroController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
            ],
            decoration: decoration('Monto a retirar'),
            validator: (value) {
              final monto = _parseMonto(value ?? '');
              if (monto <= 0) {
                return 'Ingrese un monto a retirar';
              }
              if (monto > saldo) {
                return 'No puede retirar mas que el saldo disponible';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: observacionesController,
            maxLines: 3,
            decoration: decoration('Observaciones'),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('Cancelar'),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: guardarRetiro,
                icon: const Icon(Icons.lock_outline),
                label: const Text('Confirmar retiro'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
