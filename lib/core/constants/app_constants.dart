class AppConstants {
  static const String appName = 'LexiRead';
  // Supabase Configuration
  // ⚠️ USER: Replace these with your actual Supabase URL and Anon Key ⚠️
  static const String supabaseUrl = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  
  // Storage Keys
  static const String keyHasSeenOnboarding = 'has_seen_onboarding';
  static const String keyUserToken = 'user_token';
  
  // API Config (if needed beyond Supabase)
  static const int defaultTimeout = 30000;
}
