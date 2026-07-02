import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/layout/main_layout.dart';
import '../../../shared/widgets/layout/operational_card.dart';
import '../providers/configuracion_provider.dart';
import '../widgets/configuracion_form.dart';
import '../widgets/product_category_panel.dart';
import '../widgets/user_management_panel.dart';

class ConfiguracionPage extends ConsumerWidget {
  const ConfiguracionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configuracionProvider);
    final esPropietario = ref.watch(authProvider).esPropietario;
    final compact = MediaQuery.sizeOf(context).width < 760;

    if (!esPropietario) {
      return const MainLayout(
        title: "Configuracion",
        child: Center(
          child: Text(
            "Solo el propietario puede modificar la configuracion y usuarios.",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return MainLayout(
      title: "Configuracion",
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(compact ? 18 : 24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.business_rounded,
                          color: AppColors.primary,
                          size: 40,
                        ),
                        const SizedBox(height: 14),
                        _CompanyText(
                          config.empresa,
                          config.sistema,
                          config.slogan,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        const Icon(
                          Icons.business_rounded,
                          color: AppColors.primary,
                          size: 42,
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: _CompanyText(
                            config.empresa,
                            config.sistema,
                            config.slogan,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(compact ? 16 : 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const ConfiguracionForm(),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(compact ? 16 : 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const ProductCategoryPanel(),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(compact ? 16 : 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const UserManagementPanel(),
            ),
            const SizedBox(height: 20),
            if (compact)
              Column(
                children: [
                  OperationalCard(
                    title: "Seguridad operativa",
                    icon: Icons.admin_panel_settings_outlined,
                    description:
                        "La clave del propietario protege cierres de caja, ventas y movimientos sensibles.",
                    items: const [
                      "Caja",
                      "Ventas",
                      "Autorizacion",
                      "Auditoria",
                    ],
                    actions: {
                      "Caja": () => context.go(AppRoutes.caja),
                      "Ventas": () => context.go(AppRoutes.ventas),
                      "Autorizacion": () => context.go(AppRoutes.configuracion),
                      "Auditoria": () => context.go(AppRoutes.reportes),
                    },
                  ),
                  const SizedBox(height: 12),
                  OperationalCard(
                    title: "Usuarios y roles",
                    icon: Icons.people_alt_outlined,
                    description:
                        "El propietario administra empleados, codigos de ingreso y permisos por modulo.",
                    items: const [
                      "Propietario",
                      "Empleado",
                      "Permisos",
                      "Accesos",
                    ],
                    actions: {
                      "Propietario": () => context.go(AppRoutes.configuracion),
                      "Empleado": () => context.go(AppRoutes.configuracion),
                      "Permisos": () => context.go(AppRoutes.configuracion),
                      "Accesos": () => context.go(AppRoutes.configuracion),
                    },
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OperationalCard(
                      title: "Seguridad operativa",
                      icon: Icons.admin_panel_settings_outlined,
                      description:
                          "La clave del propietario protege cierres de caja, ventas y movimientos sensibles.",
                      items: const [
                        "Caja",
                        "Ventas",
                        "Autorizacion",
                        "Auditoria",
                      ],
                      actions: {
                        "Caja": () => context.go(AppRoutes.caja),
                        "Ventas": () => context.go(AppRoutes.ventas),
                        "Autorizacion": () =>
                            context.go(AppRoutes.configuracion),
                        "Auditoria": () => context.go(AppRoutes.reportes),
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OperationalCard(
                      title: "Usuarios y roles",
                      icon: Icons.people_alt_outlined,
                      description:
                          "El propietario administra empleados, codigos de ingreso y permisos por modulo.",
                      items: const [
                        "Propietario",
                        "Empleado",
                        "Permisos",
                        "Accesos",
                      ],
                      actions: {
                        "Propietario": () =>
                            context.go(AppRoutes.configuracion),
                        "Empleado": () => context.go(AppRoutes.configuracion),
                        "Permisos": () => context.go(AppRoutes.configuracion),
                        "Accesos": () => context.go(AppRoutes.configuracion),
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _CompanyText extends StatelessWidget {
  final String empresa;
  final String sistema;
  final String slogan;

  const _CompanyText(this.empresa, this.sistema, this.slogan);

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          empresa,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: compact ? 22 : 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "$sistema - $slogan",
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
