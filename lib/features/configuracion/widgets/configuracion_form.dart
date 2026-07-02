import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/configuracion_provider.dart';

class ConfiguracionForm extends ConsumerStatefulWidget {
  const ConfiguracionForm({super.key});

  @override
  ConsumerState<ConfiguracionForm> createState() => _ConfiguracionFormState();
}

class _ConfiguracionFormState extends ConsumerState<ConfiguracionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController empresaController;
  late final TextEditingController sistemaController;
  late final TextEditingController sloganController;
  late final TextEditingController ownerPinController;

  @override
  void initState() {
    super.initState();
    final config = ref.read(configuracionProvider);
    empresaController = TextEditingController(text: config.empresa);
    sistemaController = TextEditingController(text: config.sistema);
    sloganController = TextEditingController(text: config.slogan);
    ownerPinController = TextEditingController(text: config.ownerPin);
  }

  @override
  void dispose() {
    empresaController.dispose();
    sistemaController.dispose();
    sloganController.dispose();
    ownerPinController.dispose();
    super.dispose();
  }

  InputDecoration decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Future<void> guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final config = ref.read(configuracionProvider);

    await ref
        .read(configuracionProvider.notifier)
        .guardarConfiguracion(
          config.copyWith(
            empresa: empresaController.text.trim(),
            sistema: sistemaController.text.trim(),
            slogan: sloganController.text.trim(),
            ownerPin: ownerPinController.text.trim(),
          ),
        );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Configuracion guardada correctamente'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: empresaController,
                  decoration: decoration("Empresa"),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? "Ingrese empresa"
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: sistemaController,
                  decoration: decoration("Sistema"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: sloganController,
            decoration: decoration("Slogan"),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: ownerPinController,
            obscureText: true,
            decoration: decoration("Clave del propietario"),
            validator: (value) {
              if (value == null || value.trim().length < 4) {
                return "Use al menos 4 caracteres";
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: guardar,
              icon: const Icon(Icons.save_outlined),
              label: const Text("Guardar Configuracion"),
            ),
          ),
        ],
      ),
    );
  }
}
