import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/models/app_user_model.dart';
import 'supabase_config.dart';

class SupabaseAuthService {
  SupabaseAuthService._();

  static Future<String?> signIn({
    required String identifier,
    required String password,
  }) async {
    if (!SupabaseConfig.isConfigured || !identifier.contains('@')) {
      return null;
    }

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: identifier.trim(),
        password: password.trim(),
      );

      return response.user?.id;
    } catch (_) {
      return null;
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
}
