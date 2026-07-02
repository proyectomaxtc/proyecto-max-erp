import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../auth/models/app_user_model.dart';
import '../models/app_notification_model.dart';
import '../services/notification_service.dart';

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<AppNotificationModel>>((
      ref,
    ) {
      return NotificationNotifier(NotificationService());
    });

class NotificationNotifier extends StateNotifier<List<AppNotificationModel>> {
  final NotificationService service;

  NotificationNotifier(this.service) : super(const []) {
    cargarNotificaciones();
  }

  Future<void> cargarNotificaciones() async {
    state = await service.obtenerNotificaciones();
  }

  Future<void> registrar({
    required AppUserModel? usuario,
    required String tipo,
    required String titulo,
    required String detalle,
    required String ruta,
    required double monto,
  }) async {
    if (usuario == null || usuario.esPropietario) {
      return;
    }

    final ahora = DateTime.now();
    final notification = AppNotificationModel(
      id: ahora.microsecondsSinceEpoch.toString(),
      tipo: tipo,
      titulo: titulo,
      detalle: detalle,
      ruta: ruta.isEmpty ? AppRoutes.dashboard : ruta,
      usuario: usuario.nombre,
      sucursal: usuario.sucursal,
      monto: monto,
      fecha: ahora,
    );

    await service.guardarNotificacion(notification);
    await cargarNotificaciones();
  }

  Future<void> marcarTodasLeidas() async {
    await service.marcarTodasLeidas();
    await cargarNotificaciones();
  }
}
