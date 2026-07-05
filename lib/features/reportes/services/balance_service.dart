import 'package:hive/hive.dart';

import '../../../core/constants/branches.dart';
import '../../../core/storage/cloud_json_store.dart';
import '../../../core/storage/storage_boxes.dart';
import '../../../core/storage/storage_service.dart';
import '../../compras/models/compra_model.dart';
import '../../ventas/models/venta_model.dart';
import '../models/balance_gasto_model.dart';
import '../models/balance_mensual_model.dart';
import '../models/liquidacion_sueldo_model.dart';

class BalanceService {
  Box get _gastosBox => StorageService.box(StorageBoxes.gastosBalance);
  Box get _sueldosBox => StorageService.box(StorageBoxes.liquidacionesSueldos);
  Box get _ventasBox => StorageService.box(StorageBoxes.ventas);
  Box get _comprasBox => StorageService.box(StorageBoxes.compras);

  Future<List<BalanceGastoModel>> obtenerGastos() async {
    final values = await CloudJsonStore.syncBox(
      table: StorageBoxes.gastosBalance,
      box: _gastosBox,
    );

    return values.map(BalanceGastoModel.fromMap).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  Future<List<LiquidacionSueldoModel>> obtenerLiquidaciones() async {
    final values = await CloudJsonStore.syncBox(
      table: StorageBoxes.liquidacionesSueldos,
      box: _sueldosBox,
    );

    return values.map(LiquidacionSueldoModel.fromMap).toList()
      ..sort((a, b) => b.fechaPago.compareTo(a.fechaPago));
  }

  Future<void> guardarGasto(BalanceGastoModel gasto) async {
    await _gastosBox.put(gasto.id, gasto.toMap());
    await CloudJsonStore.save(
      table: StorageBoxes.gastosBalance,
      id: gasto.id,
      data: gasto.toMap(),
    );
  }

  Future<void> guardarLiquidacion(LiquidacionSueldoModel liquidacion) async {
    await _sueldosBox.put(liquidacion.id, liquidacion.toMap());
    await CloudJsonStore.save(
      table: StorageBoxes.liquidacionesSueldos,
      id: liquidacion.id,
      data: liquidacion.toMap(),
    );
  }

  Future<List<BalanceMensualModel>> obtenerBalancesMensuales() async {
    final ventas = await _readVentas();
    final compras = await _readCompras();
    final gastos = await obtenerGastos();
    final sueldos = await obtenerLiquidaciones();
    final periodos = <DateTime>{};

    for (final venta in ventas) {
      periodos.add(_periodo(venta.fecha));
    }
    for (final compra in compras) {
      periodos.add(_periodo(compra.fecha));
    }
    for (final gasto in gastos) {
      periodos.add(_periodo(gasto.fecha));
    }
    for (final sueldo in sueldos) {
      periodos.add(_periodo(sueldo.fechaPago));
    }
    periodos.add(_periodo(DateTime.now()));

    final balances = <BalanceMensualModel>[];

    for (final periodo in periodos) {
      for (final sucursal in Branches.values) {
        final inicio = periodo;
        final fin = DateTime(periodo.year, periodo.month + 1);
        final ventasMes = ventas.where(
          (venta) =>
              venta.estado == 'Completada' &&
              venta.sucursal == sucursal &&
              _inPeriod(venta.fecha, inicio, fin),
        );
        final comprasMes = compras.where(
          (compra) =>
              compra.estado == 'Recibida' &&
              compra.sucursal == sucursal &&
              _inPeriod(compra.fecha, inicio, fin),
        );
        final gastosMes = gastos.where(
          (gasto) =>
              _aplicaSucursal(gasto.sucursal, sucursal) &&
              _inPeriod(gasto.fecha, inicio, fin),
        );
        final sueldosMes = sueldos.where(
          (sueldo) =>
              sueldo.sucursal == sucursal &&
              _inPeriod(sueldo.fechaPago, inicio, fin),
        );

        balances.add(
          BalanceMensualModel(
            periodo: periodo,
            sucursal: sucursal,
            ventas: ventasMes.fold(0, (total, venta) => total + venta.total),
            costoVentas: ventasMes.fold(
              0,
              (total, venta) => total + venta.costoTotal,
            ),
            compras: comprasMes.fold(
              0,
              (total, compra) => total + compra.total,
            ),
            gastos: gastosMes.fold(
              0,
              (total, gasto) => total + _montoGastoParaSucursal(gasto),
            ),
            sueldos: sueldosMes.fold(
              0,
              (total, sueldo) => total + sueldo.monto,
            ),
            cantidadVentas: ventasMes.length,
            cantidadCompras: comprasMes.length,
          ),
        );
      }
    }

    return balances..sort((a, b) {
      final byPeriod = b.periodo.compareTo(a.periodo);
      if (byPeriod != 0) {
        return byPeriod;
      }
      return a.sucursal.compareTo(b.sucursal);
    });
  }

  Future<List<VentaModel>> _readVentas() async {
    final values = await CloudJsonStore.syncBox(
      table: StorageBoxes.ventas,
      box: _ventasBox,
    );

    return values.map(VentaModel.fromMap).toList();
  }

  Future<List<CompraModel>> _readCompras() async {
    final values = await CloudJsonStore.syncBox(
      table: StorageBoxes.compras,
      box: _comprasBox,
    );

    return values.map(CompraModel.fromMap).toList();
  }

  DateTime _periodo(DateTime fecha) {
    return DateTime(fecha.year, fecha.month);
  }

  bool _inPeriod(DateTime date, DateTime start, DateTime end) {
    return !date.isBefore(start) && date.isBefore(end);
  }

  bool _aplicaSucursal(String gastoSucursal, String sucursal) {
    return gastoSucursal == sucursal || gastoSucursal == Branches.ambas;
  }

  double _montoGastoParaSucursal(BalanceGastoModel gasto) {
    if (gasto.sucursal == Branches.ambas) {
      return gasto.monto / Branches.values.length;
    }

    return gasto.monto;
  }
}
