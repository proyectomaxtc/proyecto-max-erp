import 'package:flutter/material.dart';

import '../../../../shared/widgets/search/app_search_bar.dart';

class ClienteSearch extends StatelessWidget {
  const ClienteSearch({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 340,
      child: AppSearchBar(
        hint: "Buscar cliente...",
      ),
    );
  }
}