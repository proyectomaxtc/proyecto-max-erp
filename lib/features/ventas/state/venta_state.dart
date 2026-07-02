import '../../../core/constants/branches.dart';
import '../models/venta_model.dart';

class VentaState {
  final List<VentaModel> ventas;
  final String busqueda;
  final String filtroEstado;
  final String filtroSucursal;

  const VentaState({
    this.ventas = const [],
    this.busqueda = '',
    this.filtroEstado = 'Todas',
    this.filtroSucursal = Branches.casaCentral,
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
  }) {
    return VentaState(
      ventas: ventas ?? this.ventas,
      busqueda: busqueda ?? this.busqueda,
      filtroEstado: filtroEstado ?? this.filtroEstado,
      filtroSucursal: filtroSucursal ?? this.filtroSucursal,
    );
  }
}
