import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/cards/kpi_card.dart';
import '../../../shared/widgets/dashboard/dashboard_header.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardBody extends ConsumerWidget {
  const DashboardBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    final usuario = ref.watch(authProvider).usuario;
    final esPropietario = ref.watch(authProvider).esPropietario;
    final compact = MediaQuery.sizeOf(context).width < 760;

    return dashboard.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          error.toString(),
          style: const TextStyle(color: Colors.red),
        ),
      ),
      data: (data) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardHeader(
                title: "${_saludo()}, ${usuario?.nombre ?? 'Usuario'}",
                subtitle:
                    "Casa Central - Tucuman Cerraduras - ${usuario?.rol ?? 'Sin sesion'} - ${data.periodLabel}",
                compact: compact,
              ),
              SizedBox(height: compact ? 10 : 30),
              _DashboardKpis(
                compact: compact,
                cards: [
                  KpiCard(
                    title: "Caja",
                    value: CurrencyFormatter.format(data.cash),
                    icon: Icons.account_balance_wallet,
                    color: AppColors.cash,
                    subtitle: "Saldo real de caja",
                  ),
                  KpiCard(
                    title: "Ventas",
                    value: CurrencyFormatter.format(data.sales),
                    icon: Icons.point_of_sale,
                    color: AppColors.sales,
                    subtitle: "Ventas del mes",
                  ),
                  KpiCard(
                    title: "Compras",
                    value: CurrencyFormatter.format(data.purchases),
                    icon: Icons.shopping_cart,
                    color: AppColors.purchases,
                    subtitle: "Compras del mes",
                  ),
                  KpiCard(
                    title: esPropietario ? "Utilidad" : "Clientes",
                    value: esPropietario
                        ? CurrencyFormatter.format(data.profit)
                        : data.todayCustomers.toString(),
                    icon: esPropietario
                        ? Icons.trending_up
                        : Icons.people_alt_outlined,
                    color: AppColors.success,
                    subtitle: esPropietario
                        ? "Utilidad del mes"
                        : "Cargados hoy",
                  ),
                ],
              ),
              SizedBox(height: compact ? 18 : 35),
              Text(
                "Acciones rapidas",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: compact ? 20 : 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: compact ? 14 : 20),
              _QuickActions(compact: compact),
            ],
          ),
        );
      },
    );
  }

  String _saludo() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return "Buenos dias";
    if (hour >= 12 && hour < 20) return "Buenas tardes";
    return "Buenas noches";
  }
}

class _QuickActions extends StatelessWidget {
  final bool compact;

  const _QuickActions({required this.compact});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction("Nueva Venta", Icons.add, AppRoutes.ventas),
      _QuickAction("Nuevo Cliente", Icons.person_add, AppRoutes.clientes),
      _QuickAction("Abrir Caja", Icons.point_of_sale, AppRoutes.caja),
      _QuickAction("Nuevo Producto", Icons.inventory, AppRoutes.productos),
      _QuickAction("Compras", Icons.shopping_cart, AppRoutes.compras),
      _QuickAction("Proveedores", Icons.local_shipping, AppRoutes.proveedores),
      _QuickAction(
        "Comprobantes",
        Icons.picture_as_pdf_outlined,
        AppRoutes.comprobantes,
      ),
      _QuickAction(
        "Mayorista",
        Icons.price_change_rounded,
        AppRoutes.mayorista,
      ),
      _QuickAction("Nuevo Servicio", Icons.key, AppRoutes.servicios),
    ];

    if (!compact) {
      return Wrap(
        spacing: 15,
        runSpacing: 15,
        children: actions.map((action) => _ActionButton(action)).toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: actions
              .map(
                (action) =>
                    SizedBox(width: width, child: _ActionButton(action)),
              )
              .toList(),
        );
      },
    );
  }
}

class _DashboardKpis extends StatelessWidget {
  final bool compact;
  final List<Widget> cards;

  const _DashboardKpis({required this.compact, required this.cards});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: cards.length,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            return SizedBox(width: 148, child: cards[index]);
          },
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: 1.35,
      children: cards,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final _QuickAction action;

  const _ActionButton(this.action);

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () {
        context.go(action.route);
      },
      icon: Icon(action.icon),
      label: Text(action.label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final String route;

  const _QuickAction(this.label, this.icon, this.route);
}
