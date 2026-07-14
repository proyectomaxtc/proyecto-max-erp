import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../enums/producto_filter.dart';
import '../models/producto_import_model.dart';
import '../models/producto_model.dart';
import '../repository/producto_repository.dart';
import '../services/producto_service.dart';
import '../state/producto_state.dart';
import '../../../core/utils/product_code_generator.dart';

final productoProvider = StateNotifierProvider<ProductoNotifier, ProductoState>(
  (ref) {
    return ProductoNotifier(ProductoRepository(service: ProductoService()));
  },
);

class ProductoNotifier extends StateNotifier<ProductoState> {
  final ProductoRepository repository;

  ProductoNotifier(this.repository) : super(const ProductoState());

  Future<void> cargarProductos() async {
    final locales = repository.obtenerProductosLocales();
    if (locales.isNotEmpty) {
      state = state.copyWith(productos: locales, loading: true);
    } else {
      state = state.copyWith(loading: true);
    }

    try {
      final productos = await repository.obtenerProductos();

      state = state.copyWith(productos: productos, loading: false);
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> agregarProducto(ProductoModel producto) async {
    await repository.guardarProducto(producto);

    await cargarProductos();
  }

  Future<int> importarCatalogoInicialLcc() async {
    final agregados = await repository.importarCatalogoInicialLcc(
      productosActuales: state.productos,
    );

    await cargarProductos();
    return agregados.length;
  }

  Future<ProductoImportResult> importarLista({
    required String proveedor,
    required List<ProductoImportItem> items,
  }) async {
    final resultado = await repository.importarLista(
      proveedor: proveedor,
      items: items,
      productosActuales: state.productos,
    );

    await cargarProductos();
    return resultado;
  }

  Future<void> actualizarProducto(ProductoModel producto) async {
    await repository.actualizarProducto(producto);

    await cargarProductos();
  }

  Future<int> actualizarPreciosMayoristas(Map<String, double> precios) async {
    if (precios.isEmpty) {
      return 0;
    }

    final ahora = DateTime.now();
    var actualizados = 0;

    for (final producto in state.productos) {
      final precio = precios[producto.id];
      if (precio == null || precio <= 0) {
        continue;
      }

      await repository.actualizarProducto(
        producto.copyWith(precioMayorista: precio, actualizado: ahora),
      );
      actualizados++;
    }

    await cargarProductos();
    return actualizados;
  }

  Future<int> actualizarLlavesDoblePaleta({
    required double costo,
    required double precio,
  }) async {
    final productos = state.productos.where(_esLlaveDoblePaleta).toList();
    final ahora = DateTime.now();

    for (final producto in productos) {
      await repository.actualizarProducto(
        producto.copyWith(costo: costo, precio: precio, actualizado: ahora),
      );
    }

    await cargarProductos();
    return productos.length;
  }

  Future<void> eliminarProducto(String id) async {
    await repository.eliminarProducto(id);

    await cargarProductos();
  }

  void buscar(String texto) {
    state = state.copyWith(busqueda: texto);
  }

  void cambiarFiltro(ProductoFilter filtro) {
    state = state.copyWith(filtro: filtro);
  }

  void cambiarSucursal(String sucursal) {
    state = state.copyWith(sucursalSeleccionada: sucursal);
  }

  //=========================
  // MÉTODOS DE NEGOCIO
  //=========================

  List<ProductoModel> get productosConStockBajo {
    return state.productos.where((p) {
      final sucursal = state.sucursalSeleccionada;
      final stock = p.stockEnSucursal(sucursal);

      return stock > 0 && stock <= p.stockMinimoEnSucursal(sucursal);
    }).toList();
  }

  List<ProductoModel> get productosSinStock {
    final sucursal = state.sucursalSeleccionada;

    return state.productos.where((p) {
      return p.stockEnSucursal(sucursal) <= 0;
    }).toList();
  }

  double get valorTotalInventario {
    final sucursal = state.sucursalSeleccionada;

    return state.productos.fold(
      0,
      (total, p) => total + (p.stockEnSucursal(sucursal) * p.costo),
    );
  }

  Future<String> generarCodigoProducto(String categoria) async {
    final numero = await repository.obtenerProximoNumero(categoria);

    return ProductCodeGenerator.generate(categoria: categoria, numero: numero);
  }

  bool _esLlaveDoblePaleta(ProductoModel producto) {
    final texto = [
      producto.nombre,
      producto.categoria,
      producto.descripcion,
    ].join(' ').toLowerCase();

    final esLlave =
        texto.contains('llave') ||
        texto.contains('copia') ||
        texto.contains('duplicado');

    return esLlave && texto.contains('doble paleta');
  }
}
