import '../models/producto_model.dart';
import '../services/producto_service.dart';

class ProductoRepository {
  final ProductoService service;

  const ProductoRepository({required this.service});

  Future<List<ProductoModel>> obtenerProductos() {
    return service.obtenerProductos();
  }

  Future<int> obtenerProximoNumero(String categoria) {
    return service.obtenerProximoNumero(categoria);
  }

  Future<void> guardarProducto(ProductoModel producto) {
    return service.guardarProducto(producto);
  }

  Future<List<ProductoModel>> importarCatalogoInicialLcc({
    List<ProductoModel>? productosActuales,
  }) {
    return service.importarCatalogoInicialLcc(
      productosActuales: productosActuales,
    );
  }

  Future<void> actualizarProducto(ProductoModel producto) {
    return service.actualizarProducto(producto);
  }

  Future<void> eliminarProducto(String id) {
    return service.eliminarProducto(id);
  }
}
