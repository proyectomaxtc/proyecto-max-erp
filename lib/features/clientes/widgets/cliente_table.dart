import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/dialogs/app_dialog.dart';
import '../../../../shared/widgets/tables/app_data_table.dart';

import '../providers/cliente_provider.dart';
import 'cliente_form.dart';

class ClienteTable extends ConsumerWidget {
  const ClienteTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clienteProvider);

    return AppDataTable(
      columns: const [
        DataColumn(label: Text("Nombre")),
        DataColumn(label: Text("Teléfono")),
        DataColumn(label: Text("Ciudad")),
        DataColumn(label: Text("Estado")),
        DataColumn(label: Text("Acciones")),
      ],
      rows: state.clientesFiltrados.map((cliente) {
        return DataRow(
          cells: [
            DataCell(
              Text(
                "${cliente.nombre} ${cliente.apellido}",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataCell(Text(cliente.telefono)),
            DataCell(Text(cliente.ciudad)),
            DataCell(
              Chip(
                backgroundColor: cliente.activo
                    ? AppColors.success
                    : AppColors.error,
                label: Text(
                  cliente.activo ? "ACTIVO" : "INACTIVO",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: "Ver",
                    child: IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) {
                            return AppDialog(
                              title: "Detalle Cliente",
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${cliente.nombre} ${cliente.apellido}",
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _DetailRow("Telefono", cliente.telefono),
                                  _DetailRow("Email", cliente.email),
                                  _DetailRow("Direccion", cliente.direccion),
                                  _DetailRow("Ciudad", cliente.ciudad),
                                  _DetailRow("Provincia", cliente.provincia),
                                  _DetailRow("CUIT", cliente.cuit),
                                  _DetailRow(
                                    "Observaciones",
                                    cliente.observaciones,
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.visibility_outlined),
                    ),
                  ),

                  Tooltip(
                    message: "Editar",
                    child: IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) {
                            return AppDialog(
                              title: "Editar Cliente",
                              child: ClienteForm(cliente: cliente),
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ),

                  Tooltip(
                    message: "Eliminar",
                    child: IconButton(
                      onPressed: () async {
                        final eliminar = await showDialog<bool>(
                          context: context,
                          builder: (_) {
                            return AlertDialog(
                              title: const Text("Eliminar Cliente"),
                              content: Text(
                                "¿Desea eliminar a ${cliente.nombre} ${cliente.apellido}?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, false);
                                  },
                                  child: const Text("Cancelar"),
                                ),

                                FilledButton(
                                  onPressed: () {
                                    Navigator.pop(context, true);
                                  },
                                  child: const Text("Eliminar"),
                                ),
                              ],
                            );
                          },
                        );

                        if (eliminar == true) {
                          await ref
                              .read(clienteProvider.notifier)
                              .eliminarCliente(cliente.id);
                        }
                      },
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? "-" : value,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
