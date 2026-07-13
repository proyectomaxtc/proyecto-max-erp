import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class OwnerAuthorizationDialog extends ConsumerStatefulWidget {
  final String reason;

  const OwnerAuthorizationDialog({super.key, required this.reason});

  static Future<bool> request(
    BuildContext context, {
    required String reason,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => OwnerAuthorizationDialog(reason: reason),
        ) ??
        false;
  }

  @override
  ConsumerState<OwnerAuthorizationDialog> createState() =>
      _OwnerAuthorizationDialogState();
}

class _OwnerAuthorizationDialogState
    extends ConsumerState<OwnerAuthorizationDialog> {
  final claveController = TextEditingController();
  bool error = false;

  @override
  void dispose() {
    claveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Autorizacion del propietario"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.reason),
          const SizedBox(height: 16),
          TextField(
            controller: claveController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: "Clave del propietario",
              errorText: error ? "Clave incorrecta" : null,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Ingrese el codigo de un usuario con rol Propietario.",
            style: TextStyle(color: AppColors.textDisabled, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancelar"),
        ),
        FilledButton(
          onPressed: () {
            final usuarios = ref.read(authProvider).usuarios;
            final codigo = claveController.text.trim();
            final autorizado = usuarios.any(
              (usuario) =>
                  usuario.activo &&
                  usuario.esPropietario &&
                  usuario.codigo == codigo,
            );

            if (autorizado) {
              Navigator.pop(context, true);
              return;
            }

            setState(() {
              error = true;
            });
          },
          child: const Text("Autorizar"),
        ),
      ],
    );
  }
}
