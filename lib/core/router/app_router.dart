import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/library/presentation/screens/library_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/reader/presentation/screens/reader_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // If the auth stream is still loading, do nothing
      if (authState.isLoading) return null;

      final session = authState.value?.session;
      final isAuth = session != null;
      final isGoingToLogin = state.matchedLocation == '/auth';

      // If user is not logged in and not heading to login -> redirect to login
      if (!isAuth && !isGoingToLogin) {
        return '/auth';
      }
      
      // If user is logged in and trying to access login -> redirect to home
      if (isAuth && isGoingToLogin) {
        return '/';
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: '/reader',
        name: 'reader',
        builder: (context, state) => const ReaderScreen(),
      ),
    ],
  );
});
