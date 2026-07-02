import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/supabase_config.dart';

class CloudJsonStore {
  CloudJsonStore._();

  static bool _initialized = false;
  static bool _available = false;

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

    if (remoteValues.isEmpty && box.isNotEmpty) {
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

    await box.clear();
    for (final value in remoteValues) {
      final id = value['id']?.toString();
      if (id == null || id.isEmpty) {
        continue;
      }

      await box.put(id, value);
    }

    return remoteValues;
  }

  static Future<List<Map<dynamic, dynamic>>> loadAll(String table) async {
    if (!enabled) {
      return const [];
    }

    try {
      final response = await _client
          .from(table)
          .select('id, data')
          .order('updated_at', ascending: false);

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
      });
    } catch (_) {
      return;
    }
  }

  static Future<void> delete({
    required String table,
    required String id,
  }) async {
    if (!enabled) {
      return;
    }

    try {
      await _client.from(table).delete().eq('id', id);
    } catch (_) {
      return;
    }
  }

  static List<Map<dynamic, dynamic>> _localValues(Box box) {
    return box.values
        .whereType<Map>()
        .map((value) => Map<dynamic, dynamic>.from(value))
        .toList();
  }
}
