import 'package:flutter/material.dart';

import '../../../../shared/widgets/tables/app_table.dart';

class ClienteTable extends StatelessWidget {
  const ClienteTable({super.key});

  @override
  Widget build(BuildContext context) {
    return AppTable(
      columns: const [

        DataColumn(
          label: Text("Nombre"),
        ),

        DataColumn(
          label: Text("Teléfono"),
        ),

        DataColumn(
          label: Text("Ciudad"),
        ),

        DataColumn(
          label: Text("Estado"),
        ),

        DataColumn(
          label: Text("Acciones"),
        ),
      ],

      rows: [

        DataRow(
          cells: [

            const DataCell(
              Text("Juan Pérez"),
            ),

            const DataCell(
              Text("3815551234"),
            ),

            const DataCell(
              Text("San Miguel"),
            ),

            const DataCell(
              Text("Activo"),
            ),

            DataCell(
              Row(
                children: [

                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.visibility),
                  ),

                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.edit),
                  ),

                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.delete),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}