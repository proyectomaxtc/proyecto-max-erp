import '../models/venta_model.dart';
import '../services/venta_service.dart';

class VentaRepository {
  final VentaService service;

  const VentaRepository({required this.service});

  Future<List<VentaModel>> obtenerVentas() {
    return service.obtenerVentas();
  }

  Future<void> guardarVenta(VentaModel venta) {
    return service.guardarVenta(venta);
  }

  Future<void> eliminarVenta(String id) {
    return service.eliminarVenta(id);
  }

  Future<int> obtenerProximoNumero() {
    return service.obtenerProximoNumero();
  }
}
