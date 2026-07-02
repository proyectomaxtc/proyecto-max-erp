class ServicioModel {
  final String id;
  final String numero;
  final String clienteId;
  final String clienteNombre;
  final String sucursal;
  final String descripcion;
  final String tecnico;
  final String estado;
  final double manoObra;
  final double repuestos;
  final double total;
  final bool cobrado;
  final String medioPago;
  final DateTime creado;
  final DateTime? entregado;
  final String observaciones;

  const ServicioModel({
    required this.id,
    required this.numero,
    required this.clienteId,
    required this.clienteNombre,
    required this.sucursal,
    required this.descripcion,
    required this.tecnico,
    required this.estado,
    required this.manoObra,
    required this.repuestos,
    required this.total,
    required this.cobrado,
    required this.medioPago,
    required this.creado,
    required this.entregado,
    required this.observaciones,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numero': numero,
      'clienteId': clienteId,
      'clienteNombre': clienteNombre,
      'sucursal': sucursal,
      'descripcion': descripcion,
      'tecnico': tecnico,
      'estado': estado,
      'manoObra': manoObra,
      'repuestos': repuestos,
      'total': total,
      'cobrado': cobrado,
      'medioPago': medioPago,
      'creado': creado.toIso8601String(),
      'entregado': entregado?.toIso8601String(),
      'observaciones': observaciones,
    };
  }

  factory ServicioModel.fromMap(Map<dynamic, dynamic> map) {
    return ServicioModel(
      id: map['id'] as String? ?? '',
      numero: map['numero'] as String? ?? '',
      clienteId: map['clienteId'] as String? ?? '',
      clienteNombre: map['clienteNombre'] as String? ?? '',
      sucursal: map['sucursal'] as String? ?? 'Casa Central Santa Fe',
      descripcion: map['descripcion'] as String? ?? '',
      tecnico: map['tecnico'] as String? ?? '',
      estado: map['estado'] as String? ?? 'Pendiente',
      manoObra: (map['manoObra'] as num?)?.toDouble() ?? 0,
      repuestos: (map['repuestos'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      cobrado: map['cobrado'] as bool? ?? false,
      medioPago: map['medioPago'] as String? ?? 'Efectivo',
      creado:
          DateTime.tryParse(map['creado'] as String? ?? '') ?? DateTime.now(),
      entregado: DateTime.tryParse(map['entregado'] as String? ?? ''),
      observaciones: map['observaciones'] as String? ?? '',
    );
  }
}
