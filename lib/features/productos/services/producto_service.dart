import 'package:hive/hive.dart';

import '../../../core/storage/cloud_json_store.dart';
import '../../../core/storage/storage_boxes.dart';
import '../../../core/storage/storage_service.dart';
import '../models/producto_model.dart';

class ProductoService {
  Box get _box => StorageService.box(StorageBoxes.productos);

  Future<List<ProductoModel>> obtenerProductos() async {
    final values = await CloudJsonStore.syncBox(
      table: StorageBoxes.productos,
      box: _box,
    );

    return values.map(ProductoModel.fromMap).toList();
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
}
