import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/configuracion_model.dart';
import '../services/configuracion_service.dart';

final configuracionProvider =
    StateNotifierProvider<ConfiguracionNotifier, ConfiguracionModel>(
      (ref) => ConfiguracionNotifier(ConfiguracionService()),
    );

class ConfiguracionNotifier extends StateNotifier<ConfiguracionModel> {
  final ConfiguracionService service;

  ConfiguracionNotifier(this.service) : super(ConfiguracionModel.defaults()) {
    cargarConfiguracion();
  }

  Future<void> cargarConfiguracion() async {
    state = await service.obtenerConfiguracion();
  }

  Future<void> guardarConfiguracion(ConfiguracionModel configuracion) async {
    await service.guardarConfiguracion(configuracion);
    state = configuracion;
  }
}
