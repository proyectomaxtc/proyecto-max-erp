import 'package:hive/hive.dart';

import '../../../core/storage/cloud_json_store.dart';
import '../../../core/storage/storage_boxes.dart';
import '../../../core/storage/storage_service.dart';
import '../models/app_notification_model.dart';

class NotificationService {
  Box get _box => StorageService.box(StorageBoxes.notificaciones);

  Future<List<AppNotificationModel>> obtenerNotificaciones() async {
    final values = await CloudJsonStore.syncBox(
      table: StorageBoxes.notificaciones,
      box: _box,
    );

    return values.map(AppNotificationModel.fromMap).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  Future<void> guardarNotificacion(AppNotificationModel notification) async {
    await _box.put(notification.id, notification.toMap());
    await CloudJsonStore.save(
      table: StorageBoxes.notificaciones,
      id: notification.id,
      data: notification.toMap(),
    );
  }

  Future<void> marcarTodasLeidas() async {
    final notificaciones = await obtenerNotificaciones();

    for (final item in notificaciones) {
      final leida = item.copyWith(leida: true);
      await _box.put(item.id, leida.toMap());
      await CloudJsonStore.save(
        table: StorageBoxes.notificaciones,
        id: leida.id,
        data: leida.toMap(),
      );
    }
  }
}
