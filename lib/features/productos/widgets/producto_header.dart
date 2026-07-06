import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/branches.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/dialogs/app_dialog.dart';
import '../../auth/providers/auth_provider.dart';

import '../enums/producto_filter.dart';
import '../models/producto_import_model.dart';
import '../models/producto_model.dart';
import '../providers/producto_provider.dart';

import 'producto_form.dart';
import 'producto_search.dart';
import 'producto_table.dart';

class ProductoHeader extends ConsumerWidget {
  const ProductoHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtroActivo = ref.watch(productoProvider).filtro;
    final state = ref.watch(productoProvider);
    final usuario = ref.watch(authProvider).usuario;
    final esPropietario = usuario?.esPropietario ?? false;
    final compact = MediaQuery.sizeOf(context).width < 760;
    final sucursalActual = esPropietario
        ? state.sucursalSeleccionada
        : (usuario?.sucursal ?? state.sucursalSeleccionada);
    final filtros = ProductoFilter.values.map((filtro) {
      return ChoiceChip(
        label: Text(_labelFiltro(filtro)),
        selected: filtroActivo == filtro,
        showCheckmark: false,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.card,
        labelStyle: TextStyle(
          color: filtroActivo == filtro
              ? Colors.black
              : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(
          color: filtroActivo == filtro ? AppColors.primary : AppColors.border,
        ),
        onSelected: (_) {
          ref.read(productoProvider.notifier).cambiarFiltro(filtro);
        },
      );
    }).toList();
    final sucursales = Branches.values.map((sucursal) {
      final selected = sucursalActual == sucursal;

      return ChoiceChip(
        label: Text(sucursal == Branches.casaCentral ? 'Santa Fe' : 'Alberdi'),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.card,
        labelStyle: TextStyle(
          color: selected ? Colors.black : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
        onSelected: esPropietario
            ? (_) {
                ref.read(productoProvider.notifier).cambiarSucursal(sucursal);
              }
            : null,
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SucursalActualBanner(
            sucursal: sucursalActual,
            esPropietario: esPropietario,
            sucursales: sucursales,
          ),
          const SizedBox(height: 14),
          compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ProductoSearch(),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: filtros
                            .map(
                              (filtro) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: filtro,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () => _abrirListaCompleta(context),
                          icon: const Icon(Icons.open_in_full_rounded),
                          label: const Text("Lista completa"),
                        ),
                        if (esPropietario) ...[
                          OutlinedButton.icon(
                            onPressed: () => _abrirActualizadorLlaves(context),
                            icon: const Icon(Icons.key_outlined),
                            label: const Text("Actualizar llaves"),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _abrirImportadorLista(context),
                            icon: const Icon(Icons.upload_file_outlined),
                            label: const Text("Importar lista"),
                          ),
                        ],
                      ],
                    ),
                  ],
                )
              : Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(flex: 3, child: ProductoSearch()),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 5,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: filtros
                                  .map(
                                    (filtro) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: filtro,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (esPropietario) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FilledButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text("Nuevo Producto"),
                            onPressed: () => _abrirProducto(context),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.open_in_full_rounded),
                            label: const Text("Lista completa"),
                            onPressed: () => _abrirListaCompleta(context),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.key_outlined),
                            label: const Text("Actualizar llaves"),
                            onPressed: () => _abrirActualizadorLlaves(context),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.upload_file_outlined),
                            label: const Text("Importar lista"),
                            onPressed: () => _abrirImportadorLista(context),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
        ],
      ),
    );
  }

  void _abrirListaCompleta(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _CatalogoCompletoDialog(),
    );
  }

  void _abrirImportadorLista(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ImportarListaDialog(),
    );
  }

  void _abrirActualizadorLlaves(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ActualizarLlavesDialog(),
    );
  }

  void _abrirProducto(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const AppDialog(title: "Nuevo Producto", child: ProductoForm());
      },
    );
  }
}

class _ActualizarLlavesDialog extends ConsumerStatefulWidget {
  const _ActualizarLlavesDialog();

  @override
  ConsumerState<_ActualizarLlavesDialog> createState() =>
      _ActualizarLlavesDialogState();
}

