class SupabaseConfig {
  SupabaseConfig._();

  static const _rawUrl = String.fromEnvironment('SUPABASE_URL');
  static const _rawAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get url => _clean(_rawUrl);
  static String get anonKey => _clean(_rawAnonKey);

  static bool get isConfigured =>
      url.trim().isNotEmpty && anonKey.trim().isNotEmpty;

  static String _clean(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), '');
  }
}
