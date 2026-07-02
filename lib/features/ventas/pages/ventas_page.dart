import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../clientes/providers/cliente_provider.dart';
import '../../productos/providers/producto_provider.dart';
import '../../../shared/layout/main_layout.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/venta_provider.dart';
import '../widgets/ventas_header.dart';
import '../widgets/ventas_summary.dart';
import '../widgets/ventas_table.dart';

class VentasPage extends ConsumerStatefulWidget {
  const VentasPage({super.key});

  @override
  ConsumerState<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends ConsumerState<VentasPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final usuario = ref.read(authProvider).usuario;
      if (usuario != null) {
        ref.read(ventaProvider.notifier).cambiarSucursal(usuario.sucursal);
      }
      ref.read(ventaProvider.notifier).cargarVentas();
      ref.read(clienteProvider.notifier).cargarClientes();
      ref.read(productoProvider.notifier).cargarProductos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;

    return MainLayout(
      title: "Ventas",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const VentasSummary(),
          SizedBox(height: compact ? 10 : 20),
          const VentasHeader(),
          SizedBox(height: compact ? 10 : 20),
          const Expanded(child: VentasTable()),
        ],
      ),
    );
  }
}
