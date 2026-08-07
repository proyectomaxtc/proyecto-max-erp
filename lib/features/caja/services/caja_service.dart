import 'package:hive/hive.dart';

import '../../../core/storage/cloud_json_store.dart';
import '../../../core/storage/storage_boxes.dart';
import '../../../core/storage/storage_service.dart';
import '../models/caja_movimiento_model.dart';
import '../models/caja_turno_model.dart';

class CajaService {
  Box get _box => StorageService.box(StorageBoxes.caja);
  Box get _turnosBox => StorageService.box(StorageBoxes.cajaTurnos);

  Future<List<CajaMovimientoModel>> obtenerMovimientos() async {
    final values = await CloudJsonStore.syncBox(
      table: StorageBoxes.caja,
      box: _box,
    );

    return values.map(CajaMovimientoModel.fromMap).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  Future<void> guardarMovimiento(CajaMovimientoModel movimiento) async {
    final data = movimiento.toMap();
    final guardado = await CloudJsonStore.save(
      table: StorageBoxes.caja,
      id: movimiento.id,
      data: data,
    );

    if (CloudJsonStore.enabled && !guardado) {
      throw Exception(
        'No se pudo guardar el movimiento de caja en la nube. Revise conexion o sesion.',
      );
    }

    await _box.put(movimiento.id, data);
  }

  Future<void> eliminarMovimiento(String id) async {
    final eliminado = await CloudJsonStore.delete(
      table: StorageBoxes.caja,
      id: id,
    );

    if (CloudJsonStore.enabled && !eliminado) {
      throw Exception(
        'No se pudo eliminar el movimiento de caja en la nube. Revise permisos o conexion.',
      );
    }

    await _box.delete(id);
  }

  Future<List<CajaTurnoModel>> obtenerTurnos() async {
    final values = await CloudJsonStore.syncBox(
      table: StorageBoxes.cajaTurnos,
      box: _turnosBox,
    );

    return values.map(CajaTurnoModel.fromMap).toList()
      ..sort((a, b) => b.apertura.compareTo(a.apertura));
  }

  Future<void> guardarTurno(CajaTurnoModel turno) async {
    final data = turno.toMap();
    final guardado = await CloudJsonStore.save(
      table: StorageBoxes.cajaTurnos,
      id: turno.id,
      data: data,
    );

    if (CloudJsonStore.enabled && !guardado) {
      throw Exception(
        'No se pudo guardar el turno de caja en la nube. Revise conexion o sesion.',
      );
    }

    await _turnosBox.put(turno.id, data);
  }

  Future<void> guardarTurnoRapido(CajaTurnoModel turno) async {
    await guardarTurno(turno);
  }
}
