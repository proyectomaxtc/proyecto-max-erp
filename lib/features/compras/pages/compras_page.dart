import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/layout/main_layout.dart';
import '../../../shared/widgets/cards/kpi_card.dart';
import '../../productos/providers/producto_provider.dart';
import '../providers/compra_provider.dart';
import '../widgets/compras_header.dart';
import '../widgets/compras_table.dart';

class ComprasPage extends ConsumerStatefulWidget {
  const ComprasPage({super.key});

  @override
  ConsumerState<ComprasPage> createState() => _ComprasPageState();
}

class _ComprasPageState extends ConsumerState<ComprasPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(productoProvider.notifier).cargarProductos();
      ref.read(compraProvider.notifier).cargarCompras();
    });
  }

  @override
  Widget build(BuildContext context) {
    final compras = ref.watch(compraProvider);
    final productoState = ref.watch(productoProvider);
    final productos = productoState.productos;
    final sucursal = productoState.sucursalSeleccionada;
    final reposicion = productos
        .where(
          (producto) =>
              producto.stockEnSucursal(sucursal) <=
                  producto.stockMinimoEnSucursal(sucursal) ||
              producto.stockEnSucursal(sucursal) <= 0,
        )
        .length;
    final valorReposicion = productos
        .where(
          (producto) =>
              producto.stockEnSucursal(sucursal) <=
                  producto.stockMinimoEnSucursal(sucursal) ||
              producto.stockEnSucursal(sucursal) <= 0,
        )
        .fold<double>(0, (total, producto) {
          final faltante =
              producto.stockMinimoEnSucursal(sucursal) -
              producto.stockEnSucursal(sucursal);
          return total + (faltante <= 0 ? 0 : faltante * producto.costo);
        });

    return MainLayout(
      title: "Compras",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 148,
            child: Row(
              children: [
                Expanded(
                  child: KpiCard(
                    title: "Total comprado",
                    value: CurrencyFormatter.format(compras.totalComprado),
                    icon: Icons.shopping_cart_checkout_outlined,
                    color: AppColors.success,
                    subtitle:
                        "Transporte: ${CurrencyFormatter.format(compras.totalTransportes)}",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCard(
                    title: "Deuda proveedores",
                    value: CurrencyFormatter.format(compras.deudaTotal),
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.error,
                    subtitle:
                        "${compras.proveedoresConDeuda} proveedores pendientes",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCard(
                    title: "A reponer",
                    value: reposicion.toString(),
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    subtitle: "Segun stock minimo",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCard(
                    title: "Compra sugerida",
                    value: CurrencyFormatter.format(valorReposicion),
                    icon: Icons.payments_outlined,
                    color: AppColors.primary,
                    subtitle: "Costo estimado",
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const ComprasHeader(),
          const SizedBox(height: 20),
          const Expanded(child: ComprasTable()),
        ],
      ),
    );
  }
}
