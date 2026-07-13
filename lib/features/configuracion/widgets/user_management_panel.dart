import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/branches.dart';
import '../../auth/models/app_user_model.dart';
import '../../auth/providers/auth_provider.dart';

class UserManagementPanel extends ConsumerStatefulWidget {
  const UserManagementPanel({super.key});

  @override
  ConsumerState<UserManagementPanel> createState() =>
      _UserManagementPanelState();
}

class _UserManagementPanelState extends ConsumerState<UserManagementPanel> {
  final nombreController = TextEditingController();
  final codigoController = TextEditingController();
  final emailController = TextEditingController();
  final authIdController = TextEditingController();
  String rol = 'Empleado';
  String sucursal = Branches.alberdi;
  String? editandoId;
  bool activo = true;

  bool get editando => editandoId != null;

  @override
  void dispose() {
    nombreController.dispose();
    codigoController.dispose();
    emailController.dispose();
    authIdController.dispose();
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

  Future<void> guardarUsuario() async {
    final nombre = nombreController.text.trim();
    final codigo = codigoController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final authId = authIdController.text.trim();

    if (nombre.isEmpty || codigo.isEmpty) {
      _mensaje('Complete nombre y codigo', AppColors.warning);
      return;
    }

    if (editando) {
      final usuario = ref
          .read(authProvider)
          .usuarios
          .firstWhere((usuario) => usuario.id == editandoId);

      await ref
          .read(authProvider.notifier)
          .actualizarUsuario(
            usuario.copyWith(
              nombre: nombre,
              codigo: codigo,
              email: email,
              authId: authId,
              rol: rol,
              sucursal: sucursal,
              activo: activo,
            ),
          );
      _mensaje('Usuario actualizado correctamente', AppColors.success);
    } else {
      final ahora = DateTime.now();

      await ref
          .read(authProvider.notifier)
          .agregarUsuario(
            AppUserModel(
              id: ahora.microsecondsSinceEpoch.toString(),
              nombre: nombre,
              codigo: codigo,
              email: email,
              authId: authId,
              rol: rol,
              sucursal: sucursal,
              activo: true,
              creado: ahora,
            ),
          );
      _mensaje('Usuario agregado correctamente', AppColors.success);
    }

    limpiarFormulario();
  }

  void editarUsuario(AppUserModel usuario) {
    setState(() {
      editandoId = usuario.id;
      nombreController.text = usuario.nombre;
      codigoController.text = usuario.codigo;
      emailController.text = usuario.email;
      authIdController.text = usuario.authId;
      rol = usuario.rol;
      sucursal = usuario.sucursal;
      activo = usuario.activo;
    });
  }

  void limpiarFormulario() {
    setState(() {
      editandoId = null;
      nombreController.clear();
      codigoController.clear();
      emailController.clear();
      authIdController.clear();
      rol = 'Empleado';
      sucursal = Branches.alberdi;
      activo = true;
    });
  }

  void _mensaje(String texto, Color color) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(backgroundColor: color, content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final usuarios = auth.usuarios;
    final compact = MediaQuery.sizeOf(context).width < 760;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Usuarios",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _UsuarioForm(
          compact: compact,
          nombreController: nombreController,
          codigoController: codigoController,
          emailController: emailController,
          authIdController: authIdController,
          rol: rol,
          sucursal: sucursal,
          activo: activo,
          editando: editando,
          decoration: decoration,
          onRolChanged: (value) => setState(() => rol = value ?? rol),
          onSucursalChanged: (value) {
            setState(() => sucursal = value ?? sucursal);
          },
          onActivoChanged: editando
              ? (value) => setState(() => activo = value)
              : null,
          onGuardar: guardarUsuario,
          onCancelar: limpiarFormulario,
        ),
        if (auth.error != null) ...[
          const SizedBox(height: 12),
          Text(
            auth.error!,
            style: const TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 18),
        ...usuarios.map(
          (usuario) => compact
              ? _UsuarioCard(
                  usuario: usuario,
                  codigoOculto: _codigoOculto(usuario),
                  onEditar: () => editarUsuario(usuario),
                )
              : ListTile(
                  leading: Icon(
                    usuario.esPropietario
                        ? Icons.admin_panel_settings
                        : Icons.badge_outlined,
                    color: usuario.esPropietario
                        ? AppColors.primary
                        : AppColors.info,
                  ),
                  title: Text(usuario.nombre),
                  subtitle: Text(
                    '${usuario.rol} - ${usuario.sucursal} - Codigo: ${_codigoOculto(usuario)}${usuario.email.isEmpty ? '' : ' - ${usuario.email}'}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        backgroundColor: usuario.activo
                            ? AppColors.success
                            : AppColors.error,
                        label: Text(
                          usuario.activo ? "Activo" : "Inactivo",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: "Editar usuario",
                        onPressed: () => editarUsuario(usuario),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  String _codigoOculto(AppUserModel usuario) {
    if (usuario.codigo.isEmpty) {
      return '-';
    }

    return '*' * usuario.codigo.length;
  }
}

class _UsuarioForm extends StatelessWidget {
  final bool compact;
  final TextEditingController nombreController;
  final TextEditingController codigoController;
  final TextEditingController emailController;
  final TextEditingController authIdController;
  final String rol;
  final String sucursal;
  final bool activo;
  final bool editando;
  final InputDecoration Function(String label) decoration;
  final ValueChanged<String?> onRolChanged;
  final ValueChanged<String?> onSucursalChanged;
  final ValueChanged<bool>? onActivoChanged;
  final VoidCallback onGuardar;
  final VoidCallback onCancelar;

  const _UsuarioForm({
    required this.compact,
    required this.nombreController,
    required this.codigoController,
    required this.emailController,
    required this.authIdController,
    required this.rol,
    required this.sucursal,
    required this.activo,
    required this.editando,
    required this.decoration,
    required this.onRolChanged,
    required this.onSucursalChanged,
    required this.onActivoChanged,
    required this.onGuardar,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    final fieldWidth = compact ? double.infinity : null;
    final children = [
      _SizedField(
        width: fieldWidth ?? 240,
        child: TextField(
          controller: nombreController,
          decoration: decoration("Nombre"),
        ),
      ),
      _SizedField(
        width: fieldWidth ?? 160,
        child: TextField(
          controller: codigoController,
          obscureText: true,
          decoration: decoration("Codigo"),
        ),
      ),
      _SizedField(
        width: fieldWidth ?? 260,
        child: TextField(
          controller: emailController,
          decoration: decoration("Email Supabase"),
        ),
      ),
      _SizedField(
        width: fieldWidth ?? 270,
        child: TextField(
          controller: authIdController,
          decoration: decoration("Auth ID Supabase"),
        ),
      ),
      _SizedField(
        width: fieldWidth ?? 180,
        child: DropdownButtonFormField<String>(
          initialValue: rol,
          dropdownColor: AppColors.surface,
          decoration: decoration("Rol"),
          items: const [
            DropdownMenuItem(value: 'Empleado', child: Text('Empleado')),
            DropdownMenuItem(value: 'Propietario', child: Text('Propietario')),
          ],
          onChanged: onRolChanged,
        ),
      ),
      _SizedField(
        width: fieldWidth ?? 210,
        child: DropdownButtonFormField<String>(
          initialValue: sucursal,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          decoration: decoration("Sucursal"),
          items: Branches.values
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(value, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onSucursalChanged,
        ),
      ),
      _SizedField(
        width: fieldWidth ?? 120,
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: activo,
          title: const Text("Activo"),
          onChanged: onActivoChanged,
        ),
      ),
    ];

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final child in children) ...[child, const SizedBox(height: 10)],
          FilledButton.icon(
            onPressed: onGuardar,
            icon: Icon(editando ? Icons.save_outlined : Icons.person_add),
            label: Text(editando ? "Guardar cambios" : "Agregar usuario"),
          ),
          if (editando) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onCancelar,
              icon: const Icon(Icons.close),
              label: const Text("Cancelar"),
            ),
          ],
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...children,
        FilledButton.icon(
          onPressed: onGuardar,
          icon: Icon(editando ? Icons.save_outlined : Icons.person_add),
          label: Text(editando ? "Guardar" : "Agregar"),
        ),
        if (editando)
          OutlinedButton.icon(
            onPressed: onCancelar,
            icon: const Icon(Icons.close),
            label: const Text("Cancelar"),
          ),
      ],
    );
  }
}

class _SizedField extends StatelessWidget {
  final double width;
  final Widget child;

  const _SizedField({required this.width, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: child);
  }
}

class _UsuarioCard extends StatelessWidget {
  final AppUserModel usuario;
  final String codigoOculto;
  final VoidCallback onEditar;

  const _UsuarioCard({
    required this.usuario,
    required this.codigoOculto,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                usuario.esPropietario
                    ? Icons.admin_panel_settings
                    : Icons.badge_outlined,
                color: usuario.esPropietario
                    ? AppColors.primary
                    : AppColors.info,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  usuario.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Chip(
                backgroundColor: usuario.activo
                    ? AppColors.success
                    : AppColors.error,
                label: Text(
                  usuario.activo ? "Activo" : "Inactivo",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${usuario.rol} - ${usuario.sucursal}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Codigo: $codigoOculto${usuario.email.isEmpty ? '' : ' - ${usuario.email}'}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textDisabled),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onEditar,
              icon: const Icon(Icons.edit_outlined),
              label: const Text("Editar usuario"),
            ),
          ),
        ],
      ),
    );
  }
}
