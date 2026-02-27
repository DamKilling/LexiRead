import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provides the Supabase Client instance globally
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// A stream provider that emits the current user state whenever it changes
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return supabase.auth.onAuthStateChange;
});

class AuthStateData {
  final bool isLoading;
  final String? errorMessage;

  AuthStateData({this.isLoading = false, this.errorMessage});

  AuthStateData copyWith({bool? isLoading, String? errorMessage, bool clearError = false}) {
    return AuthStateData(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthStateData> {
  final SupabaseClient _supabase;

  AuthNotifier(this._supabase) : super(AuthStateData());

  Future<void> signUp(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _supabase.auth.signUp(email: email, password: password);
      // Supabase handles the session internally
      state = state.copyWith(isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'An unexpected error occurred');
    }
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      state = state.copyWith(isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'An unexpected error occurred');
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _supabase.auth.signOut();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to sign out');
    }
  }
}

// Provider for the AuthNotifier
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthStateData>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AuthNotifier(supabase);
});
