import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Provide the router configuration
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Deep Read Home (To Be Implemented)')),
        ),
      ),
      GoRoute(
        path: '/reader',
        name: 'reader',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Reader View (To Be Implemented)')),
        ),
      ),
    ],
  );
});
