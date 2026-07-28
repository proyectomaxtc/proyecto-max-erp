import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/search/app_search_bar.dart';
import '../providers/producto_provider.dart';

class ProductoSearch extends ConsumerStatefulWidget {
  const ProductoSearch({
    super.key,
  });

  @override
  ConsumerState<ProductoSearch> createState() => _ProductoSearchState();
}

class _ProductoSearchState extends ConsumerState<ProductoSearch> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busqueda = ref.watch(
      productoProvider.select((state) => state.busqueda),
    );

    if (_controller.text != busqueda) {
      _controller.value = TextEditingValue(
        text: busqueda,
        selection: TextSelection.collapsed(offset: busqueda.length),
      );
    }

    return SizedBox(
      width: 320,
      child: AppSearchBar(
        controller: _controller,
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
