import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/cards/kpi_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/producto_provider.dart';

class ProductoSummary extends ConsumerWidget {
  const ProductoSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productoState = ref.watch(productoProvider);
    final productos = productoState.productos;
    final sucursal = productoState.sucursalSeleccionada;
    final esPropietario = ref.watch(authProvider).esPropietario;

    final activos = productos.where((producto) => producto.activo).length;
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
    final disponibles = productos
        .where(
          (producto) =>
              producto.activo && producto.stockEnSucursal(sucursal) > 0,
        )
        .length;
    final valorInventario = productos.fold<double>(
      0,
      (total, producto) =>
          total + (producto.stockEnSucursal(sucursal) * producto.costo),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = MediaQuery.sizeOf(context).width < 760;
        final compacto = constraints.maxWidth < 900;
        if (mobile) {
          return SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final cards = [
                  KpiCard(
                    title: "Productos activos",
                    value: activos.toString(),
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.info,
                    subtitle: "${productos.length} cargados",
                  ),
                  KpiCard(
                    title: "Stock bajo",
                    value: stockBajo.toString(),
                    icon: Icons.low_priority_outlined,
                    color: AppColors.warning,
                    subtitle: "Reposicion",
                  ),
                  KpiCard(
                    title: "Sin stock",
                    value: sinStock.toString(),
                    icon: Icons.remove_shopping_cart_outlined,
                    color: AppColors.error,
                    subtitle: "No disponibles",
                  ),
                  KpiCard(
                    title: esPropietario ? "Valor inv." : "Disponibles",
                    value: esPropietario
                        ? CurrencyFormatter.format(valorInventario)
                        : disponibles.toString(),
                    icon: esPropietario
                        ? Icons.payments_outlined
                        : Icons.check_circle_outline,
                    color: AppColors.success,
                    subtitle: esPropietario ? "Costo stock" : "Con stock",
                  ),
                ];
                return SizedBox(width: 148, child: cards[index]);
              },
            ),
          );
        }
        final anchoTarjeta = compacto ? (constraints.maxWidth - 10) / 2 : null;

        final tarjetas = [
          SizedBox(
            width: anchoTarjeta,
            height: compacto ? 102 : 98,
            child: KpiCard(
              title: "Productos activos",
              value: activos.toString(),
              icon: Icons.inventory_2_outlined,
              color: AppColors.info,
              subtitle: "${productos.length} cargados en total",
            ),
          ),
          SizedBox(
            width: anchoTarjeta,
            height: compacto ? 102 : 98,
            child: KpiCard(
              title: "Stock bajo",
              value: stockBajo.toString(),
              icon: Icons.low_priority_outlined,
              color: AppColors.warning,
              subtitle: "Revisar reposicion",
            ),
          ),
          SizedBox(
            width: anchoTarjeta,
            height: compacto ? 102 : 98,
            child: KpiCard(
              title: "Sin stock",
              value: sinStock.toString(),
              icon: Icons.remove_shopping_cart_outlined,
              color: AppColors.error,
              subtitle: "No disponibles",
            ),
          ),
          SizedBox(
            width: anchoTarjeta,
            height: compacto ? 102 : 98,
            child: KpiCard(
              title: esPropietario ? "Valor inventario" : "Disponibles",
              value: esPropietario
                  ? CurrencyFormatter.format(valorInventario)
                  : disponibles.toString(),
              icon: esPropietario
                  ? Icons.payments_outlined
                  : Icons.check_circle_outline,
              color: AppColors.success,
              subtitle: esPropietario
                  ? "Segun costo y stock"
                  : "Con stock para vender",
            ),
          ),
        ];

        if (compacto) {
          return Wrap(spacing: 10, runSpacing: 10, children: tarjetas);
        }

        return SizedBox(
          height: 98,
          child: Row(
            children: [
              for (var index = 0; index < tarjetas.length; index++) ...[
                Expanded(child: tarjetas[index]),
                if (index < tarjetas.length - 1) const SizedBox(width: 16),
              ],
            ],
          ),
        );
      },
    );
  }
}
