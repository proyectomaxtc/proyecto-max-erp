import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/branches.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/layout/main_layout.dart';
import '../../../shared/widgets/dialogs/app_dialog.dart';
import '../../auth/providers/auth_provider.dart';

import '../providers/producto_provider.dart';

import '../widgets/producto_form.dart';
import '../widgets/producto_header.dart';
import '../widgets/producto_summary.dart';
import '../widgets/producto_table.dart';

class ProductosPage extends ConsumerStatefulWidget {
  const ProductosPage({super.key});

  @override
  ConsumerState<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends ConsumerState<ProductosPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final usuario = ref.read(authProvider).usuario;
      if (usuario != null && !usuario.esPropietario) {
        ref.read(productoProvider.notifier).cambiarSucursal(usuario.sucursal);
      } else {
        ref
            .read(productoProvider.notifier)
            .cambiarSucursal(Branches.casaCentral);
      }
      ref.read(productoProvider.notifier).cargarProductos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    final esPropietario = ref.watch(authProvider).esPropietario;

    return Stack(
      children: [
        MainLayout(
          title: "Productos",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProductoSummary(),
              SizedBox(height: compact ? 8 : 12),
              const ProductoHeader(),
              SizedBox(height: compact ? 8 : 12),
              const Expanded(child: ProductoTable()),
            ],
          ),
        ),
        if (compact && esPropietario)
          Positioned(
            right: 16,
            bottom: 78,
            child: FloatingActionButton(
              heroTag: 'nuevo-producto-mobile',
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              tooltip: "Nuevo Producto",
              onPressed: () => _abrirProducto(context),
              child: const Icon(Icons.add),
            ),
          ),
      ],
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
