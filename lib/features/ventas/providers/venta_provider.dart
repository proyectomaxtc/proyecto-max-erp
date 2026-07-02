import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../productos/models/producto_model.dart';
import '../../productos/services/producto_service.dart';
import '../models/venta_model.dart';
import '../repository/venta_repository.dart';
import '../services/venta_service.dart';
import '../state/venta_state.dart';

final ventaProvider = StateNotifierProvider<VentaNotifier, VentaState>((ref) {
  return VentaNotifier(
    VentaRepository(service: VentaService()),
    ProductoService(),
  );
});

class VentaNotifier extends StateNotifier<VentaState> {
  final VentaRepository repository;
  final ProductoService productoService;

  VentaNotifier(this.repository, this.productoService)
    : super(const VentaState());

  Future<void> cargarVentas() async {
    final ventas = await repository.obtenerVentas();

    state = state.copyWith(ventas: ventas);
  }

  Future<void> agregarVenta(VentaModel venta) async {
    await repository.guardarVenta(venta);
    await cargarVentas();
  }

  Future<void> eliminarVenta(String id) async {
    VentaModel? venta;
    for (final item in state.ventas) {
      if (item.id == id) {
        venta = item;
        break;
      }
    }

    venta ??= (await repository.obtenerVentas())
        .where((item) => item.id == id)
        .firstOrNull;

    if (venta != null && venta.estado == 'Completada') {
      await _devolverStock(venta);
    }

    await repository.eliminarVenta(id);
    await cargarVentas();
  }

  Future<void> _devolverStock(VentaModel venta) async {
    final productos = await productoService.obtenerProductos();

    for (final ventaItem in venta.items) {
      final producto = productos.firstWhere(
        (producto) => producto.id == ventaItem.productoId,
        orElse: () => ProductoModel.empty(),
      );

      if (producto.id.isEmpty) {
        continue;
      }

      await productoService.actualizarProducto(
        producto
            .conStockSucursal(
              sucursal: venta.sucursal,
              stockSucursal:
                  producto.stockEnSucursal(venta.sucursal) + ventaItem.cantidad,
            )
            .copyWith(actualizado: DateTime.now()),
      );
    }
  }

  Future<String> generarNumeroVenta() async {
    final numero = await repository.obtenerProximoNumero();
    return 'VTA-${numero.toString().padLeft(6, '0')}';
  }

  void buscar(String texto) {
    state = state.copyWith(busqueda: texto);
  }

  void cambiarFiltro(String filtro) {
    state = state.copyWith(filtroEstado: filtro);
  }

  void cambiarSucursal(String sucursal) {
    state = state.copyWith(filtroSucursal: sucursal);
  }
}