class _ActualizarLlavesDialogState
    extends ConsumerState<_ActualizarLlavesDialog> {
  final costoController = TextEditingController();
  final precioController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool guardando = false;

  @override
  void dispose() {
    costoController.dispose();
    precioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productos = ref.watch(productoProvider).productos;
    final cantidad = productos.where(_esLlaveDoblePaleta).length;
    final compact = MediaQuery.sizeOf(context).width < 760;

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: EdgeInsets.all(compact ? 12 : 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: EdgeInsets.all(compact ? 16 : 22),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Actualizar llaves doble paleta",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: guardando
                          ? null
                          : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  cantidad == 1
                      ? "Se actualizara solo 1 producto detectado como llave doble paleta."
                      : "Se actualizaran solo $cantidad productos detectados como llaves doble paleta.",
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: costoController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _decoration("Nuevo costo"),
                  validator: _validarImporte,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: precioController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _decoration("Nuevo precio venta"),
                  validator: _validarImporte,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: .45),
                    ),
                  ),
                  child: const Text(
                    "Esto no modifica ventas anteriores. Solo cambia el costo y precio para futuras ventas. No afecta otros modelos de llaves que no figuren como doble paleta.",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: guardando
                          ? null
                          : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text("Cancelar"),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: guardando || cantidad == 0 ? null : _guardar,
                      icon: guardando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text("Aplicar"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  String? _validarImporte(String? value) {
    final importe = _parseMoney(value ?? '');
    if (importe <= 0) {
      return "Ingrese un importe mayor a 0";
    }

    return null;
  }

  double _parseMoney(String value) {
    final raw = value.replaceAll('\$', '').replaceAll(' ', '');
    final normalized = raw.contains(',')
        ? raw.replaceAll('.', '').replaceAll(',', '.')
        : raw;
    return double.tryParse(normalized) ?? 0;
  }

  bool _esLlaveDoblePaleta(ProductoModel producto) {
    final texto = [
      producto.nombre,
      producto.categoria,
      producto.descripcion,
    ].join(' ').toLowerCase();

    final esLlave =
        texto.contains('llave') ||
        texto.contains('copia') ||
        texto.contains('duplicado');

    return esLlave && texto.contains('doble paleta');
  }

  Future<void> _guardar() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      guardando = true;
    });

    final cantidad = await ref
        .read(productoProvider.notifier)
        .actualizarLlavesDoblePaleta(
          costo: _parseMoney(costoController.text),
          precio: _parseMoney(precioController.text),
        );

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text(
          cantidad == 1
              ? "Se actualizo 1 llave doble paleta"
              : "Se actualizaron $cantidad llaves doble paleta",
        ),
      ),
    );
  }
}

class _ImportarListaDialog extends ConsumerStatefulWidget {
  const _ImportarListaDialog();

  @override
  ConsumerState<_ImportarListaDialog> createState() =>
      _ImportarListaDialogState();
}

class _ImportarListaDialogState extends ConsumerState<_ImportarListaDialog> {
  final proveedorController = TextEditingController();
  final lineasController = TextEditingController();
  String? archivoReferencia;
  bool importando = false;

  @override
  void dispose() {
    proveedorController.dispose();
    lineasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _parsearLineas(lineasController.text);
    final compact = MediaQuery.sizeOf(context).width < 760;

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: EdgeInsets.all(compact ? 12 : 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 900,
          maxHeight: MediaQuery.sizeOf(context).height * .9,
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 16 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Importar lista",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: importando ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                "Pegue los articulos con este formato: codigo; nombre; costo; marca; categoria. Si ya existe el mismo proveedor y codigo, se actualiza el costo y los datos.",
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: proveedorController,
                decoration: _decoration("Proveedor"),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: importando ? null : _adjuntarReferencia,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(
                      archivoReferencia == null
                          ? "Adjuntar foto/remito"
                          : "Cambiar referencia",
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: importando ? null : _cargarEjemploLcc,
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text("Usar ejemplo LCC"),
                  ),
                ],
              ),
              if (archivoReferencia != null) ...[
                const SizedBox(height: 8),
                Text(
                  "Referencia: $archivoReferencia",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: lineasController,
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: _decoration(
                    "codigo; nombre; costo; marca; categoria",
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  "${items.length} articulos validos detectados",
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: importando ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text("Cancelar"),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: importando || items.isEmpty
                        ? null
                        : () => _importar(items),
                    icon: importando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file_outlined),
                    label: const Text("Importar"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Future<void> _adjuntarReferencia() async {
    const typeGroup = XTypeGroup(
      label: 'Remitos o listas',
      extensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf', 'csv', 'txt'],
    );
    final archivo = await openFile(acceptedTypeGroups: [typeGroup]);

    if (archivo == null) {
      return;
    }

    setState(() {
      archivoReferencia = archivo.name;
    });
  }

  void _cargarEjemploLcc() {
    proveedorController.text = 'LCC - La casa de la cerradura';
    lineasController.text = [
      '04301; Andif 857-40 Cerradura pasador rectangular 4 placas angosta abierta; 14910; Andif; Cerraduras de aplicar',
      '04545; Prive 200 Cerradura pasador rectangular 4 placas F-grande en bolsa; 13777.61; Prive; Cerraduras doble paleta',
      '05968; Prive 207 Cerradura pasador rectangular 4 placas F-chico en bolsa; 12527.69; Prive; Cerraduras doble paleta',
      '06833; Bronzen 805 Pasador con llave cruz cromo; 8500; Bronzen; Cerraduras de aplicar',
    ].join('\n');
    setState(() {});
  }

  List<ProductoImportItem> _parsearLineas(String texto) {
    final items = <ProductoImportItem>[];

    for (final linea in texto.split('\n')) {
      final limpia = linea.trim();
      if (limpia.isEmpty) {
        continue;
      }

      final partes = limpia.contains(';')
          ? limpia.split(';')
          : limpia.contains('\t')
          ? limpia.split('\t')
          : limpia.split(',');

      if (partes.length < 3) {
        continue;
      }

      final costo = _parseMoney(partes[2]);
      if (costo <= 0) {
        continue;
      }

      items.add(
        ProductoImportItem(
          codigoProveedor: partes[0].trim(),
          nombre: partes[1].trim(),
          costo: costo,
          marca: partes.length > 3 ? partes[3].trim() : '',
          categoria: partes.length > 4 ? partes[4].trim() : 'Otros',
        ),
      );
    }

    return items;
  }

  double _parseMoney(String value) {
    final raw = value.replaceAll('\$', '').replaceAll(' ', '');
    final normalized = raw.contains(',')
        ? raw.replaceAll('.', '').replaceAll(',', '.')
        : raw;
    return double.tryParse(normalized) ?? 0;
  }

  Future<void> _importar(List<ProductoImportItem> items) async {
    final proveedor = proveedorController.text.trim();
    if (proveedor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Ingrese el proveedor de la lista'),
        ),
      );
      return;
    }

    setState(() {
      importando = true;
    });

    final resultado = await ref
        .read(productoProvider.notifier)
        .importarLista(proveedor: proveedor, items: items);

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text(
          'Lista importada: ${resultado.creados} nuevos, ${resultado.actualizados} actualizados, ${resultado.ignorados} ignorados',
        ),
      ),
    );
  }
}

