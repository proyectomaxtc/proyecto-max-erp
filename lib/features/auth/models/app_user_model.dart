import '../../../core/constants/branches.dart';

class AppUserModel {
  final String id;
  final String nombre;
  final String codigo;
  final String email;
  final String authId;
  final String rol;
  final String sucursal;
  final bool activo;
  final DateTime creado;

  const AppUserModel({
    required this.id,
    required this.nombre,
    required this.codigo,
    this.email = '',
    this.authId = '',
    required this.rol,
    required this.sucursal,
    required this.activo,
    required this.creado,
  });

  bool get esPropietario => rol == 'Propietario';

  AppUserModel copyWith({
    String? id,
    String? nombre,
    String? codigo,
    String? email,
    String? authId,
    String? rol,
    String? sucursal,
    bool? activo,
    DateTime? creado,
  }) {
    return AppUserModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      codigo: codigo ?? this.codigo,
      email: email ?? this.email,
      authId: authId ?? this.authId,
      rol: rol ?? this.rol,
      sucursal: sucursal ?? this.sucursal,
      activo: activo ?? this.activo,
      creado: creado ?? this.creado,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'codigo': codigo,
      'email': email,
      'authId': authId,
      'rol': rol,
      'sucursal': sucursal,
      'activo': activo,
      'creado': creado.toIso8601String(),
    };
  }

  factory AppUserModel.fromMap(Map<dynamic, dynamic> map) {
    return AppUserModel(
      id: map['id'] as String? ?? '',
      nombre: map['nombre'] as String? ?? '',
      codigo: map['codigo'] as String? ?? '',
      email: map['email'] as String? ?? '',
      authId: map['authId'] as String? ?? '',
      rol: map['rol'] as String? ?? 'Empleado',
      sucursal:
          map['sucursal'] as String? ??
          ((map['rol'] as String? ?? 'Empleado') == 'Propietario'
              ? Branches.casaCentral
              : Branches.alberdi),
      activo: map['activo'] as bool? ?? true,
      creado:
          DateTime.tryParse(map['creado'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
