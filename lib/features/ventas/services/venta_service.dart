import 'package:hive/hive.dart';

import '../../../core/storage/cloud_json_store.dart';
import '../../../core/storage/storage_boxes.dart';
import '../../../core/storage/storage_service.dart';
import '../models/venta_model.dart';

class VentaService {
  Box get _box => StorageService.box(StorageBoxes.ventas);
  Box get _cajaBox => StorageService.box(StorageBoxes.caja);

  Future<List<VentaModel>> obtenerVentas() async {
    final values = await CloudJsonStore.syncBox(
      table: StorageBoxes.ventas,
      box: _box,
    );

    return values.map(VentaModel.fromMap).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  Future<void> guardarVenta(VentaModel venta) async {
    final data = venta.toMap();
    final guardada = await CloudJsonStore.save(
      table: StorageBoxes.ventas,
      id: venta.id,
      data: data,
    );

    if (CloudJsonStore.enabled && !guardada) {
      throw Exception(
        'No se pudo guardar la venta en la nube. Revise conexion o sesion e intente nuevamente.',
      );
    }

    await _box.put(venta.id, data);
  }

  Future<void> eliminarVenta(String id) async {
    final ventaEliminada = await CloudJsonStore.deleteVentaWithCaja(id);

    if (CloudJsonStore.enabled && !ventaEliminada) {
      throw Exception(
        'Supabase no permitio eliminar la venta. Revise permisos de propietario.',
      );
    }

    await _box.delete(id);
    await _cajaBox.delete('$id-caja');
  }

  Future<int> obtenerProximoNumero() async {
    final ventas = await obtenerVentas();

    if (ventas.isEmpty) {
      return 1;
    }

    var mayor = 0;

    for (final venta in ventas) {
      final numero = int.tryParse(venta.numero.split('-').last) ?? 0;

      if (numero > mayor) {
        mayor = numero;
      }
    }

    return mayor + 1;
  }
}
