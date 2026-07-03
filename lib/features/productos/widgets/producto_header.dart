import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/branches.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/dialogs/app_dialog.dart';
import '../../auth/providers/auth_provider.dart';

import '../enums/producto_filter.dart';
import '../providers/producto_provider.dart';

import 'producto_form.dart';
import 'producto_search.dart';
import 'producto_table.dart';

class ProductoHeader extends ConsumerWidget {
  const ProductoHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtroActivo = ref.watch(productoProvider).filtro;
    final state = ref.watch(productoProvider);
    final usuario = ref.watch(authProvider).usuario;
    final esPropietario = usuario?.esPropietario ?? false;
    final compact = MediaQuery.sizeOf(context).width < 760;
    final sucursalActual = esPropietario
        ? state.sucursalSeleccionada
        : (usuario?.sucursal ?? state.sucursalSeleccionada);
    final filtros = ProductoFilter.values.map((filtro) {
      return ChoiceChip(
        label: Text(_labelFiltro(filtro)),
        selected: filtroActivo == filtro,
        showCheckmark: false,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.card,
        labelStyle: TextStyle(
          color: filtroActivo == filtro
              ? Colors.black
              : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(
          color: filtroActivo == filtro ? AppColors.primary : AppColors.border,
        ),
        onSelected: (_) {
          ref.read(productoProvider.notifier).cambiarFiltro(filtro);
        },
      );
    }).toList();
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
        onSelected: esPropietario
            ? (_) {
                ref.read(productoProvider.notifier).cambiarSucursal(sucursal);
              }
            : null,
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
          _SucursalActualBanner(
            sucursal: sucursalActual,
            esPropietario: esPropietario,
            sucursales: sucursales,
          ),
          const SizedBox(height: 14),
          compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ProductoSearch(),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8, children: filtros),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _abrirListaCompleta(context),
                      icon: const Icon(Icons.open_in_full_rounded),
                      label: const Text("Lista completa"),
                    ),
                    const SizedBox(height: 12),
                    if (esPropietario)
                      OutlinedButton.icon(
                        onPressed: () => _importarCatalogoLcc(context, ref),
                        icon: const Icon(Icons.download_outlined),
                        label: const Text("Importar LCC"),
                      ),
                  ],
                )
              : Row(
                  children: [
                    const Expanded(flex: 2, child: ProductoSearch()),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: Wrap(spacing: 8, runSpacing: 8, children: filtros),
                    ),
                    if (esPropietario) ...[
                      const SizedBox(width: 16),
                      FilledButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text("Nuevo Producto"),
                        onPressed: () => _abrirProducto(context),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.open_in_full_rounded),
                        label: const Text("Lista completa"),
                        onPressed: () => _abrirListaCompleta(context),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.download_outlined),
                        label: const Text("Importar LCC"),
                        onPressed: () => _importarCatalogoLcc(context, ref),
                      ),
                    ],
                  ],
                ),
        ],
      ),
    );
  }

  void _abrirListaCompleta(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _CatalogoCompletoDialog(),
    );
  }

  void _abrirProducto(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const AppDialog(title: "Nuevo Producto", child: ProductoForm());
      },
    );
  }

  Future<void> _importarCatalogoLcc(BuildContext context, WidgetRef ref) async {
    final cantidad = await ref
        .read(productoProvider.notifier)
        .importarCatalogoInicialLcc();

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: cantidad > 0 ? AppColors.success : AppColors.info,
        content: Text(
          cantidad > 0
              ? 'Se importaron $cantidad productos de LCC'
              : 'El catalogo LCC ya estaba cargado',
        ),
      ),
    );
  }
}

String _labelFiltro(ProductoFilter filtro) {
  return switch (filtro) {
    ProductoFilter.todos => "Todos",
    ProductoFilter.activos => "Activos",
    ProductoFilter.inactivos => "Inactivos",
    ProductoFilter.bajoStock => "Stock bajo",
    ProductoFilter.sinStock => "Sin stock",
  };
}

class _CatalogoCompletoDialog extends ConsumerWidget {
  const _CatalogoCompletoDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productoProvider);
    final usuario = ref.watch(authProvider).usuario;
    final esPropietario = usuario?.esPropietario ?? false;
    final compact = MediaQuery.sizeOf(context).width < 760;
    final sucursalActual = esPropietario
        ? state.sucursalSeleccionada
        : (usuario?.sucursal ?? state.sucursalSeleccionada);
    final filtros = ProductoFilter.values.map((filtro) {
      final selected = state.filtro == filtro;
      return ChoiceChip(
        label: Text(_labelFiltro(filtro)),
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
          ref.read(productoProvider.notifier).cambiarFiltro(filtro);
        },
      );
    }).toList();
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
        onSelected: esPropietario
            ? (_) {
                ref.read(productoProvider.notifier).cambiarSucursal(sucursal);
              }
            : null,
      );
    }).toList();

    return Dialog.fullscreen(
      backgroundColor: const Color(0xFF111111),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(compact ? 10 : 18),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Catalogo de productos",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton.filled(
                    tooltip: "Cerrar",
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              SizedBox(height: compact ? 10 : 14),
              Container(
                padding: EdgeInsets.all(compact ? 12 : 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const ProductoSearch(),
                          const SizedBox(height: 10),
                          Wrap(spacing: 8, runSpacing: 8, children: filtros),
                          if (esPropietario) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: sucursales,
                            ),
                          ],
                        ],
                      )
                    : Row(
                        children: [
                          const Expanded(flex: 2, child: ProductoSearch()),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 3,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: filtros,
                            ),
                          ),
                          if (esPropietario) ...[
                            const SizedBox(width: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: sucursales,
                            ),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              const Expanded(child: ProductoTable()),
            ],
          ),
        ),
      ),
    );
  }
}

class _SucursalActualBanner extends StatelessWidget {
  final String sucursal;
  final bool esPropietario;
  final List<Widget> sucursales;

  const _SucursalActualBanner({
    required this.sucursal,
    required this.esPropietario,
    required this.sucursales,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: .45)),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SucursalLabel(sucursal: sucursal),
                if (esPropietario) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: sucursales),
                ],
              ],
            )
          : Row(
              children: [
                Expanded(child: _SucursalLabel(sucursal: sucursal)),
                if (esPropietario)
                  Wrap(spacing: 8, runSpacing: 8, children: sucursales),
              ],
            ),
    );
  }
}

class _SucursalLabel extends StatelessWidget {
  final String sucursal;

  const _SucursalLabel({required this.sucursal});

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
            'Stock navegando: $label',
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
