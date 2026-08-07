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
    final data = compra.toMap();
    final guardada = await CloudJsonStore.save(
      table: StorageBoxes.compras,
      id: compra.id,
      data: data,
    );

    if (CloudJsonStore.enabled && !guardada) {
      throw Exception(
        'No se pudo guardar la compra en la nube. Revise conexion o sesion e intente nuevamente.',
      );
    }

    await _box.put(compra.id, data);
  }

  Future<void> eliminarCompra(String id) async {
    final eliminada = await CloudJsonStore.delete(
      table: StorageBoxes.compras,
      id: id,
    );

    if (CloudJsonStore.enabled && !eliminada) {
      throw Exception(
        'No se pudo eliminar la compra en la nube. Revise permisos o conexion.',
      );
    }

    await _box.delete(id);
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
