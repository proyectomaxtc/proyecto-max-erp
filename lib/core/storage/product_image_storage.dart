import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../network/supabase_config.dart';
import 'cloud_json_store.dart';

class ProductImageStorage {
  ProductImageStorage._();

  static const bucket = 'product-images';
  static const _timeout = Duration(seconds: 18);

  static Future<String?> uploadDataUrl({
    required String productId,
    required String dataUrl,
  }) async {
    if (!CloudJsonStore.enabled ||
        !CloudJsonStore.hasActiveSession ||
        !dataUrl.startsWith('data:image/')) {
      return null;
    }

    final parsed = _parseDataUrl(dataUrl);
    if (parsed == null) {
      return null;
    }

    final fileName =
        '${_safeSegment(productId)}-${DateTime.now().millisecondsSinceEpoch}.${parsed.extension}';
    final objectPath = 'productos/$fileName';
    final uploadUri = Uri.parse(
      '${SupabaseConfig.url}/storage/v1/object/$bucket/$objectPath',
    );

    try {
      final response = await http
          .post(
            uploadUri,
            headers: {
              'apikey': SupabaseConfig.anonKey,
              'authorization': 'Bearer ${CloudJsonStore.currentAccessToken}',
              'content-type': parsed.contentType,
              'cache-control': '31536000',
              'x-upsert': 'true',
            },
            body: parsed.bytes,
          )
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      return '${SupabaseConfig.url}/storage/v1/object/public/$bucket/$objectPath';
    } catch (_) {
      return null;
    }
  }

  static _ParsedImage? _parseDataUrl(String dataUrl) {
    final comma = dataUrl.indexOf(',');
    if (comma < 0) {
      return null;
    }

    final header = dataUrl.substring(0, comma);
    final contentType = _contentType(header);
    if (contentType == null) {
      return null;
    }

    try {
      return _ParsedImage(
        contentType: contentType,
        extension: _extension(contentType),
        bytes: base64Decode(dataUrl.substring(comma + 1)),
      );
    } catch (_) {
      return null;
    }
  }

  static String? _contentType(String header) {
    final match = RegExp(r'data:(image/[a-zA-Z0-9.+-]+);base64').firstMatch(
      header,
    );
    return match?.group(1)?.toLowerCase();
  }

  static String _extension(String contentType) {
    return switch (contentType) {
      'image/jpeg' || 'image/jpg' => 'jpg',
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/heic' => 'heic',
      'image/heif' => 'heif',
      _ => 'img',
    };
  }

  static String _safeSegment(String value) {
    final safe = value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '-');
    return safe.isEmpty ? 'producto' : safe;
  }
}

class _ParsedImage {
  final String contentType;
  final String extension;
  final Uint8List bytes;

  const _ParsedImage({
    required this.contentType,
    required this.extension,
    required this.bytes,
  });
}
