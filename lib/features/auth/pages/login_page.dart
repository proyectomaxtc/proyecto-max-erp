import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/company.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final nombreController = TextEditingController(text: 'Propietario');
  final codigoController = TextEditingController(text: '1234');
  bool mostrarCodigo = false;
  bool recordarUsuario = false;

  static const _recordarKey = 'login_recordar_usuario';
  static const _usuarioKey = 'login_usuario';

  @override
  void initState() {
    super.initState();
    _cargarUsuarioRecordado();
  }

  @override
  void dispose() {
    nombreController.dispose();
    codigoController.dispose();
    super.dispose();
  }

  Future<void> ingresar() async {
    final ok = await ref
        .read(authProvider.notifier)
        .login(nombre: nombreController.text, codigo: codigoController.text);

    if (!mounted) return;

    if (ok) {
      await _guardarUsuarioRecordado();
      if (!mounted) return;

      final auth = ref.read(authProvider);
      context.go(auth.esPropietario ? AppRoutes.dashboard : AppRoutes.ventas);
    }
  }

  Future<void> _cargarUsuarioRecordado() async {
    final prefs = await SharedPreferences.getInstance();
    final debeRecordar = prefs.getBool(_recordarKey) ?? false;
    if (!mounted || !debeRecordar) return;

    setState(() {
      recordarUsuario = true;
      nombreController.text = prefs.getString(_usuarioKey) ?? '';
    });
  }

  Future<void> _guardarUsuarioRecordado() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_recordarKey, recordarUsuario);

    if (recordarUsuario) {
      await prefs.setString(_usuarioKey, nombreController.text.trim());
      return;
    }

    await prefs.remove(_usuarioKey);
  }

  InputDecoration decoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
    );
  }

  Widget _brandPanel({required bool compact}) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: compact ? 0 : 520),
      padding: EdgeInsets.all(compact ? 22 : 36),
      color: const Color(0xFF151515),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            Company.logo,
            width: compact ? 62 : 92,
            height: compact ? 62 : 92,
          ),
          SizedBox(height: compact ? 18 : 28),
          Text(
            Company.name,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: compact ? 26 : 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Company.system,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            Company.slogan,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          SizedBox(height: compact ? 24 : 70),
          if (compact)
            const Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _AccessPill(
                  icon: Icons.point_of_sale_rounded,
                  text: "Empleado",
                ),
                _AccessPill(
                  icon: Icons.admin_panel_settings_outlined,
                  text: "Propietario",
                ),
              ],
            )
          else ...[
            const _AccessHint(
              icon: Icons.point_of_sale_rounded,
              title: "Empleado",
              text: "Ingresa directo a ventas y operaciones.",
            ),
            const SizedBox(height: 14),
            const _AccessHint(
              icon: Icons.admin_panel_settings_outlined,
              title: "Propietario",
              text: "Acceso completo a caja, reportes y usuarios.",
            ),
          ],
        ],
      ),
    );
  }

  Widget _loginPanel({required bool compact, required String? error}) {
    return Padding(
      padding: EdgeInsets.all(compact ? 22 : 38),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ingreso al sistema",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: compact ? 24 : 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Use su usuario local o email de Supabase para operar.",
            style: TextStyle(color: AppColors.textSecondary),
          ),
          SizedBox(height: compact ? 22 : 28),
          TextField(
            controller: nombreController,
            textInputAction: TextInputAction.next,
            decoration: decoration(
              label: "Usuario o email",
              icon: Icons.person_outline,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: codigoController,
            obscureText: !mostrarCodigo,
            onSubmitted: (_) => ingresar(),
            decoration: decoration(
              label: "Codigo local / contrasena Supabase",
              icon: Icons.lock_outline,
              suffix: IconButton(
                tooltip: mostrarCodigo ? "Ocultar codigo" : "Mostrar codigo",
                onPressed: () {
                  setState(() {
                    mostrarCodigo = !mostrarCodigo;
                  });
                },
                icon: Icon(
                  mostrarCodigo
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                recordarUsuario = !recordarUsuario;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Checkbox(
                    value: recordarUsuario,
                    onChanged: (value) {
                      setState(() {
                        recordarUsuario = value ?? false;
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      "Recordar usuario en este dispositivo",
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error),
              ),
              child: Text(
                error,
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: ingresar,
              icon: const Icon(Icons.login_rounded),
              label: const Text("Ingresar"),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Para operar online use email y contrasena de Supabase. El codigo local solo sirve para ingreso local.",
            style: TextStyle(color: AppColors.textDisabled, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 760;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(compact ? 14 : 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: compact ? 430 : 920),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(compact ? 18 : 22),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: compact
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _brandPanel(compact: true),
                          _loginPanel(compact: true, error: auth.error),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(child: _brandPanel(compact: false)),
                          Expanded(
                            child: _loginPanel(
                              compact: false,
                              error: auth.error,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccessPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _AccessPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessHint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _AccessHint({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
