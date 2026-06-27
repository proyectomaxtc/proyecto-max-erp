import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class TopBar extends StatelessWidget {
  final String title;

  const TopBar({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider,
          ),
        ),
      ),
      child: Row(
        children: [
          //==========================
          // Título
          //==========================

          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  "Bienvenido nuevamente",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          //==========================
          // Buscador
          //==========================

          Expanded(
            flex: 4,
            child: SizedBox(
              height: 48,
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Buscar clientes, ventas, productos...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.card,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 25),

          //==========================
          // Acciones
          //==========================

          IconButton(
            tooltip: "Notificaciones",
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textSecondary,
            ),
          ),

          IconButton(
            tooltip: "Configuración",
            onPressed: () {},
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(width: 12),

          const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary,
            child: Icon(
              Icons.person,
              color: Colors.black,
            ),
          ),

          const SizedBox(width: 12),

          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Cristian",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Administrador",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}