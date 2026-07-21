import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/branches.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/layout/main_layout.dart';
import '../../../shared/widgets/access_denied_page.dart';
import '../../auth/providers/auth_provider.dart';
import '../../productos/models/producto_model.dart';
import '../../productos/providers/producto_provider.dart';

class InventarioPage extends ConsumerStatefulWidget {
  const InventarioPage({super.key});

  @override
  ConsumerState<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends ConsumerState<InventarioPage> {
  final busquedaController = TextEditingController();
  var filtro = _InventarioFiltro.todos;

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
  void dispose() {
    busquedaController.dispose();
    super.dispose();
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
    final productosFiltrados = _productosFiltrados(productos, sucursal);

    return MainLayout(
      title: "Inventario",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InventarioSucursalSelector(
            sucursal: sucursal,
            esPropietario: esPropietario,
          ),
          const SizedBox(height: 14),
          _InventarioMetricGrid(
            productos: productos.length,
            stockBajo: stockBajo,
            sinStock: sinStock,
            valorStock: valorStock,
          ),
          const SizedBox(height: 14),
          _InventarioToolbar(
            controller: busquedaController,
            filtro: filtro,
            totalMostrado: productosFiltrados.length,
            onSearchChanged: (_) => setState(() {}),
            onFiltroChanged: (value) => setState(() => filtro = value),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _InventarioList(
              productos: productosFiltrados,
              sucursal: sucursal,
            ),
          ),
        ],
      ),
    );
  }

  List<ProductoModel> _productosFiltrados(
    List<ProductoModel> productos,
    String sucursal,
  ) {
    final query = _normalizar(busquedaController.text);
    final filtrados = productos.where((producto) {
      final stock = producto.stockEnSucursal(sucursal);
      final minimo = producto.stockMinimoEnSucursal(sucursal);
      final coincideBusqueda =
          query.isEmpty ||
          _normalizar(
            [
              producto.codigo,
              producto.nombre,
              producto.categoria,
              producto.marca,
              producto.proveedor,
              producto.ubicacion,
            ].join(' '),
          ).contains(query);

      if (!coincideBusqueda) {
        return false;
      }

      return switch (filtro) {
        _InventarioFiltro.todos => true,
        _InventarioFiltro.conStock => stock > 0,
        _InventarioFiltro.stockBajo => stock > 0 && stock <= minimo,
        _InventarioFiltro.sinStock => stock <= 0,
      };
    }).toList();

    filtrados.sort((a, b) {
      final estadoA = _estado(a, sucursal).orden;
      final estadoB = _estado(b, sucursal).orden;
      if (estadoA != estadoB) {
        return estadoA.compareTo(estadoB);
      }
      return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
    });

    return filtrados;
  }

  String _normalizar(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
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

class _InventarioMetricGrid extends StatelessWidget {
  final int productos;
  final int stockBajo;
  final int sinStock;
  final double valorStock;

  const _InventarioMetricGrid({
    required this.productos,
    required this.stockBajo,
    required this.sinStock,
    required this.valorStock,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 900;
    final cards = [
      _MiniMetric(
        title: 'Productos',
        value: productos.toString(),
        icon: Icons.inventory_2_outlined,
        color: AppColors.info,
      ),
      _MiniMetric(
        title: 'Stock bajo',
        value: stockBajo.toString(),
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
      ),
      _MiniMetric(
        title: 'Sin stock',
        value: sinStock.toString(),
        icon: Icons.remove_shopping_cart_outlined,
        color: AppColors.error,
      ),
      _MiniMetric(
        title: 'Valor stock',
        value: CurrencyFormatter.format(valorStock),
        icon: Icons.payments_outlined,
        color: AppColors.success,
      ),
    ];

    return GridView.count(
      crossAxisCount: compact ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: compact ? 2.5 : 3.8,
      children: cards,
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InventarioToolbar extends StatelessWidget {
  final TextEditingController controller;
  final _InventarioFiltro filtro;
  final int totalMostrado;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_InventarioFiltro> onFiltroChanged;

  const _InventarioToolbar({
    required this.controller,
    required this.filtro,
    required this.totalMostrado,
    required this.onSearchChanged,
    required this.onFiltroChanged,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Buscar producto, codigo, categoria...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 14),
                Text(
                  '$totalMostrado resultados',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _InventarioFiltro.values.map((item) {
              final selected = item == filtro;
              return ChoiceChip(
                label: Text(item.label),
                selected: selected,
                showCheckmark: false,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.card,
                labelStyle: TextStyle(
                  color: selected ? Colors.black : AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
                side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
                onSelected: (_) => onFiltroChanged(item),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _InventarioList extends StatelessWidget {
  final List<ProductoModel> productos;
  final String sucursal;

  const _InventarioList({required this.productos, required this.sucursal});

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
            "No hay productos para mostrar con esos filtros.",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: productos.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _InventarioItem(
        producto: productos[index],
        sucursal: sucursal,
      ),
    );
  }
}

class _InventarioItem extends StatelessWidget {
  final ProductoModel producto;
  final String sucursal;

  const _InventarioItem({required this.producto, required this.sucursal});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 820;
    final stock = producto.stockEnSucursal(sucursal);
    final minimo = producto.stockMinimoEnSucursal(sucursal);
    final estado = _estado(producto, sucursal);
    final valor = stock * producto.costo;

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InventarioItemHeader(producto: producto, estado: estado),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(label: 'Stock', value: stock.toStringAsFixed(0)),
                    _InfoPill(
                      label: 'Minimo',
                      value: minimo.toStringAsFixed(0),
                    ),
                    _InfoPill(
                      label: 'Valor',
                      value: CurrencyFormatter.format(valor),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _InventarioItemHeader(
                    producto: producto,
                    estado: estado,
                  ),
                ),
                _MetricColumn(label: 'Stock', value: stock.toStringAsFixed(0)),
                _MetricColumn(label: 'Minimo', value: minimo.toStringAsFixed(0)),
                _MetricColumn(
                  label: 'Valor',
                  value: CurrencyFormatter.format(valor),
                ),
                SizedBox(
                  width: 150,
                  child: Text(
                    producto.ubicacion.isEmpty ? '-' : producto.ubicacion,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
    );
  }
}

class _InventarioItemHeader extends StatelessWidget {
  final ProductoModel producto;
  final _StockStatus estado;

  const _InventarioItemHeader({required this.producto, required this.estado});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: estado.color.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.inventory_2_outlined, color: estado.color, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                producto.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${producto.codigo} · ${producto.categoria}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _StatusBadge(status: estado),
      ],
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final String label;
  final String value;

  const _MetricColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;

  const _InfoPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _StockStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StockStatus {
  final String label;
  final Color color;
  final int orden;

  const _StockStatus(this.label, this.color, this.orden);
}

enum _InventarioFiltro {
  todos('Todos'),
  conStock('Con stock'),
  stockBajo('Stock bajo'),
  sinStock('Sin stock');

  final String label;

  const _InventarioFiltro(this.label);
}

_StockStatus _estado(ProductoModel producto, String sucursal) {
  final stock = producto.stockEnSucursal(sucursal);
  final minimo = producto.stockMinimoEnSucursal(sucursal);

  if (stock <= 0) {
    return const _StockStatus("Sin stock", AppColors.error, 0);
  }

  if (stock <= minimo) {
    return const _StockStatus("Stock bajo", AppColors.warning, 1);
  }

  return const _StockStatus("Disponible", AppColors.success, 2);
}
