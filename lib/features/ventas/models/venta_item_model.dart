class VentaItemModel {
  final String productoId;
  final String codigo;
  final String nombre;
  final double cantidad;
  final double precioUnitario;
  final double costoUnitario;

  const VentaItemModel({
    required this.productoId,
    required this.codigo,
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
    required this.costoUnitario,
  });

  double get subtotal => cantidad * precioUnitario;

  double get costoTotal => cantidad * costoUnitario;

  bool get esVentaLibre {
    return _esTextoVentaLibre(nombre) ||
        _esTextoVentaLibre(codigo) ||
        _esTextoVentaLibre(productoId);
  }

  Map<String, dynamic> toMap() {
    return {
      'productoId': productoId,
      'codigo': codigo,
      'nombre': nombre,
      'cantidad': cantidad,
      'precioUnitario': precioUnitario,
      'costoUnitario': costoUnitario,
    };
  }

  factory VentaItemModel.fromMap(Map<dynamic, dynamic> map) {
    return VentaItemModel(
      productoId: map['productoId'] as String? ?? '',
      codigo: map['codigo'] as String? ?? '',
      nombre: map['nombre'] as String? ?? '',
      cantidad: (map['cantidad'] as num?)?.toDouble() ?? 0,
      precioUnitario: (map['precioUnitario'] as num?)?.toDouble() ?? 0,
      costoUnitario: (map['costoUnitario'] as num?)?.toDouble() ?? 0,
    );
  }

  static bool _esTextoVentaLibre(String value) {
    final texto = value
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), ' ')
        .trim();

    return texto == 'VARIOS' || texto.endsWith(' VARIOS');
  }
}
