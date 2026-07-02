import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/branches.dart';
import '../../../../core/constants/app_colors.dart';
import '../../configuracion/providers/configuracion_provider.dart';
import '../constants/producto_categorias.dart';
import '../models/producto_model.dart';
import '../providers/producto_provider.dart';

class ProductoForm extends ConsumerStatefulWidget {
  final ProductoModel? producto;
  final Future<void> Function(ProductoModel producto)? onGuardar;

  const ProductoForm({super.key, this.producto, this.onGuardar});

  @override
  ConsumerState<ProductoForm> createState() => _ProductoFormState();
}

class _ProductoFormState extends ConsumerState<ProductoForm> {
  final _formKey = GlobalKey<FormState>();

  final codigoController = TextEditingController();
  final codigoBarrasController = TextEditingController();
  final nombreController = TextEditingController();
  final descripcionController = TextEditingController();
  final categoriaController = TextEditingController();
  final marcaController = TextEditingController();
  final proveedorController = TextEditingController();
  final imagenPathController = TextEditingController();
  final costoController = TextEditingController();
  final precioController = TextEditingController();
  final stockController = TextEditingController();
  final stockMinimoController = TextEditingController();
  final ubicacionController = TextEditingController();

  String? categoriaSeleccionada;
  bool activo = true;
  double ganancia = 0;
  double margen = 0;

  @override
  void initState() {
    super.initState();

    costoController.addListener(calcularMargen);
    precioController.addListener(calcularMargen);

    final producto = widget.producto;

    if (producto != null) {
      final sucursal = ref.read(productoProvider).sucursalSeleccionada;
      codigoController.text = producto.codigo;
      codigoBarrasController.text = producto.codigoBarras;
      nombreController.text = producto.nombre;
      descripcionController.text = producto.descripcion;
      categoriaController.text = producto.categoria;
      categoriaSeleccionada = producto.categoria.isEmpty
          ? null
          : producto.categoria;
      marcaController.text = producto.marca;
      proveedorController.text = producto.proveedor;
      imagenPathController.text = producto.imagenPath;
      costoController.text = producto.costo.toString();
      precioController.text = producto.precio.toString();
      stockController.text = producto.stockEnSucursal(sucursal).toString();
      stockMinimoController.text = producto
          .stockMinimoEnSucursal(sucursal)
          .toString();
      ubicacionController.text = producto.ubicacion;
      activo = producto.activo;
    } else {
      codigoController.text = "PRD-${DateTime.now().millisecondsSinceEpoch}";
    }

    calcularMargen();
  }

  @override
  void dispose() {
    codigoController.dispose();
    codigoBarrasController.dispose();
    nombreController.dispose();
    descripcionController.dispose();
    categoriaController.dispose();
    marcaController.dispose();
    proveedorController.dispose();
    imagenPathController.dispose();
    costoController.dispose();
    precioController.dispose();
    stockController.dispose();
    stockMinimoController.dispose();
    ubicacionController.dispose();

    super.dispose();
  }

  InputDecoration decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void calcularMargen() {
    if (!mounted) return;

    final costo = double.tryParse(costoController.text) ?? 0;
    final precio = double.tryParse(precioController.text) ?? 0;

    setState(() {
      ganancia = precio - costo;
      margen = costo > 0 ? (ganancia / costo) * 100 : 0;
    });
  }

