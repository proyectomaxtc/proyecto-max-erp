import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/layout/main_layout.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/caja_provider.dart';
import '../widgets/caja_header.dart';
import '../widgets/caja_summary.dart';
import '../widgets/caja_table.dart';

class CajaPage extends ConsumerStatefulWidget {
  const CajaPage({super.key});

  @override
  ConsumerState<CajaPage> createState() => _CajaPageState();
}

class _CajaPageState extends ConsumerState<CajaPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final usuario = ref.read(authProvider).usuario;
      if (usuario != null) {
        ref.read(cajaProvider.notifier).cambiarSucursal(usuario.sucursal);
      }
      ref.read(cajaProvider.notifier).cargarMovimientos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;

    return MainLayout(
      title: "Caja",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CajaSummary(),
          SizedBox(height: compact ? 10 : 20),
          const CajaHeader(),
          SizedBox(height: compact ? 10 : 20),
          const Expanded(child: CajaTable()),
        ],
      ),
    );
  }
}
