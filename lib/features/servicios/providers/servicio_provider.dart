import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/servicio_model.dart';
import '../repository/servicio_repository.dart';
import '../services/servicio_service.dart';
import '../state/servicio_state.dart';

final servicioProvider = StateNotifierProvider<ServicioNotifier, ServicioState>(
  (ref) => ServicioNotifier(ServicioRepository(service: ServicioService())),
);

class ServicioNotifier extends StateNotifier<ServicioState> {
  final ServicioRepository repository;

  ServicioNotifier(this.repository) : super(const ServicioState());

  Future<void> cargarServicios() async {
    final servicios = await repository.obtenerServicios();
    state = state.copyWith(servicios: servicios);
  }

  Future<void> agregarServicio(ServicioModel servicio) async {
    await repository.guardarServicio(servicio);
    await cargarServicios();
  }

  Future<void> eliminarServicio(String id) async {
    await repository.eliminarServicio(id);
    await cargarServicios();
  }

  Future<String> generarNumeroServicio() async {
    final numero = await repository.obtenerProximoNumero();
    return 'SER-${numero.toString().padLeft(6, '0')}';
  }

  void buscar(String texto) {
    state = state.copyWith(busqueda: texto);
  }

  void cambiarFiltro(String filtro) {
    state = state.copyWith(filtroEstado: filtro);
  }
}
