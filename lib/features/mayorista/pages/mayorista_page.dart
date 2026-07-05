import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/pdf_saver.dart';
import '../../../shared/layout/main_layout.dart';
import '../../auth/providers/auth_provider.dart';
import '../../productos/models/producto_model.dart';
import '../../productos/providers/producto_provider.dart';

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

  void _mensaje(String texto, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(backgroundColor: color, content: Text(texto)));
  }

  double _parseNumber(String value) {
    final normalizado = value.trim().replaceAll('.', '').replaceAll(',', '.');
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
