import '../models/proveedor_cuenta_model.dart';

class ProveedorState {
  final List<ProveedorCuentaModel> proveedores;
  final String busqueda;

  const ProveedorState({this.proveedores = const [], this.busqueda = ''});

  List<ProveedorCuentaModel> get filtrados {
    final texto = busqueda.trim().toLowerCase();
    if (texto.isEmpty) {
      return proveedores;
    }

    return proveedores.where((proveedor) {
      return proveedor.nombre.toLowerCase().contains(texto) ||
          proveedor.telefono.toLowerCase().contains(texto) ||
          proveedor.observaciones.toLowerCase().contains(texto);
    }).toList();
  }

  double get deudaTotal {
    return proveedores.fold(
      0,
      (total, proveedor) => total + proveedor.deudaTotal,
    );
  }

  int get conDeuda {
    return proveedores.where((proveedor) => proveedor.deudaTotal > 0).length;
  }

  ProveedorState copyWith({
    List<ProveedorCuentaModel>? proveedores,
    String? busqueda,
  }) {
    return ProveedorState(
      proveedores: proveedores ?? this.proveedores,
      busqueda: busqueda ?? this.busqueda,
    );
  }
}
