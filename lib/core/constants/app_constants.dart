class AppConstants {
  static const String appName = 'Deep Read';
  // Supabase Configuration
  // ⚠️ USER: Replace these with your actual Supabase URL and Anon Key ⚠️
  static const String supabaseUrl = 'https://YOUR_SUPABASE_PROJECT.supabase.co';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  
  // Storage Keys
  static const String keyHasSeenOnboarding = 'has_seen_onboarding';
  static const String keyUserToken = 'user_token';
  
  // API Config (if needed beyond Supabase)
  static const int defaultTimeout = 30000;
}
