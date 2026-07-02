class AppNotificationModel {
  final String id;
  final String tipo;
  final String titulo;
  final String detalle;
  final String ruta;
  final String usuario;
  final String sucursal;
  final double monto;
  final DateTime fecha;
  final bool leida;

  const AppNotificationModel({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.detalle,
    required this.ruta,
    required this.usuario,
    required this.sucursal,
    required this.monto,
    required this.fecha,
    this.leida = false,
  });

  AppNotificationModel copyWith({bool? leida}) {
    return AppNotificationModel(
      id: id,
      tipo: tipo,
      titulo: titulo,
      detalle: detalle,
      ruta: ruta,
      usuario: usuario,
      sucursal: sucursal,
      monto: monto,
      fecha: fecha,
      leida: leida ?? this.leida,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo,
      'titulo': titulo,
      'detalle': detalle,
      'ruta': ruta,
      'usuario': usuario,
      'sucursal': sucursal,
      'monto': monto,
      'fecha': fecha.toIso8601String(),
      'leida': leida,
    };
  }

  factory AppNotificationModel.fromMap(Map<dynamic, dynamic> map) {
    return AppNotificationModel(
      id: map['id'] as String? ?? '',
      tipo: map['tipo'] as String? ?? 'General',
      titulo: map['titulo'] as String? ?? '',
      detalle: map['detalle'] as String? ?? '',
      ruta: map['ruta'] as String? ?? '',
      usuario: map['usuario'] as String? ?? '',
      sucursal: map['sucursal'] as String? ?? '',
      monto: (map['monto'] as num?)?.toDouble() ?? 0,
      fecha: DateTime.tryParse(map['fecha'] as String? ?? '') ?? DateTime.now(),
      leida: map['leida'] as bool? ?? false,
    );
  }
}
