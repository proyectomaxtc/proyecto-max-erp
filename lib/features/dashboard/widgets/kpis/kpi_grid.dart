import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/cards/kpi_card.dart';
import '../../models/dashboard_stats.dart';
import '../../../../core/utils/currency_formatter.dart';

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
          value: CurrencyFormatter.format(stats.cash),
          icon: Icons.account_balance_wallet,
          color: AppColors.cash,
          variation: "+8%",
        ),

        KpiCard(
          title: "Ventas",
         value: CurrencyFormatter.format(stats.sales),
          icon: Icons.point_of_sale,
          color: AppColors.sales,
          variation: "+18%",
        ),

        KpiCard(
          title: "Compras",
          value: CurrencyFormatter.format(stats.purchases),
          icon: Icons.shopping_cart,
          color: AppColors.purchases,
          variation: "-4%",
        ),

        KpiCard(
          title: "Utilidad",
         value: CurrencyFormatter.format(stats.profit),
          icon: Icons.trending_up,
          color: AppColors.success,
          variation: "+11%",
        ),
      ],
    );
  }
}