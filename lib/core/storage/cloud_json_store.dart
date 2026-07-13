import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../network/supabase_config.dart';

class CloudJsonStore {
  CloudJsonStore._();

  static bool _initialized = false;
  static bool _available = false;
  static const _requestTimeout = Duration(seconds: 12);
  static const _accessTokenKey = 'supabase_access_token';
  static const _refreshTokenKey = 'supabase_refresh_token';
  static const _authIdKey = 'supabase_auth_id';
  static const _authEmailKey = 'supabase_auth_email';
  static String? _accessToken;
  static String? _refreshToken;
  static String? _authId;
  static String? _authEmail;

  static bool get enabled => _initialized && _available;
  static String? get currentAccessToken => _accessToken;
  static String? get currentAuthId => _authId;
  static String? get currentEmail => _authEmail;

  static Future<void> initialize() async {
    _initialized = true;

    if (!SupabaseConfig.isConfigured) {
      _available = false;
      return;
    }

    await _loadSession();
    _available = true;
  }

  static Future<void> setSession({
    required String accessToken,
    required String refreshToken,
    required String authId,
    required String email,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _authId = authId;
    _authEmail = email;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_authIdKey, authId);
    await prefs.setString(_authEmailKey, email);
  }

  static Future<void> clearSession() async {
    _accessToken = null;
    _refreshToken = null;
    _authId = null;
    _authEmail = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_authIdKey);
    await prefs.remove(_authEmailKey);
  }

  static Future<List<Map<dynamic, dynamic>>> syncBox({
    required String table,
    required Box box,
  }) async {
    if (!enabled) {
      return _localValues(box);
    }

    final remoteValues = await loadAll(table);

    if (remoteValues.isEmpty) {
      for (final key in box.keys) {
        final value = box.get(key);
        if (value is Map) {
          await save(
            table: table,
            id: key.toString(),
            data: Map<dynamic, dynamic>.from(value),
          );
        }
      }

      return _localValues(box);
    }

    final mergedValues = <String, Map<dynamic, dynamic>>{};
    for (final value in remoteValues) {
      final id = value['id']?.toString();
      if (id == null || id.isEmpty) {
        continue;
      }
      mergedValues[id] = Map<dynamic, dynamic>.from(value);
    }

    for (final local in _localValues(box)) {
      final id = local['id']?.toString();
      if (id == null || id.isEmpty) {
        continue;
      }

      final remote = mergedValues[id];
      if (remote == null || _isLocalNewer(local, remote)) {
        mergedValues[id] = local;
        await save(table: table, id: id, data: local);
        continue;
      }

      final localImage = local['imagenPath']?.toString() ?? '';
      final remoteImage = remote['imagenPath']?.toString() ?? '';
      final localHasPortableImage = localImage.startsWith('data:image/');
      final remoteHasPortableImage = remoteImage.startsWith('data:image/');
      if (localHasPortableImage && !remoteHasPortableImage) {
        final merged = Map<dynamic, dynamic>.from(remote);
        merged['imagenPath'] = localImage;
        mergedValues[id] = merged;
        await save(table: table, id: id, data: merged);
      }
    }

    await box.clear();
    for (final value in mergedValues.values) {
      final id = value['id']?.toString();
      if (id == null || id.isEmpty) {
        continue;
      }

      await box.put(id, value);
    }

    return mergedValues.values.toList();
  }

  static Future<List<Map<dynamic, dynamic>>> loadAll(String table) async {
    if (!enabled) {
      return const [];
    }

    try {
      final uri = _restUri(table, {
        'select': 'id,data',
        'order': 'updated_at.desc',
      });
      final response = await _send(() => http.get(uri, headers: _headers()));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }

      final rows = jsonDecode(response.body);
      if (rows is! List) {
        return const [];
      }

      return rows.map<Map<dynamic, dynamic>>((row) {
        final data = Map<dynamic, dynamic>.from(row['data'] as Map? ?? {});
        data['id'] = data['id'] ?? row['id'];
        return data;
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<bool> save({
    required String table,
    required String id,
    required Map<dynamic, dynamic> data,
  }) async {
    if (!enabled) {
      return true;
    }

    try {
      final uri = _restUri(table, {'on_conflict': 'id'});
      final response = await _send(
        () => http.post(
          uri,
          headers: _headers(
            prefer: 'resolution=merge-duplicates,return=minimal',
          ),
          body: jsonEncode({
            'id': id,
            'data': data,
            'updated_at': DateTime.now().toIso8601String(),
          }),
        ),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> delete({
    required String table,
    required String id,
    bool requireMatch = false,
  }) async {
    if (!enabled) {
      return true;
    }

    try {
      final uri = _restUri(table, {'id': 'eq.$id', 'select': 'id'});
      final response = await _send(
        () => http.delete(
          uri,
          headers: _headers(prefer: 'return=representation'),
        ),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }

      final deleted = jsonDecode(response.body);
      if (requireMatch && deleted is List && deleted.isEmpty) {
        return false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteVentaWithCaja(String ventaId) async {
    if (!enabled) {
      return true;
    }

    try {
      final uri = _restUri('rpc/delete_venta_owner');
      final response = await _send(
        () => http.post(
          uri,
          headers: _headers(),
          body: jsonEncode({'venta_id': ventaId}),
        ),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
    } catch (_) {
      // Si la funcion RPC no existe o falla por permisos, se intenta el camino
      // directo con las politicas RLS del propietario.
    }

    return _deleteVentaRows(ventaId);
  }

  static List<Map<dynamic, dynamic>> _localValues(Box box) {
    return box.values
        .whereType<Map>()
        .map((value) => Map<dynamic, dynamic>.from(value))
        .toList();
  }

  static Future<bool> _deleteVentaRows(String ventaId) async {
    await delete(table: 'caja', id: '$ventaId-caja');
    return delete(table: 'ventas', id: ventaId, requireMatch: true);
  }

  static Uri _restUri(String path, [Map<String, String>? query]) {
    return Uri.parse('${SupabaseConfig.url}/rest/v1/$path').replace(
      queryParameters: query,
    );
  }

  static Map<String, String> _headers({String? prefer}) {
    return {
      'apikey': SupabaseConfig.anonKey,
      'authorization': 'Bearer ${_accessToken ?? SupabaseConfig.anonKey}',
      'content-type': 'application/json',
      if (prefer != null) 'prefer': prefer,
    };
  }

  static Future<http.Response> _send(
    Future<http.Response> Function() request, {
    bool retried = false,
  }) async {
    final response = await request().timeout(_requestTimeout);
    if (response.statusCode == 401 && !retried && await _refreshSession()) {
      return _send(request, retried: true);
    }

    return response;
  }

  static Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_accessTokenKey);
    _refreshToken = prefs.getString(_refreshTokenKey);
    _authId = prefs.getString(_authIdKey);
    _authEmail = prefs.getString(_authEmailKey);
  }

  static Future<bool> _refreshSession() async {
    final refreshToken = _refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final response = await http
          .post(
            Uri.parse(
              '${SupabaseConfig.url}/auth/v1/token?grant_type=refresh_token',
            ),
            headers: {
              'apikey': SupabaseConfig.anonKey,
              'content-type': 'application/json',
            },
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        await clearSession();
        return false;
      }

      final data = jsonDecode(response.body);
      final accessToken = data['access_token'] as String? ?? '';
      final newRefreshToken = data['refresh_token'] as String? ?? refreshToken;
      final user = data['user'] as Map? ?? {};
      final authId = user['id']?.toString() ?? _authId ?? '';
      final email = user['email']?.toString() ?? _authEmail ?? '';
      if (accessToken.isEmpty || authId.isEmpty) {
        return false;
      }

      await setSession(
        accessToken: accessToken,
        refreshToken: newRefreshToken,
        authId: authId,
        email: email,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool _isLocalNewer(
    Map<dynamic, dynamic> local,
    Map<dynamic, dynamic> remote,
  ) {
    final localUpdatedAt = _recordDate(local);
    if (localUpdatedAt == null) {
      return false;
    }

    final remoteUpdatedAt = _recordDate(remote);
    if (remoteUpdatedAt == null) {
      return true;
    }

    return localUpdatedAt.isAfter(remoteUpdatedAt);
  }

  static DateTime? _recordDate(Map<dynamic, dynamic> value) {
    for (final key in const ['actualizado', 'updated_at', 'fecha', 'creado']) {
      final raw = value[key];
      if (raw is DateTime) {
        return raw;
      }
      if (raw is String) {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return null;
  }
}
