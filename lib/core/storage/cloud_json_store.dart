import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/supabase_config.dart';

class CloudJsonStore {
  CloudJsonStore._();

  static bool _initialized = false;
  static bool _available = false;
  static const _requestTimeout = Duration(seconds: 12);

  static bool get enabled => _initialized && _available;

  static Future<void> initialize() async {
    _initialized = true;

    if (!SupabaseConfig.isConfigured) {
      _available = false;
      return;
    }

    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
    _available = true;
  }

  static SupabaseClient get _client => Supabase.instance.client;

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
      final response = await _client
          .from(table)
          .select('id, data')
          .order('updated_at', ascending: false)
          .timeout(_requestTimeout);

      return response.map<Map<dynamic, dynamic>>((row) {
        final data = Map<dynamic, dynamic>.from(row['data'] as Map? ?? {});
        data['id'] = data['id'] ?? row['id'];
        return data;
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> save({
    required String table,
    required String id,
    required Map<dynamic, dynamic> data,
  }) async {
    if (!enabled) {
      return;
    }

    try {
      await _client.from(table).upsert({
        'id': id,
        'data': data,
        'updated_at': DateTime.now().toIso8601String(),
      }).timeout(_requestTimeout);
    } catch (_) {
      return;
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
      final deleted = await _client
          .from(table)
          .delete()
          .eq('id', id)
          .select('id')
          .timeout(_requestTimeout);
      if (requireMatch && deleted.isEmpty) {
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
      await _client.rpc(
        'delete_venta_owner',
        params: {'venta_id': ventaId},
      ).timeout(_requestTimeout);
      return true;
    } catch (_) {
      final ventaDeleted = await delete(
        table: 'ventas',
        id: ventaId,
        requireMatch: true,
      );
      await delete(table: 'caja', id: '$ventaId-caja');
      return ventaDeleted;
    }
  }

  static List<Map<dynamic, dynamic>> _localValues(Box box) {
    return box.values
        .whereType<Map>()
        .map((value) => Map<dynamic, dynamic>.from(value))
        .toList();
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
