import '../../../core/constants/branches.dart';

class BalanceGastoModel {
  final String id;
  final String sucursal;
  final String categoria;
  final String concepto;
  final double monto;
  final String medioPago;
  final DateTime fecha;
  final String observaciones;

  const BalanceGastoModel({
    required this.id,
    this.sucursal = Branches.casaCentral,
    required this.categoria,
    required this.concepto,
    required this.monto,
    this.medioPago = 'Efectivo',
    required this.fecha,
    this.observaciones = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sucursal': sucursal,
      'categoria': categoria,
      'concepto': concepto,
      'monto': monto,
      'medioPago': medioPago,
      'fecha': fecha.toIso8601String(),
      'observaciones': observaciones,
    };
  }

  factory BalanceGastoModel.fromMap(Map<dynamic, dynamic> map) {
    return BalanceGastoModel(
      id: map['id'] as String? ?? '',
      sucursal: map['sucursal'] as String? ?? Branches.casaCentral,
      categoria: map['categoria'] as String? ?? 'Otros',
      concepto: map['concepto'] as String? ?? '',
      monto: (map['monto'] as num?)?.toDouble() ?? 0,
      medioPago: map['medioPago'] as String? ?? 'Efectivo',
      fecha: DateTime.tryParse(map['fecha'] as String? ?? '') ?? DateTime.now(),
      observaciones: map['observaciones'] as String? ?? '',
    );
  }
}
