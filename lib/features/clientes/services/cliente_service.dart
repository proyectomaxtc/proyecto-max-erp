import '../models/cliente_model.dart';

class ClienteService {
  Future<List<ClienteModel>> obtenerClientes() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return [];
  }

  Future<void> guardarCliente(ClienteModel cliente) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> eliminarCliente(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}