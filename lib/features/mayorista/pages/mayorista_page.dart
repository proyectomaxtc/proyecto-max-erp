import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/pdf_saver.dart';
import '../../../shared/layout/main_layout.dart';
import '../../../shared/widgets/dialogs/app_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../../productos/models/producto_model.dart';
import '../../productos/providers/producto_provider.dart';
import '../../ventas/widgets/venta_form.dart';

class MayoristaPage extends ConsumerStatefulWidget {
  const MayoristaPage({super.key});

  @override
  ConsumerState<MayoristaPage> createState() => _MayoristaPageState();
}

class _MayoristaPageState extends ConsumerState<MayoristaPage> {
  final busquedaController = TextEditingController();
  final preciosControllers = <String, TextEditingController>{};
  String busqueda = '';
  bool guardando = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(productoProvider.notifier).cargarProductos();
    });
  }

  @override
  void dispose() {
    busquedaController.dispose();
    for (final controller in preciosControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<ProductoModel> _productosFiltrados(List<ProductoModel> productos) {
    final texto = busqueda.trim().toLowerCase();
    final activos = productos.where((producto) => producto.activo).toList()
      ..sort(
        (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
      );

    if (texto.isEmpty) {
      return activos;
    }

    return activos.where((producto) {
      return producto.nombre.toLowerCase().contains(texto) ||
          producto.codigo.toLowerCase().contains(texto) ||
          producto.categoria.toLowerCase().contains(texto) ||
          producto.marca.toLowerCase().contains(texto);
    }).toList();
  }

  TextEditingController _controllerPara(ProductoModel producto) {
    return preciosControllers.putIfAbsent(
      producto.id,
      () => TextEditingController(
        text: producto.precioMayorista <= 0
            ? ''
            : producto.precioMayorista.toStringAsFixed(0),
      ),
    );
  }

  Future<void> _guardarPrecio(ProductoModel producto) async {
    final controller = _controllerPara(producto);
    final precio = _parseNumber(controller.text);

    setState(() => guardando = true);
    await ref
        .read(productoProvider.notifier)
        .actualizarProducto(
          producto.copyWith(
            precioMayorista: precio,
            actualizado: DateTime.now(),
          ),
        );

    if (!mounted) {
      return;
    }

    setState(() => guardando = false);
    _mensaje('Precio mayorista actualizado', AppColors.success);
  }

  Future<void> _generarPdf(List<ProductoModel> productos) async {
    final conPrecio =
        productos
            .where(
              (producto) => producto.activo && producto.precioMayorista > 0,
            )
            .toList()
          ..sort(
            (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
          );

    if (conPrecio.isEmpty) {
      _mensaje('Cargue al menos un precio mayorista', AppColors.warning);
      return;
    }

    final ahora = DateTime.now();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(28),
        ),
        build: (context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _brandMark(),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'LISTA MAYORISTA',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text('Fecha: ${_fecha(ahora)}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 18),
            pw.TableHelper.fromTextArray(
              headers: const ['Codigo', 'Producto', 'Categoria', 'Mayorista'],
              data: conPrecio
                  .map(
                    (producto) => [
                      producto.codigo,
                      producto.nombre,
                      producto.categoria,
                      _money(producto.precioMayorista),
                    ],
                  )
                  .toList(),
              border: pw.TableBorder.all(width: .5),
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 4,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: const {3: pw.Alignment.centerRight},
            ),
            pw.SizedBox(height: 18),
            pw.Text(
              'Precios sujetos a modificacion sin previo aviso.',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ];
        },
      ),
    );

    final fileName =
        'lista-mayorista-${ahora.year}${_dos(ahora.month)}${_dos(ahora.day)}.pdf';
    final result = await savePdfBytes(
      bytes: await pdf.save(),
      fileName: fileName,
      folderName: 'mayorista',
    );

    if (!mounted) {
      return;
    }

    _mensaje(
      result.downloaded
          ? 'Lista mayorista descargada'
          : 'Lista mayorista generada',
      AppColors.success,
    );
  }

  void _abrirVentaMayorista() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const AppDialog(
          title: 'Nueva Venta Mayorista',
          child: VentaForm(mayorista: true),
        );
      },
    );
  }

  Future<void> _abrirImportadorMayorista(List<ProductoModel> productos) async {
    final controller = TextEditingController();
    final texto = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Importar lista mayorista'),
          content: SizedBox(
            width: 680,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pegue aqui el texto copiado de un PDF, Excel o lista. La app buscara coincidencias por codigo, codigo de proveedor o nombre y tomara el ultimo importe de cada linea como precio mayorista.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  minLines: 10,
                  maxLines: 14,
                  decoration: const InputDecoration(
                    hintText:
                        'Ejemplo: LCC-04301 Andif 857-40 Cerradura ... 14910',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, controller.text),
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Importar'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (texto == null || texto.trim().isEmpty) {
      return;
    }

    final resultado = _extraerPreciosMayoristas(texto, productos);
    if (resultado.precios.isEmpty) {
      _mensaje(
        'No se encontraron coincidencias para actualizar.',
        AppColors.warning,
      );
      return;
    }

    setState(() => guardando = true);
    final actualizados = await ref
        .read(productoProvider.notifier)
        .actualizarPreciosMayoristas(resultado.precios);

    if (!mounted) {
      return;
    }

    setState(() => guardando = false);
    _mensaje(
      'Precios mayoristas actualizados: $actualizados. Lineas sin coincidencia: ${resultado.ignoradas}.',
      AppColors.success,
    );
  }

  _ImportMayoristaResult _extraerPreciosMayoristas(
    String texto,
    List<ProductoModel> productos,
  ) {
    final precios = <String, double>{};
    var ignoradas = 0;
    final activos = productos.where((producto) => producto.activo).toList();

    for (final rawLine in texto.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        continue;
      }

      final producto = _buscarProductoEnLinea(line, activos);
      final precio = _ultimoImporte(line);
      if (producto == null || precio <= 0) {
        ignoradas++;
        continue;
      }

      precios[producto.id] = precio;
    }

    return _ImportMayoristaResult(precios: precios, ignoradas: ignoradas);
  }

  ProductoModel? _buscarProductoEnLinea(
    String line,
    List<ProductoModel> productos,
  ) {
    final normalizada = _normalizar(_lineaSinUltimoImporte(line));
    final tokensLinea = _tokens(normalizada).toSet();
    final porCodigo = [...productos]..sort(
      (a, b) => b.codigo.length.compareTo(a.codigo.length),
    );

    for (final producto in porCodigo) {
      final codigo = _normalizar(producto.codigo);
      final barras = _normalizar(producto.codigoBarras);
      if (codigo.length > 2 && normalizada.contains(codigo)) {
        return producto;
      }
      if (barras.length > 2 && normalizada.contains(barras)) {
        return producto;
      }
    }

    final porMarcaModelo = _buscarPorMarcaModelo(tokensLinea, productos);
    if (porMarcaModelo != null) {
      return porMarcaModelo;
    }

    ProductoModel? mejorProducto;
    var mejorPuntaje = 0;
    var segundoPuntaje = 0;

    for (final producto in productos) {
      final puntaje = _puntajeCoincidencia(producto, tokensLinea);
      if (puntaje > mejorPuntaje) {
        segundoPuntaje = mejorPuntaje;
        mejorPuntaje = puntaje;
        mejorProducto = producto;
      } else if (puntaje > segundoPuntaje) {
        segundoPuntaje = puntaje;
      }
    }

    if (mejorPuntaje >= 5 && mejorPuntaje > segundoPuntaje) {
      return mejorProducto;
    }

    return null;
  }

  ProductoModel? _buscarPorMarcaModelo(
    Set<String> tokensLinea,
    List<ProductoModel> productos,
  ) {
    final marcasLinea = tokensLinea
        .where((token) => RegExp(r'^[a-z]+$').hasMatch(token))
        .where((token) => !_tokensGenericos.contains(token))
        .toSet();
    final numerosLinea = tokensLinea
        .where((token) => RegExp(r'\d').hasMatch(token))
        .toSet();

    if (marcasLinea.isEmpty || numerosLinea.isEmpty) {
      return null;
    }

    final candidatos = <_ProductoMatch>[];
    for (final producto in productos) {
      final textoProducto = _normalizar(
        [
          producto.nombre,
          producto.marca,
          producto.codigo,
          producto.codigoBarras,
        ].join(' '),
      );
      final tokensProducto = _tokens(textoProducto).toSet();
      final coincideMarca = marcasLinea.any(tokensProducto.contains);
      final coincideNumero = numerosLinea.any(tokensProducto.contains);

      if (!coincideMarca || !coincideNumero) {
        continue;
      }

      final puntaje = tokensProducto
          .where(tokensLinea.contains)
          .fold<int>(0, (total, token) {
        if (RegExp(r'\d').hasMatch(token)) {
          return total + 5;
        }
        return total + 2;
      });
      candidatos.add(_ProductoMatch(producto: producto, puntaje: puntaje));
    }

    if (candidatos.isEmpty) {
      return null;
    }

    candidatos.sort((a, b) => b.puntaje.compareTo(a.puntaje));
    if (candidatos.length == 1 ||
        candidatos.first.puntaje > candidatos[1].puntaje) {
      return candidatos.first.producto;
    }

    return null;
  }

  double _ultimoImporte(String line) {
    final matches = RegExp(
      r'(\d{1,3}(?:[.\s]\d{3})+(?:,\d+)?|\d+(?:[,.]\d+)?)',
    ).allMatches(line).toList();
    if (matches.isEmpty) {
      return 0;
    }

    return _parseNumber(matches.last.group(0) ?? '');
  }

  String _lineaSinUltimoImporte(String line) {
    final matches = RegExp(
      r'(\d{1,3}(?:[.\s]\d{3})+(?:,\d+)?|\d+(?:[,.]\d+)?)',
    ).allMatches(line).toList();
    if (matches.isEmpty) {
      return line;
    }

    final ultimo = matches.last;
    return '${line.substring(0, ultimo.start)} ${line.substring(ultimo.end)}';
  }

  int _puntajeCoincidencia(ProductoModel producto, Set<String> tokensLinea) {
    final tokensProducto = _tokens(
      _normalizar(
        [
          producto.nombre,
          producto.categoria,
          producto.marca,
          producto.codigoBarras,
        ].join(' '),
      ),
    );
    var puntaje = 0;
    var tieneDistintivo = false;

    for (final tokenProducto in tokensProducto) {
      final match = tokensLinea.any(
        (tokenLinea) => _tokensCompatibles(tokenProducto, tokenLinea),
      );
      if (!match) {
        continue;
      }

      if (RegExp(r'\d').hasMatch(tokenProducto)) {
        puntaje += 4;
        tieneDistintivo = true;
      } else if (_esTokenDistintivo(tokenProducto)) {
        puntaje += 2;
        tieneDistintivo = true;
      } else {
        puntaje += 1;
      }
    }

    return tieneDistintivo ? puntaje : 0;
  }

  List<String> _tokens(String value) {
    return value
        .split(' ')
        .map((token) => token.trim())
        .where((token) => token.length > 1 && !_tokensGenericos.contains(token))
        .toList();
  }

  bool _tokensCompatibles(String a, String b) {
    if (a == b) {
      return true;
    }
    if (a.length >= 5 && b.length >= 5) {
      return a.contains(b) || b.contains(a);
    }

    return false;
  }

  bool _esTokenDistintivo(String token) {
    return token.length >= 4 && !_tokensGenericos.contains(token);
  }

  static const Set<String> _tokensGenericos = {
    'de',
    'del',
    'la',
    'el',
    'en',
    'con',
    'para',
    'tipo',
    'modelo',
    'precio',
    'cerradura',
    'cerraduras',
    'cerrojo',
    'cerrojos',
    'candado',
    'candados',
    'picaporte',
    'picaportes',
    'pasador',
    'pasadores',
    'seguridad',
    'bolsa',
    'placa',
    'placas',
    'perno',
    'pernos',
    'doble',
    'linea',
    'pesado',
    'comun',
  };

  String _normalizar(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  void _mensaje(String texto, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(backgroundColor: color, content: Text(texto)));
  }

  double _parseNumber(String value) {
    final limpio = value.trim();
    if (limpio.isEmpty) {
      return 0;
    }

    var normalizado = limpio;
    if (limpio.contains(',')) {
      normalizado = limpio.replaceAll('.', '').replaceAll(',', '.');
    } else if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(limpio)) {
      normalizado = limpio.replaceAll('.', '');
    }

    return double.tryParse(normalizado) ?? 0;
  }

  String _dos(int value) => value.toString().padLeft(2, '0');

  String _fecha(DateTime fecha) {
    return '${_dos(fecha.day)}/${_dos(fecha.month)}/${fecha.year}';
  }

  String _money(double value) {
    return '\$ ${value.toStringAsFixed(0)}';
  }

  pw.Widget _brandMark() {
    final yellow = PdfColor.fromHex('#FFC107');

    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: 'TUCUMAN ',
            style: pw.TextStyle(
              color: yellow,
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.TextSpan(
            text: 'CERRADURAS',
            style: pw.TextStyle(
              color: PdfColors.black,
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esPropietario = ref.watch(authProvider).esPropietario;
    final productos = ref.watch(productoProvider).productos;
    final filtrados = _productosFiltrados(productos);
    final compact = MediaQuery.sizeOf(context).width < 760;

    if (!esPropietario) {
      return const MainLayout(
        title: 'Mayorista',
        child: Center(
          child: Text(
            'Solo el propietario puede administrar precios mayoristas.',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return MainLayout(
      title: 'Mayorista',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 12 : 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SearchField(
                        controller: busquedaController,
                        onChanged: (value) => setState(() => busqueda = value),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => _generarPdf(productos),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Descargar lista PDF'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: guardando
                            ? null
                            : () => _abrirImportadorMayorista(productos),
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Importar lista/PDF'),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: _abrirVentaMayorista,
                        icon: const Icon(Icons.point_of_sale_outlined),
                        label: const Text('Venta mayorista'),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _SearchField(
                          controller: busquedaController,
                          onChanged: (value) =>
                              setState(() => busqueda = value),
                        ),
                      ),
                      const SizedBox(width: 14),
                      FilledButton.icon(
                        onPressed: () => _generarPdf(productos),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Descargar lista PDF'),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: guardando
                            ? null
                            : () => _abrirImportadorMayorista(productos),
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Importar lista/PDF'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: _abrirVentaMayorista,
                        icon: const Icon(Icons.point_of_sale_outlined),
                        label: const Text('Venta mayorista'),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: filtrados.isEmpty
                ? const Center(
                    child: Text(
                      'No hay productos para mostrar.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtrados.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final producto = filtrados[index];
                      return _MayoristaCard(
                        producto: producto,
                        controller: _controllerPara(producto),
                        compact: compact,
                        guardando: guardando,
                        onSave: () => _guardarPrecio(producto),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Buscar producto, codigo, categoria o marca...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _MayoristaCard extends StatelessWidget {
  final ProductoModel producto;
  final TextEditingController controller;
  final bool compact;
  final bool guardando;
  final VoidCallback onSave;

  const _MayoristaCard({
    required this.producto,
    required this.controller,
    required this.compact,
    required this.guardando,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProductInfo(producto: producto),
                const SizedBox(height: 12),
                _PriceEditor(
                  controller: controller,
                  guardando: guardando,
                  onSave: onSave,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: _ProductInfo(producto: producto)),
                const SizedBox(width: 16),
                SizedBox(
                  width: 330,
                  child: _PriceEditor(
                    controller: controller,
                    guardando: guardando,
                    onSave: onSave,
                  ),
                ),
              ],
            ),
    );
  }
}

class _ProductInfo extends StatelessWidget {
  final ProductoModel producto;

  const _ProductInfo({required this.producto});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          producto.nombre,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${producto.codigo} · ${producto.categoria}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Tag('Venta: ${CurrencyFormatter.format(producto.precio)}'),
            if (producto.marca.trim().isNotEmpty) _Tag(producto.marca),
          ],
        ),
      ],
    );
  }
}

class _PriceEditor extends StatelessWidget {
  final TextEditingController controller;
  final bool guardando;
  final VoidCallback onSave;

  const _PriceEditor({
    required this.controller,
    required this.guardando,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Precio mayorista',
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filled(
          tooltip: 'Guardar precio',
          onPressed: guardando ? null : onSave,
          icon: const Icon(Icons.save_outlined),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;

  const _Tag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }
}

class _ImportMayoristaResult {
  final Map<String, double> precios;
  final int ignoradas;

  const _ImportMayoristaResult({
    required this.precios,
    required this.ignoradas,
  });
}

class _ProductoMatch {
  final ProductoModel producto;
  final int puntaje;

  const _ProductoMatch({required this.producto, required this.puntaje});
}