String _labelFiltro(ProductoFilter filtro) {
  return switch (filtro) {
    ProductoFilter.todos => "Todos",
    ProductoFilter.activos => "Activos",
    ProductoFilter.inactivos => "Inactivos",
    ProductoFilter.bajoStock => "Stock bajo",
    ProductoFilter.sinStock => "Sin stock",
  };
}

class _CatalogoCompletoDialog extends ConsumerWidget {
  const _CatalogoCompletoDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productoProvider);
    final usuario = ref.watch(authProvider).usuario;
    final esPropietario = usuario?.esPropietario ?? false;
    final compact = MediaQuery.sizeOf(context).width < 760;
    final sucursalActual = esPropietario
        ? state.sucursalSeleccionada
        : (usuario?.sucursal ?? state.sucursalSeleccionada);
    final filtros = ProductoFilter.values.map((filtro) {
      final selected = state.filtro == filtro;
      return ChoiceChip(
        label: Text(_labelFiltro(filtro)),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.card,
        labelStyle: TextStyle(
          color: selected ? Colors.black : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
        onSelected: (_) {
          ref.read(productoProvider.notifier).cambiarFiltro(filtro);
        },
      );
    }).toList();
    final sucursales = Branches.values.map((sucursal) {
      final selected = sucursalActual == sucursal;
      return ChoiceChip(
        label: Text(sucursal == Branches.casaCentral ? 'Santa Fe' : 'Alberdi'),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.card,
        labelStyle: TextStyle(
          color: selected ? Colors.black : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
        onSelected: esPropietario
            ? (_) {
                ref.read(productoProvider.notifier).cambiarSucursal(sucursal);
              }
            : null,
      );
    }).toList();

    return Dialog.fullscreen(
      backgroundColor: const Color(0xFF111111),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(compact ? 10 : 18),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Catalogo de productos",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton.filled(
                    tooltip: "Cerrar",
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              SizedBox(height: compact ? 10 : 14),
              Container(
                padding: EdgeInsets.all(compact ? 12 : 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const ProductoSearch(),
                          const SizedBox(height: 10),
                          Wrap(spacing: 8, runSpacing: 8, children: filtros),
                          if (esPropietario) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: sucursales,
                            ),
                          ],
                        ],
                      )
                    : Row(
                        children: [
                          const Expanded(flex: 2, child: ProductoSearch()),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 3,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: filtros,
                            ),
                          ),
                          if (esPropietario) ...[
                            const SizedBox(width: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: sucursales,
                            ),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              const Expanded(child: ProductoTable()),
            ],
          ),
        ),
      ),
    );
  }
}

class _SucursalActualBanner extends StatelessWidget {
  final String sucursal;
  final bool esPropietario;
  final List<Widget> sucursales;

  const _SucursalActualBanner({
    required this.sucursal,
    required this.esPropietario,
    required this.sucursales,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: .45)),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SucursalLabel(sucursal: sucursal),
                if (esPropietario) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: sucursales),
                ],
              ],
            )
          : Row(
              children: [
                Expanded(child: _SucursalLabel(sucursal: sucursal)),
                if (esPropietario)
                  Wrap(spacing: 8, runSpacing: 8, children: sucursales),
              ],
            ),
    );
  }
}

class _SucursalLabel extends StatelessWidget {
  final String sucursal;

  const _SucursalLabel({required this.sucursal});

  @override
  Widget build(BuildContext context) {
    final label = sucursal == Branches.casaCentral
        ? 'Casa Central Santa Fe'
        : 'Sucursal Alberdi';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.storefront_outlined, color: AppColors.primary),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            'Stock navegando: $label',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
