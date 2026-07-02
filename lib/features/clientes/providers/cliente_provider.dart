import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../enums/cliente_filter.dart';
import '../models/cliente_model.dart';
import '../repository/cliente_repository.dart';
import '../services/cliente_service.dart';
import '../state/cliente_state.dart';

final clienteProvider =
    StateNotifierProvider<ClienteNotifier, ClienteState>(
  (ref) {
    return ClienteNotifier(
      ClienteRepository(
        service: ClienteService(),
      ),
    );
  },
);

class ClienteNotifier extends StateNotifier<ClienteState> {
  final ClienteRepository repository;

  ClienteNotifier(this.repository)
      : super(const ClienteState());

  Future<void> cargarClientes() async {
    final clientes =
        await repository.obtenerClientes();

    state = state.copyWith(
      clientes: clientes,
    );
  }

  Future<void> agregarCliente(
    ClienteModel cliente,
  ) async {
    await repository.guardarCliente(cliente);

    await cargarClientes();
  }
Future<void> actualizarCliente(
  ClienteModel cliente,
) async {
  await repository.actualizarCliente(cliente);

  await cargarClientes();
}
  Future<void> eliminarCliente(
    String id,
  ) async {
    await repository.eliminarCliente(id);

    await cargarClientes();
  }

  void buscar(
    String texto,
  ) {
    state = state.copyWith(
      busqueda: texto,
    );
  }

  void cambiarFiltro(
    ClienteFilter filtro,
  ) {
    state = state.copyWith(
      filtro: filtro,
    );
  }
}