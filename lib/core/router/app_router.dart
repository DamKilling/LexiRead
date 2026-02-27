
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/reader/presentation/screens/reader_screen.dart';

// Provide the router configuration
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        name: 'reader',
        builder: (context, state) => const ReaderScreen(),
      ),
    ],
  );
});
