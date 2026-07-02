import '../models/caja_movimiento_model.dart';
import '../models/caja_turno_model.dart';
import '../../../core/constants/branches.dart';

class CajaState {
  final List<CajaMovimientoModel> movimientos;
  final List<CajaTurnoModel> turnos;
  final String busqueda;
  final String filtroTipo;
  final String sucursalSeleccionada;

  const CajaState({
    this.movimientos = const [],
    this.turnos = const [],
    this.busqueda = '',
    this.filtroTipo = 'Todos',
    this.sucursalSeleccionada = Branches.casaCentral,
  });

  CajaTurnoModel? get turnoAbierto {
    return turnoAbiertoParaSucursal(sucursalSeleccionada);
  }

  CajaTurnoModel? turnoAbiertoParaSucursal(String sucursal) {
    for (final turno in turnos) {
      if (turno.abierta && turno.sucursal == sucursal) {
        return turno;
      }
    }

    return null;
  }

  bool get cajaAbierta => turnoAbierto != null;

  bool cajaAbiertaParaSucursal(String sucursal) {
    return turnoAbiertoParaSucursal(sucursal) != null;
  }

  List<CajaMovimientoModel> get movimientosTurnoActual {
    final turno = turnoAbierto;

    if (turno == null) {
      return const [];
    }

    return movimientos
        .where((movimiento) => movimiento.turnoId == turno.id)
        .toList();
  }

  List<CajaMovimientoModel> get _baseMovimientos {
    return cajaAbierta ? movimientosTurnoActual : const [];
  }

  List<CajaMovimientoModel> get movimientosFiltrados {
    final texto = busqueda.trim().toLowerCase();

    return _baseMovimientos.where((movimiento) {
      final coincideBusqueda =
          texto.isEmpty ||
          movimiento.concepto.toLowerCase().contains(texto) ||
          movimiento.medioPago.toLowerCase().contains(texto) ||
          movimiento.origen.toLowerCase().contains(texto) ||
          movimiento.responsable.toLowerCase().contains(texto);

      if (!coincideBusqueda) {
        return false;
      }

      if (filtroTipo == 'Todos') {
        return true;
      }

      return movimiento.tipo == filtroTipo;
    }).toList();
  }

  double get ingresos {
    return _baseMovimientos
        .where((movimiento) => movimiento.tipo == 'Ingreso')
        .fold(0, (total, movimiento) => total + movimiento.monto);
  }

  double get egresos {
    return _baseMovimientos
        .where((movimiento) => movimiento.tipo == 'Egreso')
        .fold(0, (total, movimiento) => total + movimiento.monto);
  }

  double get saldo => ingresos - egresos;

  double get saldoSistemaTurno {
    return (turnoAbierto?.saldoInicial ?? 0) + saldo;
  }

  double totalPorMedio(String medioPago) {
    return _baseMovimientos
        .where(
          (movimiento) =>
              movimiento.tipo == 'Ingreso' && movimiento.medioPago == medioPago,
        )
        .fold(0, (total, movimiento) => total + movimiento.monto);
  }

  CajaState copyWith({
    List<CajaMovimientoModel>? movimientos,
    List<CajaTurnoModel>? turnos,
    String? busqueda,
    String? filtroTipo,
    String? sucursalSeleccionada,
  }) {
    return CajaState(
      movimientos: movimientos ?? this.movimientos,
      turnos: turnos ?? this.turnos,
      busqueda: busqueda ?? this.busqueda,
      filtroTipo: filtroTipo ?? this.filtroTipo,
      sucursalSeleccionada: sucursalSeleccionada ?? this.sucursalSeleccionada,
    );
  }
}
