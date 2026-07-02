import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/company.dart';
import '../../../features/auth/providers/auth_provider.dart';
import 'menu_items.dart';

class SideMenu extends ConsumerWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final usuario = auth.usuario;
    final visibleItems = auth.esPropietario
        ? menuItems
        : menuItems.where((item) => item.visibleParaEmpleado).toList();

    return Container(
      width: 260,
      color: const Color(0xFF151515),
      child: Column(
        children: [
          const _CompanyHeader(),
          const Divider(color: AppColors.divider, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              children: visibleItems
                  .map(
                    (item) => _MenuTile(
                      icon: item.icon,
                      title: item.title,
                      route: item.route,
                    ),
                  )
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog<bool>(
                    context: context,
                    builder: (_) {
                      return AlertDialog(
                        title: const Text("Cerrar sesion"),
                        content: const Text("Desea salir del sistema?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancelar"),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Salir"),
                          ),
                        ],
                      );
                    },
                  ).then((salir) {
                    if (salir == true && context.mounted) {
                      ref.read(authProvider.notifier).logout();
                      context.go(AppRoutes.login);
                    }
                  });
                },
                icon: const Icon(Icons.logout),
                label: const Text("Cerrar sesion"),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Version 1.0.0",
            style: TextStyle(color: AppColors.textDisabled, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            usuario == null
                ? "Sin usuario"
                : "${usuario.nombre} - ${usuario.rol}",
            style: TextStyle(color: AppColors.textDisabled, fontSize: 11),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _CompanyHeader extends StatelessWidget {
  const _CompanyHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          Image.asset(Company.logo, height: 80, fit: BoxFit.contain),
          const SizedBox(height: 18),
          const Text(
            Company.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            Company.system,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 4),
          const Text(
            Company.slogan,
            style: TextStyle(color: AppColors.textDisabled, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final selected = GoRouterState.of(context).uri.toString() == route;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            context.go(route);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
