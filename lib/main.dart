import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with placeholders.
  // IMPORTANT: The user must replace these with real credentials from the Supabase dashboard.
  try {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase init failed (using mock config?): $e');
  }

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
      title: 'LexiRead',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Auto switch based on OS
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
