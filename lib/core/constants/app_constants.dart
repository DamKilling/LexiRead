import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  static const String appName = 'LexiRead';
  // Supabase Configuration
  // ⚠️ USER: Replace these with your actual Supabase URL and Anon Key ⚠️
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  
  // Storage Keys
  static const String keyHasSeenOnboarding = 'has_seen_onboarding';
  static const String keyUserToken = 'user_token';
  
  // Local Backend API
  static String get backendApiUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    } catch (_) {}
    return 'http://127.0.0.1:8000';
  }
  
  // API Config (if needed beyond Supabase)
  static const int defaultTimeout = 30000;
}