  Future<void> guardarProducto() async {
    if (!_formKey.currentState!.validate()) return;

    final ahora = DateTime.now();
    final sucursal = ref.read(productoProvider).sucursalSeleccionada;
    final categoria = categoriaSeleccionada == productoCategoriaOtra
        ? categoriaController.text.trim()
        : (categoriaSeleccionada ?? '').trim();
    final stockSucursal = double.tryParse(stockController.text) ?? 0;
    final minimoSucursal = double.tryParse(stockMinimoController.text) ?? 0;
    final stockPorSucursal = Map<String, double>.from(
      widget.producto?.stockPorSucursal ??
          {Branches.casaCentral: 0, Branches.alberdi: 0},
    );
    final minimoPorSucursal = Map<String, double>.from(
      widget.producto?.stockMinimoPorSucursal ??
          {Branches.casaCentral: 0, Branches.alberdi: 0},
    );
    stockPorSucursal[sucursal] = stockSucursal;
    minimoPorSucursal[sucursal] = minimoSucursal;
    final stockTotal = stockPorSucursal.values.fold<double>(
      0,
      (total, value) => total + value,
    );
    final minimoTotal = minimoPorSucursal.values.fold<double>(
      0,
      (total, value) => total + value,
    );

    final producto = ProductoModel(
      id: widget.producto?.id ?? ahora.millisecondsSinceEpoch.toString(),
      codigo: codigoController.text.trim(),
      codigoBarras: codigoBarrasController.text.trim(),
      nombre: nombreController.text.trim(),
      descripcion: descripcionController.text.trim(),
      categoria: categoria,
      marca: marcaController.text.trim(),
      proveedor: proveedorController.text.trim(),
      imagenPath: imagenPathController.text.trim(),
      costo: double.tryParse(costoController.text) ?? 0,
      precio: double.tryParse(precioController.text) ?? 0,
      stock: stockTotal,
      stockMinimo: minimoTotal,
      stockPorSucursal: stockPorSucursal,
      stockMinimoPorSucursal: minimoPorSucursal,
      ubicacion: ubicacionController.text.trim(),
      activo: activo,
      creado: widget.producto?.creado ?? ahora,
      actualizado: ahora,
    );

    if (widget.onGuardar != null) {
      await widget.onGuardar!(producto);
    } else if (widget.producto == null) {
      await ref.read(productoProvider.notifier).agregarProducto(producto);
    } else {
      await ref.read(productoProvider.notifier).actualizarProducto(producto);
    }

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text(
          widget.producto == null
              ? 'Producto agregado correctamente'
              : 'Producto actualizado correctamente',
        ),
      ),
    );
  }

  Future<void> cargarFoto() async {
    const typeGroup = XTypeGroup(
      label: 'Imagenes',
      extensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    final archivo = await openFile(acceptedTypeGroups: [typeGroup]);

    if (archivo == null) {
      return;
    }

    final bytes = await archivo.readAsBytes();
    final extension = p.extension(archivo.name).toLowerCase();

    if (kIsWeb) {
      final mime = switch (extension) {
        '.jpg' || '.jpeg' => 'image/jpeg',
        '.webp' => 'image/webp',
        _ => 'image/png',
      };

      if (!mounted) {
        return;
      }

      setState(() {
        imagenPathController.text = 'data:$mime;base64,${base64Encode(bytes)}';
      });
      return;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final fotosDir = Directory(
      p.join(appDir.path, 'proyecto_max', 'productos'),
    );
    if (!await fotosDir.exists()) {
      await fotosDir.create(recursive: true);
    }

    final nombreArchivo =
        '${codigoController.text.trim()}-${DateTime.now().millisecondsSinceEpoch}$extension';
    final destino = File(p.join(fotosDir.path, nombreArchivo));

    await destino.writeAsBytes(bytes);

    if (!mounted) {
      return;
    }

    setState(() {
      imagenPathController.text = destino.path;
    });
  }

  void quitarFoto() {
    setState(() {
      imagenPathController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categorias = _categoriasDisponibles(ref);
    final categoriaActual = _categoriaActual(categorias);
    final sucursal = ref.watch(productoProvider).sucursalSeleccionada;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: codigoController,
            readOnly: true,
            decoration: decoration("Codigo"),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: nombreController,
            decoration: decoration("Nombre"),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Ingrese un nombre";
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: codigoBarrasController,
            decoration: decoration("Codigo de barras"),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: categoriaActual,
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
                  decoration: decoration("Categoria"),
                  items: categorias
                      .map(
                        (categoria) => DropdownMenuItem(
                          value: categoria,
                          child: Text(
                            categoria,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  selectedItemBuilder: (context) {
                    return categorias.map((categoria) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          categoria,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList();
                  },
                  onChanged: (value) {
                    setState(() {
                      categoriaSeleccionada = value;
                      if (value != null && value != productoCategoriaOtra) {
                        categoriaController.text = value;
                      } else {
                        categoriaController.clear();
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Seleccione una categoria";
                    }

                    if (value == productoCategoriaOtra &&
                        categoriaController.text.trim().isEmpty) {
                      return "Ingrese la categoria";
                    }

                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: marcaController,
                  decoration: decoration("Marca"),
                ),
              ),
            ],
          ),
          if (categoriaSeleccionada == productoCategoriaOtra) ...[
            const SizedBox(height: 18),
            TextFormField(
              controller: categoriaController,
              decoration: decoration("Nueva categoria"),
              validator: (value) {
                if (categoriaSeleccionada == productoCategoriaOtra &&
                    (value == null || value.trim().isEmpty)) {
                  return "Ingrese la categoria";
                }

                return null;
              },
            ),
          ],
          const SizedBox(height: 18),
          TextFormField(
            controller: proveedorController,
            decoration: decoration("Proveedor"),
          ),
          const SizedBox(height: 18),
          _FotoProductoField(
            path: imagenPathController.text,
            onCargar: cargarFoto,
            onQuitar: imagenPathController.text.trim().isEmpty
                ? null
                : quitarFoto,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: costoController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: decoration("Costo"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: precioController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: decoration("Precio"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 0,
            color: ganancia >= 0
                ? AppColors.success.withValues(alpha: .12)
                : AppColors.error.withValues(alpha: .12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: ganancia >= 0 ? AppColors.success : AppColors.error,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        ganancia >= 0
                            ? Icons.trending_up
                            : Icons.warning_rounded,
                        color: ganancia >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Rentabilidad",
                        style: TextStyle(
                          color: ganancia >= 0
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "Ganancia: \$ ${ganancia.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Margen: ${margen.toStringAsFixed(2)} %",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (ganancia < 0) ...[
                    const SizedBox(height: 12),
                    const Text(
                      "Atencion: el precio de venta es menor al costo.",
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  decoration: decoration(
                    "Stock ${sucursal == Branches.casaCentral ? 'Santa Fe' : 'Alberdi'}",
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: stockMinimoController,
                  keyboardType: TextInputType.number,
                  decoration: decoration("Stock minimo"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: ubicacionController,
            decoration: decoration("Ubicacion"),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: descripcionController,
            maxLines: 4,
            decoration: decoration("Descripcion"),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            value: activo,
            title: const Text(
              "Producto activo",
              style: TextStyle(color: AppColors.textPrimary),
            ),
            onChanged: (value) {
              setState(() {
                activo = value;
              });
            },
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close),
                label: const Text("Cancelar"),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: guardarProducto,
                icon: const Icon(Icons.save),
                label: Text(
                  widget.producto == null
                      ? "Guardar Producto"
                      : "Actualizar Producto",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _categoriasDisponibles(WidgetRef ref) {
    final configuradas = ref.watch(configuracionProvider).categoriasProducto;
    final existentes = ref
        .watch(productoProvider)
        .productos
        .map((producto) => producto.categoria.trim())
        .where((categoria) => categoria.isNotEmpty);
    final categorias = <String>{...configuradas, ...existentes}.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    categorias.remove(productoCategoriaOtra);
    categorias.add(productoCategoriaOtra);

    return categorias;
  }

  String? _categoriaActual(List<String> categorias) {
    if (categoriaSeleccionada == null || categoriaSeleccionada!.isEmpty) {
      return null;
    }

    if (categorias.contains(categoriaSeleccionada)) {
      return categoriaSeleccionada;
    }

    return productoCategoriaOtra;
  }
}

class _FotoProductoField extends StatelessWidget {
  final String path;
  final VoidCallback onCargar;
  final VoidCallback? onQuitar;

  const _FotoProductoField({
    required this.path,
    required this.onCargar,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    final imageBytes = _imageBytes(path);
    final tieneFoto =
        imageBytes != null ||
        (!kIsWeb && path.trim().isNotEmpty && File(path).existsSync());

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageBytes != null
                ? Image.memory(imageBytes, fit: BoxFit.cover)
                : tieneFoto
                ? Image.file(File(path), fit: BoxFit.cover)
                : const Icon(
                    Icons.image_outlined,
                    color: AppColors.textDisabled,
                    size: 34,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Foto del producto",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tieneFoto
                      ? _fotoNombre(path)
                      : "Sin foto cargada. Solo el propietario puede cambiarla desde este formulario.",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: onCargar,
                      icon: const Icon(Icons.upload_file_outlined),
                      label: Text(tieneFoto ? "Cambiar foto" : "Cargar foto"),
                    ),
                    if (onQuitar != null)
                      OutlinedButton.icon(
                        onPressed: onQuitar,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text("Quitar"),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Uint8List? _imageBytes(String value) {
    if (!value.startsWith('data:image/')) {
      return null;
    }

    final comma = value.indexOf(',');
    if (comma < 0) {
      return null;
    }

    return base64Decode(value.substring(comma + 1));
  }

  String _fotoNombre(String value) {
    if (value.startsWith('data:image/')) {
      return 'Foto cargada desde galeria';
    }

    return p.basename(value);
  }
}
