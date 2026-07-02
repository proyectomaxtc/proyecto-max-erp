import '../models/servicio_model.dart';
import '../services/servicio_service.dart';

class ServicioRepository {
  final ServicioService service;

  const ServicioRepository({required this.service});

  Future<List<ServicioModel>> obtenerServicios() {
    return service.obtenerServicios();
  }

  Future<void> guardarServicio(ServicioModel servicio) {
    return service.guardarServicio(servicio);
  }

  Future<void> eliminarServicio(String id) {
    return service.eliminarServicio(id);
  }

  Future<int> obtenerProximoNumero() {
    return service.obtenerProximoNumero();
  }
}
