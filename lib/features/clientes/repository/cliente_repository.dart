import '../models/cliente_model.dart';
import '../services/cliente_service.dart';

class ClienteRepository {
  final ClienteService service;

  const ClienteRepository({
    required this.service,
  });

  Future<List<ClienteModel>> obtenerClientes() {
    return service.obtenerClientes();
  }

  Future<void> guardarCliente(
    ClienteModel cliente,
  ) {
    return service.guardarCliente(cliente);
  }

  Future<void> actualizarCliente(
    ClienteModel cliente,
  ) {
    return service.actualizarCliente(cliente);
  }

  Future<void> eliminarCliente(
    String id,
  ) {
    return service.eliminarCliente(id);
  }
}