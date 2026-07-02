import '../../../core/constants/branches.dart';
import '../enums/producto_filter.dart';
import '../models/producto_model.dart';

class ProductoState {
  final List<ProductoModel> productos;
  final bool loading;
  final String busqueda;
  final ProductoFilter filtro;
  final String sucursalSeleccionada;

  const ProductoState({
    this.productos = const [],
    this.loading = false,
    this.busqueda = '',
    this.filtro = ProductoFilter.todos,
    this.sucursalSeleccionada = Branches.casaCentral,
  });

  List<ProductoModel> get productosFiltrados {
    final texto = busqueda.trim().toLowerCase();

    return productos.where((producto) {
      final coincideBusqueda =
          texto.isEmpty ||
          producto.codigo.toLowerCase().contains(texto) ||
          producto.nombre.toLowerCase().contains(texto) ||
          producto.categoria.toLowerCase().contains(texto) ||
          producto.marca.toLowerCase().contains(texto) ||
          producto.proveedor.toLowerCase().contains(texto);

      if (!coincideBusqueda) {
        return false;
      }

      return switch (filtro) {
        ProductoFilter.todos => true,
        ProductoFilter.activos => producto.activo,
        ProductoFilter.inactivos => !producto.activo,
        ProductoFilter.bajoStock =>
          producto.stockEnSucursal(sucursalSeleccionada) > 0 &&
              producto.stockEnSucursal(sucursalSeleccionada) <=
                  producto.stockMinimoEnSucursal(sucursalSeleccionada),
        ProductoFilter.sinStock =>
          producto.stockEnSucursal(sucursalSeleccionada) <= 0,
      };
    }).toList();
  }

  ProductoState copyWith({
    List<ProductoModel>? productos,
    bool? loading,
    String? busqueda,
    ProductoFilter? filtro,
    String? sucursalSeleccionada,
  }) {
    return ProductoState(
      productos: productos ?? this.productos,
      loading: loading ?? this.loading,
      busqueda: busqueda ?? this.busqueda,
      filtro: filtro ?? this.filtro,
      sucursalSeleccionada: sucursalSeleccionada ?? this.sucursalSeleccionada,
    );
  }
}
