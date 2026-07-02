import 'package:hive/hive.dart';

import '../../../core/storage/cloud_json_store.dart';
import '../../../core/storage/storage_boxes.dart';
import '../../../core/storage/storage_service.dart';
import '../models/compra_model.dart';

class CompraService {
  Box get _box => StorageService.box(StorageBoxes.compras);

  Future<List<CompraModel>> obtenerCompras() async {
    final values = await CloudJsonStore.syncBox(
      table: StorageBoxes.compras,
      box: _box,
    );

    return values.map(CompraModel.fromMap).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  Future<void> guardarCompra(CompraModel compra) async {
    await _box.put(compra.id, compra.toMap());
    await CloudJsonStore.save(
      table: StorageBoxes.compras,
      id: compra.id,
      data: compra.toMap(),
    );
  }

  Future<void> eliminarCompra(String id) async {
    await _box.delete(id);
    await CloudJsonStore.delete(table: StorageBoxes.compras, id: id);
  }

  Future<int> obtenerProximoNumero() async {
    final compras = await obtenerCompras();
    var mayor = 0;

    for (final compra in compras) {
      final numero = int.tryParse(compra.numero.split('-').last) ?? 0;
      if (numero > mayor) {
        mayor = numero;
      }
    }

    return mayor + 1;
  }
}
