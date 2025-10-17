import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_routes.dart';
import 'providers/auth_provider.dart';
import 'providers/reports_provider.dart';
import 'providers/messages_provider.dart';
import 'providers/search_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/matches_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/media_provider.dart';
import 'providers/user_profile_provider.dart';
import 'providers/messaging_provider.dart';
import 'providers/location_provider.dart';
import 'services/api_service.dart';
import 'services/api_service_manager.dart';
import 'services/offline_manager.dart';
import 'services/storage_service.dart';
import 'widgets/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline services
  await _initializeServices();

  runApp(const LostFinderApp());
}

/// Initialize all required services
Future<void> _initializeServices() async {
  try {
    // Initialize storage service first
    await StorageService().initialize();

    // Initialize offline manager
    await OfflineManager().initialize();

    // Initialize API service manager
    await ApiServiceManager().initialize();

    debugPrint('✅ All services initialized successfully');
  } catch (e) {
    debugPrint('❌ Failed to initialize services: $e');
  }
}

class LostFinderApp extends StatelessWidget {
  const LostFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
        ChangeNotifierProvider(create: (_) => MessagesProvider(ApiService())),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => MatchesProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => MediaProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => MessagingProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Lost Finder - Enhanced',
        theme: AppTheme.light,
        initialRoute: AppRoutes.home,
        routes: {
          AppRoutes.home: (context) => const AuthWrapper(),
          ...AppRoutes.staticRoutes,
        },
        onGenerateRoute: AppRouteGenerator.generateRoute,
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Page Not Found')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Page not found: ${settings.name}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushReplacementNamed(AppRoutes.home),
                      child: const Text('Go Home'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
