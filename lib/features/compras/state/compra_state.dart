import '../models/compra_model.dart';

class CompraState {
  final List<CompraModel> compras;
  final String busqueda;
  final String filtroEstado;

  const CompraState({
    this.compras = const [],
    this.busqueda = '',
    this.filtroEstado = 'Todas',
  });

  List<CompraModel> get comprasFiltradas {
    final texto = busqueda.trim().toLowerCase();

    return compras.where((compra) {
      final coincideBusqueda =
          texto.isEmpty ||
          compra.numero.toLowerCase().contains(texto) ||
          compra.proveedor.toLowerCase().contains(texto) ||
          compra.responsable.toLowerCase().contains(texto);

      if (!coincideBusqueda) {
        return false;
      }

      if (filtroEstado == 'Todas') {
        return true;
      }

      return compra.estado == filtroEstado;
    }).toList();
  }

  double get totalComprado {
    return compras.fold(0, (total, compra) => total + compra.total);
  }

  int get recibidas {
    return compras.where((compra) => compra.estado == 'Recibida').length;
  }

  double get totalTransportes {
    return compras.fold(0, (total, compra) => total + compra.transporteCosto);
  }

  double get deudaTotal {
    return compras.fold(0, (total, compra) => total + compra.saldoPendiente);
  }

  int get proveedoresConDeuda {
    return deudaPorProveedor.keys.length;
  }

  Map<String, double> get deudaPorProveedor {
    final deuda = <String, double>{};

    for (final compra in compras) {
      if (!compra.tieneDeuda) {
        continue;
      }

      final proveedor = compra.proveedor.trim().isEmpty
          ? 'Sin proveedor'
          : compra.proveedor.trim();
      deuda[proveedor] = (deuda[proveedor] ?? 0) + compra.saldoPendiente;
    }

    return deuda;
  }

  CompraState copyWith({
    List<CompraModel>? compras,
    String? busqueda,
    String? filtroEstado,
  }) {
    return CompraState(
      compras: compras ?? this.compras,
      busqueda: busqueda ?? this.busqueda,
      filtroEstado: filtroEstado ?? this.filtroEstado,
    );
  }
}
