import '../../../core/constants/branches.dart';

class ProductoModel {
  final String id;
  final String codigo;
  final String codigoBarras;
  final String nombre;
  final String descripcion;
  final String categoria;
  final String marca;
  final String proveedor;
  final String imagenPath;
  final double costo;
  final double precio;
  final double precioMayorista;
  final double stock;
  final double stockMinimo;
  final Map<String, double> stockPorSucursal;
  final Map<String, double> stockMinimoPorSucursal;
  final String ubicacion;
  final bool activo;
  final DateTime creado;
  final DateTime actualizado;

  const ProductoModel({
    required this.id,
    required this.codigo,
    required this.codigoBarras,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.marca,
    required this.proveedor,
    required this.imagenPath,
    required this.costo,
    required this.precio,
    this.precioMayorista = 0,
    required this.stock,
    required this.stockMinimo,
    this.stockPorSucursal = const {},
    this.stockMinimoPorSucursal = const {},
    required this.ubicacion,
    required this.activo,
    required this.creado,
    required this.actualizado,
  });

  ProductoModel copyWith({
    String? id,
    String? codigo,
    String? codigoBarras,
    String? nombre,
    String? descripcion,
    String? categoria,
    String? marca,
    String? proveedor,
    String? imagenPath,
    double? costo,
    double? precio,
    double? precioMayorista,
    double? stock,
    double? stockMinimo,
    Map<String, double>? stockPorSucursal,
    Map<String, double>? stockMinimoPorSucursal,
    String? ubicacion,
    bool? activo,
    DateTime? creado,
    DateTime? actualizado,
  }) {
    return ProductoModel(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      categoria: categoria ?? this.categoria,
      marca: marca ?? this.marca,
      proveedor: proveedor ?? this.proveedor,
      imagenPath: imagenPath ?? this.imagenPath,
      costo: costo ?? this.costo,
      precio: precio ?? this.precio,
      precioMayorista: precioMayorista ?? this.precioMayorista,
      stock: stock ?? this.stock,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      stockPorSucursal: stockPorSucursal ?? this.stockPorSucursal,
      stockMinimoPorSucursal:
          stockMinimoPorSucursal ?? this.stockMinimoPorSucursal,
      ubicacion: ubicacion ?? this.ubicacion,
      activo: activo ?? this.activo,
      creado: creado ?? this.creado,
      actualizado: actualizado ?? this.actualizado,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'codigoBarras': codigoBarras,
      'nombre': nombre,
      'descripcion': descripcion,
      'categoria': categoria,
      'marca': marca,
      'proveedor': proveedor,
      'imagenPath': imagenPath,
      'costo': costo,
      'precio': precio,
      'precioMayorista': precioMayorista,
      'stock': stock,
      'stockMinimo': stockMinimo,
      'stockPorSucursal': stockPorSucursal,
      'stockMinimoPorSucursal': stockMinimoPorSucursal,
      'ubicacion': ubicacion,
      'activo': activo,
      'creado': creado.toIso8601String(),
      'actualizado': actualizado.toIso8601String(),
    };
  }

  factory ProductoModel.fromMap(Map<dynamic, dynamic> map) {
    return ProductoModel(
      id: map['id'] as String? ?? '',
      codigo: map['codigo'] as String? ?? '',
      codigoBarras: map['codigoBarras'] as String? ?? '',
      nombre: map['nombre'] as String? ?? '',
      descripcion: map['descripcion'] as String? ?? '',
      categoria: map['categoria'] as String? ?? '',
      marca: map['marca'] as String? ?? '',
      proveedor: map['proveedor'] as String? ?? '',
      imagenPath: map['imagenPath'] as String? ?? '',
      costo: (map['costo'] as num?)?.toDouble() ?? 0,
      precio: (map['precio'] as num?)?.toDouble() ?? 0,
      precioMayorista: (map['precioMayorista'] as num?)?.toDouble() ?? 0,
      stock: (map['stock'] as num?)?.toDouble() ?? 0,
      stockMinimo: (map['stockMinimo'] as num?)?.toDouble() ?? 0,
      stockPorSucursal: _doubleMap(
        map['stockPorSucursal'],
        fallbackSantaFe: (map['stock'] as num?)?.toDouble() ?? 0,
      ),
      stockMinimoPorSucursal: _doubleMap(
        map['stockMinimoPorSucursal'],
        fallbackSantaFe: (map['stockMinimo'] as num?)?.toDouble() ?? 0,
      ),
      ubicacion: map['ubicacion'] as String? ?? '',
      activo: map['activo'] as bool? ?? true,
      creado:
          DateTime.tryParse(map['creado'] as String? ?? '') ?? DateTime.now(),
      actualizado:
          DateTime.tryParse(map['actualizado'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  factory ProductoModel.empty() {
    return ProductoModel(
      id: '',
      codigo: '',
      codigoBarras: '',
      nombre: '',
      descripcion: '',
      categoria: '',
      marca: '',
      proveedor: '',
      imagenPath: '',
      costo: 0,
      precio: 0,
      precioMayorista: 0,
      stock: 0,
      stockMinimo: 0,
      stockPorSucursal: const {},
      stockMinimoPorSucursal: const {},
      ubicacion: '',
      activo: true,
      creado: DateTime.now(),
      actualizado: DateTime.now(),
    );
  }

  double stockEnSucursal(String sucursal) {
    return stockPorSucursal[sucursal] ?? stock;
  }

  double stockMinimoEnSucursal(String sucursal) {
    return stockMinimoPorSucursal[sucursal] ?? stockMinimo;
  }

  ProductoModel conStockSucursal({
    required String sucursal,
    required double stockSucursal,
    double? stockMinimoSucursal,
  }) {
    final nuevoStockPorSucursal = Map<String, double>.from(stockPorSucursal);
    nuevoStockPorSucursal[sucursal] = stockSucursal;

    final nuevoMinimoPorSucursal = Map<String, double>.from(
      stockMinimoPorSucursal,
    );
    if (stockMinimoSucursal != null) {
      nuevoMinimoPorSucursal[sucursal] = stockMinimoSucursal;
    }

    return copyWith(
      stock: _sumarSucursales(nuevoStockPorSucursal),
      stockMinimo: _sumarSucursales(nuevoMinimoPorSucursal),
      stockPorSucursal: nuevoStockPorSucursal,
      stockMinimoPorSucursal: nuevoMinimoPorSucursal,
    );
  }

  static Map<String, double> _doubleMap(
    dynamic value, {
    required double fallbackSantaFe,
  }) {
    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), (val as num?)?.toDouble() ?? 0),
      );
    }

    if (fallbackSantaFe > 0) {
      return {Branches.casaCentral: fallbackSantaFe, Branches.alberdi: 0};
    }

    return const {};
  }

  static double _sumarSucursales(Map<String, double> valores) {
    return valores.values.fold(0, (total, valor) => total + valor);
  }
}
