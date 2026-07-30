import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/navigation/pending_logout_provider.dart';
import '../providers/caja_provider.dart';

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
  var guardando = false;

  @override
  void initState() {
    super.initState();

    final usuario = ref.read(authProvider).usuario;
    if (!widget.cierre && usuario != null) {
      responsableController.text = usuario.nombre;
    }
  }

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
    if (guardando) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => guardando = true);

    try {
      final usuario = ref.read(authProvider).usuario;
      final responsable = usuario?.nombre.trim().isNotEmpty == true
          ? usuario!.nombre.trim()
          : responsableController.text.trim();
      final sucursal = usuario?.esPropietario == true
          ? ref.read(cajaProvider).sucursalSeleccionada
          : (usuario?.sucursal ?? ref.read(cajaProvider).sucursalSeleccionada);

      if (widget.cierre) {
        await ref
            .read(cajaProvider.notifier)
            .cerrarCaja(
              saldoFinalDeclarado: double.tryParse(saldoController.text) ?? 0,
              observaciones: observacionesController.text.trim(),
              responsable: responsable,
              sucursal: sucursal,
            );
      } else {
        await ref
            .read(cajaProvider.notifier)
            .abrirCaja(
              sucursal: sucursal,
              responsable: responsable,
              saldoInicial: double.tryParse(saldoController.text) ?? 0,
              observaciones: observacionesController.text.trim(),
            );
      }
    } finally {
      if (mounted) {
        setState(() => guardando = false);
      }
    }

    if (!mounted) return;

    final cerrarSesionPendiente =
        widget.cierre && ref.read(pendingLogoutAfterCajaCloseProvider);
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);

    Navigator.pop(context);

    if (cerrarSesionPendiente) {
      ref.read(pendingLogoutAfterCajaCloseProvider.notifier).state = false;
      ref.read(authProvider.notifier).logout();
      router.go(AppRoutes.login);
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text(widget.cierre ? 'Caja cerrada' : 'Caja abierta'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cajaProvider);
    final usuario = ref.watch(authProvider).usuario;
    final sucursal = usuario?.esPropietario == true
        ? state.sucursalSeleccionada
        : (usuario?.sucursal ?? state.sucursalSeleccionada);
    final turno = state.turnoAbiertoParaSucursal(sucursal);
    final saldoDeclarado = double.tryParse(saldoController.text) ?? 0;
    final saldoSistema = state.saldoSistemaParaSucursal(sucursal);
    final diferencia = saldoDeclarado - saldoSistema;
    final responsableCierre = usuario?.nombre.trim().isNotEmpty == true
        ? usuario!.nombre.trim()
        : turno?.responsable ?? '';

    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (widget.cierre && turno != null) ...[
            _InfoBox(
              responsable: responsableCierre,
              saldoSistema: saldoSistema,
              diferencia: diferencia,
            ),
            const SizedBox(height: 18),
          ],
          if (!widget.cierre) ...[
            _SucursalBox(sucursal: sucursal),
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
                onPressed: guardando ? null : guardar,
                icon: Icon(
                  guardando
                      ? Icons.hourglass_top_rounded
                      : widget.cierre
                      ? Icons.lock_outline
                      : Icons.lock_open,
                ),
                label: Text(
                  guardando
                      ? (widget.cierre ? "Cerrando..." : "Abriendo...")
                      : (widget.cierre ? "Cerrar Caja" : "Abrir Caja"),
                ),
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
