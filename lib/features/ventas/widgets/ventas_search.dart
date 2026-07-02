import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/search/app_search_bar.dart';
import '../providers/venta_provider.dart';

class VentasSearch extends ConsumerWidget {
  const VentasSearch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppSearchBar(
      hint: "Buscar venta, cliente o medio de pago...",
      onChanged: (texto) {
        ref.read(ventaProvider.notifier).buscar(texto);
      },
    );
  }
}
