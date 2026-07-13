import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/branches.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/layout/main_layout.dart';
import '../../../shared/widgets/access_denied_page.dart';
import '../../../shared/widgets/cards/kpi_card.dart';
import '../../../shared/widgets/tables/app_data_table.dart';
import '../../auth/providers/auth_provider.dart';
import '../../productos/models/producto_model.dart';
import '../../productos/providers/producto_provider.dart';

class InventarioPage extends ConsumerStatefulWidget {
  const InventarioPage({super.key});

  @override
  ConsumerState<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends ConsumerState<InventarioPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final usuario = ref.read(authProvider).usuario;
      if (usuario != null && !usuario.esPropietario) {
        ref.read(productoProvider.notifier).cambiarSucursal(usuario.sucursal);
      }
      ref.read(productoProvider.notifier).cargarProductos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productoState = ref.watch(productoProvider);
    final productos = productoState.productos;
    final sucursal = productoState.sucursalSeleccionada;
    final esPropietario = ref.watch(authProvider).esPropietario;

    if (!esPropietario) {
      return const AccessDeniedPage(
        title: "Inventario",
        message:
            "El inventario administrativo es solo para propietarios. Use Productos para consultar stock.",
      );
    }

    final stockBajo = productos
        .where(
          (producto) =>
              producto.stockEnSucursal(sucursal) > 0 &&
              producto.stockEnSucursal(sucursal) <=
                  producto.stockMinimoEnSucursal(sucursal),
        )
        .length;
    final sinStock = productos
        .where((producto) => producto.stockEnSucursal(sucursal) <= 0)
        .length;
    final valorStock = productos.fold<double>(
      0,
      (total, producto) =>
          total + producto.stockEnSucursal(sucursal) * producto.costo,
    );

    return MainLayout(
      title: "Inventario",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InventarioSucursalSelector(
            sucursal: sucursal,
            esPropietario: esPropietario,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 148,
            child: Row(
              children: [
                Expanded(
                  child: KpiCard(
                    title: "Productos",
                    value: productos.length.toString(),
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.info,
                    subtitle: "Catalogo con stock",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCard(
                    title: "Stock bajo",
                    value: stockBajo.toString(),
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    subtitle: "Requieren reposicion",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCard(
                    title: "Sin stock",
                    value: sinStock.toString(),
                    icon: Icons.remove_shopping_cart_outlined,
                    color: AppColors.error,
                    subtitle: "No disponibles",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCard(
                    title: "Valor stock",
                    value: CurrencyFormatter.format(valorStock),
                    icon: Icons.payments_outlined,
                    color: AppColors.success,
                    subtitle: "Valorizado a costo",
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _InventarioTable(productos: productos, sucursal: sucursal),
          ),
        ],
      ),
    );
  }
}

class _InventarioSucursalSelector extends ConsumerWidget {
  final String sucursal;
  final bool esPropietario;

  const _InventarioSucursalSelector({
    required this.sucursal,
    required this.esPropietario,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    final chips = Branches.values.map((branch) {
      final selected = branch == sucursal;

      return ChoiceChip(
        label: Text(branch == Branches.casaCentral ? 'Santa Fe' : 'Alberdi'),
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
            ? (_) => ref.read(productoProvider.notifier).cambiarSucursal(branch)
            : null,
      );
    }).toList();

    final label = sucursal == Branches.casaCentral
        ? 'Casa Central Santa Fe'
        : 'Sucursal Alberdi';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InventarioSucursalLabel(label: label),
                if (esPropietario) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: chips),
                ],
              ],
            )
          : Row(
              children: [
                Expanded(child: _InventarioSucursalLabel(label: label)),
                if (esPropietario)
                  Wrap(spacing: 8, runSpacing: 8, children: chips),
              ],
            ),
    );
  }
}

class _InventarioSucursalLabel extends StatelessWidget {
  final String label;

  const _InventarioSucursalLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.storefront_outlined, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Inventario navegando: $label',
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

class _InventarioTable extends StatelessWidget {
  final List<ProductoModel> productos;
  final String sucursal;

  const _InventarioTable({required this.productos, required this.sucursal});

  @override
  Widget build(BuildContext context) {
    if (productos.isEmpty) {
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
            "No hay productos cargados para controlar inventario.",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return AppDataTable(
      columns: const [
        DataColumn(label: Text("Codigo")),
        DataColumn(label: Text("Producto")),
        DataColumn(label: Text("Categoria")),
        DataColumn(label: Text("Stock")),
        DataColumn(label: Text("Minimo")),
        DataColumn(label: Text("Ubicacion")),
        DataColumn(label: Text("Estado")),
      ],
      rows: productos.map((producto) {
        final estado = _estado(producto);
        final stock = producto.stockEnSucursal(sucursal);
        final minimo = producto.stockMinimoEnSucursal(sucursal);

        return DataRow(
          cells: [
            DataCell(Text(producto.codigo)),
            DataCell(Text(producto.nombre)),
            DataCell(Text(producto.categoria)),
            DataCell(Text(stock.toStringAsFixed(0))),
            DataCell(Text(minimo.toStringAsFixed(0))),
            DataCell(
              Text(producto.ubicacion.isEmpty ? "-" : producto.ubicacion),
            ),
            DataCell(
              Chip(
                backgroundColor: estado.color,
                label: Text(
                  estado.label,
                  style: const TextStyle(
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

  _StockStatus _estado(ProductoModel producto) {
    final stock = producto.stockEnSucursal(sucursal);
    final minimo = producto.stockMinimoEnSucursal(sucursal);

    if (stock <= 0) {
      return const _StockStatus("Sin stock", AppColors.error);
    }

    if (stock <= minimo) {
      return const _StockStatus("Stock bajo", AppColors.warning);
    }

    return const _StockStatus("Disponible", AppColors.success);
  }
}

class _StockStatus {
  final String label;
  final Color color;

  const _StockStatus(this.label, this.color);
}
