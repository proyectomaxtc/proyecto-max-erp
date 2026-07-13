import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/dialogs/app_dialog.dart';
import '../../../shared/widgets/search/app_search_bar.dart';
import '../providers/servicio_provider.dart';
import 'servicio_form.dart';

class ServiciosHeader extends ConsumerWidget {
  const ServiciosHeader({super.key});

  static const filtros = [
    'Todos',
    'Pendiente',
    'En proceso',
    'Listo',
    'Entregado',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtroActivo = ref.watch(servicioProvider).filtroEstado;
    final compact = MediaQuery.sizeOf(context).width < 760;
    final chips = filtros.map((filtro) {
      final selected = filtro == filtroActivo;
      return ChoiceChip(
        label: Text(filtro),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.card,
        labelStyle: TextStyle(
          color: selected ? Colors.black : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
        onSelected: (_) {
          ref.read(servicioProvider.notifier).cambiarFiltro(filtro);
        },
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Search(ref),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: chips),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => _abrirServicio(context),
                  icon: const Icon(Icons.add),
                  label: const Text("Nuevo Servicio"),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 2, child: _Search(ref)),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Wrap(spacing: 8, runSpacing: 8, children: chips),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: () => _abrirServicio(context),
                  icon: const Icon(Icons.add),
                  label: const Text("Nuevo Servicio"),
                ),
              ],
            ),
    );
  }

  void _abrirServicio(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const AppDialog(
          title: "Nuevo Servicio",
          maxWidth: 920,
          maxHeight: 760,
          child: ServicioForm(),
        );
      },
    );
  }
}

class _Search extends StatelessWidget {
  final WidgetRef ref;

  const _Search(this.ref);

  @override
  Widget build(BuildContext context) {
    return AppSearchBar(
      hint: "Buscar servicio, cliente o tecnico...",
      onChanged: (texto) {
        ref.read(servicioProvider.notifier).buscar(texto);
      },
    );
  }
}
