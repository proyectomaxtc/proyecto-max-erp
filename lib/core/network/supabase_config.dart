class SupabaseConfig {
  SupabaseConfig._();

  static const _rawUrl = String.fromEnvironment('SUPABASE_URL');
  static const _rawAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get url => _clean(_rawUrl);
  static String get anonKey => _clean(_rawAnonKey);

  static bool get isConfigured =>
      url.trim().isNotEmpty && anonKey.trim().isNotEmpty;

  static String _clean(String value) {
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r"""[\s"'`]+"""), '')
        .replaceAll('\uFEFF', '')
        .replaceAll('\u200B', '')
        .replaceAll('\u200C', '')
        .replaceAll('\u200D', '');

    if (cleaned.isEmpty) {
      return '';
    }

    final uri = Uri.tryParse(cleaned);
    if (uri != null && uri.scheme.isNotEmpty && uri.host.isNotEmpty) {
      return '${uri.scheme}://${uri.host}';
    }

    return cleaned.replaceAll(RegExp(r'/+$'), '');
  }
}
