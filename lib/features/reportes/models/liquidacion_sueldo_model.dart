import '../../../core/constants/branches.dart';

class LiquidacionSueldoModel {
  final String id;
  final String empleado;
  final String sucursal;
  final double monto;
  final DateTime periodoDesde;
  final DateTime periodoHasta;
  final DateTime fechaPago;
  final String medioPago;
  final String observaciones;

  const LiquidacionSueldoModel({
    required this.id,
    required this.empleado,
    this.sucursal = Branches.casaCentral,
    required this.monto,
    required this.periodoDesde,
    required this.periodoHasta,
    required this.fechaPago,
    this.medioPago = 'Efectivo',
    this.observaciones = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'empleado': empleado,
      'sucursal': sucursal,
      'monto': monto,
      'periodoDesde': periodoDesde.toIso8601String(),
      'periodoHasta': periodoHasta.toIso8601String(),
      'fechaPago': fechaPago.toIso8601String(),
      'medioPago': medioPago,
      'observaciones': observaciones,
    };
  }

  factory LiquidacionSueldoModel.fromMap(Map<dynamic, dynamic> map) {
    return LiquidacionSueldoModel(
      id: map['id'] as String? ?? '',
      empleado: map['empleado'] as String? ?? '',
      sucursal: map['sucursal'] as String? ?? Branches.casaCentral,
      monto: (map['monto'] as num?)?.toDouble() ?? 0,
      periodoDesde:
          DateTime.tryParse(map['periodoDesde'] as String? ?? '') ??
          DateTime.now(),
      periodoHasta:
          DateTime.tryParse(map['periodoHasta'] as String? ?? '') ??
          DateTime.now(),
      fechaPago:
          DateTime.tryParse(map['fechaPago'] as String? ?? '') ??
          DateTime.now(),
      medioPago: map['medioPago'] as String? ?? 'Efectivo',
      observaciones: map['observaciones'] as String? ?? '',
    );
  }

  LiquidacionSueldoModel copyWith({
    String? id,
    String? empleado,
    String? sucursal,
    double? monto,
    DateTime? periodoDesde,
    DateTime? periodoHasta,
    DateTime? fechaPago,
    String? medioPago,
    String? observaciones,
  }) {
    return LiquidacionSueldoModel(
      id: id ?? this.id,
      empleado: empleado ?? this.empleado,
      sucursal: sucursal ?? this.sucursal,
      monto: monto ?? this.monto,
      periodoDesde: periodoDesde ?? this.periodoDesde,
      periodoHasta: periodoHasta ?? this.periodoHasta,
      fechaPago: fechaPago ?? this.fechaPago,
      medioPago: medioPago ?? this.medioPago,
      observaciones: observaciones ?? this.observaciones,
    );
  }
}
