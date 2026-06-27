import 'package:flutter/material.dart';

import '../../../shared/layout/main_layout.dart';
import '../widgets/cliente_table.dart';

class ClientesPage extends StatelessWidget {
  const ClientesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainLayout(
      title: "Clientes",
      child: Padding(
        padding: EdgeInsets.all(24),
        child: ClienteTable(),
      ),
    );
  }
}