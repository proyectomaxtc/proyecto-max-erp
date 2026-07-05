import '../../../core/constants/branches.dart';
import '../models/venta_model.dart';

class VentaState {
  final List<VentaModel> ventas;
  final String busqueda;
  final String filtroEstado;
  final String filtroSucursal;
  final DateTime? fechaDesde;
  final DateTime? fechaHasta;

  const VentaState({
    this.ventas = const [],
    this.busqueda = '',
    this.filtroEstado = 'Todas',
    this.filtroSucursal = Branches.casaCentral,
    this.fechaDesde,
    this.fechaHasta,
  });

  List<VentaModel> get ventasPorSucursal {
    return ventas.where((venta) {
      return venta.sucursal == filtroSucursal;
    }).toList();
  }

  List<VentaModel> get ventasFiltradas {
    final texto = busqueda.trim().toLowerCase();

    return ventasPorSucursal.where((venta) {
      final coincideBusqueda =
          texto.isEmpty ||
          venta.numero.toLowerCase().contains(texto) ||
          venta.clienteNombre.toLowerCase().contains(texto) ||
          venta.medioPago.toLowerCase().contains(texto);

      if (!coincideBusqueda) {
        return false;
      }

      if (fechaDesde != null && venta.fecha.isBefore(_inicioDia(fechaDesde!))) {
        return false;
      }

      if (fechaHasta != null && venta.fecha.isAfter(_finDia(fechaHasta!))) {
        return false;
      }

      if (filtroEstado == 'Todas') {
        return true;
      }

      return venta.estado == filtroEstado;
    }).toList();
  }

  double get totalVendido {
    return ventasPorSucursal.fold(0, (total, venta) => total + venta.total);
  }

  double get rentabilidad {
    return ventasPorSucursal.fold(
      0,
      (total, venta) => total + venta.rentabilidad,
    );
  }

  int get ventasCompletadas {
    return ventasPorSucursal
        .where((venta) => venta.estado == 'Completada')
        .length;
  }

  VentaState copyWith({
    List<VentaModel>? ventas,
    String? busqueda,
    String? filtroEstado,
    String? filtroSucursal,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    bool limpiarFechas = false,
  }) {
    return VentaState(
      ventas: ventas ?? this.ventas,
      busqueda: busqueda ?? this.busqueda,
      filtroEstado: filtroEstado ?? this.filtroEstado,
      filtroSucursal: filtroSucursal ?? this.filtroSucursal,
      fechaDesde: limpiarFechas ? null : fechaDesde ?? this.fechaDesde,
      fechaHasta: limpiarFechas ? null : fechaHasta ?? this.fechaHasta,
    );
  }

  DateTime _inicioDia(DateTime fecha) {
    return DateTime(fecha.year, fecha.month, fecha.day);
  }

  DateTime _finDia(DateTime fecha) {
    return DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59, 999);
  }
}
