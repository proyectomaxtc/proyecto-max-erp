import 'package:hive/hive.dart';

import '../../../core/storage/cloud_json_store.dart';
import '../../../core/storage/storage_boxes.dart';
import '../../../core/storage/storage_service.dart';
import '../models/producto_import_model.dart';
import '../data/catalogo_inicial_lcc.dart';
import '../models/producto_model.dart';

class ProductoService {
  Box get _box => StorageService.box(StorageBoxes.productos);

  Future<List<ProductoModel>> obtenerProductos() async {
    final values = await CloudJsonStore.syncBox(
      table: StorageBoxes.productos,
      box: _box,
    );

    return values.map(ProductoModel.fromMap).toList();
  }

  Future<int> obtenerProximoNumero(String categoria) async {
    final productos = await obtenerProductos();

    final prefijo = categoria.trim().toLowerCase();

    final mismosProductos = productos.where(
      (p) => p.categoria.trim().toLowerCase() == prefijo,
    );

    if (mismosProductos.isEmpty) {
      return 1;
    }

    int mayor = 0;

    for (final producto in mismosProductos) {
      final partes = producto.codigo.split('-');

      if (partes.length < 2) continue;

      final numero = int.tryParse(partes.last) ?? 0;

      if (numero > mayor) {
        mayor = numero;
      }
    }

    return mayor + 1;
  }

  Future<void> guardarProducto(ProductoModel producto) async {
    final data = producto.toMap();
    final sincronizado = await CloudJsonStore.save(
      table: StorageBoxes.productos,
      id: producto.id,
      data: data,
    );

    if (CloudJsonStore.enabled && !sincronizado) {
      throw Exception(
        'Supabase no permitio guardar el producto. Revise permisos de propietario o conexion.',
      );
    }

    await _box.put(producto.id, data);
  }

  Future<void> actualizarProducto(ProductoModel producto) async {
    await guardarProducto(producto);
  }

  Future<void> eliminarProducto(String id) async {
    await _box.delete(id);
    await CloudJsonStore.delete(table: StorageBoxes.productos, id: id);
  }

  Future<List<ProductoModel>> importarCatalogoInicialLcc({
    List<ProductoModel>? productosActuales,
  }) async {
    final productos = productosActuales ?? await obtenerProductos();
    final codigosExistentes = productos
        .map((producto) => producto.codigo.trim().toLowerCase())
        .toSet();
    final codigosProveedor = productos
        .map((producto) => producto.codigoBarras.trim())
        .where((codigo) => codigo.isNotEmpty)
        .toSet();
    final agregados = <ProductoModel>[];

    for (final producto in catalogoInicialLcc()) {
      final existePorCodigo = codigosExistentes.contains(
        producto.codigo.trim().toLowerCase(),
      );
      final existePorProveedor = codigosProveedor.contains(
        producto.codigoBarras.trim(),
      );

      if (existePorCodigo || existePorProveedor) {
        continue;
      }

      await guardarProducto(producto);
      agregados.add(producto);
      codigosExistentes.add(producto.codigo.trim().toLowerCase());
      codigosProveedor.add(producto.codigoBarras.trim());
    }

    return agregados;
  }

  Future<ProductoImportResult> importarLista({
    required String proveedor,
    required List<ProductoImportItem> items,
    List<ProductoModel>? productosActuales,
  }) async {
    final productos = productosActuales ?? await obtenerProductos();
    var creados = 0;
    var actualizados = 0;
    var ignorados = 0;

    for (final item in items) {
      if (item.codigoProveedor.trim().isEmpty ||
          item.nombre.trim().isEmpty ||
          item.costo <= 0) {
        ignorados++;
        continue;
      }

      final existente = _buscarExistente(
        productos,
        proveedor: proveedor,
        codigoProveedor: item.codigoProveedor,
      );

      if (existente == null) {
        final nuevo = _crearProductoImportado(proveedor: proveedor, item: item);
        await guardarProducto(nuevo);
        productos.add(nuevo);
        creados++;
        continue;
      }

      final actualizado = existente.copyWith(
        nombre: item.nombre.trim(),
        categoria: item.categoria.trim().isEmpty
            ? existente.categoria
            : item.categoria.trim(),
        marca: item.marca.trim().isEmpty ? existente.marca : item.marca.trim(),
        proveedor: proveedor.trim(),
        costo: item.costo,
        actualizado: DateTime.now(),
      );
      await actualizarProducto(actualizado);
      final index = productos.indexWhere(
        (producto) => producto.id == actualizado.id,
      );
      if (index >= 0) {
        productos[index] = actualizado;
      }
      actualizados++;
    }

    return ProductoImportResult(
      creados: creados,
      actualizados: actualizados,
      ignorados: ignorados,
    );
  }

  ProductoModel? _buscarExistente(
    List<ProductoModel> productos, {
    required String proveedor,
    required String codigoProveedor,
  }) {
    final proveedorNormalizado = proveedor.trim().toLowerCase();
    final codigoNormalizado = codigoProveedor.trim().toLowerCase();
    final codigoInterno = _codigoInterno(
      proveedor,
      codigoProveedor,
    ).trim().toLowerCase();

    for (final producto in productos) {
      final mismoProveedor =
          producto.proveedor.trim().toLowerCase() == proveedorNormalizado;
      final mismoCodigoProveedor =
          producto.codigoBarras.trim().toLowerCase() == codigoNormalizado;
      final mismoCodigoInterno =
          producto.codigo.trim().toLowerCase() == codigoInterno;

      if (mismoProveedor && mismoCodigoProveedor) {
        return producto;
      }

      if (mismoCodigoInterno) {
        return producto;
      }
    }

    return null;
  }

  ProductoModel _crearProductoImportado({
    required String proveedor,
    required ProductoImportItem item,
  }) {
    final ahora = DateTime.now();

    return ProductoModel(
      id: 'imp-${_prefijoProveedor(proveedor).toLowerCase()}-${item.codigoProveedor.trim()}',
      codigo: _codigoInterno(proveedor, item.codigoProveedor),
      codigoBarras: item.codigoProveedor.trim(),
      nombre: item.nombre.trim(),
      descripcion: 'Producto importado desde lista de proveedor.',
      categoria: item.categoria.trim().isEmpty
          ? 'Otros'
          : item.categoria.trim(),
      marca: item.marca.trim(),
      proveedor: proveedor.trim(),
      imagenPath: '',
      costo: item.costo,
      precio: 0,
      stock: 0,
      stockMinimo: 0,
      stockPorSucursal: const {},
      stockMinimoPorSucursal: const {},
      ubicacion: '',
      activo: true,
      creado: ahora,
      actualizado: ahora,
    );
  }

  String _codigoInterno(String proveedor, String codigoProveedor) {
    return '${_prefijoProveedor(proveedor)}-${codigoProveedor.trim()}';
  }

  String _prefijoProveedor(String proveedor) {
    final limpio = proveedor
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), ' ')
        .trim();

    if (limpio.isEmpty) {
      return 'PROV';
    }

    final partes = limpio.split(RegExp(r'\s+'));
    if (partes.length == 1) {
      return partes.first.length <= 4
          ? partes.first
          : partes.first.substring(0, 4);
    }

    return partes.take(3).map((parte) => parte[0]).join();
  }
}
