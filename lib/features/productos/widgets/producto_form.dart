import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/branches.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
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
  final margenDeseadoController = TextEditingController();
  final stockSantaFeController = TextEditingController();
  final stockAlberdiController = TextEditingController();
  final stockMinimoSantaFeController = TextEditingController();
  final stockMinimoAlberdiController = TextEditingController();
  final ubicacionController = TextEditingController();

  String? categoriaSeleccionada;
  bool activo = true;
  bool guardando = false;
  double ganancia = 0;
  double margen = 0;

  @override
  void initState() {
    super.initState();

    costoController.addListener(calcularMargen);
    precioController.addListener(calcularMargen);

    final producto = widget.producto;

    if (producto != null) {
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
      stockSantaFeController.text = producto
          .stockEnSucursal(Branches.casaCentral)
          .toString();
      stockAlberdiController.text = producto
          .stockEnSucursal(Branches.alberdi)
          .toString();
      stockMinimoSantaFeController.text = producto
          .stockMinimoEnSucursal(Branches.casaCentral)
          .toString();
      stockMinimoAlberdiController.text = producto
          .stockMinimoEnSucursal(Branches.alberdi)
          .toString();
      ubicacionController.text = producto.ubicacion;
      activo = producto.activo;
    } else {
      codigoController.text = "PRD-${DateTime.now().millisecondsSinceEpoch}";
      stockSantaFeController.text = '0';
      stockAlberdiController.text = '0';
      stockMinimoSantaFeController.text = '0';
      stockMinimoAlberdiController.text = '0';
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
    margenDeseadoController.dispose();
    stockSantaFeController.dispose();
    stockAlberdiController.dispose();
    stockMinimoSantaFeController.dispose();
    stockMinimoAlberdiController.dispose();
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

    final costo = _parseNumber(costoController.text);
    final precio = _parseNumber(precioController.text);

    setState(() {
      ganancia = precio - costo;
      margen = costo > 0 ? (ganancia / costo) * 100 : 0;
    });
  }

  void aplicarMargenDeseado() {
    final costo = _parseNumber(costoController.text);
    final margenDeseado = _parseNumber(margenDeseadoController.text);

    if (costo <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.warning,
          content: Text(
            'Ingrese primero el costo del producto.',
            style: TextStyle(
              color: AppColors.background,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
      return;
    }

    final precioSugerido = costo * (1 + (margenDeseado / 100));

    setState(() {
      precioController.text = precioSugerido.toStringAsFixed(2);
    });
  }

  double _parseNumber(String value) {
    final clean = value.trim();
    if (clean.isEmpty) {
      return 0;
    }

    final hasComma = clean.contains(',');
    final hasDot = clean.contains('.');
    final normalized = hasComma
        ? clean.replaceAll('.', '').replaceAll(',', '.')
        : hasDot && RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(clean)
        ? clean.replaceAll('.', '')
        : clean;

    return double.tryParse(normalized) ?? 0;
  }

  ProductoModel? _productoConNombreRepetido(String nombre) {
    final nombreNormalizado = _normalizarNombreProducto(nombre);
    if (nombreNormalizado.isEmpty) {
      return null;
    }

    for (final producto in ref.read(productoProvider).productos) {
      if (producto.id == widget.producto?.id) {
        continue;
      }

      if (_normalizarNombreProducto(producto.nombre) == nombreNormalizado) {
        return producto;
      }
    }

    return null;
  }

  String _normalizarNombreProducto(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  void _mostrarProductoRepetido(ProductoModel producto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.warning,
        content: Text(
          'Ya existe un producto con ese nombre: ${producto.nombre}. '
          'Revise el catalogo antes de cargarlo de nuevo.',
          style: const TextStyle(
            color: AppColors.background,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _mostrarErrorGuardado(Object error) {
    if (!mounted) return;

    final mensaje = error.toString().replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
        content: Text(
          mensaje.isEmpty
              ? 'No se pudo guardar el producto. Revise la conexion e intente nuevamente.'
              : mensaje,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Future<void> guardarProducto() async {
    if (guardando) return;
    if (!ref.read(authProvider).esPropietario) {
      _mostrarErrorGuardado(
        'Solo el propietario puede crear o modificar productos.',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final productoRepetido = _productoConNombreRepetido(nombreController.text);
    if (productoRepetido != null) {
      _mostrarProductoRepetido(productoRepetido);
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final ahora = DateTime.now();
      final categoria = categoriaSeleccionada == productoCategoriaOtra
          ? categoriaController.text.trim()
          : (categoriaSeleccionada ?? '').trim();
      final stockPorSucursal = {
        Branches.casaCentral: _parseNumber(stockSantaFeController.text),
        Branches.alberdi: _parseNumber(stockAlberdiController.text),
      };
      final minimoPorSucursal = {
        Branches.casaCentral: _parseNumber(stockMinimoSantaFeController.text),
        Branches.alberdi: _parseNumber(stockMinimoAlberdiController.text),
      };
      final stockTotal = stockPorSucursal.values.fold<double>(
        0,
        (total, value) => total + value,
      );
      final minimoTotal = minimoPorSucursal.values.fold<double>(
        0,
        (total, value) => total + value,
      );

      final imagenPersistente = await _imagenPersistente();

      final producto = ProductoModel(
        id: widget.producto?.id ?? ahora.millisecondsSinceEpoch.toString(),
        codigo: codigoController.text.trim(),
        codigoBarras: codigoBarrasController.text.trim(),
        nombre: nombreController.text.trim(),
        descripcion: descripcionController.text.trim(),
        categoria: categoria,
        marca: marcaController.text.trim(),
        proveedor: proveedorController.text.trim(),
        imagenPath: imagenPersistente,
        costo: _parseNumber(costoController.text),
        precio: _parseNumber(precioController.text),
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
    } catch (error) {
      _mostrarErrorGuardado(error);
      if (mounted) {
        setState(() {
          guardando = false;
        });
      }
      return;
    }

    if (!mounted) return;

    setState(() {
      guardando = false;
    });
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
    try {
      const typeGroup = XTypeGroup(
        label: 'Imagenes',
        extensions: ['jpg', 'jpeg', 'png', 'webp', 'jfif', 'heic', 'heif'],
        mimeTypes: [
          'image/jpeg',
          'image/png',
          'image/webp',
          'image/heic',
          'image/heif',
        ],
      );
      final archivo = await openFile(acceptedTypeGroups: [typeGroup]);

      if (archivo == null) {
        return;
      }

      final bytes = await archivo.readAsBytes();
      if (bytes.isEmpty) {
        _mostrarErrorFoto(
          'No se pudo leer la foto seleccionada. Intente descargarla desde WhatsApp y volver a elegirla.',
        );
        return;
      }
      final extension = p.extension(archivo.name).toLowerCase();
      final mime = _mimeImagen(extension, archivo.mimeType);

      if (kIsWeb) {
        if (!mounted) {
          return;
        }

        setState(() {
          imagenPathController.text =
              'data:$mime;base64,${base64Encode(bytes)}';
        });
        _advertirFormatoFoto(mime);
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
      _advertirFormatoFoto(mime);
    } catch (_) {
      _mostrarErrorFoto(
        'No se pudo cargar la foto. Si viene de WhatsApp, descarguela primero en Galeria o Archivos y vuelva a intentarlo.',
      );
    }
  }

  Future<String> _imagenPersistente() async {
    final value = imagenPathController.text.trim();
    if (value.isEmpty || value.startsWith('data:image/')) {
      return value;
    }

    if (kIsWeb) {
      return value;
    }

    final file = File(value);
    if (!await file.exists()) {
      return value;
    }

    final extension = p.extension(file.path).toLowerCase();
    final mime = _mimeImagen(extension, null);
    final bytes = await file.readAsBytes();
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  String _mimeImagen(String extension, String? reportedMime) {
    if (reportedMime != null && reportedMime.startsWith('image/')) {
      return reportedMime;
    }

    return switch (extension) {
      '.jpg' || '.jpeg' || '.jfif' => 'image/jpeg',
      '.webp' => 'image/webp',
      '.heic' => 'image/heic',
      '.heif' => 'image/heif',
      _ => 'image/png',
    };
  }

  void _advertirFormatoFoto(String mime) {
    if (!mounted || !(mime.contains('heic') || mime.contains('heif'))) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.warning,
        content: Text(
          'Foto cargada. Si no se visualiza en algun equipo, vuelva a subirla en formato JPG o PNG.',
          style: TextStyle(
            color: AppColors.background,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _mostrarErrorFoto(String mensaje) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
        content: Text(
          mensaje,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
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

              final productoRepetido = _productoConNombreRepetido(value);
              if (productoRepetido != null) {
                return "Ya existe un producto con ese nombre";
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
          const SizedBox(height: 12),
          _MarginSetter(
            controller: margenDeseadoController,
            onAplicar: aplicarMargenDeseado,
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
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Stock inicial por sucursal",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: stockSantaFeController,
                  keyboardType: TextInputType.number,
                  decoration: decoration("Stock Santa Fe"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: stockAlberdiController,
                  keyboardType: TextInputType.number,
                  decoration: decoration("Stock Alberdi"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: stockMinimoSantaFeController,
                  keyboardType: TextInputType.number,
                  decoration: decoration("Minimo Santa Fe"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: stockMinimoAlberdiController,
                  keyboardType: TextInputType.number,
                  decoration: decoration("Minimo Alberdi"),
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
                onPressed: guardando
                    ? null
                    : () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close),
                label: const Text("Cancelar"),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: guardando ? null : guardarProducto,
                icon: guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  guardando
                      ? "Guardando..."
                      : widget.producto == null
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

    try {
      return base64Decode(value.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }

  String _fotoNombre(String value) {
    if (value.startsWith('data:image/')) {
      return 'Foto cargada desde galeria';
    }

    return p.basename(value);
  }
}

class _MarginSetter extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAplicar;

  const _MarginSetter({required this.controller, required this.onAplicar});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 620;
    final field = TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: "Margen deseado %",
        helperText: "Calcula precio sobre el costo cargado",
        prefixIcon: const Icon(Icons.percent_rounded),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onSubmitted: (_) => onAplicar(),
    );

    final button = FilledButton.icon(
      onPressed: onAplicar,
      icon: const Icon(Icons.calculate_outlined),
      label: const Text("Aplicar precio"),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: .35)),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [field, const SizedBox(height: 10), button],
            )
          : Row(
              children: [
                Expanded(child: field),
                const SizedBox(width: 12),
                button,
              ],
            ),
    );
  }
}
