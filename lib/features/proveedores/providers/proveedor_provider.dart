import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/proveedor_cuenta_model.dart';
import '../services/proveedor_service.dart';
import '../state/proveedor_state.dart';

final proveedorProvider =
    StateNotifierProvider<ProveedorNotifier, ProveedorState>(
      (ref) => ProveedorNotifier(ProveedorService()),
    );

class ProveedorNotifier extends StateNotifier<ProveedorState> {
  final ProveedorService service;

  ProveedorNotifier(this.service) : super(const ProveedorState());

  Future<void> cargarProveedores() async {
    final proveedores = await service.obtenerProveedores();
    state = state.copyWith(proveedores: proveedores);
  }

  Future<void> guardarProveedor(ProveedorCuentaModel proveedor) async {
    await service.guardarProveedor(proveedor);
    await cargarProveedores();
  }

  Future<void> agregarMovimiento({
    required String proveedorId,
    required ProveedorMovimientoModel movimiento,
  }) async {
    final proveedores = state.proveedores.isEmpty
        ? await service.obtenerProveedores()
        : state.proveedores;
    final proveedor = proveedores.firstWhere(
      (item) => item.id == proveedorId,
      orElse: () => ProveedorCuentaModel(
        id: '',
        nombre: '',
        creado: DateTime.now(),
        actualizado: DateTime.now(),
      ),
    );

    if (proveedor.id.isEmpty) {
      return;
    }

    await service.guardarProveedor(
      proveedor.copyWith(
        movimientos: [...proveedor.movimientos, movimiento],
        actualizado: DateTime.now(),
      ),
    );
    await cargarProveedores();
  }

  void buscar(String texto) {
    state = state.copyWith(busqueda: texto);
  }
}
