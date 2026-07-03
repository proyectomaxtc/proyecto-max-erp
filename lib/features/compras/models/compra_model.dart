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
  final double pagado;
  final List<CompraPagoModel> pagos;
  final double transporteCosto;
  final String transporteMedioPago;
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
    this.pagado = 0,
    this.pagos = const [],
    this.transporteCosto = 0,
    this.transporteMedioPago = 'Efectivo',
    required this.estado,
    required this.fecha,
    required this.observaciones,
  });

  int get cantidadItems => items.length;

  double get saldoPendiente {
    final saldo = total - pagado;
    return saldo < 0 ? 0 : saldo;
  }

  bool get tieneDeuda => saldoPendiente > 0.01;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numero': numero,
      'proveedor': proveedor,
      'responsable': responsable,
      'sucursal': sucursal,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'pagado': pagado,
      'pagos': pagos.map((pago) => pago.toMap()).toList(),
      'transporteCosto': transporteCosto,
      'transporteMedioPago': transporteMedioPago,
      'estado': estado,
      'fecha': fecha.toIso8601String(),
      'observaciones': observaciones,
    };
  }

  factory CompraModel.fromMap(Map<dynamic, dynamic> map) {
    final rawItems = map['items'] as List? ?? const [];
    final rawPagos = map['pagos'] as List? ?? const [];

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
      pagado: (map['pagado'] as num?)?.toDouble() ?? 0,
      pagos: rawPagos
          .map(
            (pago) => CompraPagoModel.fromMap(
              Map<dynamic, dynamic>.from(pago as Map),
            ),
          )
          .toList(),
      transporteCosto: (map['transporteCosto'] as num?)?.toDouble() ?? 0,
      transporteMedioPago: map['transporteMedioPago'] as String? ?? 'Efectivo',
      estado: map['estado'] as String? ?? 'Recibida',
      fecha: DateTime.tryParse(map['fecha'] as String? ?? '') ?? DateTime.now(),
      observaciones: map['observaciones'] as String? ?? '',
    );
  }

  CompraModel copyWith({
    String? id,
    String? numero,
    String? proveedor,
    String? responsable,
    String? sucursal,
    List<CompraItemModel>? items,
    double? total,
    double? pagado,
    List<CompraPagoModel>? pagos,
    double? transporteCosto,
    String? transporteMedioPago,
    String? estado,
    DateTime? fecha,
    String? observaciones,
  }) {
    return CompraModel(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      proveedor: proveedor ?? this.proveedor,
      responsable: responsable ?? this.responsable,
      sucursal: sucursal ?? this.sucursal,
      items: items ?? this.items,
      total: total ?? this.total,
      pagado: pagado ?? this.pagado,
      pagos: pagos ?? this.pagos,
      transporteCosto: transporteCosto ?? this.transporteCosto,
      transporteMedioPago: transporteMedioPago ?? this.transporteMedioPago,
      estado: estado ?? this.estado,
      fecha: fecha ?? this.fecha,
      observaciones: observaciones ?? this.observaciones,
    );
  }
}

class CompraPagoModel {
  final String id;
  final double monto;
  final String medioPago;
  final String responsable;
  final String observaciones;
  final DateTime fecha;

  const CompraPagoModel({
    required this.id,
    required this.monto,
    required this.medioPago,
    required this.responsable,
    required this.observaciones,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'monto': monto,
      'medioPago': medioPago,
      'responsable': responsable,
      'observaciones': observaciones,
      'fecha': fecha.toIso8601String(),
    };
  }

  factory CompraPagoModel.fromMap(Map<dynamic, dynamic> map) {
    return CompraPagoModel(
      id: map['id'] as String? ?? '',
      monto: (map['monto'] as num?)?.toDouble() ?? 0,
      medioPago: map['medioPago'] as String? ?? '',
      responsable: map['responsable'] as String? ?? '',
      observaciones: map['observaciones'] as String? ?? '',
      fecha: DateTime.tryParse(map['fecha'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
