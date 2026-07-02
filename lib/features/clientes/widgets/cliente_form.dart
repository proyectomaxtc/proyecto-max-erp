import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../models/cliente_model.dart';
import '../providers/cliente_provider.dart';

class ClienteForm extends ConsumerStatefulWidget {
  final ClienteModel? cliente;

  const ClienteForm({
    super.key,
    this.cliente,
  });

  @override
  ConsumerState<ClienteForm> createState() =>
      _ClienteFormState();
}

class _ClienteFormState
    extends ConsumerState<ClienteForm> {

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nombreController;
  late final TextEditingController apellidoController;
  late final TextEditingController telefonoController;
  late final TextEditingController emailController;
  late final TextEditingController direccionController;
  late final TextEditingController ciudadController;
  late final TextEditingController provinciaController;
  late final TextEditingController cuitController;
  late final TextEditingController observacionesController;

  bool activo = true;

  @override
  void initState() {
    super.initState();

    final cliente = widget.cliente;

    nombreController = TextEditingController(
      text: cliente?.nombre ?? '',
    );

    apellidoController = TextEditingController(
      text: cliente?.apellido ?? '',
    );

    telefonoController = TextEditingController(
      text: cliente?.telefono ?? '',
    );

    emailController = TextEditingController(
      text: cliente?.email ?? '',
    );

    direccionController = TextEditingController(
      text: cliente?.direccion ?? '',
    );

    ciudadController = TextEditingController(
      text: cliente?.ciudad ?? '',
    );

    provinciaController = TextEditingController(
      text: cliente?.provincia ?? '',
    );

    cuitController = TextEditingController(
      text: cliente?.cuit ?? '',
    );

    observacionesController =
        TextEditingController(
      text: cliente?.observaciones ?? '',
    );

    activo = cliente?.activo ?? true;
  }

  @override
  void dispose() {
    nombreController.dispose();
    apellidoController.dispose();
    telefonoController.dispose();
    emailController.dispose();
    direccionController.dispose();
    ciudadController.dispose();
    provinciaController.dispose();
    cuitController.dispose();
    observacionesController.dispose();

    super.dispose();
  }

  InputDecoration decoration(
    String label,
  ) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
      ),
    );
  }

  Future<void> guardarCliente() async {

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ahora = DateTime.now();

    final cliente = ClienteModel(

      id: widget.cliente?.id ??
          ahora.millisecondsSinceEpoch
              .toString(),

      nombre: nombreController.text.trim(),

      apellido:
          apellidoController.text.trim(),

      telefono:
          telefonoController.text.trim(),

      email: emailController.text.trim(),

      direccion:
          direccionController.text.trim(),

      ciudad:
          ciudadController.text.trim(),

      provincia:
          provinciaController.text.trim(),

      cuit:
          cuitController.text.trim(),

      observaciones:
          observacionesController.text.trim(),

      activo: activo,

      creado:
          widget.cliente?.creado ??
              ahora,

      actualizado: ahora,
    );

    if (widget.cliente == null) {

      await ref
          .read(clienteProvider.notifier)
          .agregarCliente(cliente);

    } else {

      await ref
          .read(clienteProvider.notifier)
          .actualizarCliente(cliente);

    }

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(

        backgroundColor:
            AppColors.success,

        content: Text(

          widget.cliente == null
              ? 'Cliente agregado correctamente'
              : 'Cliente actualizado correctamente',

        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Form(

      key: _formKey,

      child: SingleChildScrollView(

        child: Column(

          children: [

            TextFormField(

              controller:
                  nombreController,

              decoration:
                  decoration("Nombre"),

              validator: (v) {

                if (v == null ||
                    v.trim().isEmpty) {

                  return "Ingrese un nombre";

                }

                return null;

              },

            ),

            const SizedBox(height: 18),

            TextFormField(

              controller:
                  apellidoController,

              decoration:
                  decoration("Apellido"),

            ),

            const SizedBox(height: 18),
                        TextFormField(
              controller: telefonoController,
              decoration: decoration("Teléfono"),
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 18),

            TextFormField(
              controller: emailController,
              decoration: decoration("Email"),
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 18),

            TextFormField(
              controller: direccionController,
              decoration: decoration("Dirección"),
            ),

            const SizedBox(height: 18),

            Row(
              children: [

                Expanded(
                  child: TextFormField(
                    controller: ciudadController,
                    decoration: decoration("Ciudad"),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: TextFormField(
                    controller: provinciaController,
                    decoration: decoration("Provincia"),
                  ),
                ),

              ],
            ),

            const SizedBox(height: 18),

            TextFormField(
              controller: cuitController,
              decoration: decoration("CUIT"),
            ),

            const SizedBox(height: 18),

            TextFormField(
              controller: observacionesController,
              maxLines: 4,
              decoration: decoration("Observaciones"),
            ),

            const SizedBox(height: 24),

            SwitchListTile(
              value: activo,
              title: const Text(
                "Cliente activo",
                style: TextStyle(
                  color: AppColors.textPrimary,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  activo = value;
                });
              },
            ),

            const SizedBox(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [

                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                  label: const Text("Cancelar"),
                ),

                const SizedBox(width: 16),

                FilledButton.icon(
                  onPressed: guardarCliente,
                  icon: const Icon(Icons.save),
                  label: Text(
                    widget.cliente == null
                        ? "Guardar Cliente"
                        : "Actualizar Cliente",
                  ),
                ),

              ],
            ),

          ],
        ),
      ),
    );
  }
}