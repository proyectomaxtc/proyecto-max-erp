import 'package:hive/hive.dart';

import '../../../core/storage/cloud_json_store.dart';
import '../../../core/storage/storage_boxes.dart';
import '../../../core/storage/storage_service.dart';
import '../data/catalogo_inicial_lcc.dart';
import '../models/producto_model.dart';

class ProductoService {
  Box get _box => StorageService.box(StorageBoxes.productos);

  Future<List<ProductoModel>> obtenerProductos() async {
    final values = await CloudJsonStore.syncBox(
      table: StorageBoxes.productos,
      box: _box,
    );

    final productos = values.map(ProductoModel.fromMap).toList();
    final agregados = await importarCatalogoInicialLcc(
      productosActuales: productos,
    );

    return [...productos, ...agregados];
  }

  Future<int> obtenerProximoNumero(String categoria) async {
    final productos = await obtenerProductos();

    final prefijo = categoria.trim().toLowerCase();

    final mismosProductos = productos.where(
      (p) => p.categoria.trim().toLowerCase() == prefijo,
    );

    if (mismosProductos.isEmpty) {
      return 1;
    }

    int mayor = 0;

    for (final producto in mismosProductos) {
      final partes = producto.codigo.split('-');

      if (partes.length < 2) continue;

      final numero = int.tryParse(partes.last) ?? 0;

      if (numero > mayor) {
        mayor = numero;
      }
    }

    return mayor + 1;
  }

  Future<void> guardarProducto(ProductoModel producto) async {
    await _box.put(producto.id, producto.toMap());
    await CloudJsonStore.save(
      table: StorageBoxes.productos,
      id: producto.id,
      data: producto.toMap(),
    );
  }

  Future<void> actualizarProducto(ProductoModel producto) async {
    await guardarProducto(producto);
  }

  Future<void> eliminarProducto(String id) async {
    await _box.delete(id);
    await CloudJsonStore.delete(table: StorageBoxes.productos, id: id);
  }

  Future<List<ProductoModel>> importarCatalogoInicialLcc({
    List<ProductoModel>? productosActuales,
  }) async {
    final productos = productosActuales ?? await obtenerProductos();
    final codigosExistentes = productos
        .map((producto) => producto.codigo.trim().toLowerCase())
        .toSet();
    final codigosProveedor = productos
        .map((producto) => producto.codigoBarras.trim())
        .where((codigo) => codigo.isNotEmpty)
        .toSet();
    final agregados = <ProductoModel>[];

    for (final producto in catalogoInicialLcc()) {
      final existePorCodigo = codigosExistentes.contains(
        producto.codigo.trim().toLowerCase(),
      );
      final existePorProveedor = codigosProveedor.contains(
        producto.codigoBarras.trim(),
      );

      if (existePorCodigo || existePorProveedor) {
        continue;
      }

      await guardarProducto(producto);
      agregados.add(producto);
      codigosExistentes.add(producto.codigo.trim().toLowerCase());
      codigosProveedor.add(producto.codigoBarras.trim());
    }

    return agregados;
  }
}
