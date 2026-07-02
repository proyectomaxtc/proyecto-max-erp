import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../app/routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/company.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../caja/models/caja_movimiento_model.dart';
import '../../caja/providers/caja_provider.dart';
import '../../clientes/models/cliente_model.dart';
import '../../clientes/providers/cliente_provider.dart';
import '../../notificaciones/providers/notification_provider.dart';
import '../../productos/models/producto_model.dart';
import '../../productos/providers/producto_provider.dart';
import '../models/venta_item_model.dart';
import '../models/venta_model.dart';
import '../providers/venta_provider.dart';

class VentaForm extends ConsumerStatefulWidget {
  const VentaForm({super.key});

  @override
  ConsumerState<VentaForm> createState() => _VentaFormState();
}

class _VentaFormState extends ConsumerState<VentaForm> {
  final _formKey = GlobalKey<FormState>();
  final descuentoController = TextEditingController(text: '0');
  final observacionesController = TextEditingController();

  ClienteModel? clienteSeleccionado;
  ProductoModel? productoSeleccionado;
  String medioPago = 'Efectivo';
  String estado = 'Completada';
  bool modoCopiasLlaves = false;
  final List<VentaItemModel> items = [];

  double get subtotal {
    return items.fold(0, (total, item) => total + item.subtotal);
  }

  double get descuento {
    return double.tryParse(descuentoController.text) ?? 0;
  }

  double get total {
    final resultado = subtotal - descuento;
    return resultado < 0 ? 0 : resultado;
  }

  double get costoTotal {
    return items.fold(0, (total, item) => total + item.costoTotal);
  }

  @override
  void initState() {
    super.initState();

    descuentoController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    descuentoController.dispose();
    observacionesController.dispose();
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

  void agregarItem() {
    final producto = productoSeleccionado;
    final sucursal = _sucursalOperativa();

    if (producto == null) {
      return;
    }

    final stockDisponible = producto.stockEnSucursal(sucursal);

    if (stockDisponible <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('El producto seleccionado no tiene stock disponible'),
        ),
      );
      return;
    }

    final index = items.indexWhere((item) => item.productoId == producto.id);

