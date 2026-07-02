import '../models/servicio_model.dart';

class ServicioState {
  final List<ServicioModel> servicios;
  final String busqueda;
  final String filtroEstado;

  const ServicioState({
    this.servicios = const [],
    this.busqueda = '',
    this.filtroEstado = 'Todos',
  });

  List<ServicioModel> get serviciosFiltrados {
    final texto = busqueda.trim().toLowerCase();

    return servicios.where((servicio) {
      final coincideBusqueda =
          texto.isEmpty ||
          servicio.numero.toLowerCase().contains(texto) ||
          servicio.clienteNombre.toLowerCase().contains(texto) ||
          servicio.descripcion.toLowerCase().contains(texto) ||
          servicio.tecnico.toLowerCase().contains(texto);

      if (!coincideBusqueda) {
        return false;
      }

      if (filtroEstado == 'Todos') {
        return true;
      }

      return servicio.estado == filtroEstado;
    }).toList();
  }

  int get abiertos {
    return servicios.where((servicio) => servicio.estado != 'Entregado').length;
  }

  int get pendientes {
    return servicios.where((servicio) => servicio.estado == 'Pendiente').length;
  }

  int get listos {
    return servicios.where((servicio) => servicio.estado == 'Listo').length;
  }

  double get facturacion {
    return servicios
        .where((servicio) => servicio.cobrado)
        .fold(0, (total, servicio) => total + servicio.total);
  }

  ServicioState copyWith({
    List<ServicioModel>? servicios,
    String? busqueda,
    String? filtroEstado,
  }) {
    return ServicioState(
      servicios: servicios ?? this.servicios,
      busqueda: busqueda ?? this.busqueda,
      filtroEstado: filtroEstado ?? this.filtroEstado,
    );
  }
}
