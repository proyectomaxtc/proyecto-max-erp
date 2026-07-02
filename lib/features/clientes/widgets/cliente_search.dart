import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/search/app_search_bar.dart';

import '../providers/cliente_provider.dart';

class ClienteSearch extends ConsumerStatefulWidget {
  const ClienteSearch({
    super.key,
  });

  @override
  ConsumerState<ClienteSearch> createState() =>
      _ClienteSearchState();
}

class _ClienteSearchState
    extends ConsumerState<ClienteSearch> {

  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return SizedBox(

      width: 320,

      child:      AppSearchBar(
        controller: controller,
        hint: "Buscar cliente...",
        onChanged: (texto) {
          ref
              .read(clienteProvider.notifier)
              .buscar(texto);
        },
      ),
    );
  }
}