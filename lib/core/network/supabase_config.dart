class SupabaseConfig {
  SupabaseConfig._();

  static final url = _clean(String.fromEnvironment('SUPABASE_URL'));
  static final anonKey = _clean(String.fromEnvironment('SUPABASE_ANON_KEY'));

  static bool get isConfigured =>
      url.trim().isNotEmpty && anonKey.trim().isNotEmpty;

  static String _clean(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), '');
  }
}
