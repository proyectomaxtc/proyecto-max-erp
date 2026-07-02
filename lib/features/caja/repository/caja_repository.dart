import '../models/caja_movimiento_model.dart';
import '../models/caja_turno_model.dart';
import '../services/caja_service.dart';

class CajaRepository {
  final CajaService service;

  const CajaRepository({required this.service});

  Future<List<CajaMovimientoModel>> obtenerMovimientos() {
    return service.obtenerMovimientos();
  }

  Future<void> guardarMovimiento(CajaMovimientoModel movimiento) {
    return service.guardarMovimiento(movimiento);
  }

  Future<void> eliminarMovimiento(String id) {
    return service.eliminarMovimiento(id);
  }

  Future<List<CajaTurnoModel>> obtenerTurnos() {
    return service.obtenerTurnos();
  }

  Future<void> guardarTurno(CajaTurnoModel turno) {
    return service.guardarTurno(turno);
  }
}
