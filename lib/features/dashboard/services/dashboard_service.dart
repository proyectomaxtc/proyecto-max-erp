import '../../../core/storage/storage_boxes.dart';
import '../../../core/storage/cloud_json_store.dart';
import '../../../core/storage/storage_service.dart';
import '../../caja/models/caja_movimiento_model.dart';
import '../../caja/models/caja_turno_model.dart';
import '../../compras/models/compra_model.dart';
import '../../clientes/models/cliente_model.dart';
import '../../productos/models/producto_model.dart';
import '../../servicios/models/servicio_model.dart';
import '../../ventas/models/venta_model.dart';
import '../models/dashboard_stats.dart';

class DashboardService {
  Future<DashboardStats> loadDashboard() async {
    final movimientos = await _readBox(
      StorageBoxes.caja,
      CajaMovimientoModel.fromMap,
    );
    final turnos = await _readBox(
      StorageBoxes.cajaTurnos,
      CajaTurnoModel.fromMap,
    );
    final ventas = await _readBox(StorageBoxes.ventas, VentaModel.fromMap);
    final compras = await _readBox(StorageBoxes.compras, CompraModel.fromMap);
    final productos = await _readBox(
      StorageBoxes.productos,
      ProductoModel.fromMap,
    );
    final servicios = await _readBox(
      StorageBoxes.servicios,
      ServicioModel.fromMap,
    );
    final clientes = await _readBox(
      StorageBoxes.clientes,
      ClienteModel.fromMap,
    );

    final hoy = DateTime.now();
    final inicioMes = DateTime(hoy.year, hoy.month);
    final finMes = DateTime(hoy.year, hoy.month + 1);
    final saldoCaja = _saldoCajasAbiertas(turnos, movimientos);
    final ventasCompletadas = ventas.where(
      (venta) =>
          venta.estado == 'Completada' &&
          _inPeriod(venta.fecha, inicioMes, finMes),
    );
    final comprasRecibidas = compras.where(
      (compra) =>
          compra.estado == 'Recibida' &&
          _inPeriod(compra.fecha, inicioMes, finMes),
    );

    return DashboardStats(
      cash: saldoCaja,
      sales: ventasCompletadas.fold<double>(
        0,
        (total, venta) => total + venta.total,
      ),
      purchases: comprasRecibidas.fold<double>(
        0,
        (total, compra) => total + compra.total,
      ),
      profit: ventasCompletadas.fold<double>(
        0,
        (total, venta) => total + venta.rentabilidad,
      ),
      periodStart: inicioMes,
      periodEnd: finMes,
      lowStockProducts: productos
          .where(
            (producto) =>
                producto.activo &&
                producto.stock > 0 &&
                producto.stock <= producto.stockMinimo,
          )
          .length,
      pendingServices: servicios
          .where((servicio) => servicio.estado != 'Entregado')
          .length,
      todayCustomers: clientes
          .where(
            (cliente) =>
                cliente.id != ClienteModel.consumidorFinalId &&
                _sameDay(cliente.creado, hoy),
          )
          .length,
    );
  }

  Future<List<T>> _readBox<T>(
    String boxName,
    T Function(Map<dynamic, dynamic> map) fromMap,
  ) async {
    final box = StorageService.box(boxName);
    final values = await CloudJsonStore.syncBox(table: boxName, box: box);

    return values.map(fromMap).toList();
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _inPeriod(DateTime date, DateTime start, DateTime end) {
    return !date.isBefore(start) && date.isBefore(end);
  }

  double _saldoCajasAbiertas(
    List<CajaTurnoModel> turnos,
    List<CajaMovimientoModel> movimientos,
  ) {
    final turnosAbiertos = turnos.where((turno) => turno.abierta).toList();

    return turnosAbiertos.fold<double>(0, (total, turno) {
      final movimientosTurno = movimientos.where(
        (movimiento) => movimiento.turnoId == turno.id,
      );
      final ingresos = movimientosTurno
          .where((movimiento) => movimiento.tipo == 'Ingreso')
          .fold<double>(0, (sum, movimiento) => sum + movimiento.monto);
      final egresos = movimientosTurno
          .where((movimiento) => movimiento.tipo == 'Egreso')
          .fold<double>(0, (sum, movimiento) => sum + movimiento.monto);

      return total + turno.saldoInicial + ingresos - egresos;
    });
  }
}
