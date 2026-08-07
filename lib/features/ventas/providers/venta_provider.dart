import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/branches.dart';
import '../../../core/storage/cloud_json_store.dart';
import '../../../core/storage/storage_boxes.dart';
import '../../../core/storage/storage_service.dart';
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
    var stockDescontado = false;
    var ventaParaGuardar = venta;

    try {
      if (venta.estado == 'Completada') {
        await _descontarStock(venta);
        stockDescontado = true;
        ventaParaGuardar = venta.copyWith(stockAplicado: true);
      }

      await repository.guardarVenta(ventaParaGuardar);
      await cargarVentas();
    } catch (_) {
      if (stockDescontado) {
        try {
          await _devolverStock(venta);
        } catch (_) {
          // Si la compensacion falla, se informa el error principal.
        }
      }
      rethrow;
    }
  }

  Future<void> actualizarVenta({
    required VentaModel original,
    required VentaModel actualizada,
  }) async {
    var stockOriginalDevuelto = false;
    var stockActualizadoDescontado = false;
    var ventaParaGuardar = actualizada.copyWith(stockAplicado: false);

    try {
      if (original.estado == 'Completada' && original.stockAplicado) {
        await _devolverStock(original);
        stockOriginalDevuelto = true;
      }

      if (actualizada.estado == 'Completada') {
        await _descontarStock(actualizada);
        stockActualizadoDescontado = true;
        ventaParaGuardar = actualizada.copyWith(stockAplicado: true);
      }

      await repository.guardarVenta(ventaParaGuardar);
      await cargarVentas();
    } catch (_) {
      if (stockActualizadoDescontado) {
        try {
          await _devolverStock(ventaParaGuardar);
        } catch (_) {
          // Se intenta dejar el stock como estaba antes de la edicion.
        }
      }

      if (stockOriginalDevuelto) {
        try {
          await _descontarStock(original);
        } catch (_) {
          // Se mantiene el error principal para que el usuario reintente.
        }
      }

      rethrow;
    }
  }

  Future<void> eliminarVenta(String id) async {
    VentaModel? venta;
    for (final item in state.ventas) {
      if (item.id == id) {
        venta = item;
        break;
      }
    }

    final ventasAntes = state.ventas;
    state = state.copyWith(
      ventas: state.ventas.where((item) => item.id != id).toList(),
    );

    var stockDevuelto = false;

    try {
      if (venta != null &&
          venta.estado == 'Completada' &&
          venta.stockAplicado &&
          !_stockYaDevueltoPorEliminacion(venta.id)) {
        await _devolverStock(venta);
        stockDevuelto = true;
      }

      await repository.eliminarVenta(id);
    } catch (_) {
      if (venta != null && stockDevuelto) {
        try {
          await _descontarStock(venta);
        } catch (_) {
          // Si falla la compensacion, igual se restaura la venta en pantalla.
        }
      }
      state = state.copyWith(ventas: ventasAntes);
      rethrow;
    }

    if (venta != null && stockDevuelto) {
      await _marcarStockDevueltoPorEliminacion(venta.id);
    }
  }

  bool _stockYaDevueltoPorEliminacion(String ventaId) {
    final box = StorageService.box(StorageBoxes.configuracion);
    return box.get(_stockDevueltoKey(ventaId)) == true;
  }

  Future<void> _marcarStockDevueltoPorEliminacion(String ventaId) async {
    final box = StorageService.box(StorageBoxes.configuracion);
    await box.put(_stockDevueltoKey(ventaId), true);
  }

  String _stockDevueltoKey(String ventaId) {
    return 'venta_stock_devuelto_al_eliminar_$ventaId';
  }

  Future<void> _devolverStock(VentaModel venta) async {
    await _aplicarMovimientoStock(venta, 1);
  }

  Future<void> _descontarStock(VentaModel venta) async {
    await _aplicarMovimientoStock(venta, -1);
  }

  Future<void> _aplicarMovimientoStock(VentaModel venta, double signo) async {
    final sucursal = _normalizarSucursal(venta.sucursal);
    final productos = await _obtenerProductosParaStock();
    final cantidadesPorProducto = <String, double>{};
    final productosOriginales = <ProductoModel>[];
    final productosActualizados = <ProductoModel>[];

    for (final ventaItem in venta.items) {
      if (ventaItem.esVentaLibre) {
        continue;
      }

      cantidadesPorProducto.update(
        ventaItem.productoId,
        (cantidad) => cantidad + ventaItem.cantidad,
        ifAbsent: () => ventaItem.cantidad,
      );
    }

    for (final entry in cantidadesPorProducto.entries) {
      final producto = productos.firstWhere(
        (producto) => producto.id == entry.key,
        orElse: () => ProductoModel.empty(),
      );

      if (producto.esVentaLibre) {
        continue;
      }

      if (producto.id.isEmpty) {
        throw Exception(
          'No se encontro el producto de la venta en el catalogo. Revise sincronizacion antes de registrar.',
        );
      }

      final stockActual = producto.stockEnSucursal(sucursal);
      final stockNuevo = stockActual + (entry.value * signo);

      if (signo < 0 && stockNuevo < 0) {
        throw Exception(
          'Stock insuficiente para ${producto.nombre}. Disponible: ${stockActual.toStringAsFixed(0)}.',
        );
      }

      final actualizado = producto
          .conStockSucursal(sucursal: sucursal, stockSucursal: stockNuevo)
          .copyWith(actualizado: DateTime.now());

      productosOriginales.add(producto);
      productosActualizados.add(actualizado);
    }

    for (var index = 0; index < productosActualizados.length; index++) {
      try {
        await productoService.actualizarProducto(productosActualizados[index]);
      } catch (_) {
        for (
          var rollbackIndex = index - 1;
          rollbackIndex >= 0;
          rollbackIndex--
        ) {
          try {
            await productoService.actualizarProducto(
              productosOriginales[rollbackIndex],
            );
          } catch (_) {
            // Se mantiene el primer error para que el usuario reintente.
          }
        }

        rethrow;
      }
    }
  }

  Future<List<ProductoModel>> _obtenerProductosParaStock() async {
    if (CloudJsonStore.enabled && CloudJsonStore.hasActiveSession) {
      final remoteValues = await CloudJsonStore.loadAll(StorageBoxes.productos);
      if (remoteValues == null) {
        throw Exception(
          'No se pudo confirmar el stock en Supabase. Intente nuevamente.',
        );
      }

      return remoteValues.map(ProductoModel.fromMap).toList();
    }

    return productoService.obtenerProductos();
  }

  String _normalizarSucursal(String sucursal) {
    final value = sucursal.trim().toLowerCase();
    if (value.contains('alberdi')) {
      return Branches.alberdi;
    }

    return Branches.casaCentral;
  }

  Future<void> refrescarStock() async {
    await productoService.obtenerProductos();
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

  void cambiarRangoFechas(DateTime? desde, DateTime? hasta) {
    state = state.copyWith(fechaDesde: desde, fechaHasta: hasta);
  }

  void limpiarRangoFechas() {
    state = state.copyWith(limpiarFechas: true);
  }
}
