import '../enums/cliente_filter.dart';
import '../models/cliente_model.dart';

class ClienteState {
  final List<ClienteModel> clientes;

  final bool loading;

  final String busqueda;

  final ClienteFilter filtro;

  const ClienteState({
    this.clientes = const [],
    this.loading = false,
    this.busqueda = '',
    this.filtro = ClienteFilter.todos,
  });

  ClienteState copyWith({
    List<ClienteModel>? clientes,
    bool? loading,
    String? busqueda,
    ClienteFilter? filtro,
  }) {
    return ClienteState(
      clientes: clientes ?? this.clientes,
      loading: loading ?? this.loading,
      busqueda: busqueda ?? this.busqueda,
      filtro: filtro ?? this.filtro,
    );
  }

  List<ClienteModel> get clientesFiltrados {
    Iterable<ClienteModel> resultado = clientes;    // ==========================
    // FILTRO POR TEXTO
    // ==========================

    if (busqueda.trim().isNotEmpty) {
      final texto = busqueda.toLowerCase();

      resultado = resultado.where(
        (cliente) =>
            cliente.nombre.toLowerCase().contains(texto) ||
            cliente.apellido.toLowerCase().contains(texto) ||
            cliente.telefono.toLowerCase().contains(texto) ||
            cliente.ciudad.toLowerCase().contains(texto) ||
            cliente.email.toLowerCase().contains(texto),
      );
    }

    // ==========================
    // FILTRO POR ESTADO
    // ==========================

    switch (filtro) {
      case ClienteFilter.todos:
        break;

      case ClienteFilter.activos:
        resultado = resultado.where(
          (cliente) => cliente.activo,
        );
        break;

      case ClienteFilter.inactivos:
        resultado = resultado.where(
          (cliente) => !cliente.activo,
        );
        break;
    }

    return resultado.toList();
  }
}