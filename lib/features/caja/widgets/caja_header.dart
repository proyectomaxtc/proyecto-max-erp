import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/branches.dart';
import '../../../../shared/widgets/dialogs/app_dialog.dart';
import '../../../../shared/widgets/search/app_search_bar.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/caja_provider.dart';
import 'caja_form.dart';
import 'caja_retiro_form.dart';
import 'caja_turno_form.dart';

class CajaHeader extends ConsumerWidget {
  const CajaHeader({super.key});

  static const filtros = ['Todos', 'Ingreso', 'Egreso'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtroActivo = ref.watch(cajaProvider).filtroTipo;
    final state = ref.watch(cajaProvider);
    final usuario = ref.watch(authProvider).usuario;
    final esPropietario = usuario?.esPropietario ?? false;
    final compact = MediaQuery.sizeOf(context).width < 760;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (esPropietario) ...[
                  _SucursalCaja(ref, state.sucursalSeleccionada),
                  const SizedBox(height: 12),
                ],
                AppSearchBar(
                  hint: "Buscar concepto, medio u origen...",
                  onChanged: (texto) {
                    ref.read(cajaProvider.notifier).buscar(texto);
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _filtroChips(ref, filtroActivo),
                ),
                const SizedBox(height: 14),
                _CajaButtons(state: state, esPropietario: esPropietario),
              ],
            )
          : Row(
              children: [
                if (esPropietario) ...[
                  SizedBox(
                    width: 220,
                    child: _SucursalCaja(ref, state.sucursalSeleccionada),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  flex: 2,
                  child: AppSearchBar(
                    hint: "Buscar concepto, medio u origen...",
                    onChanged: (texto) {
                      ref.read(cajaProvider.notifier).buscar(texto);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _filtroChips(ref, filtroActivo),
                  ),
                ),
                const SizedBox(width: 16),
                _CajaButtons(state: state, esPropietario: esPropietario),
              ],
            ),
    );
  }

  List<Widget> _filtroChips(WidgetRef ref, String filtroActivo) {
    return filtros.map((filtro) {
      final selected = filtro == filtroActivo;

      return ChoiceChip(
        label: Text(filtro),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.card,
        labelStyle: TextStyle(
          color: selected ? Colors.black : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
        onSelected: (_) {
          ref.read(cajaProvider.notifier).cambiarFiltro(filtro);
        },
      );
    }).toList();
  }
}

class _SucursalCaja extends StatelessWidget {
  final WidgetRef ref;
  final String sucursalSeleccionada;

  const _SucursalCaja(this.ref, this.sucursalSeleccionada);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: sucursalSeleccionada,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: "Caja",
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dropdownColor: AppColors.surface,
      items: Branches.values
          .map(
            (sucursal) => DropdownMenuItem(
              value: sucursal,
              child: Text(
                sucursal == Branches.casaCentral ? 'Santa Fe' : 'Alberdi',
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        ref.read(cajaProvider.notifier).cambiarSucursal(value);
      },
    );
  }
}

class _CajaButtons extends StatelessWidget {
  final dynamic state;
  final bool esPropietario;

  const _CajaButtons({required this.state, required this.esPropietario});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    final buttons = [
      if (state.cajaAbierta && esPropietario)
        FilledButton.icon(
          icon: const Icon(Icons.savings_outlined),
          label: const Text("Retiro de caja"),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.warning,
            foregroundColor: Colors.white,
          ),
          onPressed: () => _abrirRetiro(context),
        ),
      FilledButton.icon(
        icon: Icon(state.cajaAbierta ? Icons.lock_outline : Icons.lock_open),
        label: Text(state.cajaAbierta ? "Cerrar Caja" : "Abrir Caja"),
        style: FilledButton.styleFrom(
          backgroundColor: state.cajaAbierta
              ? AppColors.warning
              : AppColors.success,
          foregroundColor: Colors.white,
        ),
        onPressed: () => _abrirTurno(context),
      ),
      FilledButton.icon(
        icon: const Icon(Icons.add),
        label: const Text("Nuevo Movimiento"),
        onPressed: state.cajaAbierta ? () => _abrirMovimiento(context) : null,
      ),
    ];

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < buttons.length; index++) ...[
            buttons[index],
            if (index < buttons.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    return Wrap(spacing: 12, runSpacing: 12, children: buttons);
  }

  void _abrirRetiro(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const AppDialog(
          title: "Retiro de caja",
          maxWidth: 640,
          maxHeight: 650,
          child: CajaRetiroForm(),
        );
      },
    );
  }

  void _abrirTurno(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AppDialog(
          title: state.cajaAbierta ? "Cerrar Caja" : "Abrir Caja",
          maxWidth: 640,
          maxHeight: 620,
          child: CajaTurnoForm(cierre: state.cajaAbierta),
        );
      },
    );
  }

  void _abrirMovimiento(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const AppDialog(
          title: "Nuevo Movimiento",
          maxWidth: 680,
          maxHeight: 620,
          child: CajaForm(),
        );
      },
    );
  }
}
