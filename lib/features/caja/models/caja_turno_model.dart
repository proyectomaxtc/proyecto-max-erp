class CajaTurnoModel {
  final String id;
  final String sucursal;
  final String responsable;
  final DateTime apertura;
  final DateTime? cierre;
  final double saldoInicial;
  final double? saldoFinalDeclarado;
  final double? saldoSistema;
  final String estado;
  final String observaciones;

  const CajaTurnoModel({
    required this.id,
    required this.sucursal,
    required this.responsable,
    required this.apertura,
    required this.cierre,
    required this.saldoInicial,
    required this.saldoFinalDeclarado,
    required this.saldoSistema,
    required this.estado,
    required this.observaciones,
  });

  bool get abierta => estado == 'Abierta';

  CajaTurnoModel copyWith({
    String? sucursal,
    DateTime? cierre,
    double? saldoFinalDeclarado,
    double? saldoSistema,
    String? estado,
    String? observaciones,
  }) {
    return CajaTurnoModel(
      id: id,
      sucursal: sucursal ?? this.sucursal,
      responsable: responsable,
      apertura: apertura,
      cierre: cierre ?? this.cierre,
      saldoInicial: saldoInicial,
      saldoFinalDeclarado: saldoFinalDeclarado ?? this.saldoFinalDeclarado,
      saldoSistema: saldoSistema ?? this.saldoSistema,
      estado: estado ?? this.estado,
      observaciones: observaciones ?? this.observaciones,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sucursal': sucursal,
      'responsable': responsable,
      'apertura': apertura.toIso8601String(),
      'cierre': cierre?.toIso8601String(),
      'saldoInicial': saldoInicial,
      'saldoFinalDeclarado': saldoFinalDeclarado,
      'saldoSistema': saldoSistema,
      'estado': estado,
      'observaciones': observaciones,
    };
  }

  factory CajaTurnoModel.fromMap(Map<dynamic, dynamic> map) {
    return CajaTurnoModel(
      id: map['id'] as String? ?? '',
      sucursal: map['sucursal'] as String? ?? 'Casa Central Santa Fe',
      responsable: map['responsable'] as String? ?? '',
      apertura:
          DateTime.tryParse(map['apertura'] as String? ?? '') ?? DateTime.now(),
      cierre: DateTime.tryParse(map['cierre'] as String? ?? ''),
      saldoInicial: (map['saldoInicial'] as num?)?.toDouble() ?? 0,
      saldoFinalDeclarado: (map['saldoFinalDeclarado'] as num?)?.toDouble(),
      saldoSistema: (map['saldoSistema'] as num?)?.toDouble(),
      estado: map['estado'] as String? ?? 'Abierta',
      observaciones: map['observaciones'] as String? ?? '',
    );
  }
}
