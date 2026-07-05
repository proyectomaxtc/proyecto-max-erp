import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/pdf_saver.dart';
import '../../auth/providers/auth_provider.dart';
import '../../productos/models/producto_model.dart';
import '../../productos/providers/producto_provider.dart';
import '../../../shared/layout/main_layout.dart';

class ComprobantesPage extends ConsumerStatefulWidget {
  const ComprobantesPage({super.key});

  @override
  ConsumerState<ComprobantesPage> createState() => _ComprobantesPageState();
}

class _ComprobantesPageState extends ConsumerState<ComprobantesPage> {
  final clienteController = TextEditingController(text: 'Consumidor Final');
  final telefonoController = TextEditingController();
  final direccionController = TextEditingController();
  final localidadController = TextEditingController();
  final cuitController = TextEditingController();
  final observacionesController = TextEditingController();
  final items = <_ComprobanteItem>[_ComprobanteItem()];

  String tipo = 'Remito';
  String? ultimoPdf;
  String? ultimaUbicacion;
  bool ultimoDescargado = false;

  double get total {
    return items.fold(0, (total, item) => total + item.subtotal);
  }

  @override
  void dispose() {
    clienteController.dispose();
    telefonoController.dispose();
    direccionController.dispose();
    localidadController.dispose();
    cuitController.dispose();
    observacionesController.dispose();
    for (final item in items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(productoProvider.notifier).cargarProductos();
    });
  }

  InputDecoration decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Future<void> generarPdf() async {
    final utiles = items
        .where((item) => item.descripcion.text.trim().isNotEmpty)
        .toList();

    if (utiles.isEmpty) {
      _mensaje('Agregue al menos un item', AppColors.warning);
      return;
    }

    final ahora = DateTime.now();
    final usuario = ref.read(authProvider).usuario;
    final pdf = pw.Document();
    final numero =
        '${ahora.year}${_dos(ahora.month)}${_dos(ahora.day)}-${ahora.millisecondsSinceEpoch}';

    pdf.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
        ),
        build: (context) {
          return [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: _brandMark()),
                pw.Container(
                  width: 92,
                  height: 26,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  child: pw.Text(
                    'X',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(width: 18),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'ORIGINAL - CLIENTE',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      tipo.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text('Nro. $numero'),
                    pw.Text('Fecha: ${_fecha(ahora)}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 18),
            pw.Center(
              child: pw.Text(
                'COMPROBANTE NO VALIDO COMO FACTURA',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _pdfDataRow('Cliente', clienteController.text.trim()),
                      _pdfDataRow('Domicilio', direccionController.text.trim()),
                      _pdfDataRow('CUIT', cuitController.text.trim()),
                    ],
                  ),
                ),
                pw.SizedBox(width: 24),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _pdfDataRow(
                        'Vendedor',
                        usuario?.nombre ?? 'Tucuman Cerraduras',
                      ),
                      _pdfDataRow('Telefono', telefonoController.text.trim()),
                      _pdfDataRow('Localidad', localidadController.text.trim()),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Cant',
                'Descripcion',
                'U x B',
                '\$ Unitario',
                'Dto',
                '\$ Bulto',
                'Total',
              ],
              data: utiles
                  .map(
                    (item) => [
                      item.cantidad.toStringAsFixed(0),
                      item.descripcion.text.trim(),
                      '1.00',
                      _money(item.precio),
                      '',
                      _money(item.precio),
                      _money(item.subtotal),
                    ],
                  )
                  .toList(),
              border: pw.TableBorder.all(width: .7),
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
              cellAlignments: const {
                0: pw.Alignment.center,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.centerRight,
                6: pw.Alignment.centerRight,
              },
            ),
            pw.SizedBox(height: 18),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Observaciones',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        observacionesController.text.trim(),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 26),
                pw.Container(
                  width: 150,
                  child: pw.Column(
                    children: [
                      _totalRow('Subtotal', total, bold: false),
                      _totalRow('Descuento', 0, bold: false),
                      pw.Divider(height: 4, thickness: .7),
                      _totalRow('Total', total, bold: true),
                    ],
                  ),
                ),
              ],
            ),
            pw.Spacer(),
            pw.Center(
              child: pw.Column(
                children: [
                  _brandMark(centered: true, large: true),
                  pw.SizedBox(height: 18),
                  pw.Text(
                    'Forma de pago: efectivo / transferencia',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    final fileName =
        '${tipo.toLowerCase()}-${clienteController.text.trim().replaceAll(' ', '_')}-$numero.pdf';
    final result = await savePdfBytes(
      bytes: await pdf.save(),
      fileName: fileName,
      folderName: 'comprobantes',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      ultimoPdf = result.fileName;
      ultimaUbicacion = result.location;
      ultimoDescargado = result.downloaded;
    });
    _mensaje(
      result.downloaded
          ? 'PDF descargado correctamente'
          : 'PDF generado correctamente',
      AppColors.success,
    );
  }

  void agregarItem() {
    setState(() {
      items.add(_ComprobanteItem());
    });
  }

  void quitarItem(_ComprobanteItem item) {
    if (items.length == 1) {
      item.descripcion.clear();
      item.cantidadController.text = '1';
      item.precioController.text = '0';
      setState(() {});
      return;
    }

    setState(() {
      items.remove(item);
      item.dispose();
    });
  }

  void _mensaje(String texto, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(backgroundColor: color, content: Text(texto)));
  }

  String _dos(int value) => value.toString().padLeft(2, '0');

  String _fecha(DateTime fecha) {
    return '${_dos(fecha.day)}/${_dos(fecha.month)}/${fecha.year}';
  }

  String _money(double value) {
    return '\$ ${value.toStringAsFixed(0)}';
  }

  pw.Widget _brandMark({bool centered = false, bool large = false}) {
    final yellow = PdfColor.fromHex('#FFC107');
    final tucumanSize = large ? 18.0 : 14.0;
    final cerradurasSize = large ? 18.0 : 14.0;

    return pw.Column(
      crossAxisAlignment: centered
          ? pw.CrossAxisAlignment.center
          : pw.CrossAxisAlignment.start,
      children: [
        pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: 'TUCUMAN ',
                style: pw.TextStyle(
                  color: yellow,
                  fontSize: tucumanSize,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.TextSpan(
                text: 'CERRADURAS',
                style: pw.TextStyle(
                  color: PdfColors.black,
                  fontSize: cerradurasSize,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (large) ...[
          pw.SizedBox(height: 4),
          pw.Container(width: 82, height: 3, color: yellow),
        ],
      ],
    );
  }

  pw.Widget _totalRow(String label, double value, {required bool bold}) {
    final style = pw.TextStyle(
      fontSize: 8,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label.toUpperCase(), style: style),
          pw.Text(_money(value), style: style),
        ],
      ),
    );
  }

  pw.Widget _pdfDataRow(String label, String value) {
    final text = value.trim().isEmpty ? '-' : value.trim();

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.TextSpan(text: text),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esPropietario = ref.watch(authProvider).esPropietario;
    final productos = ref.watch(productoProvider).productos;
    final productosActivos =
        productos.where((producto) => producto.activo).toList()..sort(
          (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
        );
    final compact = MediaQuery.sizeOf(context).width < 760;

    if (!esPropietario) {
      return const MainLayout(
        title: 'Comprobantes',
        child: Center(
          child: Text(
            'Solo el propietario puede generar comprobantes.',
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
      title: 'Comprobantes',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(compact ? 14 : 22),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _ResponsiveFields(
                    compact: compact,
                    children: [
                      _FieldSlot(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          initialValue: tipo,
                          isExpanded: true,
                          dropdownColor: AppColors.surface,
                          decoration: decoration('Tipo'),
                          items: const [
                            DropdownMenuItem(
                              value: 'Remito',
                              child: Text('Remito'),
                            ),
                            DropdownMenuItem(
                              value: 'Presupuesto',
                              child: Text('Presupuesto'),
                            ),
                            DropdownMenuItem(
                              value: 'Trabajo',
                              child: Text('Trabajo'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => tipo = value ?? tipo);
                          },
                        ),
                      ),
                      _FieldSlot(
                        flex: 2,
                        child: TextField(
                          controller: clienteController,
                          decoration: decoration('Cliente'),
                        ),
                      ),
                      _FieldSlot(
                        flex: 2,
                        child: TextField(
                          controller: telefonoController,
                          decoration: decoration('Telefono / WhatsApp'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ResponsiveFields(
                    compact: compact,
                    children: [
                      _FieldSlot(
                        flex: 2,
                        child: TextField(
                          controller: direccionController,
                          decoration: decoration('Domicilio'),
                        ),
                      ),
                      _FieldSlot(
                        flex: 1,
                        child: TextField(
                          controller: localidadController,
                          decoration: decoration('Localidad'),
                        ),
                      ),
                      _FieldSlot(
                        flex: 1,
                        child: TextField(
                          controller: cuitController,
                          decoration: decoration('CUIL/CUIT'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...items.map(
                    (item) => _ItemRow(
                      compact: compact,
                      item: item,
                      productos: productosActivos,
                      onChanged: () => setState(() {}),
                      onRemove: () => quitarItem(item),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: agregarItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar item'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: observacionesController,
                    maxLines: 3,
                    decoration: decoration('Observaciones'),
                  ),
                  const SizedBox(height: 22),
                  compact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Total: ${CurrencyFormatter.format(total)}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 14),
                            FilledButton.icon(
                              onPressed: generarPdf,
                              icon: const Icon(Icons.picture_as_pdf_outlined),
                              label: const Text('Generar PDF'),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Text(
                              'Total: ${CurrencyFormatter.format(total)}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: generarPdf,
                              icon: const Icon(Icons.picture_as_pdf_outlined),
                              label: const Text('Generar PDF'),
                            ),
                          ],
                        ),
                ],
              ),
            ),
            if (ultimoPdf != null) ...[
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.success),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.check_circle_outline,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PDF listo para enviar por WhatsApp',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ultimoDescargado
                                ? 'Ubicacion: ${ultimaUbicacion ?? 'Descargas del navegador'}'
                                : 'Carpeta: ${ultimaUbicacion ?? '-'}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            'Archivo: $ultimoPdf',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ultimoDescargado
                                ? 'En web queda en la carpeta de descargas del navegador. Desde el celular puede compartirlo desde descargas.'
                                : 'En Windows busquelo en Documentos > proyecto_max > comprobantes.',
                            style: TextStyle(
                              color: AppColors.textDisabled,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  final bool compact;
  final List<_FieldSlot> children;

  const _ResponsiveFields({required this.compact, required this.children});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index].child,
            if (index < children.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          Expanded(flex: children[index].flex, child: children[index].child),
          if (index < children.length - 1) const SizedBox(width: 16),
        ],
      ],
    );
  }
}

class _FieldSlot {
  final int flex;
  final Widget child;

  const _FieldSlot({required this.flex, required this.child});
}

class _ComprobanteItem {
  String? productoId;
  final descripcion = TextEditingController();
  final cantidadController = TextEditingController(text: '1');
  final precioController = TextEditingController(text: '0');

  double get cantidad => double.tryParse(cantidadController.text) ?? 0;

  double get precio => double.tryParse(precioController.text) ?? 0;

  double get subtotal => cantidad * precio;

  void dispose() {
    descripcion.dispose();
    cantidadController.dispose();
    precioController.dispose();
  }
}

class _ItemRow extends StatelessWidget {
  final bool compact;
  final _ComprobanteItem item;
  final List<ProductoModel> productos;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _ItemRow({
    required this.compact,
    required this.item,
    required this.productos,
    required this.onChanged,
    required this.onRemove,
  });

  InputDecoration decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _productSelector() {
    return DropdownButtonFormField<String>(
      initialValue: item.productoId ?? '',
      isExpanded: true,
      dropdownColor: AppColors.surface,
      decoration: decoration('Producto cargado'),
      items: [
        const DropdownMenuItem(
          value: '',
          child: Text('Carga manual / servicio'),
        ),
        ...productos.map(
          (producto) => DropdownMenuItem(
            value: producto.id,
            child: Text(
              '${producto.nombre} - ${CurrencyFormatter.format(producto.precio)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: (value) {
        item.productoId = value == null || value.isEmpty ? null : value;
        if (item.productoId == null) {
          onChanged();
          return;
        }

        final producto = productos.firstWhere(
          (producto) => producto.id == item.productoId,
          orElse: ProductoModel.empty,
        );

        if (producto.id.isEmpty) {
          onChanged();
          return;
        }

        item.descripcion.text = producto.nombre;
        item.precioController.text = producto.precio.toStringAsFixed(0);
        onChanged();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            _productSelector(),
            const SizedBox(height: 12),
            TextField(
              controller: item.descripcion,
              decoration: decoration('Articulo o servicio'),
              onChanged: (_) => onChanged(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: item.cantidadController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: decoration('Cant.'),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: item.precioController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: decoration('Precio'),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    CurrencyFormatter.format(item.subtotal),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton.outlined(
                  tooltip: 'Quitar',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          _productSelector(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: TextField(
                  controller: item.descripcion,
                  decoration: decoration('Articulo o servicio'),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: TextField(
                  controller: item.cantidadController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: decoration('Cant.'),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 150,
                child: TextField(
                  controller: item.precioController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: decoration('Precio'),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 140,
                child: Text(
                  CurrencyFormatter.format(item.subtotal),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Quitar',
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
