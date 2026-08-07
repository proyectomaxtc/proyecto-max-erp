import '../../../core/constants/branches.dart';
import 'venta_item_model.dart';

class VentaModel {
  final String id;
  final String numero;
  final String clienteId;
  final String clienteNombre;
  final String sucursal;
  final List<VentaItemModel> items;
  final double subtotal;
  final double descuento;
  final double total;
  final double costoTotal;
  final String medioPago;
  final String estado;
  final DateTime fecha;
  final String observaciones;
  final bool stockAplicado;

  const VentaModel({
    required this.id,
    required this.numero,
    required this.clienteId,
    required this.clienteNombre,
    required this.sucursal,
    required this.items,
    required this.subtotal,
    required this.descuento,
    required this.total,
    required this.costoTotal,
    required this.medioPago,
    required this.estado,
    required this.fecha,
    required this.observaciones,
    this.stockAplicado = false,
  });

  double get rentabilidad => total - costoTotal;

  int get cantidadItems => items.length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numero': numero,
      'clienteId': clienteId,
      'clienteNombre': clienteNombre,
      'sucursal': sucursal,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'descuento': descuento,
      'total': total,
      'costoTotal': costoTotal,
      'medioPago': medioPago,
      'estado': estado,
      'fecha': fecha.toIso8601String(),
      'observaciones': observaciones,
      'stockAplicado': stockAplicado,
    };
  }

  factory VentaModel.fromMap(Map<dynamic, dynamic> map) {
    final rawItems = map['items'] as List? ?? const [];

    return VentaModel(
      id: map['id'] as String? ?? '',
      numero: map['numero'] as String? ?? '',
      clienteId: map['clienteId'] as String? ?? '',
      clienteNombre: map['clienteNombre'] as String? ?? '',
      sucursal: map['sucursal'] as String? ?? Branches.casaCentral,
      items: rawItems
          .map(
            (item) =>
                VentaItemModel.fromMap(Map<dynamic, dynamic>.from(item as Map)),
          )
          .toList(),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      descuento: (map['descuento'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      costoTotal: (map['costoTotal'] as num?)?.toDouble() ?? 0,
      medioPago: map['medioPago'] as String? ?? 'Efectivo',
      estado: map['estado'] as String? ?? 'Completada',
      fecha: DateTime.tryParse(map['fecha'] as String? ?? '') ?? DateTime.now(),
      observaciones: map['observaciones'] as String? ?? '',
      stockAplicado: _boolValue(map['stockAplicado']),
    );
  }

  static bool _boolValue(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'si';
    }

    return false;
  }

  VentaModel copyWith({
    String? id,
    String? numero,
    String? clienteId,
    String? clienteNombre,
    String? sucursal,
    List<VentaItemModel>? items,
    double? subtotal,
    double? descuento,
    double? total,
    double? costoTotal,
    String? medioPago,
    String? estado,
    DateTime? fecha,
    String? observaciones,
    bool? stockAplicado,
  }) {
    return VentaModel(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      clienteId: clienteId ?? this.clienteId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      sucursal: sucursal ?? this.sucursal,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      descuento: descuento ?? this.descuento,
      total: total ?? this.total,
      costoTotal: costoTotal ?? this.costoTotal,
      medioPago: medioPago ?? this.medioPago,
      estado: estado ?? this.estado,
      fecha: fecha ?? this.fecha,
      observaciones: observaciones ?? this.observaciones,
      stockAplicado: stockAplicado ?? this.stockAplicado,
    );
  }
}
