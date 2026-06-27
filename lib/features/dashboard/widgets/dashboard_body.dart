import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/cards/kpi_card.dart';
import '../../../../shared/widgets/dashboard/dashboard_header.dart';
import '../providers/dashboard_provider.dart';

class DashboardBody extends ConsumerWidget {
  const DashboardBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);

    return dashboard.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),

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

              const DashboardHeader(
                title: "Buenos días, Cristian",
                subtitle: "Casa Central • Tucumán Cerraduras",
              ),

              const SizedBox(height: 30),

              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.35,
                children: [

                  KpiCard(
                    title: "Caja",
                    value: "\$${data.cash.toStringAsFixed(0)}",
                    icon: Icons.account_balance_wallet,
                    color: AppColors.cash,
                    variation: "+8%",
                  ),

                  KpiCard(
                    title: "Ventas",
                    value: "\$${data.sales.toStringAsFixed(0)}",
                    icon: Icons.point_of_sale,
                    color: AppColors.sales,
                    variation: "+18%",
                  ),

                  KpiCard(
                    title: "Compras",
                    value: "\$${data.purchases.toStringAsFixed(0)}",
                    icon: Icons.shopping_cart,
                    color: AppColors.purchases,
                    variation: "-4%",
                  ),

                  KpiCard(
                    title: "Utilidad",
                    value: "\$${data.profit.toStringAsFixed(0)}",
                    icon: Icons.trending_up,
                    color: AppColors.success,
                    variation: "+11%",
                  ),
                ],
              ),

              const SizedBox(height: 35),

              const Text(
                "Acciones rápidas",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Wrap(
                spacing: 15,
                runSpacing: 15,
                children: [

                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    label: const Text("Nueva Venta"),
                  ),

                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.person_add),
                    label: const Text("Nuevo Cliente"),
                  ),

                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.point_of_sale),
                    label: const Text("Abrir Caja"),
                  ),

                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.inventory),
                    label: const Text("Nuevo Producto"),
                  ),

                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.key),
                    label: const Text("Nuevo Servicio"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}