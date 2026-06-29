import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import 'cliente_search.dart';

class ClienteHeader extends StatelessWidget {
  const ClienteHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Clientes",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              SizedBox(height: 6),

              Text(
                "Administración de clientes",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        const ClienteSearch(),

        const SizedBox(width: 16),

        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text("Nuevo Cliente"),
        ),
      ],
    );
  }
}