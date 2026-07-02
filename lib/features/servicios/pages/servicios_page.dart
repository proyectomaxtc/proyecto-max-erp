import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/layout/main_layout.dart';
import '../../../shared/widgets/cards/kpi_card.dart';
import '../../clientes/providers/cliente_provider.dart';
import '../providers/servicio_provider.dart';
import '../widgets/servicios_header.dart';
import '../widgets/servicios_table.dart';

class ServiciosPage extends ConsumerStatefulWidget {
  const ServiciosPage({super.key});

  @override
  ConsumerState<ServiciosPage> createState() => _ServiciosPageState();
}

class _ServiciosPageState extends ConsumerState<ServiciosPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(servicioProvider.notifier).cargarServicios();
      ref.read(clienteProvider.notifier).cargarClientes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(servicioProvider);
    final compact = MediaQuery.sizeOf(context).width < 760;
    final cards = [
      KpiCard(
        title: "Servicios abiertos",
        value: state.abiertos.toString(),
        icon: Icons.build_circle_outlined,
        color: AppColors.info,
        subtitle: "Trabajos en curso",
      ),
      KpiCard(
        title: "Pendientes",
        value: state.pendientes.toString(),
        icon: Icons.pending_actions_outlined,
        color: AppColors.warning,
        subtitle: "A revisar",
      ),
      KpiCard(
        title: "Listos",
        value: state.listos.toString(),
        icon: Icons.task_alt_outlined,
        color: AppColors.success,
        subtitle: "Para entregar",
      ),
      KpiCard(
        title: "Facturacion",
        value: CurrencyFormatter.format(state.facturacion),
        icon: Icons.receipt_long_outlined,
        color: AppColors.primary,
        subtitle: "Servicios cobrados",
      ),
    ];

    return MainLayout(
      title: "Servicios",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact)
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cards.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return SizedBox(width: 148, child: cards[index]);
                },
              ),
            )
          else
            SizedBox(
              height: 148,
              child: Row(
                children: [
                  for (var index = 0; index < cards.length; index++) ...[
                    Expanded(child: cards[index]),
                    if (index < cards.length - 1) const SizedBox(width: 16),
                  ],
                ],
              ),
            ),
          SizedBox(height: compact ? 10 : 20),
          const ServiciosHeader(),
          SizedBox(height: compact ? 10 : 20),
          const Expanded(child: ServiciosTable()),
        ],
      ),
    );
  }
}
