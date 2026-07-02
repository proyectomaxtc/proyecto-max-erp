import 'package:hive/hive.dart';

import '../../../core/storage/cloud_json_store.dart';
import '../../../core/storage/storage_boxes.dart';
import '../../../core/storage/storage_service.dart';
import '../models/configuracion_model.dart';

class ConfiguracionService {
  static const _settingsKey = 'settings';

  Box get _box => StorageService.box(StorageBoxes.configuracion);

  Future<ConfiguracionModel> obtenerConfiguracion() async {
    final values = await CloudJsonStore.syncBox(
      table: StorageBoxes.configuracion,
      box: _box,
    );
    Map<dynamic, dynamic>? cloudValue;
    for (final value in values) {
      if (value['id'] == _settingsKey) {
        cloudValue = value;
        break;
      }
    }
    if (cloudValue != null) {
      return ConfiguracionModel.fromMap(cloudValue);
    }

    final value = _box.get(_settingsKey);

    if (value == null) {
      return ConfiguracionModel.defaults();
    }

    return ConfiguracionModel.fromMap(Map<dynamic, dynamic>.from(value));
  }

  Future<void> guardarConfiguracion(ConfiguracionModel configuracion) async {
    await _box.put(_settingsKey, configuracion.toMap());
    await CloudJsonStore.save(
      table: StorageBoxes.configuracion,
      id: _settingsKey,
      data: {'id': _settingsKey, ...configuracion.toMap()},
    );
  }
}
