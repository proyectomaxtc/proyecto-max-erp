class CajaMovimientoModel {
  final String id;
  final String tipo;
  final String concepto;
  final double monto;
  final String medioPago;
  final String referenciaId;
  final String origen;
  final String turnoId;
  final String responsable;
  final bool bloqueado;
  final DateTime fecha;
  final String observaciones;

  const CajaMovimientoModel({
    required this.id,
    required this.tipo,
    required this.concepto,
    required this.monto,
    required this.medioPago,
    required this.referenciaId,
    required this.origen,
    required this.turnoId,
    required this.responsable,
    this.bloqueado = true,
    required this.fecha,
    required this.observaciones,
  });

  bool get esIngreso => tipo == 'Ingreso';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo,
      'concepto': concepto,
      'monto': monto,
      'medioPago': medioPago,
      'referenciaId': referenciaId,
      'origen': origen,
      'turnoId': turnoId,
      'responsable': responsable,
      'bloqueado': bloqueado,
      'fecha': fecha.toIso8601String(),
      'observaciones': observaciones,
    };
  }

  factory CajaMovimientoModel.fromMap(Map<dynamic, dynamic> map) {
    return CajaMovimientoModel(
      id: map['id'] as String? ?? '',
      tipo: map['tipo'] as String? ?? 'Ingreso',
      concepto: map['concepto'] as String? ?? '',
      monto: (map['monto'] as num?)?.toDouble() ?? 0,
      medioPago: map['medioPago'] as String? ?? 'Efectivo',
      referenciaId: map['referenciaId'] as String? ?? '',
      origen: map['origen'] as String? ?? 'Manual',
      turnoId: map['turnoId'] as String? ?? '',
      responsable: map['responsable'] as String? ?? '',
      bloqueado: map['bloqueado'] as bool? ?? true,
      fecha: DateTime.tryParse(map['fecha'] as String? ?? '') ?? DateTime.now(),
      observaciones: map['observaciones'] as String? ?? '',
    );
  }
}
