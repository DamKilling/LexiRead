import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (Replace with your actual URL and Anon Key later)
  // await Supabase.initialize(
  //   url: 'YOUR_SUPABASE_URL',
  //   anonKey: 'YOUR_SUPABASE_ANON_KEY',
  // );

  runApp(
    const ProviderScope(
      child: DeepReadApp(),
    ),
  );
}

class DeepReadApp extends ConsumerWidget {
  const DeepReadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Deep Read',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Auto switch based on OS
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
