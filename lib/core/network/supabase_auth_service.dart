import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../features/auth/models/app_user_model.dart';
import '../storage/cloud_json_store.dart';
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
      final response = await http
          .post(
            Uri.parse(
              '${SupabaseConfig.url}/auth/v1/token?grant_type=password',
            ),
            headers: {
              'apikey': SupabaseConfig.anonKey,
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'email': identifier.trim(),
              'password': password.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = response.body.isEmpty ? const {} : jsonDecode(response.body);
      final message = body is Map
          ? (body['msg'] ?? body['message'] ?? body['error_description'] ?? '')
                .toString()
                .toLowerCase()
          : '';

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

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final savedSession = _savedSessionFor(identifier);
        if (savedSession != null) {
          return SupabaseSignInResult(authId: savedSession);
        }

        return const SupabaseSignInResult(
          error:
              'Supabase no permitio iniciar sesion. Revise email, contrasena y clave publishable.',
        );
      }

      if (body is! Map) {
        return const SupabaseSignInResult(
          error: 'Supabase respondio con un formato inesperado.',
        );
      }

      final accessToken = body['access_token'] as String? ?? '';
      final refreshToken = body['refresh_token'] as String? ?? '';
      final user = body['user'] as Map? ?? {};
      final authId = user['id']?.toString() ?? '';
      final email = user['email']?.toString() ?? identifier.trim();

      if (accessToken.isEmpty || refreshToken.isEmpty || authId.isEmpty) {
        return const SupabaseSignInResult(
          error: 'Supabase no devolvio una sesion valida.',
        );
      }

      await CloudJsonStore.setSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        authId: authId,
        email: email,
      );

      return SupabaseSignInResult(authId: authId);
    } catch (_) {
      final savedSession = _savedSessionFor(identifier);
      if (savedSession != null) {
        return SupabaseSignInResult(authId: savedSession);
      }

      return const SupabaseSignInResult(
        error:
            'No se pudo conectar con Supabase Auth. Revise conexion o espere unos segundos e intente de nuevo.',
      );
    }
  }

  static Future<void> signOut() async {
    if (!SupabaseConfig.isConfigured) {
      return;
    }

    await CloudJsonStore.clearSession();
  }

  static String? currentAuthId() {
    if (!SupabaseConfig.isConfigured) {
      return null;
    }

    return CloudJsonStore.currentAuthId;
  }

  static String? currentEmail() {
    if (!SupabaseConfig.isConfigured) {
      return null;
    }

    return CloudJsonStore.currentEmail;
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
      final signIn = await signIn(
        identifier: cleanEmail,
        password: cleanCurrentPassword,
      );
      if (signIn.authId == null) {
        return signIn.error ?? 'Email o contrasena actual incorrectos.';
      }

      final response = await http
          .put(
            Uri.parse('${SupabaseConfig.url}/auth/v1/user'),
            headers: {
              'apikey': SupabaseConfig.anonKey,
              'authorization': 'Bearer ${CloudJsonStore.currentAccessToken}',
              'content-type': 'application/json',
            },
            body: jsonEncode({'password': cleanNewPassword}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return 'Supabase no acepto la nueva contrasena. Use al menos 6 caracteres.';
      }

      return null;
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
      final response = await http
          .get(
            Uri.parse('${SupabaseConfig.url}/rest/v1/user_profiles').replace(
              queryParameters: {
                'select': 'auth_id,app_user_id,nombre,rol,sucursal,activo',
                'auth_id': 'eq.$authId',
                'limit': '1',
              },
            ),
            headers: {
              'apikey': SupabaseConfig.anonKey,
              'authorization': 'Bearer ${CloudJsonStore.currentAccessToken}',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final rows = jsonDecode(response.body);
      if (rows is! List || rows.isEmpty) {
        return null;
      }

      final row = Map<String, dynamic>.from(rows.first as Map);
      if (row['activo'] != true) {
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

  static String? _savedSessionFor(String identifier) {
    final authId = CloudJsonStore.currentAuthId;
    final email = CloudJsonStore.currentEmail;
    if (authId == null || authId.isEmpty || email == null || email.isEmpty) {
      return null;
    }

    if (email.trim().toLowerCase() != identifier.trim().toLowerCase()) {
      return null;
    }

    return authId;
  }

}

class SupabaseSignInResult {
  final String? authId;
  final String? error;

  const SupabaseSignInResult({this.authId, this.error});
}
