import 'package:hive/hive.dart';

import '../../../core/constants/branches.dart';
import '../../../core/storage/cloud_json_store.dart';
import '../../../core/storage/storage_boxes.dart';
import '../../../core/storage/storage_service.dart';
import '../models/app_user_model.dart';

class UserService {
  Box get _box => StorageService.box(StorageBoxes.usuarios);

  Future<List<AppUserModel>> obtenerUsuarios() async {
    await asegurarUsuarioInicial();

    final values = await CloudJsonStore.syncBox(
      table: StorageBoxes.usuarios,
      box: _box,
    );

    return values.map((value) => AppUserModel.fromMap(value)).toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  Future<void> guardarUsuario(AppUserModel user) async {
    await _box.put(user.id, user.toMap());
    await CloudJsonStore.save(
      table: StorageBoxes.usuarios,
      id: user.id,
      data: user.toMap(),
    );
  }

  Future<void> asegurarUsuarioInicial() async {
    if (_box.isNotEmpty) {
      return;
    }

    final ahora = DateTime.now();

    final owner = AppUserModel(
      id: 'owner',
      nombre: 'Propietario',
      codigo: '1234',
      rol: 'Propietario',
      sucursal: Branches.casaCentral,
      activo: true,
      creado: ahora,
    );

    await guardarUsuario(owner);
  }
}