    setState(() {
      if (index >= 0) {
        final item = items[index];
        final nuevaCantidad = item.cantidad + 1;

        if (nuevaCantidad > stockDisponible) {
          return;
        }

        items[index] = VentaItemModel(
          productoId: item.productoId,
          codigo: item.codigo,
          nombre: item.nombre,
          cantidad: nuevaCantidad,
          precioUnitario: item.precioUnitario,
          costoUnitario: item.costoUnitario,
        );
      } else {
        items.add(
          VentaItemModel(
            productoId: producto.id,
            codigo: producto.codigo,
            nombre: producto.nombre,
            cantidad: 1,
            precioUnitario: producto.precio,
            costoUnitario: producto.costo,
          ),
        );
      }
    });
  }

  void agregarProducto(ProductoModel producto) {
    final sucursal = _sucursalOperativa();
    final stockDisponible = producto.stockEnSucursal(sucursal);

    if (stockDisponible <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('El producto seleccionado no tiene stock disponible'),
        ),
      );
      return;
    }

    final index = items.indexWhere((item) => item.productoId == producto.id);

    setState(() {
      if (index >= 0) {
        final item = items[index];
        final nuevaCantidad = item.cantidad + 1;

        if (nuevaCantidad > stockDisponible) {
          return;
        }

        items[index] = VentaItemModel(
          productoId: item.productoId,
          codigo: item.codigo,
          nombre: item.nombre,
          cantidad: nuevaCantidad,
          precioUnitario: item.precioUnitario,
          costoUnitario: item.costoUnitario,
        );
        return;
      }

      items.add(
        VentaItemModel(
          productoId: producto.id,
          codigo: producto.codigo,
          nombre: producto.nombre,
          cantidad: 1,
          precioUnitario: producto.precio,
          costoUnitario: producto.costo,
        ),
      );
    });
  }

  void actualizarCantidad(VentaItemModel item, double cantidad) {
    final productos = ref.read(productoProvider).productos;
    final sucursal = _sucursalOperativa();
    final producto = productos.firstWhere(
      (producto) => producto.id == item.productoId,
      orElse: () => ProductoModel.empty(),
    );

    if (cantidad <= 0) {
      setState(() {
        items.remove(item);
      });
      return;
    }

    final stockDisponible = producto.stockEnSucursal(sucursal);

    if (producto.id.isNotEmpty && cantidad > stockDisponible) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.warning,
          content: Text(
            'Stock disponible: ${stockDisponible.toStringAsFixed(0)}',
          ),
        ),
      );
      return;
    }

    final index = items.indexOf(item);

    setState(() {
      items[index] = VentaItemModel(
        productoId: item.productoId,
        codigo: item.codigo,
        nombre: item.nombre,
        cantidad: cantidad,
        precioUnitario: item.precioUnitario,
        costoUnitario: item.costoUnitario,
      );
    });
  }

  Future<void> guardarVenta() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (clienteSeleccionado == null) {
      _mostrarError('Seleccione un cliente para continuar');
      return;
    }

    if (items.isEmpty) {
      _mostrarError('Agregue al menos un producto a la venta');
      return;
    }

    final usuario = ref.read(authProvider).usuario;
    final sucursal = _sucursalOperativa();

    if (estado == 'Completada' &&
        ref.read(cajaProvider).turnoAbiertoParaSucursal(sucursal) == null) {
      _mostrarError(
        'Debe abrir caja de $sucursal antes de registrar una venta completada',
      );
      return;
    }

    final ahora = DateTime.now();
    final numero = await ref.read(ventaProvider.notifier).generarNumeroVenta();
    final cliente = clienteSeleccionado!;

    final venta = VentaModel(
      id: ahora.millisecondsSinceEpoch.toString(),
      numero: numero,
      clienteId: cliente.id,
      clienteNombre: '${cliente.nombre} ${cliente.apellido}'.trim(),
      sucursal: sucursal,
      items: List.unmodifiable(items),
      subtotal: subtotal,
      descuento: descuento,
      total: total,
      costoTotal: costoTotal,
      medioPago: medioPago,
      estado: estado,
      fecha: ahora,
      observaciones: observacionesController.text.trim(),
    );

    await ref.read(ventaProvider.notifier).agregarVenta(venta);

    if (estado == 'Completada') {
      await _descontarStock();
      await _registrarIngresoCaja(venta);
    }

    await ref
        .read(notificationProvider.notifier)
        .registrar(
          usuario: usuario,
          tipo: 'Venta',
          titulo: 'Venta ${venta.numero}',
          detalle:
              '${venta.clienteNombre} - ${CurrencyFormatter.format(venta.total)} - ${venta.sucursal}',
          ruta: AppRoutes.ventas,
          monto: venta.total,
        );

    if (!mounted) return;

    final ticketPath = await _ofrecerTicket(venta);

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text(
          ticketPath == null
              ? 'Venta registrada correctamente'
              : 'Venta registrada. Ticket generado: $ticketPath',
        ),
      ),
    );
  }

  Future<void> _descontarStock() async {
    final productos = ref.read(productoProvider).productos;
    final notifier = ref.read(productoProvider.notifier);
    final sucursal = _sucursalOperativa();

    for (final item in items) {
      final producto = productos.firstWhere(
        (producto) => producto.id == item.productoId,
        orElse: () => ProductoModel.empty(),
      );

      if (producto.id.isEmpty) {
        continue;
      }

      await notifier.actualizarProducto(
        producto
            .conStockSucursal(
              sucursal: sucursal,
              stockSucursal: producto.stockEnSucursal(sucursal) - item.cantidad,
            )
            .copyWith(actualizado: DateTime.now()),
      );
    }
  }

  String _sucursalOperativa() {
    final usuario = ref.read(authProvider).usuario;
    if (usuario != null && !usuario.esPropietario) {
      return usuario.sucursal;
    }

    return ref.read(productoProvider).sucursalSeleccionada;
  }

  Future<void> _registrarIngresoCaja(VentaModel venta) async {
    final turno = ref
        .read(cajaProvider)
        .turnoAbiertoParaSucursal(venta.sucursal);

    if (turno == null) {
      return;
    }

    await ref
        .read(cajaProvider.notifier)
        .agregarMovimiento(
          CajaMovimientoModel(
            id: '${venta.id}-caja',
            tipo: 'Ingreso',
            concepto: 'Venta ${venta.numero} - ${venta.clienteNombre}',
            monto: venta.total,
            medioPago: venta.medioPago,
            referenciaId: venta.id,
            origen: 'Venta',
            turnoId: turno.id,
            responsable: turno.responsable,
            bloqueado: true,
            fecha: venta.fecha,
            observaciones: venta.observaciones,
          ),
        );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppColors.error, content: Text(mensaje)),
    );
  }

  Future<String?> _ofrecerTicket(VentaModel venta) async {
    final imprimir = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Ticket de venta"),
          content: Text(
            "Desea generar el ticket de la venta ${venta.numero} para el cliente?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No"),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text("Generar ticket"),
            ),
          ],
        );
      },
    );

    if (imprimir != true) {
      return null;
    }

    final path = await _generarTicketPdf(venta);
    return path;
  }

  Future<String> _generarTicketPdf(VentaModel venta) async {
    final pdf = pw.Document();
    final logoBytes = await rootBundle.load(Company.logo);
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(226.77, 600),
        margin: const pw.EdgeInsets.all(14),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Image(logo, width: 58, height: 58)),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  Company.name,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  "Ticket no fiscal",
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              pw.Divider(),
              pw.Text("Venta: ${venta.numero}"),
              pw.Text("Fecha: ${_fechaTicket(venta.fecha)}"),
              pw.Text("Cliente: ${venta.clienteNombre}"),
              pw.Text("Sucursal: ${venta.sucursal}"),
              pw.Text("Pago: ${venta.medioPago}"),
              pw.Divider(),
              ...venta.items.map(
                (item) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        item.nombre,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            "${item.cantidad.toStringAsFixed(0)} x ${_money(item.precioUnitario)}",
                          ),
                          pw.Text(_money(item.subtotal)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Subtotal"),
                  pw.Text(_money(venta.subtotal)),
                ],
              ),
              if (venta.descuento > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Descuento"),
                    pw.Text(_money(venta.descuento)),
                  ],
                ),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "TOTAL",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    _money(venta.total),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              if (venta.observaciones.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Text("Obs.: ${venta.observaciones}"),
              ],
              pw.SizedBox(height: 16),
              pw.Center(child: pw.Text("Gracias por su compra")),
            ],
          );
        },
      ),
    );

    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'proyecto_max', 'tickets'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final file = File(p.join(dir.path, 'ticket-${venta.numero}.pdf'));
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  String _fechaTicket(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year} $hora:$minuto';
  }

  String _money(double value) {
    return '\$ ${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final clientes = ref
        .watch(clienteProvider)
        .clientes
        .where((cliente) => cliente.activo)
        .toList();
    if (clienteSeleccionado == null) {
      for (final cliente in clientes) {
        if (cliente.id == ClienteModel.consumidorFinalId) {
          clienteSeleccionado = cliente;
          break;
        }
      }
    }
    final sucursal = _sucursalOperativa();
    final productos = ref
        .watch(productoProvider)
        .productos
        .where(
          (producto) =>
              producto.activo && producto.stockEnSucursal(sucursal) > 0,
        )
        .toList();
    final productosLlaves = productos.where(_esProductoLlave).toList();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<ClienteModel>(
                  initialValue: clienteSeleccionado,
                  decoration: decoration("Cliente"),
                  dropdownColor: AppColors.surface,
                  items: clientes
                      .map(
                        (cliente) => DropdownMenuItem(
                          value: cliente,
                          child: Text(
                            '${cliente.nombre} ${cliente.apellido}'.trim(),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (cliente) {
                    setState(() {
                      clienteSeleccionado = cliente;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return "Seleccione un cliente";
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: medioPago,
                  decoration: decoration("Medio de pago"),
                  dropdownColor: AppColors.surface,
                  items: const [
                    DropdownMenuItem(
                      value: 'Efectivo',
                      child: Text('Efectivo'),
                    ),
                    DropdownMenuItem(
                      value: 'Transferencia',
                      child: Text('Transferencia'),
                    ),
                    DropdownMenuItem(value: 'Tarjeta', child: Text('Tarjeta')),
                    DropdownMenuItem(
                      value: 'Cuenta corriente',
                      child: Text('Cuenta corriente'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      medioPago = value ?? medioPago;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SwitchListTile(
            value: modoCopiasLlaves,
            title: const Text(
              "Modo copias de llaves",
              style: TextStyle(color: AppColors.textPrimary),
            ),
            subtitle: const Text(
              "Muestra modelos visuales filtrados para duplicados.",
              style: TextStyle(color: AppColors.textSecondary),
            ),
            onChanged: (value) {
              setState(() {
                modoCopiasLlaves = value;
              });
            },
          ),
          const SizedBox(height: 12),
          if (modoCopiasLlaves) ...[
            _KeyCopyGrid(productos: productosLlaves, onAdd: agregarProducto),
            const SizedBox(height: 20),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ProductoModel>(
                    initialValue: productoSeleccionado,
                    decoration: decoration("Producto"),
                    dropdownColor: AppColors.surface,
                    items: productos
                        .map(
                          (producto) => DropdownMenuItem(
                            value: producto,
                            child: Text(
                              '${producto.codigo} - ${producto.nombre}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (producto) {
                      setState(() {
                        productoSeleccionado = producto;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: agregarItem,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text("Agregar"),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          _ItemsTable(
            items: items,
            onCantidadChanged: actualizarCantidad,
            onRemove: (item) {
              setState(() {
                items.remove(item);
              });
            },
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: observacionesController,
                  maxLines: 4,
                  decoration: decoration("Observaciones"),
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 300,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: estado,
                      decoration: decoration("Estado"),
                      dropdownColor: AppColors.surface,
                      items: const [
                        DropdownMenuItem(
                          value: 'Completada',
                          child: Text('Completada'),
                        ),
                        DropdownMenuItem(
                          value: 'Pendiente',
                          child: Text('Pendiente'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          estado = value ?? estado;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: descuentoController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: decoration("Descuento"),
                    ),
                    const SizedBox(height: 14),
                    _TotalBox(
                      subtotal: subtotal,
                      descuento: descuento,
                      total: total,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
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
                onPressed: guardarVenta,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Registrar Venta"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _esProductoLlave(ProductoModel producto) {
    final texto = [
      producto.nombre,
      producto.categoria,
      producto.descripcion,
      producto.marca,
    ].join(' ').toLowerCase();

    return texto.contains('llave') ||
        texto.contains('copia') ||
        texto.contains('duplicado');
  }
}

class _KeyCopyGrid extends StatelessWidget {
  final List<ProductoModel> productos;
  final void Function(ProductoModel producto) onAdd;

  const _KeyCopyGrid({required this.productos, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    if (productos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          "No hay productos marcados como llaves. Use categoria/nombre con 'llave', 'copia' o 'duplicado'.",
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.08,
      ),
      itemCount: productos.length,
      itemBuilder: (context, index) {
        final producto = productos[index];

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onAdd(producto),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: _ProductImage(path: producto.imagenPath),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  producto.codigo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  producto.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(producto.precio),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String path;

  const _ProductImage({required this.path});

  @override
  Widget build(BuildContext context) {
    final imageBytes = _imageBytes(path);
    final tieneFoto =
        imageBytes != null ||
        path.trim().isNotEmpty &&
            (path.startsWith('assets/') ||
                (!kIsWeb && File(path).existsSync()));

    if (!tieneFoto) {
      return const Icon(
        Icons.key_rounded,
        color: AppColors.textDisabled,
        size: 42,
      );
    }

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: imageBytes != null
          ? Image.memory(imageBytes, fit: BoxFit.cover)
          : path.startsWith('assets/')
          ? Image.asset(path, fit: BoxFit.cover)
          : Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.key_rounded,
                  color: AppColors.textDisabled,
                  size: 42,
                );
              },
            ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _mostrarFoto(context, imageBytes),
      child: MouseRegion(cursor: SystemMouseCursors.click, child: image),
    );
  }

  void _mostrarFoto(BuildContext context, Uint8List? imageBytes) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: AppColors.surface,
          insetPadding: const EdgeInsets.all(18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * .9,
                      maxHeight: MediaQuery.sizeOf(context).height * .75,
                    ),
                    child: imageBytes != null
                        ? Image.memory(imageBytes, fit: BoxFit.contain)
                        : path.startsWith('assets/')
                        ? Image.asset(path, fit: BoxFit.contain)
                        : Image.file(File(path), fit: BoxFit.contain),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: IconButton.filled(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        );
      },
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
}

class _ItemsTable extends StatelessWidget {
  final List<VentaItemModel> items;
  final void Function(VentaItemModel item, double cantidad) onCantidadChanged;
  final void Function(VentaItemModel item) onRemove;

  const _ItemsTable({
    required this.items,
    required this.onCantidadChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          "Agrega productos para armar el detalle de la venta.",
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: items.map((item) {
          final cantidadText = item.cantidad % 1 == 0
              ? item.cantidad.toStringAsFixed(0)
              : item.cantidad.toStringAsFixed(2);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.nombre,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 116,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: "Restar",
                          onPressed: () {
                            onCantidadChanged(item, item.cantidad - 1);
                          },
                          icon: const Icon(Icons.remove, size: 18),
                        ),
                        Expanded(
                          child: Text(
                            cantidadText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: "Sumar",
                          onPressed: () {
                            onCantidadChanged(item, item.cantidad + 1);
                          },
                          icon: const Icon(Icons.add, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                SizedBox(
                  width: 110,
                  child: Text(
                    CurrencyFormatter.format(item.precioUnitario),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 18),
                SizedBox(
                  width: 120,
                  child: Text(
                    CurrencyFormatter.format(item.subtotal),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: "Quitar",
                  onPressed: () => onRemove(item),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TotalBox extends StatelessWidget {
  final double subtotal;
  final double descuento;
  final double total;

  const _TotalBox({
    required this.subtotal,
    required this.descuento,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: .45)),
      ),
      child: Column(
        children: [
          _TotalRow(
            label: "Subtotal",
            value: CurrencyFormatter.format(subtotal),
          ),
          const SizedBox(height: 8),
          _TotalRow(
            label: "Descuento",
            value: CurrencyFormatter.format(descuento),
          ),
          const Divider(height: 24),
          _TotalRow(
            label: "Total",
            value: CurrencyFormatter.format(total),
            destacado: true,
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool destacado;

  const _TotalRow({
    required this.label,
    required this.value,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: destacado ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: destacado ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: destacado ? 22 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
