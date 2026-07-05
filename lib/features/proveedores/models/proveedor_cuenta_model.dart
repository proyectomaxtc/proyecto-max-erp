class ProveedorCuentaModel {
  final String id;
  final String nombre;
  final String telefono;
  final String observaciones;
  final bool activo;
  final List<ProveedorMovimientoModel> movimientos;
  final DateTime creado;
  final DateTime actualizado;

  const ProveedorCuentaModel({
    required this.id,
    required this.nombre,
    this.telefono = '',
    this.observaciones = '',
    this.activo = true,
    this.movimientos = const [],
    required this.creado,
    required this.actualizado,
  });

  double get deudaTotal {
    final deuda = movimientos.fold<double>(0, (total, movimiento) {
      if (movimiento.tipo == ProveedorMovimientoTipo.deuda) {
        return total + movimiento.monto;
      }
      return total - movimiento.monto;
    });

    return deuda < 0 ? 0 : deuda;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'observaciones': observaciones,
      'activo': activo,
      'movimientos': movimientos
          .map((movimiento) => movimiento.toMap())
          .toList(),
      'creado': creado.toIso8601String(),
      'actualizado': actualizado.toIso8601String(),
    };
  }

  factory ProveedorCuentaModel.fromMap(Map<dynamic, dynamic> map) {
    final rawMovimientos = map['movimientos'] as List? ?? const [];

    return ProveedorCuentaModel(
      id: map['id'] as String? ?? '',
      nombre: map['nombre'] as String? ?? '',
      telefono: map['telefono'] as String? ?? '',
      observaciones: map['observaciones'] as String? ?? '',
      activo: map['activo'] as bool? ?? true,
      movimientos: rawMovimientos
          .map(
            (movimiento) => ProveedorMovimientoModel.fromMap(
              Map<dynamic, dynamic>.from(movimiento as Map),
            ),
          )
          .toList(),
      creado:
          DateTime.tryParse(map['creado'] as String? ?? '') ?? DateTime.now(),
      actualizado:
          DateTime.tryParse(map['actualizado'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  ProveedorCuentaModel copyWith({
    String? id,
    String? nombre,
    String? telefono,
    String? observaciones,
    bool? activo,
    List<ProveedorMovimientoModel>? movimientos,
    DateTime? creado,
    DateTime? actualizado,
  }) {
    return ProveedorCuentaModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      observaciones: observaciones ?? this.observaciones,
      activo: activo ?? this.activo,
      movimientos: movimientos ?? this.movimientos,
      creado: creado ?? this.creado,
      actualizado: actualizado ?? this.actualizado,
    );
  }
}

class ProveedorMovimientoTipo {
  static const deuda = 'Deuda';
  static const pago = 'Pago';
}

class ProveedorMovimientoModel {
  final String id;
  final String tipo;
  final String concepto;
  final double monto;
  final String medioPago;
  final DateTime fecha;
  final String responsable;
  final String observaciones;

  const ProveedorMovimientoModel({
    required this.id,
    required this.tipo,
    required this.concepto,
    required this.monto,
    this.medioPago = 'Efectivo',
    required this.fecha,
    this.responsable = '',
    this.observaciones = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo,
      'concepto': concepto,
      'monto': monto,
      'medioPago': medioPago,
      'fecha': fecha.toIso8601String(),
      'responsable': responsable,
      'observaciones': observaciones,
    };
  }

  factory ProveedorMovimientoModel.fromMap(Map<dynamic, dynamic> map) {
    return ProveedorMovimientoModel(
      id: map['id'] as String? ?? '',
      tipo: map['tipo'] as String? ?? ProveedorMovimientoTipo.deuda,
      concepto: map['concepto'] as String? ?? '',
      monto: (map['monto'] as num?)?.toDouble() ?? 0,
      medioPago: map['medioPago'] as String? ?? 'Efectivo',
      fecha: DateTime.tryParse(map['fecha'] as String? ?? '') ?? DateTime.now(),
      responsable: map['responsable'] as String? ?? '',
      observaciones: map['observaciones'] as String? ?? '',
    );
  }
}
