class ProductoImportItem {
  final String codigoProveedor;
  final String nombre;
  final double costo;
  final String marca;
  final String categoria;

  const ProductoImportItem({
    required this.codigoProveedor,
    required this.nombre,
    required this.costo,
    required this.marca,
    required this.categoria,
  });
}

class ProductoImportResult {
  final int creados;
  final int actualizados;
  final int ignorados;

  const ProductoImportResult({
    required this.creados,
    required this.actualizados,
    required this.ignorados,
  });

  int get totalProcesados => creados + actualizados;
}
