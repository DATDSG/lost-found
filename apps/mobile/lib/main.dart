import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/core/di/dependency_injection.dart';
import 'app/core/router/app_router.dart';
import 'app/core/services/auth_service.dart';
import 'app/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await initDependencyInjection();

  runApp(
    ProviderScope(
      overrides: [
        // Override SharedPreferences provider with actual instance
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ],
      child: const LostFoundApp(),
    ),
  );
}

/// Main application widget
class LostFoundApp extends ConsumerWidget {
  /// Creates a new [LostFoundApp] instance
  const LostFoundApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Lost Finder',
      debugShowCheckedModeBanner: false,
      theme: appThemeLight,
      darkTheme: appThemeLight, // Using light theme for both modes for now
      // Routing
      routerConfig: router,
    );
  }
}
