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

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/branches.dart';
import '../../../core/constants/company.dart';
import '../../../core/utils/currency_formatter.dart';
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
  final VentaModel? venta;
  final bool mayorista;

  const VentaForm({super.key, this.venta, this.mayorista = false});

  @override
  ConsumerState<VentaForm> createState() => _VentaFormState();
}

class _VentaFormState extends ConsumerState<VentaForm> {
  final _formKey = GlobalKey<FormState>();
  final descuentoController = TextEditingController(text: '0');
  final observacionesController = TextEditingController();
  final busquedaCopiasController = TextEditingController();

  ClienteModel? clienteSeleccionado;
  ProductoModel? productoSeleccionado;
  String medioPago = 'Efectivo';
  String estado = 'Completada';
  late String sucursalVenta;
  DateTime fechaVenta = DateTime.now();
  bool modoCopiasLlaves = false;
  bool guardandoVenta = false;
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

    final venta = widget.venta;
    sucursalVenta = _sucursalInicial();
    if (venta != null) {
      medioPago = venta.medioPago;
      estado = venta.estado;
      fechaVenta = venta.fecha;
      descuentoController.text = venta.descuento.toStringAsFixed(0);
      observacionesController.text = venta.observaciones;
      items.addAll(venta.items);
    } else if (widget.mayorista) {
      observacionesController.text = 'Venta mayorista';
    }

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
    busquedaCopiasController.dispose();
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

    if (producto == null) {
      return;
    }

    final esVentaLibre = producto.esVentaLibre;
    final stockDisponible = _stockDisponible(producto);

