import 'package:hive/hive.dart';

import '../../../core/storage/cloud_json_store.dart';
import '../../../core/storage/storage_boxes.dart';
import '../../../core/storage/storage_service.dart';
import '../models/servicio_model.dart';

class ServicioService {
  Box get _box => StorageService.box(StorageBoxes.servicios);

  Future<List<ServicioModel>> obtenerServicios() async {
    final values = await CloudJsonStore.syncBox(
      table: StorageBoxes.servicios,
      box: _box,
    );

    return values.map(ServicioModel.fromMap).toList()
      ..sort((a, b) => b.creado.compareTo(a.creado));
  }

  Future<void> guardarServicio(ServicioModel servicio) async {
    await _box.put(servicio.id, servicio.toMap());
    await CloudJsonStore.save(
      table: StorageBoxes.servicios,
      id: servicio.id,
      data: servicio.toMap(),
    );
  }

  Future<void> eliminarServicio(String id) async {
    await _box.delete(id);
    await CloudJsonStore.delete(table: StorageBoxes.servicios, id: id);
  }

  Future<int> obtenerProximoNumero() async {
    final servicios = await obtenerServicios();
    var mayor = 0;

    for (final servicio in servicios) {
      final numero = int.tryParse(servicio.numero.split('-').last) ?? 0;
      if (numero > mayor) {
        mayor = numero;
      }
    }

    return mayor + 1;
  }
}
