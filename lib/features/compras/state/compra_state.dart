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
