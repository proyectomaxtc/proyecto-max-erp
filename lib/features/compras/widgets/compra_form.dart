import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/branches.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../caja/models/caja_movimiento_model.dart';
import '../../caja/providers/caja_provider.dart';
import '../../productos/models/producto_model.dart';
import '../../productos/providers/producto_provider.dart';
import '../models/compra_item_model.dart';
import '../models/compra_model.dart';
import '../providers/compra_provider.dart';

class CompraForm extends ConsumerStatefulWidget {
  const CompraForm({super.key});

  @override
  ConsumerState<CompraForm> createState() => _CompraFormState();
}

class _CompraFormState extends ConsumerState<CompraForm> {
  final _formKey = GlobalKey<FormState>();
  final proveedorController = TextEditingController();
  final responsableController = TextEditingController();
  final cantidadController = TextEditingController(text: '1');
  final costoController = TextEditingController();
  final pagadoController = TextEditingController(text: '0');
  final transporteController = TextEditingController(text: '0');
  final observacionesController = TextEditingController();

  ProductoModel? productoSeleccionado;
  String estado = 'Recibida';
  String transporteMedioPago = 'Efectivo';
  final List<CompraItemModel> items = [];

  double get total {
    return items.fold(0, (total, item) => total + item.subtotal);
  }

  @override
  void dispose() {
    proveedorController.dispose();
    responsableController.dispose();
    cantidadController.dispose();
    costoController.dispose();
    pagadoController.dispose();
    transporteController.dispose();
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
    final cantidad = double.tryParse(cantidadController.text) ?? 0;
    final costo = double.tryParse(costoController.text) ?? 0;

    if (producto == null || cantidad <= 0 || costo <= 0) {
      return;
    }

    setState(() {
      items.add(
        CompraItemModel(
          productoId: producto.id,
          codigo: producto.codigo,
          nombre: producto.nombre,
          cantidad: cantidad,
          costoUnitario: costo,
        ),
      );
      productoSeleccionado = null;
      cantidadController.text = '1';
      costoController.clear();
    });
  }

