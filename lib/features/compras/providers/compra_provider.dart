import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../productos/models/producto_model.dart';
import '../../productos/services/producto_service.dart';
import '../models/compra_model.dart';
import '../repository/compra_repository.dart';
import '../services/compra_service.dart';
import '../state/compra_state.dart';

final compraProvider = StateNotifierProvider<CompraNotifier, CompraState>(
  (ref) => CompraNotifier(
    CompraRepository(service: CompraService()),
    ProductoService(),
  ),
);

class CompraNotifier extends StateNotifier<CompraState> {
  final CompraRepository repository;
  final ProductoService productoService;

  CompraNotifier(this.repository, this.productoService)
    : super(const CompraState());

  Future<void> cargarCompras() async {
    final compras = await repository.obtenerCompras();
    state = state.copyWith(compras: compras);
  }

  Future<void> agregarCompra(CompraModel compra) async {
    await repository.guardarCompra(compra);
    await cargarCompras();
  }

  Future<void> eliminarCompra(String id) async {
    CompraModel? compra;
    for (final item in state.compras) {
      if (item.id == id) {
        compra = item;
        break;
      }
    }

    compra ??= (await repository.obtenerCompras())
        .where((item) => item.id == id)
        .firstOrNull;

    if (compra != null && compra.estado == 'Recibida') {
      await _revertirStock(compra);
    }

    await repository.eliminarCompra(id);
    await cargarCompras();
  }

  Future<void> _revertirStock(CompraModel compra) async {
    final productos = await productoService.obtenerProductos();

    for (final compraItem in compra.items) {
      final producto = productos.firstWhere(
        (producto) => producto.id == compraItem.productoId,
        orElse: () => ProductoModel.empty(),
      );

      if (producto.id.isEmpty) {
        continue;
      }

      final stockSucursal = producto.stockEnSucursal(compra.sucursal);
      final nuevoStock = stockSucursal - compraItem.cantidad;

      await productoService.actualizarProducto(
        producto
            .conStockSucursal(
              sucursal: compra.sucursal,
              stockSucursal: nuevoStock < 0 ? 0 : nuevoStock,
            )
            .copyWith(actualizado: DateTime.now()),
      );
    }
  }

  Future<String> generarNumeroCompra() async {
    final numero = await repository.obtenerProximoNumero();
    return 'COM-${numero.toString().padLeft(6, '0')}';
  }

  void buscar(String texto) {
    state = state.copyWith(busqueda: texto);
  }

  void cambiarFiltro(String filtro) {
    state = state.copyWith(filtroEstado: filtro);
  }
}
