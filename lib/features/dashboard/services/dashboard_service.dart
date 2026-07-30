import '../../../core/storage/storage_boxes.dart';
import '../../../core/storage/cloud_json_store.dart';
import '../../../core/storage/storage_service.dart';
import '../../caja/models/caja_movimiento_model.dart';
import '../../caja/models/caja_turno_model.dart';
import '../../compras/models/compra_model.dart';
import '../../clientes/models/cliente_model.dart';
import '../../productos/models/producto_model.dart';
import '../../servicios/models/servicio_model.dart';
import '../../auth/models/app_user_model.dart';
import '../../ventas/models/venta_model.dart';
import '../models/dashboard_stats.dart';

class DashboardService {
  Future<DashboardStats> loadDashboard({bool syncCloud = true}) async {
    final movimientos = await _readBox(
      StorageBoxes.caja,
      CajaMovimientoModel.fromMap,
      syncCloud: syncCloud,
    );
    final turnos = await _readBox(
      StorageBoxes.cajaTurnos,
      CajaTurnoModel.fromMap,
      syncCloud: syncCloud,
    );
    final ventas = await _readBox(
      StorageBoxes.ventas,
      VentaModel.fromMap,
      syncCloud: syncCloud,
    );
    final compras = await _readBox(
      StorageBoxes.compras,
      CompraModel.fromMap,
      syncCloud: syncCloud,
    );
    final productos = await _readBox(
      StorageBoxes.productos,
      ProductoModel.fromMap,
      syncCloud: syncCloud,
    );
    final servicios = await _readBox(
      StorageBoxes.servicios,
      ServicioModel.fromMap,
      syncCloud: syncCloud,
    );
    final clientes = await _readBox(
      StorageBoxes.clientes,
      ClienteModel.fromMap,
      syncCloud: syncCloud,
    );
    final usuarios = await _readBox(
      StorageBoxes.usuarios,
      AppUserModel.fromMap,
      syncCloud: syncCloud,
    );

    final hoy = DateTime.now();
    final inicioMes = DateTime(hoy.year, hoy.month);
    final finMes = DateTime(hoy.year, hoy.month + 1);
    final saldoCaja = _saldoCajasAbiertas(turnos, movimientos);
    final ventasCompletadas = ventas.where(
      (venta) =>
          venta.estado == 'Completada' &&
          _inPeriod(venta.fecha, inicioMes, finMes),
    ).toList();
    final comprasRecibidas = compras.where(
      (compra) =>
          compra.estado == 'Recibida' &&
          _inPeriod(compra.fecha, inicioMes, finMes),
    );
    final totalVentas = ventasCompletadas.fold<double>(
      0,
      (total, venta) => total + venta.total,
    );
    final utilidadVentas = ventasCompletadas.fold<double>(
      0,
      (total, venta) => total + venta.rentabilidad,
    );

    return DashboardStats(
      cash: saldoCaja,
      sales: totalVentas,
      purchases: comprasRecibidas.fold<double>(
        0,
        (total, compra) => total + compra.total,
      ),
      profit: utilidadVentas,
      salesCount: ventasCompletadas.length,
      averageTicket: ventasCompletadas.isEmpty
          ? 0
          : totalVentas / ventasCompletadas.length,
      periodStart: inicioMes,
      periodEnd: finMes,
      employeePerformance: _employeePerformance(
        ventasCompletadas,
        movimientos,
        usuarios,
        inicioMes,
        finMes,
      ),
      branchPerformance: _branchPerformance(ventasCompletadas),
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
    T Function(Map<dynamic, dynamic> map) fromMap, {
    required bool syncCloud,
  }) async {
    final box = StorageService.box(boxName);
    final values = syncCloud
        ? await CloudJsonStore.syncBox(table: boxName, box: box)
        : box.values
              .whereType<Map>()
              .map((value) => Map<dynamic, dynamic>.from(value))
              .toList();

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

  List<EmployeePerformance> _employeePerformance(
    List<VentaModel> ventas,
    List<CajaMovimientoModel> movimientos,
    List<AppUserModel> usuarios,
    DateTime start,
    DateTime end,
  ) {
    final ventasPorId = {for (final venta in ventas) venta.id: venta};
    final empleados = <String, _EmployeeAccumulator>{};
    final usuariosPorNombre = {
      for (final usuario in usuarios) _normalize(usuario.nombre): usuario,
    };

    for (final usuario in usuarios.where(
      (usuario) => usuario.activo && !usuario.esPropietario,
    )) {
      empleados[_normalize(usuario.nombre)] = _EmployeeAccumulator(
        name: usuario.nombre,
        branch: usuario.sucursal,
      );
    }

    final movimientosVenta = movimientos.where(
      (movimiento) =>
          movimiento.origen == 'Venta' &&
          movimiento.tipo == 'Ingreso' &&
          _inPeriod(movimiento.fecha, start, end),
    );

    for (final movimiento in movimientosVenta) {
      final venta = ventasPorId[movimiento.referenciaId];
      final responsable = movimiento.responsable.trim().isEmpty
          ? 'Sin responsable'
          : movimiento.responsable.trim();
      final key = _normalize(responsable);
      final usuario = usuariosPorNombre[key];
      final accumulator = empleados.putIfAbsent(
        key,
        () => _EmployeeAccumulator(
          name: responsable,
          branch: usuario?.sucursal ?? venta?.sucursal ?? '',
        ),
      );

      accumulator.salesCount++;
      accumulator.salesTotal += movimiento.monto;
      accumulator.profitTotal += venta?.rentabilidad ?? 0;
    }

    final result = empleados.values
        .map(
          (item) => EmployeePerformance(
            name: item.name,
            branch: item.branch,
            salesCount: item.salesCount,
            salesTotal: item.salesTotal,
            profitTotal: item.profitTotal,
          ),
        )
        .toList();

    result.sort((a, b) => b.salesTotal.compareTo(a.salesTotal));
    return result;
  }

  List<BranchPerformance> _branchPerformance(List<VentaModel> ventas) {
    final data = <String, _BranchAccumulator>{};

    for (final venta in ventas) {
      final accumulator = data.putIfAbsent(
        venta.sucursal,
        () => _BranchAccumulator(branch: venta.sucursal),
      );
      accumulator.salesCount++;
      accumulator.salesTotal += venta.total;
      accumulator.profitTotal += venta.rentabilidad;
    }

    final result = data.values
        .map(
          (item) => BranchPerformance(
            branch: item.branch,
            salesCount: item.salesCount,
            salesTotal: item.salesTotal,
            profitTotal: item.profitTotal,
          ),
        )
        .toList();

    result.sort((a, b) => b.salesTotal.compareTo(a.salesTotal));
    return result;
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}

class _EmployeeAccumulator {
  final String name;
  final String branch;
  int salesCount = 0;
  double salesTotal = 0;
  double profitTotal = 0;

  _EmployeeAccumulator({required this.name, required this.branch});
}

class _BranchAccumulator {
  final String branch;
  int salesCount = 0;
  double salesTotal = 0;
  double profitTotal = 0;

  _BranchAccumulator({required this.branch});
}
