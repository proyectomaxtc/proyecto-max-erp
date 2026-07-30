import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/dialogs/app_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/producto_model.dart';
import '../providers/producto_provider.dart';
import 'producto_form.dart';

class ProductoTable extends ConsumerWidget {
  const ProductoTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productoProvider);
    final productos = state.productosFiltrados;
    final sucursal = state.sucursalSeleccionada;
    final esPropietario = ref.watch(authProvider).esPropietario;
    final compact = MediaQuery.sizeOf(context).width < 760;

    if (productos.isEmpty) {
      if (state.loading) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                "Cargando productos",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Sincronizando el catalogo con la nube.",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              color: AppColors.textDisabled,
              size: 56,
            ),
            SizedBox(height: 16),
            Text(
              "No hay productos para mostrar",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Ajusta la busqueda o carga un nuevo producto.",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (compact) {
      return ListView.separated(
        padding: const EdgeInsets.only(bottom: 90),
        itemCount: productos.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final producto = productos[index];
          return _ProductoMobileCard(
            producto: producto,
            stock: producto.stockEnSucursal(sucursal),
            estado: _estadoProducto(producto, sucursal),
            esPropietario: esPropietario,
            onEdit: () => _abrirEditor(context, producto),
            onDelete: () => _confirmarEliminar(context, ref, producto),
          );
        },
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 18),
      itemCount: productos.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final producto = productos[index];
        return _ProductoListCard(
          producto: producto,
          stock: producto.stockEnSucursal(sucursal),
          estado: _estadoProducto(producto, sucursal),
          esPropietario: esPropietario,
          onEdit: () => _abrirEditor(context, producto),
          onDelete: () => _confirmarEliminar(context, ref, producto),
        );
      },
    );
  }

  void _abrirEditor(BuildContext context, ProductoModel producto) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AppDialog(
          title: "Editar Producto",
          child: ProductoForm(producto: producto),
        );
      },
    );
  }

  Future<void> _confirmarEliminar(
    BuildContext context,
    WidgetRef ref,
    ProductoModel producto,
  ) async {
    final eliminar = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Eliminar Producto"),
          content: Text("Desea eliminar ${producto.nombre}?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancelar"),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Eliminar"),
            ),
          ],
        );
      },
    );

    if (eliminar == true) {
      try {
        await ref.read(productoProvider.notifier).eliminarProducto(producto.id);
      } catch (error) {
        if (!context.mounted) return;

        final mensaje = error.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              mensaje.isEmpty
                  ? 'No se pudo eliminar el producto.'
                  : mensaje,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      }
    }
  }

  _ProductoStatus _estadoProducto(ProductoModel producto, String sucursal) {
    final stock = producto.stockEnSucursal(sucursal);
    final minimo = producto.stockMinimoEnSucursal(sucursal);

    if (producto.esVentaLibre) {
      return const _ProductoStatus(
        label: "Venta libre",
        color: AppColors.primary,
      );
    }

    if (!producto.activo) {
      return const _ProductoStatus(
        label: "Inactivo",
        color: AppColors.textDisabled,
      );
    }

    if (stock <= 0) {
      return const _ProductoStatus(label: "Sin stock", color: AppColors.error);
    }

    if (stock <= minimo) {
      return const _ProductoStatus(
        label: "Stock bajo",
        color: AppColors.warning,
      );
    }

    return const _ProductoStatus(label: "Disponible", color: AppColors.success);
  }
}

class _ProductoMobileCard extends StatelessWidget {
  final ProductoModel producto;
  final double stock;
  final _ProductoStatus estado;
  final bool esPropietario;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductoMobileCard({
    required this.producto,
    required this.stock,
    required this.estado,
    required this.esPropietario,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _ProductoThumb(path: producto.imagenPath),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${producto.codigo} - ${producto.categoria}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _InfoPill("Stock", stock.toStringAsFixed(0)),
                    _PricePill(CurrencyFormatter.format(producto.precio)),
                    _StatusPill(estado),
                  ],
                ),
              ],
            ),
          ),
          if (esPropietario) ...[
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.filledTonal(
                  tooltip: "Editar",
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
                const SizedBox(height: 2),
                IconButton(
                  tooltip: "Eliminar",
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductoListCard extends StatelessWidget {
  final ProductoModel producto;
  final double stock;
  final _ProductoStatus estado;
  final bool esPropietario;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductoListCard({
    required this.producto,
    required this.stock,
    required this.estado,
    required this.esPropietario,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final medium = MediaQuery.sizeOf(context).width < 1040;
    final details = [
      _InfoPill("Codigo", producto.codigo),
      _InfoPill("Categoria", producto.categoria),
      if (producto.marca.trim().isNotEmpty) _InfoPill("Marca", producto.marca),
      _InfoPill("Stock", stock.toStringAsFixed(0)),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductoThumb(path: producto.imagenPath, size: 58),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre,
                  maxLines: medium ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (producto.descripcion.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    producto.descripcion,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textDisabled,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(spacing: 7, runSpacing: 7, children: details),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _PricePanel(CurrencyFormatter.format(producto.precio)),
              const SizedBox(height: 8),
              _StatusPill(estado),
              if (esPropietario) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.filledTonal(
                      tooltip: "Editar",
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: "Eliminar",
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
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
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;

  const _InfoPill(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        "$label: $value",
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PricePanel extends StatelessWidget {
  final String value;

  const _PricePanel(this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 142),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .2),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            "Precio venta",
            style: TextStyle(
              color: Colors.black87,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  final String value;

  const _PricePill(this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.secondary),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sell_outlined, size: 15, color: Colors.black),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final _ProductoStatus estado;

  const _StatusPill(this.estado);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: estado.color,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        estado.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ProductoThumb extends StatelessWidget {
  final String path;
  final double size;

  const _ProductoThumb({required this.path, this.size = 46});

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

    final image = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageBytes != null
          ? Image.memory(imageBytes, fit: BoxFit.cover)
          : isNetworkImage
          ? Image.network(
              path,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.image_outlined,
                  color: AppColors.textDisabled,
                  size: 22,
                );
              },
            )
          : tieneFoto && path.startsWith('assets/')
          ? Image.asset(path, fit: BoxFit.cover)
          : tieneFoto && !kIsWeb
          ? Image.file(File(path), fit: BoxFit.cover)
          : const Icon(
              Icons.image_outlined,
              color: AppColors.textDisabled,
              size: 22,
            ),
    );

    if (!tieneFoto) {
      return image;
    }

    return Tooltip(
      message: 'Ver foto',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _mostrarFoto(context, imageBytes),
        child: MouseRegion(cursor: SystemMouseCursors.click, child: image),
      ),
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
                                Icons.image_outlined,
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

class _ProductoStatus {
  final String label;
  final Color color;

  const _ProductoStatus({required this.label, required this.color});
}
