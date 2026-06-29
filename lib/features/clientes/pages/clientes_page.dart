import 'package:flutter/material.dart';

import '../../../shared/layout/main_layout.dart';
import '../widgets/cliente_header.dart';
import '../widgets/cliente_table.dart';

class ClientesPage extends StatelessWidget {
  const ClientesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Clientes",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ClienteHeader(),

          const SizedBox(height: 30),

          const Expanded(
            child: ClienteTable(),
          ),
        ],
      ),
    );
  }
}