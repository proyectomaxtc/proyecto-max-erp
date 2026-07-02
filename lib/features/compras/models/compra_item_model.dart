class CompraItemModel {
  final String productoId;
  final String codigo;
  final String nombre;
  final double cantidad;
  final double costoUnitario;

  const CompraItemModel({
    required this.productoId,
    required this.codigo,
    required this.nombre,
    required this.cantidad,
    required this.costoUnitario,
  });

  double get subtotal => cantidad * costoUnitario;

  Map<String, dynamic> toMap() {
    return {
      'productoId': productoId,
      'codigo': codigo,
      'nombre': nombre,
      'cantidad': cantidad,
      'costoUnitario': costoUnitario,
    };
  }

  factory CompraItemModel.fromMap(Map<dynamic, dynamic> map) {
    return CompraItemModel(
      productoId: map['productoId'] as String? ?? '',
      codigo: map['codigo'] as String? ?? '',
      nombre: map['nombre'] as String? ?? '',
      cantidad: (map['cantidad'] as num?)?.toDouble() ?? 0,
      costoUnitario: (map['costoUnitario'] as num?)?.toDouble() ?? 0,
    );
  }
}
