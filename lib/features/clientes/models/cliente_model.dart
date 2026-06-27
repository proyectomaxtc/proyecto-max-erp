import 'dart:convert';

class ClienteModel {
  final String id;

  final String nombre;

  final String apellido;

  final String telefono;

  final String? email;

  final String? direccion;

  final DateTime createdAt;

  final DateTime updatedAt;

  final bool isActive;

  const ClienteModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.telefono,
    this.email,
    this.direccion,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  ClienteModel copyWith({
    String? id,
    String? nombre,
    String? apellido,
    String? telefono,
    String? email,
    String? direccion,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ClienteModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory ClienteModel.fromMap(Map<String, dynamic> map) {
    return ClienteModel(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      apellido: map['apellido'] as String,
      telefono: map['telefono'] as String,
      email: map['email'] as String?,
      direccion: map['direccion'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ClienteModel.fromJson(String source) =>
      ClienteModel.fromMap(jsonDecode(source));
}