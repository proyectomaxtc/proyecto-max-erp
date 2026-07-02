import '../../../core/constants/branches.dart';
import 'compra_item_model.dart';

class CompraModel {
  final String id;
  final String numero;
  final String proveedor;
  final String responsable;
  final String sucursal;
  final List<CompraItemModel> items;
  final double total;
  final String estado;
  final DateTime fecha;
  final String observaciones;

  const CompraModel({
    required this.id,
    required this.numero,
    required this.proveedor,
    required this.responsable,
    this.sucursal = Branches.casaCentral,
    required this.items,
    required this.total,
    required this.estado,
    required this.fecha,
    required this.observaciones,
  });

  int get cantidadItems => items.length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numero': numero,
      'proveedor': proveedor,
      'responsable': responsable,
      'sucursal': sucursal,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'estado': estado,
      'fecha': fecha.toIso8601String(),
      'observaciones': observaciones,
    };
  }

  factory CompraModel.fromMap(Map<dynamic, dynamic> map) {
    final rawItems = map['items'] as List? ?? const [];

    return CompraModel(
      id: map['id'] as String? ?? '',
      numero: map['numero'] as String? ?? '',
      proveedor: map['proveedor'] as String? ?? '',
      responsable: map['responsable'] as String? ?? '',
      sucursal: map['sucursal'] as String? ?? Branches.casaCentral,
      items: rawItems
          .map(
            (item) => CompraItemModel.fromMap(
              Map<dynamic, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      total: (map['total'] as num?)?.toDouble() ?? 0,
      estado: map['estado'] as String? ?? 'Recibida',
      fecha: DateTime.tryParse(map['fecha'] as String? ?? '') ?? DateTime.now(),
      observaciones: map['observaciones'] as String? ?? '',
    );
  }
}
