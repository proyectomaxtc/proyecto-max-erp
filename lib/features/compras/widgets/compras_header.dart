import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/branches.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/dialogs/app_dialog.dart';
import '../../../shared/widgets/search/app_search_bar.dart';
import '../../productos/providers/producto_provider.dart';
import '../providers/compra_provider.dart';
import 'compra_form.dart';

class ComprasHeader extends ConsumerWidget {
  const ComprasHeader({super.key});

  static const filtros = ['Todas', 'Recibida', 'Pendiente'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtroActivo = ref.watch(compraProvider).filtroEstado;
    final sucursalActual = ref.watch(productoProvider).sucursalSeleccionada;
    final compact = MediaQuery.sizeOf(context).width < 760;
    final sucursales = Branches.values.map((sucursal) {
      final selected = sucursalActual == sucursal;

      return ChoiceChip(
        label: Text(sucursal == Branches.casaCentral ? 'Santa Fe' : 'Alberdi'),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.card,
        labelStyle: TextStyle(
          color: selected ? Colors.black : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
        onSelected: (_) {
          ref.read(productoProvider.notifier).cambiarSucursal(sucursal);
        },
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: .45),
              ),
            ),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CompraSucursalLabel(sucursal: sucursalActual),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8, children: sucursales),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _CompraSucursalLabel(sucursal: sucursalActual),
                      ),
                      Wrap(spacing: 8, runSpacing: 8, children: sucursales),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSearchBar(
                      hint: "Buscar compra, proveedor o responsable...",
                      onChanged: (texto) {
                        ref.read(compraProvider.notifier).buscar(texto);
                      },
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _filtroChips(ref, filtroActivo),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _abrirCompra(context),
                      icon: const Icon(Icons.add),
                      label: const Text("Nueva Compra"),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: AppSearchBar(
                        hint: "Buscar compra, proveedor o responsable...",
                        onChanged: (texto) {
                          ref.read(compraProvider.notifier).buscar(texto);
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
                    FilledButton.icon(
                      onPressed: () => _abrirCompra(context),
                      icon: const Icon(Icons.add),
                      label: const Text("Nueva Compra"),
                    ),
                  ],
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
          ref.read(compraProvider.notifier).cambiarFiltro(filtro);
        },
      );
    }).toList();
  }

  void _abrirCompra(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const AppDialog(
          title: "Nueva Compra",
          maxWidth: 980,
          maxHeight: 760,
          child: CompraForm(),
        );
      },
    );
  }
}

class _CompraSucursalLabel extends StatelessWidget {
  final String sucursal;

  const _CompraSucursalLabel({required this.sucursal});

  @override
  Widget build(BuildContext context) {
    final label = sucursal == Branches.casaCentral
        ? 'Casa Central Santa Fe'
        : 'Sucursal Alberdi';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.storefront_outlined, color: AppColors.primary),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            'La compra ingresa a: $label',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
