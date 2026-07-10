import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/models/app_user_model.dart';
import 'supabase_config.dart';

class SupabaseAuthService {
  SupabaseAuthService._();

  static Future<SupabaseSignInResult> signIn({
    required String identifier,
    required String password,
  }) async {
    if (!identifier.contains('@')) {
      return const SupabaseSignInResult();
    }

    if (!SupabaseConfig.isConfigured) {
      return const SupabaseSignInResult(
        error:
            'La app no tiene Supabase configurado. Revise SUPABASE_URL y SUPABASE_ANON_KEY en el publicador web.',
      );
    }

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: identifier.trim(),
        password: password.trim(),
      );

      return SupabaseSignInResult(authId: response.user?.id);
    } on AuthException catch (error) {
      final message = error.message.toLowerCase();

      if (message.contains('email not confirmed')) {
        return const SupabaseSignInResult(
          error:
              'El email existe en Supabase, pero falta confirmarlo en Authentication.',
        );
      }

      if (message.contains('invalid login credentials')) {
        return const SupabaseSignInResult(
          error:
              'Email o contrasena de Supabase incorrectos. Use la contrasena creada en Supabase, no el codigo local.',
        );
      }

      if (_isConnectionError(message)) {
        return const SupabaseSignInResult(
          error:
              'No se pudo conectar con Supabase. Revise que SUPABASE_URL no tenga espacios y que SUPABASE_ANON_KEY este completa.',
        );
      }

      return SupabaseSignInResult(error: error.message);
    } catch (_) {
      return const SupabaseSignInResult(
        error: 'No se pudo conectar con Supabase. Revise la configuracion.',
      );
    }
  }

  static Future<void> signOut() async {
    if (!SupabaseConfig.isConfigured) {
      return;
    }

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      return;
    }
  }

  static String? currentAuthId() {
    if (!SupabaseConfig.isConfigured) {
      return null;
    }

    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  static String? currentEmail() {
    if (!SupabaseConfig.isConfigured) {
      return null;
    }

    try {
      return Supabase.instance.client.auth.currentUser?.email;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanCurrentPassword = currentPassword.trim();
    final cleanNewPassword = newPassword.trim();

    if (!cleanEmail.contains('@')) {
      return 'Ingrese el email de Supabase del usuario.';
    }

    if (cleanCurrentPassword.isEmpty) {
      return 'Ingrese la contrasena actual o provisoria.';
    }

    if (cleanNewPassword.length < 6) {
      return 'La nueva contrasena debe tener al menos 6 caracteres.';
    }

    if (!SupabaseConfig.isConfigured) {
      return 'La app no tiene Supabase configurado. Revise SUPABASE_URL y SUPABASE_ANON_KEY en el publicador web.';
    }

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: cleanEmail,
        password: cleanCurrentPassword,
      );
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: cleanNewPassword),
      );
      return null;
    } on AuthException catch (error) {
      final message = error.message.toLowerCase();

      if (message.contains('invalid login credentials')) {
        return 'Email o contrasena actual incorrectos.';
      }

      if (message.contains('password')) {
        return 'Supabase no acepto la nueva contrasena. Use al menos 6 caracteres.';
      }

      if (_isConnectionError(message)) {
        return 'No se pudo conectar con Supabase. Revise que SUPABASE_URL no tenga espacios y que SUPABASE_ANON_KEY este completa.';
      }

      return error.message;
    } catch (_) {
      return 'No se pudo cambiar la contrasena. Revise la conexion.';
    }
  }

  static AppUserModel? matchUser({
    required List<AppUserModel> users,
    required String identifier,
    required String authId,
  }) {
    final email = identifier.trim().toLowerCase();
    final localPart = email.split('@').first;

    for (final user in users) {
      final matchesAuthId = user.authId.isNotEmpty && user.authId == authId;
      final matchesEmail = user.email.trim().toLowerCase() == email;
      final matchesName =
          _normalize(user.nombre) == _normalize(localPart) ||
          _normalize(user.nombre) == _normalize(identifier);

      if (user.activo && (matchesAuthId || matchesEmail || matchesName)) {
        return user.copyWith(email: email, authId: authId);
      }
    }

    return null;
  }

  static Future<AppUserModel?> loadProfile({
    required String identifier,
    required String authId,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      return null;
    }

    try {
      final row = await Supabase.instance.client
          .from('user_profiles')
          .select('auth_id, app_user_id, nombre, rol, sucursal, activo')
          .eq('auth_id', authId)
          .maybeSingle();

      if (row == null || row['activo'] != true) {
        return null;
      }

      return AppUserModel(
        id: row['app_user_id'] as String? ?? authId,
        nombre: row['nombre'] as String? ?? identifier,
        codigo: '',
        email: identifier.trim().toLowerCase(),
        authId: authId,
        rol: row['rol'] as String? ?? 'Empleado',
        sucursal: row['sucursal'] as String? ?? '',
        activo: row['activo'] as bool? ?? true,
        creado: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  static bool _isConnectionError(String message) {
    return message.contains('failed to fetch') ||
        message.contains('clientexception') ||
        message.contains('network') ||
        message.contains('xmlhttprequest');
  }
}

class SupabaseSignInResult {
  final String? authId;
  final String? error;

  const SupabaseSignInResult({this.authId, this.error});
}
