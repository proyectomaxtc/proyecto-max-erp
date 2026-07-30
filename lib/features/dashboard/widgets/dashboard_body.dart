import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/cards/kpi_card.dart';
import '../../../shared/widgets/dashboard/dashboard_header.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/dashboard_stats.dart';
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
                    subtitle: "${data.salesCount} ventas del mes",
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
              if (esPropietario) ...[
                SizedBox(height: compact ? 18 : 26),
                _OwnerInsights(stats: data, compact: compact),
              ],
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

class _OwnerInsights extends StatelessWidget {
  final DashboardStats stats;
  final bool compact;

  const _OwnerInsights({required this.stats, required this.compact});

  @override
  Widget build(BuildContext context) {
    final metrics = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _MiniInsightMetric(
          icon: Icons.receipt_long_outlined,
          label: "Ticket promedio",
          value: CurrencyFormatter.format(stats.averageTicket),
        ),
        _MiniInsightMetric(
          icon: Icons.build_circle_outlined,
          label: "Servicios pendientes",
          value: stats.pendingServices.toString(),
        ),
        _MiniInsightMetric(
          icon: Icons.warning_amber_rounded,
          label: "Stock bajo",
          value: stats.lowStockProducts.toString(),
        ),
      ],
    );
    final children = [
      _InsightPanel(
        icon: Icons.badge_outlined,
        title: "Rendimiento por empleado",
        subtitle: stats.periodLabel,
        child: stats.employeePerformance.isEmpty
            ? const _EmptyInsight("Todavia no hay ventas por empleado.")
            : Column(
                children: stats.employeePerformance
                    .take(5)
                    .map(
                      (item) => _EmployeePerformanceRow(
                        employee: item,
                        compact: compact,
                      ),
                    )
                    .toList(),
              ),
      ),
      _InsightPanel(
        icon: Icons.store_mall_directory_outlined,
        title: "Sucursales",
        subtitle: "Ventas y utilidad del mes",
        child: stats.branchPerformance.isEmpty
            ? const _EmptyInsight("Todavia no hay ventas por sucursal.")
            : Column(
                children: stats.branchPerformance
                    .map((item) => _BranchPerformanceRow(branch: item))
                    .toList(),
              ),
      ),
    ];

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          metrics,
          const SizedBox(height: 10),
          ...children.expand(
            (child) => [
              child,
              const SizedBox(height: 10),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        Align(alignment: Alignment.centerLeft, child: metrics),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: children[0]),
            const SizedBox(width: 18),
            Expanded(child: children[1]),
          ],
        ),
      ],
    );
  }
}

class _MiniInsightMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniInsightMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 170),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 19),
          const SizedBox(width: 8),
          SizedBox(
            width: 128,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _InsightPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _EmployeePerformanceRow extends StatelessWidget {
  final EmployeePerformance employee;
  final bool compact;

  const _EmployeePerformanceRow({
    required this.employee,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return _InsightRow(
      title: employee.name,
      subtitle:
          "${employee.branch.isEmpty ? 'Sin sucursal' : employee.branch} - ${employee.salesCount} ventas",
      primaryValue: CurrencyFormatter.format(employee.salesTotal),
      secondaryValue: "Utilidad ${CurrencyFormatter.format(employee.profitTotal)}",
      compact: compact,
    );
  }
}

class _BranchPerformanceRow extends StatelessWidget {
  final BranchPerformance branch;

  const _BranchPerformanceRow({required this.branch});

  @override
  Widget build(BuildContext context) {
    return _InsightRow(
      title: branch.branch,
      subtitle: "${branch.salesCount} ventas registradas",
      primaryValue: CurrencyFormatter.format(branch.salesTotal),
      secondaryValue: "Utilidad ${CurrencyFormatter.format(branch.profitTotal)}",
      compact: false,
    );
  }
}

class _InsightRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String primaryValue;
  final String secondaryValue;
  final bool compact;

  const _InsightRow({
    required this.title,
    required this.subtitle,
    required this.primaryValue,
    required this.secondaryValue,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final content = [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            primaryValue,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            secondaryValue,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: content),
    );
  }
}

class _EmptyInsight extends StatelessWidget {
  final String message;

  const _EmptyInsight(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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
