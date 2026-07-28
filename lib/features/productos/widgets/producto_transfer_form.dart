import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/branches.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/producto_model.dart';
import '../providers/producto_provider.dart';

class ProductoTransferForm extends ConsumerStatefulWidget {
  const ProductoTransferForm({super.key});

  @override
  ConsumerState<ProductoTransferForm> createState() =>
      _ProductoTransferFormState();
}

class _ProductoTransferFormState extends ConsumerState<ProductoTransferForm> {
  final cantidadController = TextEditingController();
  final productoTextController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  ProductoModel? productoSeleccionado;
  String origen = Branches.casaCentral;
  String destino = Branches.alberdi;
  bool guardando = false;

  @override
  void dispose() {
    cantidadController.dispose();
    productoTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productos = ref.watch(productoProvider).productos;
    final compact = MediaQuery.sizeOf(context).width < 760;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoBox(
            text:
                'La transferencia descuenta stock de la sucursal origen y lo suma en la sucursal destino. No modifica precio, costo ni ventas anteriores.',
          ),
          const SizedBox(height: 16),
          _ProductoAutocomplete(
            controller: productoTextController,
            productos: productos,
            origen: origen,
            destino: destino,
            productoSeleccionado: productoSeleccionado,
            onSelected: (producto) {
              setState(() {
                productoSeleccionado = producto;
                productoTextController.text = _displayProducto(producto);
              });
            },
          ),
          const SizedBox(height: 14),
          compact
              ? Column(
                  children: [
                    _SucursalDropdown(
                      label: 'Desde',
                      value: origen,
                      onChanged: _cambiarOrigen,
                    ),
                    const SizedBox(height: 12),
                    _SucursalDropdown(
                      label: 'Hacia',
                      value: destino,
                      onChanged: _cambiarDestino,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _SucursalDropdown(
                        label: 'Desde',
                        value: origen,
                        onChanged: _cambiarOrigen,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _SucursalDropdown(
                        label: 'Hacia',
                        value: destino,
                        onChanged: _cambiarDestino,
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 14),
          if (productoSeleccionado != null) ...[
            _StockPreview(
              producto: productoSeleccionado!,
              origen: origen,
              destino: destino,
            ),
            const SizedBox(height: 14),
          ],
          TextFormField(
            controller: cantidadController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _decoration('Cantidad a transferir'),
            validator: (value) {
              final cantidad = _parseCantidad(value ?? '');
              if (cantidad <= 0) {
                return 'Ingrese una cantidad mayor a 0';
              }

              final producto = productoSeleccionado;
              if (producto == null) {
                return 'Seleccione un producto';
              }

              final disponible = _stockEnSucursal(producto, origen);
              if (cantidad > disponible) {
                return 'Disponible en origen: ${disponible.toStringAsFixed(0)}';
              }

              return null;
            },
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: guardando ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('Cancelar'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: guardando ? null : _transferir,
                icon: guardando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.swap_horiz_rounded),
                label: const Text('Transferir stock'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _cambiarOrigen(String value) {
    setState(() {
      origen = value;
      if (destino == origen) {
        destino = Branches.values.firstWhere((sucursal) => sucursal != origen);
      }
    });
  }

  void _cambiarDestino(String value) {
    setState(() {
      destino = value;
      if (origen == destino) {
        origen = Branches.values.firstWhere((sucursal) => sucursal != destino);
      }
    });
  }

  Future<void> _transferir() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final producto = productoSeleccionado;
    if (producto == null) {
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      await ref.read(productoProvider.notifier).transferirStock(
            productoId: producto.id,
            origen: origen,
            destino: destino,
            cantidad: _parseCantidad(cantidadController.text),
          );

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            'Transferencia realizada: ${producto.nombre} de ${_branchLabel(origen)} a ${_branchLabel(destino)}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        guardando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  double _parseCantidad(String value) {
    return double.tryParse(value.replaceAll(',', '.').trim()) ?? 0;
  }
}

class _ProductoAutocomplete extends StatelessWidget {
  final TextEditingController controller;
  final List<ProductoModel> productos;
  final String origen;
  final String destino;
  final ProductoModel? productoSeleccionado;
  final ValueChanged<ProductoModel> onSelected;

  const _ProductoAutocomplete({
    required this.controller,
    required this.productos,
    required this.origen,
    required this.destino,
    required this.productoSeleccionado,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<ProductoModel>(
      initialValue: TextEditingValue(
        text: productoSeleccionado == null
            ? ''
            : _displayProducto(productoSeleccionado!),
      ),
      displayStringForOption: _displayProducto,
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) {
          return productos.where((producto) => producto.activo).take(40);
        }

        return productos
            .where(
              (producto) =>
                  producto.activo && _textoBusqueda(producto).contains(query),
            )
            .take(40);
      },
      onSelected: onSelected,
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
        if (textEditingController.text != controller.text) {
          textEditingController.text = controller.text;
        }

        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Producto',
            hintText: 'Buscar por nombre, codigo o marca',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: AppColors.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (_) => productoSeleccionado == null
              ? 'Seleccione un producto de la lista'
              : null,
          onChanged: (value) {
            controller.text = value;
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: AppColors.surface,
            elevation: 8,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width < 760
                    ? MediaQuery.sizeOf(context).width - 44
                    : 640,
                maxHeight: 340,
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final producto = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(
                      producto.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${producto.codigo} - ${_branchLabel(origen)} ${_stockEnSucursal(producto, origen).toStringAsFixed(0)} - ${_branchLabel(destino)} ${_stockEnSucursal(producto, destino).toStringAsFixed(0)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      CurrencyFormatter.format(producto.precio),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => onSelected(producto),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SucursalDropdown extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _SucursalDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: Branches.values
          .map(
            (sucursal) => DropdownMenuItem(
              value: sucursal,
              child: Text(_branchLabel(sucursal)),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _StockPreview extends StatelessWidget {
  final ProductoModel producto;
  final String origen;
  final String destino;

  const _StockPreview({
    required this.producto,
    required this.origen,
    required this.destino,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: .45)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _StockPill(
            label: _branchLabel(origen),
            value: _stockEnSucursal(producto, origen),
          ),
          const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
          _StockPill(
            label: _branchLabel(destino),
            value: _stockEnSucursal(producto, destino),
          ),
        ],
      ),
    );
  }
}

class _StockPill extends StatelessWidget {
  final String label;
  final double value;

  const _StockPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label: ${value.toStringAsFixed(0)}',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;

  const _InfoBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: .45)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _displayProducto(ProductoModel producto) {
  return '${producto.codigo} - ${producto.nombre}';
}

String _textoBusqueda(ProductoModel producto) {
  return [
    producto.codigo,
    producto.codigoBarras,
    producto.nombre,
    producto.categoria,
    producto.marca,
    producto.proveedor,
  ].join(' ').toLowerCase();
}

double _stockEnSucursal(ProductoModel producto, String sucursal) {
  if (producto.stockPorSucursal.isEmpty && producto.stock > 0) {
    return sucursal == Branches.casaCentral ? producto.stock : 0;
  }

  return producto.stockPorSucursal[sucursal] ?? 0;
}

String _branchLabel(String sucursal) {
  return sucursal == Branches.casaCentral ? 'Santa Fe' : 'Alberdi';
}
