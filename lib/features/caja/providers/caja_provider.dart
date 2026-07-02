import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../servicios/services/servicio_service.dart';
import '../../ventas/services/venta_service.dart';
import '../models/caja_movimiento_model.dart';
import '../models/caja_turno_model.dart';
import '../repository/caja_repository.dart';
import '../services/caja_service.dart';
import '../state/caja_state.dart';

final cajaProvider = StateNotifierProvider<CajaNotifier, CajaState>((ref) {
  return CajaNotifier(
    CajaRepository(service: CajaService()),
    VentaService(),
    ServicioService(),
  );
});

class CajaNotifier extends StateNotifier<CajaState> {
  final CajaRepository repository;
  final VentaService ventaService;
  final ServicioService servicioService;

  CajaNotifier(this.repository, this.ventaService, this.servicioService)
    : super(const CajaState());

  Future<void> cargarMovimientos() async {
    final turnos = await repository.obtenerTurnos();
    var movimientos = await repository.obtenerMovimientos();

    final reparado = await _repararMovimientosVinculados(movimientos, turnos);
    if (reparado) {
      movimientos = await repository.obtenerMovimientos();
    }

    state = state.copyWith(movimientos: movimientos, turnos: turnos);
  }

  Future<void> agregarMovimiento(CajaMovimientoModel movimiento) async {
    await repository.guardarMovimiento(movimiento);
    await cargarMovimientos();
  }

  Future<void> eliminarMovimiento(String id) async {
    CajaMovimientoModel? movimiento;
    for (final item in state.movimientos) {
      if (item.id == id) {
        movimiento = item;
        break;
      }
    }

    if (movimiento != null && movimiento.origen != 'Manual') {
      return;
    }

    await repository.eliminarMovimiento(id);
    await cargarMovimientos();
  }

  Future<bool> _repararMovimientosVinculados(
    List<CajaMovimientoModel> movimientos,
    List<CajaTurnoModel> turnos,
  ) async {
    var reparado = false;
    final ventas = await ventaService.obtenerVentas();
    final servicios = await servicioService.obtenerServicios();
    final ventasIds = ventas.map((venta) => venta.id).toSet();
    final serviciosIds = servicios.map((servicio) => servicio.id).toSet();

    for (final movimiento in movimientos) {
      final ventaEliminada =
          movimiento.origen == 'Venta' &&
          movimiento.referenciaId.isNotEmpty &&
          !ventasIds.contains(movimiento.referenciaId);
      final servicioEliminado =
          movimiento.origen == 'Servicio' &&
          movimiento.referenciaId.isNotEmpty &&
          !serviciosIds.contains(movimiento.referenciaId);

      if (ventaEliminada || servicioEliminado) {
        await repository.eliminarMovimiento(movimiento.id);
        reparado = true;
      }
    }

    if (reparado) {
      movimientos = await repository.obtenerMovimientos();
    }

    for (final venta in ventas.where((venta) => venta.estado == 'Completada')) {
      final existe = movimientos.any(
        (movimiento) =>
            movimiento.origen == 'Venta' && movimiento.referenciaId == venta.id,
      );

      if (existe) {
        continue;
      }

      final turno = _turnoParaFecha(turnos, venta.fecha);

      await repository.guardarMovimiento(
        CajaMovimientoModel(
          id: '${venta.id}-caja',
          tipo: 'Ingreso',
          concepto: 'Venta ${venta.numero} - ${venta.clienteNombre}',
          monto: venta.total,
          medioPago: venta.medioPago,
          referenciaId: venta.id,
          origen: 'Venta',
          turnoId: turno?.id ?? '',
          responsable: turno?.responsable ?? 'Sistema',
          bloqueado: true,
          fecha: venta.fecha,
          observaciones: venta.observaciones,
        ),
      );
      reparado = true;
    }

    for (final servicio in servicios.where((servicio) => servicio.cobrado)) {
      final existe = movimientos.any(
        (movimiento) =>
            movimiento.origen == 'Servicio' &&
            movimiento.referenciaId == servicio.id,
      );

      if (existe) {
        continue;
      }

      final turno = _turnoParaFecha(turnos, servicio.creado);

      await repository.guardarMovimiento(
        CajaMovimientoModel(
          id: '${servicio.id}-caja',
          tipo: 'Ingreso',
          concepto: 'Servicio ${servicio.numero} - ${servicio.clienteNombre}',
          monto: servicio.total,
          medioPago: servicio.medioPago,
          referenciaId: servicio.id,
          origen: 'Servicio',
          turnoId: turno?.id ?? '',
          responsable: turno?.responsable ?? 'Sistema',
          bloqueado: true,
          fecha: servicio.creado,
          observaciones: servicio.observaciones,
        ),
      );
      reparado = true;
    }

    return reparado;
  }

  CajaTurnoModel? _turnoParaFecha(List<CajaTurnoModel> turnos, DateTime fecha) {
    for (final turno in turnos) {
      final despuesDeApertura =
          fecha.isAtSameMomentAs(turno.apertura) ||
          fecha.isAfter(turno.apertura);
      final antesDeCierre =
          turno.cierre == null ||
          fecha.isAtSameMomentAs(turno.cierre!) ||
          fecha.isBefore(turno.cierre!);

      if (despuesDeApertura && antesDeCierre) {
        return turno;
      }
    }

    return null;
  }

  Future<void> abrirCaja({
    required String sucursal,
    required String responsable,
    required double saldoInicial,
    required String observaciones,
  }) async {
    if (state.cajaAbiertaParaSucursal(sucursal)) {
      return;
    }

    final ahora = DateTime.now();

    await repository.guardarTurno(
      CajaTurnoModel(
        id: ahora.microsecondsSinceEpoch.toString(),
        sucursal: sucursal,
        responsable: responsable,
        apertura: ahora,
        cierre: null,
        saldoInicial: saldoInicial,
        saldoFinalDeclarado: null,
        saldoSistema: null,
        estado: 'Abierta',
        observaciones: observaciones,
      ),
    );

    await cargarMovimientos();
  }

  Future<void> cerrarCaja({
    required double saldoFinalDeclarado,
    required String observaciones,
  }) async {
    final turno = state.turnoAbierto;

    if (turno == null) {
      return;
    }

    await repository.guardarTurno(
      turno.copyWith(
        cierre: DateTime.now(),
        saldoFinalDeclarado: saldoFinalDeclarado,
        saldoSistema: state.saldoSistemaTurno,
        estado: 'Cerrada',
        observaciones: observaciones,
      ),
    );

    await cargarMovimientos();
  }

  void buscar(String texto) {
    state = state.copyWith(busqueda: texto);
  }

  void cambiarFiltro(String filtro) {
    state = state.copyWith(filtroTipo: filtro);
  }

  void cambiarSucursal(String sucursal) {
    state = state.copyWith(
      sucursalSeleccionada: sucursal,
      busqueda: '',
      filtroTipo: 'Todos',
    );
  }
}
