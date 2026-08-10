import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/company.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/caja/providers/caja_provider.dart';
import 'menu_items.dart';
import 'pending_logout_provider.dart';

class SideMenu extends ConsumerWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final usuario = auth.usuario;
    final visibleItems = auth.esPropietario
        ? menuItems
        : menuItems.where((item) => item.visibleParaEmpleado).toList();
    final shortMenu = MediaQuery.sizeOf(context).height < 820;

    return Container(
      width: 260,
      color: const Color(0xFF151515),
      child: Column(
        children: [
          _CompanyHeader(compact: shortMenu),
          const Divider(color: AppColors.divider, height: 1),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: shortMenu ? 12 : 20,
              ),
              children: visibleItems
                  .map(
                    (item) => _MenuTile(
                      icon: item.icon,
                      title: item.title,
                      route: item.route,
                      compact: shortMenu,
                    ),
                  )
                  .toList(),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, shortMenu ? 8 : 16, 16, 10),
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
                  ).then((salir) async {
                    if (salir == true && context.mounted) {
                      await _cerrarSesion(context, ref);
                    }
                  });
                },
                icon: const Icon(Icons.logout),
                label: const Text("Cerrar sesion"),
              ),
            ),
          ),
          SizedBox(height: shortMenu ? 4 : 12),
          const Text(
            "Version 1.0.0",
            style: TextStyle(color: AppColors.textDisabled, fontSize: 11),
          ),
          SizedBox(height: shortMenu ? 2 : 4),
          Text(
            usuario == null
                ? "Sin usuario"
                : "${usuario.nombre} - ${usuario.rol}",
            style: TextStyle(color: AppColors.textDisabled, fontSize: 11),
          ),
          SizedBox(height: shortMenu ? 10 : 18),
        ],
      ),
    );
  }

  Future<void> _cerrarSesion(BuildContext context, WidgetRef ref) async {
    final usuario = ref.read(authProvider).usuario;

    if (usuario != null && !usuario.esPropietario) {
      var cajaAbierta = ref
          .read(cajaProvider)
          .cajaAbiertaParaSucursal(usuario.sucursal);

      if (!cajaAbierta) {
        await ref.read(cajaProvider.notifier).cargarMovimientos();
        if (!context.mounted) {
          return;
        }

        cajaAbierta = ref
            .read(cajaProvider)
            .cajaAbiertaParaSucursal(usuario.sucursal);
      }

      if (cajaAbierta) {
        ref.read(pendingLogoutAfterCajaCloseProvider.notifier).state = true;

        await showDialog<void>(
          context: context,
          builder: (_) {
            return AlertDialog(
              title: const Text("Controlar y cerrar caja"),
              content: const Text(
                "Antes de cerrar sesion debe controlar y cerrar la caja del turno.",
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Ir a Caja"),
                ),
              ],
            );
          },
        );

        if (context.mounted) {
          context.go(AppRoutes.caja);
        }
        return;
      }
    }

    ref.read(authProvider.notifier).logout();
    ref.read(pendingLogoutAfterCajaCloseProvider.notifier).state = false;
    if (context.mounted) {
      context.go(AppRoutes.login);
    }
  }
}

class _CompanyHeader extends StatelessWidget {
  final bool compact;

  const _CompanyHeader({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        compact ? 18 : 26,
        18,
        compact ? 18 : 28,
      ),
      child: Column(
        children: [
          Image.asset(
            Company.logo,
            width: compact ? 124 : 150,
            fit: BoxFit.contain,
          ),
          SizedBox(height: compact ? 14 : 20),
          Column(
            children: [
              Text(
                "Tucuman",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 23 : 26,
                  height: 1.05,
                ),
              ),
              Text(
                "Cerraduras",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 23 : 26,
                  height: 1.05,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 7 : 10),
          const Text(
            Company.system,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          const Text(
            Company.slogan,
            textAlign: TextAlign.center,
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
  final bool compact;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.route,
    required this.compact,
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
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: compact ? 11 : 14,
            ),
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
