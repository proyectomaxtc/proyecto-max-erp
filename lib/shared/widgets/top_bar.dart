import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/constants/app_colors.dart';

class TopBar extends StatelessWidget {
  final String title;

  const TopBar({super.key, this.title = "Dashboard"});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 25),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: .08)),
        ),
      ),

      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          SizedBox(
            width: 320,

            child: TextField(
              onSubmitted: (value) {
                final query = value.trim().toLowerCase();

                if (query.contains('venta')) {
                  context.go(AppRoutes.ventas);
                } else if (query.contains('cliente')) {
                  context.go(AppRoutes.clientes);
                } else if (query.contains('producto') ||
                    query.contains('stock')) {
                  context.go(AppRoutes.productos);
                } else if (query.contains('caja')) {
                  context.go(AppRoutes.caja);
                } else if (query.contains('servicio')) {
                  context.go(AppRoutes.servicios);
                }
              },
              decoration: InputDecoration(
                hintText: "Buscar...",
                prefixIcon: const Icon(Icons.search),

                filled: true,

                fillColor: AppColors.card,

                contentPadding: const EdgeInsets.symmetric(vertical: 0),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(width: 20),

          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("No hay notificaciones pendientes"),
                ),
              );
            },
            icon: const Icon(Icons.notifications_none, color: Colors.white70),
          ),

          IconButton(
            onPressed: () {
              context.go(AppRoutes.configuracion);
            },
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
          ),

          const SizedBox(width: 15),

          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, color: Colors.black),
          ),

          const SizedBox(width: 10),

          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Cristian",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 2),

              Text(
                "Administrador",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
