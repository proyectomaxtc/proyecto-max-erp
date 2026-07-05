class BalanceMensualModel {
  final DateTime periodo;
  final String sucursal;
  final double ventas;
  final double costoVentas;
  final double compras;
  final double gastos;
  final double sueldos;
  final int cantidadVentas;
  final int cantidadCompras;

  const BalanceMensualModel({
    required this.periodo,
    required this.sucursal,
    required this.ventas,
    required this.costoVentas,
    required this.compras,
    required this.gastos,
    required this.sueldos,
    required this.cantidadVentas,
    required this.cantidadCompras,
  });

  double get utilidadBruta => ventas - costoVentas;

  double get utilidadNeta => utilidadBruta - gastos - sueldos;

  double get egresosOperativos => gastos + sueldos;
}
