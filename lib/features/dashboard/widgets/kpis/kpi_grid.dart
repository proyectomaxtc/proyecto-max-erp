import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/cards/kpi_card.dart';
import '../../models/dashboard_stats.dart';

class KpiGrid extends StatelessWidget {
  final DashboardStats stats;

  const KpiGrid({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: 1.18,
      children: [
        KpiCard(
          title: "Caja",
          value: "\$${stats.cash.toStringAsFixed(0)}",
          icon: Icons.account_balance_wallet,
          color: AppColors.cash,
          variation: "+8%",
        ),

        KpiCard(
          title: "Ventas",
          value: "\$${stats.sales.toStringAsFixed(0)}",
          icon: Icons.point_of_sale,
          color: AppColors.sales,
          variation: "+18%",
        ),

        KpiCard(
          title: "Compras",
          value: "\$${stats.purchases.toStringAsFixed(0)}",
          icon: Icons.shopping_cart,
          color: AppColors.purchases,
          variation: "-4%",
        ),

        KpiCard(
          title: "Utilidad",
          value: "\$${stats.profit.toStringAsFixed(0)}",
          icon: Icons.trending_up,
          color: AppColors.success,
          variation: "+11%",
        ),
      ],
    );
  }
}