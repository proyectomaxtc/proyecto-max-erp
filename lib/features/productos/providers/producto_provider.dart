import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/branches.dart';
import '../../../core/utils/product_code_generator.dart';
import '../enums/producto_filter.dart';
import '../models/producto_import_model.dart';
import '../models/producto_model.dart';
import '../repository/producto_repository.dart';
import '../services/producto_service.dart';
import '../state/producto_state.dart';

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
    _aplicarProductoEnPantalla(producto);
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
    _aplicarProductoEnPantalla(producto);
  }

  Future<ProductoModel> transferirStock({
    required String productoId,
    required String origen,
    required String destino,
    required double cantidad,
  }) async {
    if (origen == destino) {
      throw Exception('Seleccione sucursales diferentes para transferir.');
    }

    if (cantidad <= 0) {
      throw Exception('Ingrese una cantidad mayor a 0.');
    }

    final producto = state.productos.firstWhere(
      (item) => item.id == productoId,
      orElse: ProductoModel.empty,
    );

    if (producto.id.isEmpty) {
      throw Exception('No se encontro el producto seleccionado.');
    }

    final stockPorSucursal = _stockNormalizado(producto);
    final stockOrigen = stockPorSucursal[origen] ?? 0;
    final stockDestino = stockPorSucursal[destino] ?? 0;

    if (stockOrigen < cantidad) {
      throw Exception(
        'Stock insuficiente en $origen. Disponible: ${stockOrigen.toStringAsFixed(0)}.',
      );
    }

    stockPorSucursal[origen] = stockOrigen - cantidad;
    stockPorSucursal[destino] = stockDestino + cantidad;
    final stockTotal = stockPorSucursal.values.fold<double>(
      0.0,
      (total, stock) => total + stock,
    );

    final actualizado = producto.copyWith(
      stock: stockTotal,
      stockPorSucursal: stockPorSucursal,
      actualizado: DateTime.now(),
    );

    await repository.actualizarProducto(actualizado);
    _aplicarProductoEnPantalla(actualizado);

    return actualizado;
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

  Future<int> actualizarPreciosLlaves({
    required String familia,
    required double costo,
    required double precio,
  }) async {
    final productos = state.productos
        .where((producto) => _coincideFamiliaLlave(producto, familia))
        .toList();
    final ahora = DateTime.now();

    for (final producto in productos) {
      await repository.actualizarProducto(
        producto.copyWith(costo: costo, precio: precio, actualizado: ahora),
      );
    }

    await cargarProductos();
    return productos.length;
  }

  int cantidadLlavesPorFamilia(String familia) {
    return state.productos
        .where((producto) => _coincideFamiliaLlave(producto, familia))
        .length;
  }

  Future<void> eliminarProducto(String id) async {
    await repository.eliminarProducto(id);

    state = state.copyWith(
      productos: state.productos
          .where((producto) => producto.id != id)
          .toList(growable: false),
    );
  }

  void buscar(String texto) {
    state = state.copyWith(busqueda: texto);
  }

  void cambiarCategoria(String categoria) {
    state = state.copyWith(categoria: categoria);
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
      if (p.esVentaLibre) {
        return false;
      }

      final sucursal = state.sucursalSeleccionada;
      final stock = p.stockEnSucursal(sucursal);

      return stock > 0 && stock <= p.stockMinimoEnSucursal(sucursal);
    }).toList();
  }

  List<ProductoModel> get productosSinStock {
    final sucursal = state.sucursalSeleccionada;

    return state.productos.where((p) {
      if (p.esVentaLibre) {
        return false;
      }

      return p.stockEnSucursal(sucursal) <= 0;
    }).toList();
  }

  double get valorTotalInventario {
    final sucursal = state.sucursalSeleccionada;

    return state.productos.fold(
      0,
      (total, p) {
        if (p.esVentaLibre) {
          return total;
        }

        return total + (p.stockEnSucursal(sucursal) * p.costo);
      },
    );
  }

  Future<String> generarCodigoProducto(String categoria) async {
    final numero = await repository.obtenerProximoNumero(categoria);

    return ProductCodeGenerator.generate(categoria: categoria, numero: numero);
  }

  bool _coincideFamiliaLlave(ProductoModel producto, String familia) {
    final texto = _normalizarTexto([
      producto.nombre,
      producto.categoria,
      producto.descripcion,
      producto.marca,
    ].join(' '));

    final esLlave =
        texto.contains('llave') ||
        texto.contains('copia') ||
        texto.contains('duplicado') ||
        texto.contains('yale') ||
        texto.contains('moto') ||
        texto.contains('multipunto') ||
        texto.contains('multi punto');

    if (!esLlave) {
      return false;
    }

    return switch (familia) {
      'doble_paleta' =>
        texto.contains('doble paleta') && !texto.contains('grande'),
      'doble_paleta_grande' =>
        texto.contains('doble paleta') && texto.contains('grande'),
      'yale' => texto.contains('yale'),
      'moto_corta' =>
        texto.contains('moto') &&
            (texto.contains('corta') || texto.contains('corto')),
      'moto_mediana' =>
        texto.contains('moto') &&
            (texto.contains('mediana') || texto.contains('mediano')),
      'multipunto' =>
        texto.contains('multipunto') || texto.contains('multi punto'),
      _ => false,
    };
  }

  String _normalizarTexto(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  Map<String, double> _stockNormalizado(ProductoModel producto) {
    final stockPorSucursal = Map<String, double>.from(
      producto.stockPorSucursal,
    );

    if (stockPorSucursal.isEmpty && producto.stock > 0) {
      stockPorSucursal[Branches.casaCentral] = producto.stock;
      stockPorSucursal[Branches.alberdi] = 0;
    }

    for (final sucursal in Branches.values) {
      stockPorSucursal.putIfAbsent(sucursal, () => 0);
    }

    return stockPorSucursal;
  }

  void _aplicarProductoEnPantalla(ProductoModel producto) {
    final productos = [...state.productos];
    final index = productos.indexWhere((item) => item.id == producto.id);

    if (index >= 0) {
      productos[index] = producto;
    } else {
      productos.add(producto);
    }

    state = state.copyWith(productos: productos, loading: false);
  }
}
