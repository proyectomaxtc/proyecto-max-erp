import '../../../core/result/result.dart';

import '../models/cliente_model.dart';
import '../services/cliente_service.dart';

class ClienteRepository {
  final ClienteService _service;

  const ClienteRepository({
    required ClienteService service,
  }) : _service = service;

  Future<Result<List<ClienteModel>>> obtenerClientes() async {
    try {
      final clientes = await _service.obtenerClientes();

      return Success(clientes);
    } catch (e) {
      return Failure(
        "No se pudieron obtener los clientes.",
        error: e,
      );
    }
  }

  Future<Result<void>> guardarCliente(
    ClienteModel cliente,
  ) async {
    try {
      await _service.guardarCliente(cliente);

      return const Success(null);
    } catch (e) {
      return Failure(
        "No se pudo guardar el cliente.",
        error: e,
      );
    }
  }

  Future<Result<void>> eliminarCliente(
    String id,
  ) async {
    try {
      await _service.eliminarCliente(id);

      return const Success(null);
    } catch (e) {
      return Failure(
        "No se pudo eliminar el cliente.",
        error: e,
      );
    }
  }
}