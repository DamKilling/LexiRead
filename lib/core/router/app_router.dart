import 'package:flutter/material.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/reader/presentation/screens/reader_screen.dart';
import '../../features/library/presentation/screens/search_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen(authStateChangesProvider, (_, __) {
      notifyListeners();
    });
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = ref.read(authStateChangesProvider);

      if (authState.isLoading) {
        return '/splash';
      }

      final session = authState.value?.session;
      final isAuth = session != null;
      final isGoingToLogin = state.matchedLocation == '/auth';
      final isSplash = state.matchedLocation == '/splash';

      // If user is not logged in and not heading to login -> redirect to login
      if (!isAuth && !isGoingToLogin) {
        return '/auth';
      }

      // If user is logged in and trying to access login or splash -> redirect to home
      if (isAuth && (isGoingToLogin || isSplash)) {
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
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/reader/:bookId/:chapterNumber',
        name: 'reader',
        builder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          final chapterNumber = int.parse(state.pathParameters['chapterNumber']!);
          return ReaderScreen(bookId: bookId, chapterNumber: chapterNumber);
        },
      ),
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
    ],
  );
});
