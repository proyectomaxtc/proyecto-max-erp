import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/dialogs/app_dialog.dart';

import 'cliente_form.dart';
import 'cliente_search.dart';

class ClienteHeader extends StatelessWidget {
  const ClienteHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    return Row(

      children: [

        const Expanded(

          child: Column(

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Text(

                "Clientes",

                style: TextStyle(

                  fontSize: 30,

                  fontWeight: FontWeight.bold,

                  color: AppColors.textPrimary,

                ),

              ),

              SizedBox(height: 6),

              Text(

                "Administración de clientes",

                style: TextStyle(

                  color:
                      AppColors.textSecondary,

                ),

              ),

            ],

          ),

        ),

        const ClienteSearch(),

        const SizedBox(width: 20),

        FilledButton.icon(

          icon: const Icon(Icons.add),

          label:
              const Text("Nuevo Cliente"),

          onPressed: () {

            showDialog(

              context: context,

              barrierDismissible: false,
                            builder: (_) {

                return const AppDialog(

                  title: "Nuevo Cliente",

                  child: ClienteForm(),

                );

              },

            );

          },

        ),

      ],

    );

  }

}