import 'package:hive_flutter/hive_flutter.dart';

import 'cloud_json_store.dart';
import 'storage_boxes.dart';

class StorageService {
  StorageService._();

  static Future<void> initialize() async {
    await Hive.initFlutter();

    await Hive.openBox(StorageBoxes.clientes);

    await Hive.openBox(StorageBoxes.productos);

    await Hive.openBox(StorageBoxes.proveedores);

    await Hive.openBox(StorageBoxes.caja);

    await Hive.openBox(StorageBoxes.cajaTurnos);

    await Hive.openBox(StorageBoxes.inventario);

    await Hive.openBox(StorageBoxes.compras);

    await Hive.openBox(StorageBoxes.ventas);

    await Hive.openBox(StorageBoxes.servicios);

    await Hive.openBox(StorageBoxes.gastosBalance);

    await Hive.openBox(StorageBoxes.liquidacionesSueldos);

    await Hive.openBox(StorageBoxes.configuracion);

    await Hive.openBox(StorageBoxes.usuarios);

    await Hive.openBox(StorageBoxes.notificaciones);

    await CloudJsonStore.initialize();
  }

  static Box box(String name) {
    return Hive.box(name);
  }
}
