import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/search/app_search_bar.dart';
import '../providers/producto_provider.dart';

class ProductoSearch extends ConsumerWidget {
  const ProductoSearch({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    return SizedBox(
      width: 320,
      child: AppSearchBar(
        hint: "Buscar producto...",
        onChanged: (texto) {
          ref
              .read(productoProvider.notifier)
              .buscar(texto);
        },
      ),
    );
  }
}