    if (!esVentaLibre && stockDisponible <= 0) {
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

        if (!esVentaLibre && nuevaCantidad > stockDisponible) {
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
            precioUnitario: esVentaLibre ? 0 : _precioVenta(producto),
            costoUnitario: esVentaLibre ? 0 : producto.costo,
          ),
        );
      }
      productoSeleccionado = null;
    });
  }

  void agregarProducto(ProductoModel producto) {
    final esVentaLibre = producto.esVentaLibre;
    final stockDisponible = _stockDisponible(producto);

    if (!esVentaLibre && stockDisponible <= 0) {
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

        if (!esVentaLibre && nuevaCantidad > stockDisponible) {
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
          precioUnitario: esVentaLibre ? 0 : _precioVenta(producto),
          costoUnitario: esVentaLibre ? 0 : producto.costo,
        ),
      );
    });
  }

  double _precioVenta(ProductoModel producto) {
    if (widget.mayorista && producto.precioMayorista > 0) {
      return producto.precioMayorista;
    }

    return producto.precio;
  }

  void actualizarCantidad(VentaItemModel item, double cantidad) {
    final productos = ref.read(productoProvider).productos;
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

    final stockDisponible = _stockDisponible(producto);

    if (!item.esVentaLibre &&
        producto.id.isNotEmpty &&
        cantidad > stockDisponible) {
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

  void actualizarPrecioItem(VentaItemModel item, double precio) {
    if (precio < 0) {
      return;
    }

    final index = items.indexOf(item);
    if (index < 0) {
      return;
    }

    setState(() {
      items[index] = VentaItemModel(
        productoId: item.productoId,
        codigo: item.codigo,
        nombre: item.nombre,
        cantidad: item.cantidad,
        precioUnitario: precio,
        costoUnitario: item.costoUnitario,
      );
    });
  }

  Future<void> guardarVenta() async {
    if (guardandoVenta) {
      return;
    }

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

    if (!_validarVentasLibres()) {
      return;
    }

    if (!_validarStockDisponible()) {
      return;
    }

    setState(() => guardandoVenta = true);

    var ventaProcesada = false;
    String? mensajeExito;

    try {
      final usuario = ref.read(authProvider).usuario;
      final sucursal = _sucursalOperativa();

      final esEdicion = widget.venta != null;

      if (!esEdicion &&
          estado == 'Completada' &&
          ref.read(cajaProvider).turnoAbiertoParaSucursal(sucursal) == null) {
        _mostrarError(
          'Debe abrir caja de $sucursal antes de registrar una venta completada',
        );
        return;
      }

      final ahora = DateTime.now();
      final fechaFinal = DateTime(
        fechaVenta.year,
        fechaVenta.month,
        fechaVenta.day,
        widget.venta?.fecha.hour ?? ahora.hour,
        widget.venta?.fecha.minute ?? ahora.minute,
      );
      final numero =
          widget.venta?.numero ??
          await ref.read(ventaProvider.notifier).generarNumeroVenta();
      final cliente = clienteSeleccionado!;

      final venta = VentaModel(
        id: widget.venta?.id ?? ahora.millisecondsSinceEpoch.toString(),
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
        fecha: fechaFinal,
        observaciones: observacionesController.text.trim(),
      );

      if (widget.venta == null) {
        await ref.read(ventaProvider.notifier).agregarVenta(venta);
        ventaProcesada = true;
        mensajeExito = 'Venta registrada correctamente';

        if (estado == 'Completada') {
          await _descontarStock();
          await _registrarIngresoCaja(venta);
        }
      } else {
        await ref
            .read(ventaProvider.notifier)
            .actualizarVenta(original: widget.venta!, actualizada: venta);
        await ref.read(cajaProvider.notifier).sincronizarMovimientoVenta(venta);
        ventaProcesada = true;
        mensajeExito = 'Venta actualizada correctamente';
      }

      await ref
          .read(notificationProvider.notifier)
          .registrar(
            usuario: usuario,
            tipo: 'Venta',
            titulo: widget.venta == null
                ? 'Venta ${venta.numero}'
                : 'Venta modificada ${venta.numero}',
            detalle:
                '${venta.clienteNombre} - ${CurrencyFormatter.format(venta.total)} - ${venta.sucursal}',
            ruta: AppRoutes.ventas,
            monto: venta.total,
          );

      if (!mounted) return;

      final ticketPath = widget.venta == null
          ? await _ofrecerTicket(venta)
          : null;

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            ticketPath == null
                ? mensajeExito ?? 'Venta guardada correctamente'
                : 'Venta registrada. Ticket generado: $ticketPath',
          ),
        ),
      );
    } catch (error) {
      if (ventaProcesada && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.warning,
            content: Text(
              'La venta se guardo. Revise caja o sincronizacion si nota diferencias.',
            ),
          ),
        );
        return;
      }

      if (mounted) {
        _mostrarError('No se pudo guardar la venta. Revise conexion y stock.');
      }
    } finally {
      if (mounted) {
        setState(() => guardandoVenta = false);
      }
    }
  }

  bool _validarStockDisponible() {
    final productos = ref.read(productoProvider).productos;

    for (final item in items) {
      final producto = productos.firstWhere(
        (producto) => producto.id == item.productoId,
        orElse: () => ProductoModel.empty(),
      );

      if (item.esVentaLibre || producto.esVentaLibre) {
        continue;
      }

      if (producto.id.isEmpty) {
        _mostrarError('No se encontro el producto ${item.nombre}');
        return false;
      }

      final disponible = _stockDisponible(producto);
      if (item.cantidad > disponible) {
        _mostrarError(
          'Stock insuficiente para ${item.nombre}. Disponible: ${disponible.toStringAsFixed(0)}',
        );
        return false;
      }
    }

    return true;
  }

  bool _validarVentasLibres() {
    for (final item in items) {
      if (item.esVentaLibre && item.precioUnitario <= 0) {
        _mostrarError('Ingrese el monto manual para ${item.nombre}');
        return false;
      }
    }

    return true;
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

      if (item.esVentaLibre || producto.esVentaLibre || producto.id.isEmpty) {
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

  double _stockDisponible(ProductoModel producto) {
    final sucursal = _sucursalOperativa();
    var disponible = producto.stockEnSucursal(sucursal);
    final ventaOriginal = widget.venta;

    if (ventaOriginal != null &&
        ventaOriginal.estado == 'Completada' &&
        ventaOriginal.sucursal == sucursal) {
      for (final item in ventaOriginal.items) {
        if (item.productoId == producto.id) {
          disponible += item.cantidad;
        }
      }
    }

    return disponible;
  }

  String _sucursalOperativa() {
    final usuario = ref.read(authProvider).usuario;
    if (usuario != null && !usuario.esPropietario) {
      return usuario.sucursal;
    }

    return sucursalVenta;
  }

  String _sucursalInicial() {
    final venta = widget.venta;
    if (venta != null) {
      return venta.sucursal;
    }

    final usuario = ref.read(authProvider).usuario;
    if (usuario != null && !usuario.esPropietario) {
      return usuario.sucursal;
    }

    return ref.read(productoProvider).sucursalSeleccionada;
  }

  void _cambiarSucursalVenta(String? value) {
    if (value == null || value == sucursalVenta) {
      return;
    }

    if (items.isNotEmpty) {
      _mostrarError(
        'Cambie la sucursal antes de agregar productos para no mezclar stock.',
      );
      return;
    }

    setState(() {
      sucursalVenta = value;
      productoSeleccionado = null;
    });
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

  String _fechaLabel(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  Future<void> _seleccionarFecha() async {
    final seleccion = await showDatePicker(
      context: context,
      initialDate: fechaVenta,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (seleccion == null || !mounted) {
      return;
    }

    setState(() {
      fechaVenta = seleccion;
    });
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    final clientes = ref
        .watch(clienteProvider)
        .clientes
        .where((cliente) => cliente.activo)
        .toList();
    if (clienteSeleccionado == null && widget.venta != null) {
      for (final cliente in clientes) {
        if (cliente.id == widget.venta!.clienteId) {
          clienteSeleccionado = cliente;
          break;
        }
      }
    }
    if (clienteSeleccionado == null) {
      for (final cliente in clientes) {
        if (cliente.id == ClienteModel.consumidorFinalId) {
          clienteSeleccionado = cliente;
          break;
        }
      }
    }
    final productos = ref
        .watch(productoProvider)
        .productos
        .where((producto) => producto.activo)
        .toList();
    final productosLlaves = _filtrarCopiasDeLlaves(productos);
    final esPropietario = ref.watch(authProvider).esPropietario;

    final clienteField = DropdownButtonFormField<ClienteModel>(
      initialValue: clienteSeleccionado,
      isExpanded: true,
      decoration: decoration("Cliente"),
      dropdownColor: AppColors.surface,
      items: clientes
          .map(
            (cliente) => DropdownMenuItem(
              value: cliente,
              child: Text(
                '${cliente.nombre} ${cliente.apellido}'.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
    );

    final pagoField = DropdownButtonFormField<String>(
      initialValue: medioPago,
      isExpanded: true,
      decoration: decoration("Medio de pago"),
      dropdownColor: AppColors.surface,
      items: const [
        DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
        DropdownMenuItem(value: 'Transferencia', child: Text('Transferencia')),
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
    );

    final fechaField = OutlinedButton.icon(
      onPressed: _seleccionarFecha,
      icon: const Icon(Icons.calendar_today_outlined),
      label: Text('Fecha: ${_fechaLabel(fechaVenta)}'),
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight(compact ? 52 : 56),
        alignment: Alignment.centerLeft,
      ),
    );

    final sucursalField = DropdownButtonFormField<String>(
      initialValue: sucursalVenta,
      isExpanded: true,
      decoration: decoration("Sucursal de venta"),
      dropdownColor: AppColors.surface,
      items: Branches.values
          .map(
            (sucursal) => DropdownMenuItem(
              value: sucursal,
              child: Text(
                sucursal == Branches.casaCentral ? 'Santa Fe' : 'Alberdi',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: widget.venta == null ? _cambiarSucursalVenta : null,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Seleccione una sucursal";
        }
        return null;
      },
    );

    final datosVenta = compact
        ? Column(
            children: [
              if (esPropietario) ...[
                sucursalField,
                const SizedBox(height: 12),
              ],
              clienteField,
              const SizedBox(height: 12),
              pagoField,
              const SizedBox(height: 12),
              fechaField,
            ],
          )
        : Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              if (esPropietario)
                SizedBox(width: 220, child: sucursalField),
              SizedBox(width: esPropietario ? 235 : 260, child: clienteField),
              SizedBox(width: esPropietario ? 220 : 260, child: pagoField),
              SizedBox(width: esPropietario ? 220 : 260, child: fechaField),
            ],
          );

    final modoCopias = SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: modoCopiasLlaves,
      title: const Text(
        "Modo copias de llaves",
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: const Text(
        "Filtra modelos visuales para duplicados.",
        style: TextStyle(color: AppColors.textSecondary),
      ),
      secondary: const Icon(Icons.key_rounded, color: AppColors.primary),
      onChanged: (value) {
        setState(() {
          modoCopiasLlaves = value;
        });
      },
    );

    final mayoristaNotice = widget.mayorista
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: .35),
              ),
            ),
            child: const Text(
              'Venta mayorista: se usa el precio mayorista cargado. Si el producto no tiene precio mayorista, se usa el precio de venta normal.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        : const SizedBox.shrink();

    final productoSelector = modoCopiasLlaves
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (productos.isEmpty) ...[
                const _ProductLoadNotice(),
                SizedBox(height: compact ? 10 : 12),
              ],
              TextField(
                controller: busquedaCopiasController,
                decoration: decoration("Buscar copia de llave").copyWith(
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: busquedaCopiasController.text.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip: "Limpiar busqueda",
                          onPressed: () {
                            setState(() {
                              busquedaCopiasController.clear();
                            });
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: compact ? 10 : 12),
              _KeyCopyGrid(
                productos: productosLlaves,
                totalCopias: productos.where(_esProductoLlave).length,
                onAdd: agregarProducto,
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (productos.isEmpty) ...[
                const _ProductLoadNotice(),
                SizedBox(height: compact ? 10 : 12),
              ],
              if (compact) ...[
                _ProductSearchPicker(
                  productos: productos,
                  productoSeleccionado: productoSeleccionado,
                  sucursal: _sucursalOperativa(),
                  mayorista: widget.mayorista,
                  decoration: decoration,
                  onSelected: (producto) {
                    setState(() {
                      productoSeleccionado = producto;
                    });
                  },
                  onCleared: () {
                    setState(() {
                      productoSeleccionado = null;
                    });
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: agregarItem,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text("Agregar producto"),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _ProductSearchPicker(
                        productos: productos,
                        productoSeleccionado: productoSeleccionado,
                        sucursal: _sucursalOperativa(),
                        mayorista: widget.mayorista,
                        decoration: decoration,
                        onSelected: (producto) {
                          setState(() {
                            productoSeleccionado = producto;
                          });
                        },
                        onCleared: () {
                          setState(() {
                            productoSeleccionado = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: agregarItem,
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text("Agregar"),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );

    final itemsTable = _ItemsTable(
      items: items,
      compact: compact,
      puedeEditarPrecio: esPropietario || widget.mayorista,
      onCantidadChanged: actualizarCantidad,
      onPrecioChanged: actualizarPrecioItem,
      onRemove: (item) {
        setState(() {
          items.remove(item);
        });
      },
    );

    final cobroPanel = _VentaDetailsSection(
      compact: true,
      observacionesController: observacionesController,
      descuentoController: descuentoController,
      estado: estado,
      decoration: decoration,
      onEstadoChanged: (value) {
        setState(() {
          estado = value ?? estado;
        });
      },
      totalBox: _TotalBox(
        subtotal: subtotal,
        descuento: descuento,
        total: total,
      ),
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VentaFormHeader(
            sucursal: _sucursalOperativa(),
            items: items.length,
            total: total,
            editing: widget.venta != null,
          ),
          const SizedBox(height: 14),
          if (compact) ...[
            _SaleSection(
              number: 1,
              title: "Datos de la venta",
              child: Column(
                children: [
                  datosVenta,
                  const SizedBox(height: 8),
                  modoCopias,
                  if (widget.mayorista) ...[
                    const SizedBox(height: 10),
                    mayoristaNotice,
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SaleSection(
              number: 2,
              title: "Agregar productos",
              child: productoSelector,
            ),
            const SizedBox(height: 12),
            _SaleSection(number: 3, title: "Detalle", child: itemsTable),
            const SizedBox(height: 12),
            _SaleSection(
              number: 4,
              title: "Cobro y cierre",
              child: Column(
                children: [
                  cobroPanel,
                  const SizedBox(height: 14),
                  _ActionButtons(
                    compact: true,
                    editing: widget.venta != null,
                    saving: guardandoVenta,
                    onSave: guardarVenta,
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: Column(
                    children: [
                      _SaleSection(
                        number: 1,
                        title: "Datos de la venta",
                        child: Column(
                          children: [
                            datosVenta,
                            const SizedBox(height: 12),
                            modoCopias,
                            if (widget.mayorista) ...[
                              const SizedBox(height: 12),
                              mayoristaNotice,
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SaleSection(
                        number: 2,
                        title: "Buscar y agregar producto",
                        child: productoSelector,
                      ),
                      const SizedBox(height: 14),
                      _SaleSection(
                        number: 3,
                        title: "Productos cargados",
                        trailing: Text(
                          '${items.length} item${items.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: itemsTable,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 340,
                  child: _SaleSection(
                    number: 4,
                    title: "Cobro",
                    child: Column(
                      children: [
                        cobroPanel,
                        const SizedBox(height: 18),
                        _ActionButtons(
                          compact: false,
                          editing: widget.venta != null,
                          saving: guardandoVenta,
                          onSave: guardarVenta,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  DropdownMenuItem<ProductoModel> _productoMenuItem(ProductoModel producto) {
    final stock = producto.stockEnSucursal(_sucursalOperativa());
    final stockSantaFe = producto.stockEnSucursal(Branches.casaCentral);
    final stockAlberdi = producto.stockEnSucursal(Branches.alberdi);
    final stockLabel = producto.esVentaLibre
        ? 'Sin control de stock'
        : 'Stock ${stock.toStringAsFixed(0)} · Santa Fe ${stockSantaFe.toStringAsFixed(0)} · Alberdi ${stockAlberdi.toStringAsFixed(0)}';

    return DropdownMenuItem(
      value: producto,
      child: Text(
        '${producto.codigo} - ${producto.nombre} · $stockLabel',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  List<ProductoModel> _filtrarCopiasDeLlaves(List<ProductoModel> productos) {
    final texto = _normalizarTexto(busquedaCopiasController.text);

    return productos.where((producto) {
      if (!_esProductoLlave(producto)) {
        return false;
      }

      if (texto.isEmpty) {
        return true;
      }

      return _textoProducto(producto).contains(texto);
    }).toList()..sort(
      (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
    );
  }

  bool _esProductoLlave(ProductoModel producto) {
    final texto = _textoProducto(producto);

    return texto.contains('llave') ||
        texto.contains('llaves') ||
        texto.contains('copia') ||
        texto.contains('copias') ||
        texto.contains('duplicado') ||
        texto.contains('duplicados') ||
        texto.contains('blank');
  }

  String _textoProducto(ProductoModel producto) {
    return _normalizarTexto(
      [
        producto.codigo,
        producto.codigoBarras,
        producto.nombre,
        producto.categoria,
        producto.descripcion,
        producto.marca,
        producto.proveedor,
      ].join(' '),
    );
  }

  String _normalizarTexto(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}

class _VentaFormHeader extends StatelessWidget {
  final String sucursal;
  final int items;
  final double total;
  final bool editing;

  const _VentaFormHeader({
    required this.sucursal,
    required this.items,
    required this.total,
    required this.editing,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: .35)),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderTitle(editing: editing),
                const SizedBox(height: 12),
                _HeaderStats(sucursal: sucursal, items: items, total: total),
              ],
            )
          : Row(
              children: [
                Expanded(child: _HeaderTitle(editing: editing)),
                _HeaderStats(sucursal: sucursal, items: items, total: total),
              ],
            ),
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  final bool editing;

  const _HeaderTitle({required this.editing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.point_of_sale_rounded, color: Colors.black),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                editing ? 'Editar venta' : 'Venta rapida',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Busque, agregue y confirme en pocos pasos.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderStats extends StatelessWidget {
  final String sucursal;
  final int items;
  final double total;

  const _HeaderStats({
    required this.sucursal,
    required this.items,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        _HeaderChip(
          icon: Icons.storefront_outlined,
          label: sucursal,
        ),
        _HeaderChip(
          icon: Icons.shopping_basket_outlined,
          label: '$items item${items == 1 ? '' : 's'}',
        ),
        _HeaderChip(
          icon: Icons.payments_outlined,
          label: CurrencyFormatter.format(total),
          destacado: true,
        ),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool destacado;

  const _HeaderChip({
    required this.icon,
    required this.label,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: destacado ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: destacado ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: destacado ? Colors.black : AppColors.primary,
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: destacado ? Colors.black : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleSection extends StatelessWidget {
  final int number;
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SaleSection({
    required this.number,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ProductSearchPicker extends StatelessWidget {
  final List<ProductoModel> productos;
  final ProductoModel? productoSeleccionado;
  final String sucursal;
  final bool mayorista;
  final InputDecoration Function(String label) decoration;
  final ValueChanged<ProductoModel> onSelected;
  final VoidCallback onCleared;

  const _ProductSearchPicker({
    required this.productos,
    required this.productoSeleccionado,
    required this.sucursal,
    required this.mayorista,
    required this.decoration,
    required this.onSelected,
    required this.onCleared,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<ProductoModel>(
      key: ValueKey(productoSeleccionado?.id ?? 'producto-search-empty'),
      initialValue: TextEditingValue(
        text: productoSeleccionado == null
            ? ''
            : _displayProducto(productoSeleccionado!),
      ),
      displayStringForOption: _displayProducto,
      optionsBuilder: (textEditingValue) {
        final query = _normalizar(textEditingValue.text);
        final terms = query.split(' ').where((term) => term.isNotEmpty);
        final base = [...productos]..sort(
          (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
        );

        if (query.isEmpty) {
          return base.take(12);
        }

        return base.where((producto) {
          final texto = _textoBusqueda(producto);
          return terms.every(texto.contains);
        }).take(20);
      },
      onSelected: onSelected,
      fieldViewBuilder:
          (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: decoration("Buscar producto por nombre o codigo")
              .copyWith(
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.text.trim().isEmpty
                    ? null
                    : IconButton(
                        tooltip: "Limpiar producto",
                        onPressed: () {
                          controller.clear();
                          onCleared();
                          focusNode.requestFocus();
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
          onFieldSubmitted: (_) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelectedOption, options) {
        final lista = options.toList();

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: AppColors.surface,
            elevation: 8,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320, maxWidth: 720),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: lista.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  color: AppColors.border,
                ),
                itemBuilder: (context, index) {
                  final producto = lista[index];
                  final stockSucursal = producto.stockEnSucursal(sucursal);
                  final stockSantaFe = producto.stockEnSucursal(
                    Branches.casaCentral,
                  );
                  final stockAlberdi = producto.stockEnSucursal(
                    Branches.alberdi,
                  );
                  final stockLabel = producto.esVentaLibre
                      ? 'Sin control de stock'
                      : 'Stock ${stockSucursal.toStringAsFixed(0)} - SF ${stockSantaFe.toStringAsFixed(0)} - ALB ${stockAlberdi.toStringAsFixed(0)}';

                  return ListTile(
                    dense: true,
                    title: Text(
                      producto.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${producto.codigo} - $stockLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    trailing: Text(
                      CurrencyFormatter.format(_precioProducto(producto)),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => onSelectedOption(producto),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  String _displayProducto(ProductoModel producto) {
    return '${producto.codigo} - ${producto.nombre}';
  }

  double _precioProducto(ProductoModel producto) {
    if (mayorista && producto.precioMayorista > 0) {
      return producto.precioMayorista;
    }

    return producto.precio;
  }

  String _textoBusqueda(ProductoModel producto) {
    return _normalizar(
      [
        producto.codigo,
        producto.codigoBarras,
        producto.nombre,
        producto.categoria,
        producto.marca,
        producto.proveedor,
      ].join(' '),
    );
  }

  String _normalizar(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}

class _KeyCopyGrid extends StatelessWidget {
  final List<ProductoModel> productos;
  final int totalCopias;
  final void Function(ProductoModel producto) onAdd;

  const _KeyCopyGrid({
    required this.productos,
    required this.totalCopias,
    required this.onAdd,
  });

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
          "No hay copias de llave para mostrar con esa busqueda.",
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 760;
    final columns = compact
        ? 2
        : width < 1100
        ? 3
        : 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mostrando ${productos.length} de $totalCopias copias de llave disponibles',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: compact ? .9 : 1.08,
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
                    const SizedBox(height: 2),
                    Text(
                      'SF ${producto.stockEnSucursal(Branches.casaCentral).toStringAsFixed(0)} · ALB ${producto.stockEnSucursal(Branches.alberdi).toStringAsFixed(0)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textDisabled,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ProductLoadNotice extends StatelessWidget {
  const _ProductLoadNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: .45)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.warning),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "No se cargaron productos activos. Revise que haya productos cargados y que el usuario tenga acceso al catalogo.",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String path;

  const _ProductImage({required this.path});

  @override
  Widget build(BuildContext context) {
    final imageBytes = _imageBytes(path);
    final isNetworkImage = _isNetworkImage(path);
    final tieneFoto =
        imageBytes != null ||
        isNetworkImage ||
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
          : isNetworkImage
          ? Image.network(
              path,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.key_rounded,
                  color: AppColors.textDisabled,
                  size: 42,
                );
              },
            )
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
                        : _isNetworkImage(path)
                        ? Image.network(
                            path,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.key_rounded,
                                color: AppColors.textDisabled,
                                size: 64,
                              );
                            },
                          )
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

  bool _isNetworkImage(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }
}

class _ItemsTable extends StatelessWidget {
  final List<VentaItemModel> items;
  final bool compact;
  final bool puedeEditarPrecio;
  final void Function(VentaItemModel item, double cantidad) onCantidadChanged;
  final void Function(VentaItemModel item, double precio) onPrecioChanged;
  final void Function(VentaItemModel item) onRemove;

  const _ItemsTable({
    required this.items,
    required this.compact,
    required this.puedeEditarPrecio,
    required this.onCantidadChanged,
    required this.onPrecioChanged,
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

    if (compact) {
      return Column(
        children: items.map((item) {
          final editarPrecio = puedeEditarPrecio || item.esVentaLibre;
          final cantidadText = item.cantidad % 1 == 0
              ? item.cantidad.toStringAsFixed(0)
              : item.cantidad.toStringAsFixed(2);

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: "Quitar",
                      onPressed: () => onRemove(item),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: "Restar",
                            onPressed: () {
                              onCantidadChanged(item, item.cantidad - 1);
                            },
                            icon: const Icon(Icons.remove, size: 18),
                          ),
                          SizedBox(
                            width: 38,
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
                    const Spacer(),
                    if (editarPrecio) ...[
                      SizedBox(
                        width: 120,
                        child: _InlinePriceField(
                          value: item.precioUnitario,
                          onChanged: (precio) => onPrecioChanged(item, precio),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      CurrencyFormatter.format(item.subtotal),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
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
          final editarPrecio = puedeEditarPrecio || item.esVentaLibre;
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
                  child: editarPrecio
                      ? _InlinePriceField(
                          value: item.precioUnitario,
                          onChanged: (precio) => onPrecioChanged(item, precio),
                        )
                      : Text(
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

class _InlinePriceField extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _InlinePriceField({required this.value, required this.onChanged});

  @override
  State<_InlinePriceField> createState() => _InlinePriceFieldState();
}

class _InlinePriceFieldState extends State<_InlinePriceField> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.value.toStringAsFixed(0));
  }

  @override
  void didUpdateWidget(covariant _InlinePriceField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        _parseNumber(controller.text) != widget.value) {
      controller.text = widget.value.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.right,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: "Precio",
        isDense: true,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onChanged: (value) {
        widget.onChanged(_parseNumber(value));
      },
    );
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
}

class _VentaDetailsSection extends StatelessWidget {
  final bool compact;
  final TextEditingController observacionesController;
  final TextEditingController descuentoController;
  final String estado;
  final InputDecoration Function(String label) decoration;
  final ValueChanged<String?> onEstadoChanged;
  final Widget totalBox;

  const _VentaDetailsSection({
    required this.compact,
    required this.observacionesController,
    required this.descuentoController,
    required this.estado,
    required this.decoration,
    required this.onEstadoChanged,
    required this.totalBox,
  });

  @override
  Widget build(BuildContext context) {
    final estadoField = DropdownButtonFormField<String>(
      initialValue: estado,
      isExpanded: true,
      decoration: decoration("Estado"),
      dropdownColor: AppColors.surface,
      items: const [
        DropdownMenuItem(value: 'Completada', child: Text('Completada')),
        DropdownMenuItem(value: 'Pendiente', child: Text('Pendiente')),
      ],
      onChanged: onEstadoChanged,
    );

    final descuentoField = TextFormField(
      controller: descuentoController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: decoration("Descuento"),
    );

    final observacionesField = TextFormField(
      controller: observacionesController,
      maxLines: compact ? 3 : 4,
      decoration: decoration("Observaciones"),
    );

    if (compact) {
      return Column(
        children: [
          estadoField,
          const SizedBox(height: 10),
          descuentoField,
          const SizedBox(height: 10),
          observacionesField,
          const SizedBox(height: 10),
          totalBox,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: observacionesField),
        const SizedBox(width: 20),
        SizedBox(
          width: 300,
          child: Column(
            children: [
              estadoField,
              const SizedBox(height: 14),
              descuentoField,
              const SizedBox(height: 14),
              totalBox,
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final bool compact;
  final bool editing;
  final bool saving;
  final VoidCallback onSave;

  const _ActionButtons({
    required this.compact,
    required this.editing,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final cancelButton = OutlinedButton.icon(
      onPressed: saving
          ? null
          : () {
              Navigator.pop(context);
            },
      icon: const Icon(Icons.close),
      label: const Text("Cancelar"),
    );

    final saveButton = FilledButton.icon(
      onPressed: saving ? null : onSave,
      icon: Icon(
        saving ? Icons.hourglass_top_rounded : Icons.check_circle_outline,
      ),
      label: Text(
        saving
            ? (editing ? "Actualizando..." : "Registrando...")
            : (editing ? "Actualizar Venta" : "Registrar Venta"),
      ),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [saveButton, const SizedBox(height: 10), cancelButton],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [cancelButton, const SizedBox(width: 16), saveButton],
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
