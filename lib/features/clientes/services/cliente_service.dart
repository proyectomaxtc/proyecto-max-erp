import 'package:hive/hive.dart';

import '../../../core/storage/cloud_json_store.dart';
import '../../../core/storage/storage_boxes.dart';
import '../../../core/storage/storage_service.dart';

import '../models/cliente_model.dart';

class ClienteService {
  Box get _box => StorageService.box(StorageBoxes.clientes);

  Future<List<ClienteModel>> obtenerClientes() async {
    await asegurarConsumidorFinal();

    final values = await CloudJsonStore.syncBox(
      table: StorageBoxes.clientes,
      box: _box,
    );

    return values.map(ClienteModel.fromMap).toList();
  }

  Future<void> asegurarConsumidorFinal() async {
    if (_box.containsKey(ClienteModel.consumidorFinalId)) {
      final cliente = ClienteModel.fromMap(
        Map<dynamic, dynamic>.from(_box.get(ClienteModel.consumidorFinalId)),
      );

      if (cliente.activo && cliente.nombre == 'Consumidor Final') {
        return;
      }
    }

    final existente = _box.values
        .map((e) => ClienteModel.fromMap(Map<dynamic, dynamic>.from(e)))
        .where(
          (cliente) =>
              cliente.nombre.trim().toLowerCase() == 'consumidor final',
        )
        .toList();

    if (existente.isNotEmpty) {
      final cliente = existente.first.copyWith(
        id: ClienteModel.consumidorFinalId,
        nombre: 'Consumidor Final',
        apellido: '',
        activo: true,
        actualizado: DateTime.now(),
      );

      await _box.put(ClienteModel.consumidorFinalId, cliente.toMap());
      await CloudJsonStore.save(
        table: StorageBoxes.clientes,
        id: cliente.id,
        data: cliente.toMap(),
      );
      return;
    }

    final cliente = ClienteModel.consumidorFinal();

    await _box.put(cliente.id, cliente.toMap());
    await CloudJsonStore.save(
      table: StorageBoxes.clientes,
      id: cliente.id,
      data: cliente.toMap(),
    );
  }

  Future<void> guardarCliente(ClienteModel cliente) async {
    await _box.put(cliente.id, cliente.toMap());
    await CloudJsonStore.save(
      table: StorageBoxes.clientes,
      id: cliente.id,
      data: cliente.toMap(),
    );
  }

  Future<void> actualizarCliente(ClienteModel cliente) async {
    await guardarCliente(cliente);
  }

  Future<void> eliminarCliente(String id) async {
    if (id == ClienteModel.consumidorFinalId) {
      await asegurarConsumidorFinal();
      return;
    }

    await _box.delete(id);
    await CloudJsonStore.delete(table: StorageBoxes.clientes, id: id);
  }
}
