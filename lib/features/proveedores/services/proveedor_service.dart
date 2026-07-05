import 'package:hive/hive.dart';

import '../../../core/storage/cloud_json_store.dart';
import '../../../core/storage/storage_boxes.dart';
import '../../../core/storage/storage_service.dart';
import '../models/proveedor_cuenta_model.dart';

class ProveedorService {
  Box get _box => StorageService.box(StorageBoxes.proveedores);

  Future<List<ProveedorCuentaModel>> obtenerProveedores() async {
    final values = await CloudJsonStore.syncBox(
      table: StorageBoxes.proveedores,
      box: _box,
    );

    return values.map(ProveedorCuentaModel.fromMap).toList()..sort(
      (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
    );
  }

  Future<void> guardarProveedor(ProveedorCuentaModel proveedor) async {
    await _box.put(proveedor.id, proveedor.toMap());
    await CloudJsonStore.save(
      table: StorageBoxes.proveedores,
      id: proveedor.id,
      data: proveedor.toMap(),
    );
  }
}
