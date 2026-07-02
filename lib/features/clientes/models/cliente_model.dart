class ClienteModel {
  static const consumidorFinalId = 'cliente-consumidor-final';

  final String id;
  final String nombre;
  final String apellido;
  final String telefono;
  final String email;
  final String direccion;
  final String ciudad;
  final String provincia;
  final String cuit;
  final String observaciones;
  final bool activo;
  final DateTime creado;
  final DateTime actualizado;

  const ClienteModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.telefono,
    required this.email,
    required this.direccion,
    required this.ciudad,
    required this.provincia,
    required this.cuit,
    required this.observaciones,
    required this.activo,
    required this.creado,
    required this.actualizado,
  });

  ClienteModel copyWith({
    String? id,
    String? nombre,
    String? apellido,
    String? telefono,
    String? email,
    String? direccion,
    String? ciudad,
    String? provincia,
    String? cuit,
    String? observaciones,
    bool? activo,
    DateTime? creado,
    DateTime? actualizado,
  }) {
    return ClienteModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
      ciudad: ciudad ?? this.ciudad,
      provincia: provincia ?? this.provincia,
      cuit: cuit ?? this.cuit,
      observaciones: observaciones ?? this.observaciones,
      activo: activo ?? this.activo,
      creado: creado ?? this.creado,
      actualizado: actualizado ?? this.actualizado,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
      'email': email,
      'direccion': direccion,
      'ciudad': ciudad,
      'provincia': provincia,
      'cuit': cuit,
      'observaciones': observaciones,
      'activo': activo,
      'creado': creado.toIso8601String(),
      'actualizado': actualizado.toIso8601String(),
    };
  }

  factory ClienteModel.fromMap(Map<dynamic, dynamic> map) {
    return ClienteModel(
      id: map['id'] as String? ?? '',
      nombre: map['nombre'] as String? ?? '',
      apellido: map['apellido'] as String? ?? '',
      telefono: map['telefono'] as String? ?? '',
      email: map['email'] as String? ?? '',
      direccion: map['direccion'] as String? ?? '',
      ciudad: map['ciudad'] as String? ?? '',
      provincia: map['provincia'] as String? ?? '',
      cuit: map['cuit'] as String? ?? '',
      observaciones: map['observaciones'] as String? ?? '',
      activo: map['activo'] as bool? ?? true,
      creado:
          DateTime.tryParse(map['creado'] as String? ?? '') ?? DateTime.now(),
      actualizado:
          DateTime.tryParse(map['actualizado'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  factory ClienteModel.empty() {
    return ClienteModel(
      id: '',
      nombre: '',
      apellido: '',
      telefono: '',
      email: '',
      direccion: '',
      ciudad: '',
      provincia: '',
      cuit: '',
      observaciones: '',
      activo: true,
      creado: DateTime.now(),
      actualizado: DateTime.now(),
    );
  }

  factory ClienteModel.consumidorFinal() {
    final ahora = DateTime.now();

    return ClienteModel(
      id: consumidorFinalId,
      nombre: 'Consumidor Final',
      apellido: '',
      telefono: '',
      email: '',
      direccion: '',
      ciudad: 'Tucuman',
      provincia: 'Tucuman',
      cuit: '',
      observaciones: 'Cliente fijo para ventas de mostrador.',
      activo: true,
      creado: ahora,
      actualizado: ahora,
    );
  }
}
