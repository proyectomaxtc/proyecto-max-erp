import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/layout/main_layout.dart';
import '../providers/cliente_provider.dart';
import '../widgets/cliente_header.dart';
import '../widgets/cliente_table.dart';

class ClientesPage extends ConsumerStatefulWidget {
  const ClientesPage({
    super.key,
  });

  @override
  ConsumerState<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends ConsumerState<ClientesPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clienteProvider.notifier).cargarClientes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Clientes",
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClienteHeader(),

          SizedBox(height: 30),

          Expanded(
            child: ClienteTable(),
          ),
        ],
      ),
    );
  }
}