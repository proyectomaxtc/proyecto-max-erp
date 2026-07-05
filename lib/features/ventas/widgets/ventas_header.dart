import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/branches.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/dialogs/app_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/venta_provider.dart';
import 'venta_form.dart';
import 'ventas_search.dart';

class VentasHeader extends ConsumerWidget {
  const VentasHeader({super.key});

  static const filtros = ['Todas', 'Completada', 'Pendiente', 'Anulada'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtroActivo = ref.watch(ventaProvider).filtroEstado;
    final ventaState = ref.watch(ventaProvider);
    final auth = ref.watch(authProvider);
    final usuario = auth.usuario;
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
                const VentasSearch(),
                const SizedBox(height: 12),
                _FiltroWrap(children: _filtroChips(ref, filtroActivo)),
                const SizedBox(height: 12),
                _FiltroWrap(
                  children: _sucursalChips(ref, ventaState, auth, usuario),
                ),
                const SizedBox(height: 12),
                _FechaFiltro(ref: ref),
                const SizedBox(height: 14),
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Nueva Venta"),
                  onPressed: () => _abrirVenta(context),
                ),
              ],
            )
          : Row(
              children: [
                const Expanded(flex: 2, child: VentasSearch()),
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
                Expanded(
                  flex: 2,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _sucursalChips(ref, ventaState, auth, usuario),
                  ),
                ),
                const SizedBox(width: 16),
                _FechaFiltro(ref: ref),
                const SizedBox(width: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Nueva Venta"),
                  onPressed: () => _abrirVenta(context),
                ),
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
          ref.read(ventaProvider.notifier).cambiarFiltro(filtro);
        },
      );
    }).toList();
  }

  List<Widget> _sucursalChips(
    WidgetRef ref,
    dynamic ventaState,
    dynamic auth,
    dynamic usuario,
  ) {
    return Branches.values.map((sucursal) {
      final selected = sucursal == ventaState.filtroSucursal;
      final habilitado = auth.esPropietario || usuario?.sucursal == sucursal;

      return ChoiceChip(
        label: Text(sucursal),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.card,
        disabledColor: AppColors.card.withValues(alpha: .45),
        labelStyle: TextStyle(
          color: selected ? Colors.black : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
        onSelected: habilitado
            ? (_) {
                ref.read(ventaProvider.notifier).cambiarSucursal(sucursal);
              }
            : null,
      );
    }).toList();
  }

  void _abrirVenta(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const AppDialog(
          title: "Nueva Venta",
          maxWidth: 980,
          maxHeight: 760,
          child: VentaForm(),
        );
      },
    );
  }
}

class _FechaFiltro extends StatelessWidget {
  final WidgetRef ref;

  const _FechaFiltro({required this.ref});

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ventaProvider);
    final texto = _label(state.fechaDesde, state.fechaHasta);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: () => _seleccionarRango(context),
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text(texto),
        ),
        if (state.fechaDesde != null || state.fechaHasta != null)
          IconButton(
            tooltip: "Limpiar fechas",
            onPressed: () {
              ref.read(ventaProvider.notifier).limpiarRangoFechas();
            },
            icon: const Icon(Icons.close),
          ),
      ],
    );
  }

  Future<void> _seleccionarRango(BuildContext context) async {
    final state = ref.read(ventaProvider);
    final now = DateTime.now();
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: state.fechaDesde != null && state.fechaHasta != null
          ? DateTimeRange(start: state.fechaDesde!, end: state.fechaHasta!)
          : null,
    );

    if (rango == null) {
      return;
    }

    ref.read(ventaProvider.notifier).cambiarRangoFechas(rango.start, rango.end);
  }

  String _label(DateTime? desde, DateTime? hasta) {
    if (desde == null || hasta == null) {
      return "Fecha";
    }

    return '${_fecha(desde)} - ${_fecha(hasta)}';
  }

  String _fecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes';
  }
}

class _FiltroWrap extends StatelessWidget {
  final List<Widget> children;

  const _FiltroWrap({required this.children});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: children);
  }
}
