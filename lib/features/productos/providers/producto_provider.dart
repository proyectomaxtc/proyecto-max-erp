import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../enums/producto_filter.dart';
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
    final productos = await repository.obtenerProductos();

    state = state.copyWith(productos: productos);
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

  Future<void> actualizarProducto(ProductoModel producto) async {
    await repository.actualizarProducto(producto);

    await cargarProductos();
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
}
