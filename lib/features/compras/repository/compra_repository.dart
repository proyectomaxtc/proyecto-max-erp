import '../models/compra_model.dart';
import '../services/compra_service.dart';

class CompraRepository {
  final CompraService service;

  const CompraRepository({required this.service});

  Future<List<CompraModel>> obtenerCompras() => service.obtenerCompras();

  Future<void> guardarCompra(CompraModel compra) {
    return service.guardarCompra(compra);
  }

  Future<void> eliminarCompra(String id) {
    return service.eliminarCompra(id);
  }

  Future<int> obtenerProximoNumero() {
    return service.obtenerProximoNumero();
  }
}