  Future<void> guardarCompra() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Agregue al menos un producto'),
        ),
      );
      return;
    }

    final ahora = DateTime.now();
    final sucursal = ref.read(productoProvider).sucursalSeleccionada;
    final numero = await ref
        .read(compraProvider.notifier)
        .generarNumeroCompra();

    final compra = CompraModel(
      id: ahora.microsecondsSinceEpoch.toString(),
      numero: numero,
      proveedor: proveedorController.text.trim(),
      responsable: responsableController.text.trim(),
      sucursal: sucursal,
      items: List.unmodifiable(items),
      total: total,
      pagado: _montoPagadoInicial(),
      transporteCosto: _montoTransporte(),
      transporteMedioPago: transporteMedioPago,
      estado: estado,
      fecha: ahora,
      observaciones: observacionesController.text.trim(),
    );

    await ref.read(compraProvider.notifier).agregarCompra(compra);

    if (estado == 'Recibida') {
      await _impactarStock();
    }

    await _registrarTransporteEnCaja(compra);

    if (!mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Compra registrada correctamente'),
      ),
    );
  }

  Future<void> _impactarStock() async {
    final productos = ref.read(productoProvider).productos;
    final notifier = ref.read(productoProvider.notifier);
    final sucursal = ref.read(productoProvider).sucursalSeleccionada;

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
              stockSucursal: producto.stockEnSucursal(sucursal) + item.cantidad,
            )
            .copyWith(
              costo: item.costoUnitario,
              proveedor: proveedorController.text.trim(),
              actualizado: DateTime.now(),
            ),
      );
    }
  }

  double _montoPagadoInicial() {
    final pagado = double.tryParse(pagadoController.text) ?? 0;
    if (pagado < 0) {
      return 0;
    }

    if (pagado > total) {
      return total;
    }

    return pagado;
  }

  double _montoTransporte() {
    final transporte = double.tryParse(transporteController.text) ?? 0;
    return transporte < 0 ? 0 : transporte;
  }

  Future<void> _registrarTransporteEnCaja(CompraModel compra) async {
    if (compra.transporteCosto <= 0) {
      return;
    }

    final turno = ref
        .read(cajaProvider)
        .turnoAbiertoParaSucursal(compra.sucursal);

    if (turno == null) {
      return;
    }

    await ref
        .read(cajaProvider.notifier)
        .agregarMovimiento(
          CajaMovimientoModel(
            id: '${compra.id}-transporte',
            tipo: 'Egreso',
            concepto:
                'Transporte compra ${compra.numero} - ${compra.proveedor}',
            monto: compra.transporteCosto,
            medioPago: compra.transporteMedioPago,
            referenciaId: compra.id,
            origen: 'Compra',
            turnoId: turno.id,
            responsable: compra.responsable,
            bloqueado: true,
            fecha: compra.fecha,
            observaciones: compra.observaciones,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final productos = ref.watch(productoProvider).productos;
    final sucursal = ref.watch(productoProvider).sucursalSeleccionada;
    final compact = MediaQuery.sizeOf(context).width < 760;
    final sucursalLabel = sucursal == Branches.casaCentral
        ? 'Casa Central Santa Fe'
        : 'Sucursal Alberdi';

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: .45),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.storefront_outlined, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Esta mercaderia ingresara al stock de: $sucursalLabel',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ResponsiveFields(
            compact: compact,
            children: [
              TextFormField(
                controller: proveedorController,
                decoration: decoration("Proveedor"),
                validator: (value) => value == null || value.trim().isEmpty
                    ? "Ingrese proveedor"
                    : null,
              ),
              TextFormField(
                controller: responsableController,
                decoration: decoration("Responsable"),
                validator: (value) => value == null || value.trim().isEmpty
                    ? "Ingrese responsable"
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withValues(alpha: .35)),
            ),
            child: const Text(
              "Las compras recibidas actualizan stock y costo del producto para operaciones futuras. Las ventas ya registradas conservan el precio y costo original.",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 18),
          compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<ProductoModel>(
                      initialValue: productoSeleccionado,
                      decoration: decoration("Producto"),
                      dropdownColor: AppColors.surface,
                      isExpanded: true,
                      items: productos
                          .map(
                            (producto) => DropdownMenuItem(
                              value: producto,
                              child: Text(
                                '${producto.codigo} - ${producto.nombre}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (producto) {
                        setState(() {
                          productoSeleccionado = producto;
                          costoController.text =
                              producto?.costo.toString() ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _ResponsiveFields(
                      compact: compact,
                      children: [
                        TextFormField(
                          controller: cantidadController,
                          keyboardType: TextInputType.number,
                          decoration: decoration("Cantidad"),
                        ),
                        TextFormField(
                          controller: costoController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: decoration("Costo"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: agregarItem,
                      icon: const Icon(Icons.add),
                      label: const Text("Agregar"),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 2,
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
                            costoController.text =
                                producto?.costo.toString() ?? '';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 110,
                      child: TextFormField(
                        controller: cantidadController,
                        keyboardType: TextInputType.number,
                        decoration: decoration("Cantidad"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 140,
                      child: TextFormField(
                        controller: costoController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: decoration("Costo"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: agregarItem,
                      icon: const Icon(Icons.add),
                      label: const Text("Agregar"),
                    ),
                  ],
                ),
          const SizedBox(height: 18),
          _CompraItems(
            items: items,
            onRemove: (item) {
              setState(() {
                items.remove(item);
              });
            },
          ),
          const SizedBox(height: 18),
          compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: observacionesController,
                      maxLines: 3,
                      decoration: decoration("Observaciones"),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: estado,
                      decoration: decoration("Estado"),
                      dropdownColor: AppColors.surface,
                      items: const [
                        DropdownMenuItem(
                          value: 'Recibida',
                          child: Text('Recibida'),
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
                      controller: pagadoController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: decoration("Pagado al proveedor"),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: transporteController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: decoration("Transporte contado"),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: transporteMedioPago,
                      decoration: decoration("Pago transporte"),
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
                        DropdownMenuItem(
                          value: 'Mercado Pago',
                          child: Text('Mercado Pago'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          transporteMedioPago = value ?? transporteMedioPago;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    _TotalBox(total: total),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: observacionesController,
                        maxLines: 4,
                        decoration: decoration("Observaciones"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 260,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: estado,
                            decoration: decoration("Estado"),
                            dropdownColor: AppColors.surface,
                            items: const [
                              DropdownMenuItem(
                                value: 'Recibida',
                                child: Text('Recibida'),
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
                            controller: pagadoController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: decoration("Pagado al proveedor"),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: transporteController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: decoration("Transporte contado"),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: transporteMedioPago,
                            decoration: decoration("Pago transporte"),
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
                              DropdownMenuItem(
                                value: 'Mercado Pago',
                                child: Text('Mercado Pago'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                transporteMedioPago =
                                    value ?? transporteMedioPago;
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                          _TotalBox(total: total),
                        ],
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 28),
          compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: guardarCompra,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text("Registrar Compra"),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text("Cancelar"),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text("Cancelar"),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      onPressed: guardarCompra,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text("Registrar Compra"),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  final bool compact;
  final List<Widget> children;

  const _ResponsiveFields({required this.compact, required this.children});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            children[i],
          ],
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

class _TotalBox extends StatelessWidget {
  final double total;

  const _TotalBox({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: .4)),
      ),
      child: Text(
        CurrencyFormatter.format(total),
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CompraItems extends StatelessWidget {
  final List<CompraItemModel> items;
  final void Function(CompraItemModel item) onRemove;

  const _CompraItems({required this.items, required this.onRemove});

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
          "Agregue productos para registrar la compra.",
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: items
          .map(
            (item) => ListTile(
              title: Text(item.nombre),
              subtitle: Text("Cantidad: ${item.cantidad.toStringAsFixed(0)}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    CurrencyFormatter.format(item.subtotal),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => onRemove(item),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
