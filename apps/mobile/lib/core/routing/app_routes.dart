import 'package:flutter/material.dart';
import '../../screens/splash_screen.dart';
import '../../screens/landing_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/signup_screen.dart';
import '../../features/shell/ui/app_shell.dart';
import '../../screens/report_lost_screen.dart';
import '../../screens/report_found_screen.dart';
import '../../screens/report_success_screen.dart';
import '../../screens/matches_detail_screen.dart';
import '../../screens/my_items_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/support_screen.dart';
import '../../screens/view_details_screen.dart';
import '../../features/chat/ui/chat_page.dart';
import '../../features/matches/ui/matches_page.dart';
import '../../features/notifications/ui/notifications_page.dart';
import '../../features/profile/ui/profile_page.dart';
import '../../features/report/ui/report_page.dart';

/// Centralized routing configuration for the Lost Finder app
///
/// This class provides a comprehensive routing system with:
/// - Type-safe route definitions
/// - Organized route categories
/// - Enhanced navigation methods
/// - Route validation and error handling
/// - Deep linking support
class AppRoutes {
  // ============================================================================
  // AUTHENTICATION ROUTES
  // ============================================================================
  static const String splash = '/splash';
  static const String landing = '/landing';
  static const String login = '/login';
  static const String signup = '/signup';

  // ============================================================================
  // MAIN APP ROUTES
  // ============================================================================
  static const String home = '/home';
  static const String profile = '/profile';
  static const String matches = '/matches';
  static const String notifications = '/notifications';

  // ============================================================================
  // REPORT ROUTES
  // ============================================================================
  static const String reportLost = '/report-lost';
  static const String reportFound = '/report-found';
  static const String reportDetail = '/report-detail';
  static const String reportEdit = '/report-edit';
  static const String viewDetails = '/view-details';
  static const String success = '/success';

  // ============================================================================
  // COMMUNICATION ROUTES
  // ============================================================================
  static const String chat = '/chat';
  static const String conversations = '/conversations';

  // ============================================================================
  // PROFILE & SETTINGS ROUTES
  // ============================================================================
  static const String editProfile = '/edit-profile';
  static const String myItems = '/my-items';
  static const String settings = '/settings';
  static const String support = '/support';

  // ============================================================================
  // DETAIL ROUTES
  // ============================================================================
  static const String itemDetails = '/item-details';
  static const String matchesDetail = '/matches-detail';

  // ============================================================================
  // UTILITY ROUTES
  // ============================================================================
  static const String search = '/search';
  static const String filters = '/filters';
  static const String camera = '/camera';
  static const String gallery = '/gallery';

  // ============================================================================
  // ADDITIONAL ROUTES (To be implemented)
  // ============================================================================
  static const String privacySettings = '/privacy-settings';
  static const String changePassword = '/change-password';
  static const String blockedUsers = '/blocked-users';
  static const String languageSettings = '/language-settings';
  static const String feedback = '/feedback';
  static const String faq = '/faq';
  static const String userGuide = '/user-guide';
  static const String tutorials = '/tutorials';
  static const String liveChat = '/live-chat';
  static const String privacyPolicy = '/privacy-policy';
  static const String terms = '/terms';
  static const String bugReport = '/bug-report';
  static const String featureRequest = '/feature-request';

  /// Get all static routes for MaterialApp
  static Map<String, WidgetBuilder> get staticRoutes => {
    splash: (context) => const SplashScreen(),
    landing: (context) => const LandingScreen(),
    login: (context) => const LoginScreen(),
    signup: (context) => const SignUpScreen(),
    // Dynamic routes are handled by generateRoute
  };

  /// Get route categories for organization
  static Map<String, List<String>> get routeCategories => {
    'Authentication': [splash, landing, login, signup],
    'Main App': [home, profile, matches, notifications],
    'Reports': [reportLost, reportFound, reportDetail, reportEdit, success],
    'Communication': [chat, conversations],
    'Profile & Settings': [editProfile, myItems, settings, support],
    'Details': [itemDetails, matchesDetail],
    'Utilities': [search, filters, camera, gallery],
    'Additional Routes': [
      privacySettings,
      changePassword,
      blockedUsers,
      languageSettings,
      feedback,
      faq,
      userGuide,
      tutorials,
      liveChat,
      privacyPolicy,
      terms,
      bugReport,
      featureRequest,
    ],
  };

  /// Check if a route requires authentication
  static bool requiresAuth(String routeName) {
    const authRoutes = [
      home,
      profile,
      matches,
      notifications,
      reportLost,
      reportFound,
      reportDetail,
      reportEdit,
      chat,
      conversations,
      editProfile,
      myItems,
      settings,
      support,
      itemDetails,
      matchesDetail,
      search,
      filters,
      camera,
      gallery,
    ];
    return authRoutes.contains(routeName);
  }

  /// Get route display name for UI
  static String getDisplayName(String routeName) {
    switch (routeName) {
      case splash:
        return 'Splash';
      case landing:
        return 'Welcome';
      case login:
        return 'Login';
      case signup:
        return 'Sign Up';
      case home:
        return 'Home';
      case profile:
        return 'Profile';
      case matches:
        return 'Matches';
      case notifications:
        return 'Notifications';
      case reportLost:
        return 'Report Lost Item';
      case reportFound:
        return 'Report Found Item';
      case reportDetail:
        return 'Report Details';
      case reportEdit:
        return 'Edit Report';
      case success:
        return 'Success';
      case chat:
        return 'Chat';
      case conversations:
        return 'Conversations';
      case editProfile:
        return 'Edit Profile';
      case myItems:
        return 'My Items';
      case settings:
        return 'Settings';
      case support:
        return 'Support';
      case itemDetails:
        return 'Item Details';
      case matchesDetail:
        return 'Match Details';
      case search:
        return 'Search';
      case filters:
        return 'Filters';
      case camera:
        return 'Camera';
      case gallery:
        return 'Gallery';
      default:
        return 'Unknown';
    }
  }
}

/// Enhanced navigation helper methods with better error handling and logging
class AppNavigation {
  /// Navigate to a route with enhanced error handling
  static Future<T?> pushNamed<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    try {
      return Navigator.of(
        context,
      ).pushNamed<T>(routeName, arguments: arguments);
    } catch (e) {
      _logNavigationError('pushNamed', routeName, e);
      return Future<T?>.value(null);
    }
  }

  /// Navigate to a route and replace current
  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    TO? result,
  }) {
    try {
      return Navigator.of(context).pushReplacementNamed<T, TO>(
        routeName,
        arguments: arguments,
        result: result,
      );
    } catch (e) {
      _logNavigationError('pushReplacementNamed', routeName, e);
      return Future<T?>.value(null);
    }
  }

  /// Navigate to a route and clear stack
  static Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool Function(Route<dynamic>)? predicate,
  }) {
    try {
      return Navigator.of(context).pushNamedAndRemoveUntil<T>(
        routeName,
        predicate ?? (route) => false,
        arguments: arguments,
      );
    } catch (e) {
      _logNavigationError('pushNamedAndRemoveUntil', routeName, e);
      return Future<T?>.value(null);
    }
  }

  /// Pop current route with result
  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    try {
      Navigator.of(context).pop<T>(result);
    } catch (e) {
      _logNavigationError('pop', 'current', e);
    }
  }

  /// Pop until a specific route
  static void popUntil(BuildContext context, String routeName) {
    try {
      Navigator.of(context).popUntil(ModalRoute.withName(routeName));
    } catch (e) {
      _logNavigationError('popUntil', routeName, e);
    }
  }

  /// Pop to root (home screen)
  static void popToRoot(BuildContext context) {
    try {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      _logNavigationError('popToRoot', 'home', e);
    }
  }

  /// Check if can pop
  static bool canPop(BuildContext context) {
    return Navigator.of(context).canPop();
  }

  /// Get current route name
  static String? getCurrentRoute(BuildContext context) {
    return ModalRoute.of(context)?.settings.name;
  }

  /// Navigate with custom transition
  static Future<T?> pushWithTransition<T extends Object?>(
    BuildContext context,
    Widget page, {
    String? routeName,
    RouteTransitionsBuilder? transitionsBuilder,
    Duration transitionDuration = const Duration(milliseconds: 300),
  }) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        settings: RouteSettings(name: routeName),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder:
            transitionsBuilder ??
            (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: animation.drive(
                  Tween(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).chain(CurveTween(curve: Curves.easeInOut)),
                ),
                child: child,
              );
            },
        transitionDuration: transitionDuration,
      ),
    );
  }

  /// Log navigation errors
  static void _logNavigationError(String method, String route, dynamic error) {
    debugPrint('Navigation Error [$method]: $route - $error');
  }
}

/// Authentication flow navigation with enhanced error handling
class AuthFlow {
  /// Navigate to splash screen
  static Future<void> toSplash(BuildContext context) {
    return AppNavigation.pushReplacementNamed(context, AppRoutes.splash);
  }

  /// Navigate to landing screen
  static Future<void> toLanding(BuildContext context) {
    return AppNavigation.pushReplacementNamed(context, AppRoutes.landing);
  }

  /// Navigate to login screen
  static Future<void> toLogin(BuildContext context) {
    return AppNavigation.pushReplacementNamed(context, AppRoutes.login);
  }

  /// Navigate to signup screen
  static Future<void> toSignup(BuildContext context) {
    return AppNavigation.pushReplacementNamed(context, AppRoutes.signup);
  }

  /// Navigate to home (main app)
  static Future<void> toHome(BuildContext context) {
    return AppNavigation.pushReplacementNamed(context, AppRoutes.home);
  }

  /// Complete auth flow and go to home
  static Future<void> completeAuth(BuildContext context) {
    return AppNavigation.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      predicate: (route) => false, // Clear entire stack
    );
  }

  /// Logout and return to landing
  static Future<void> logout(BuildContext context) {
    return AppNavigation.pushNamedAndRemoveUntil(
      context,
      AppRoutes.landing,
      predicate: (route) => false,
    );
  }
}

/// Main app navigation with organized methods
class AppFlow {
  // ============================================================================
  // REPORT NAVIGATION
  // ============================================================================

  /// Navigate to report lost item
  static Future<void> toReportLost(BuildContext context) {
    return AppNavigation.pushNamed(context, AppRoutes.reportLost);
  }

  /// Navigate to report found item
  static Future<void> toReportFound(BuildContext context) {
    return AppNavigation.pushNamed(context, AppRoutes.reportFound);
  }

  /// Navigate to report detail
  static Future<void> toReportDetail(BuildContext context, String reportId) {
    return AppNavigation.pushNamed(
      context,
      AppRoutes.reportDetail,
      arguments: reportId,
    );
  }

  /// Navigate to edit report
  static Future<void> toEditReport(BuildContext context, String reportId) {
    return AppNavigation.pushNamed(
      context,
      AppRoutes.reportEdit,
      arguments: reportId,
    );
  }

  /// Navigate to success screen
  static Future<void> toSuccess(BuildContext context, {String? message}) {
    return AppNavigation.pushNamed(
      context,
      AppRoutes.success,
      arguments: message,
    );
  }

  // ============================================================================
  // COMMUNICATION NAVIGATION
  // ============================================================================

  /// Navigate to chat
  static Future<void> toChat(BuildContext context, String conversationId) {
    return AppNavigation.pushNamed(
      context,
      AppRoutes.chat,
      arguments: conversationId,
    );
  }

  /// Navigate to conversations
  static Future<void> toConversations(BuildContext context) {
    return AppNavigation.pushNamed(context, AppRoutes.conversations);
  }

  // ============================================================================
  // PROFILE & SETTINGS NAVIGATION
  // ============================================================================

  /// Navigate to profile
  static Future<void> toProfile(BuildContext context) {
    return AppNavigation.pushNamed(context, AppRoutes.profile);
  }

  /// Navigate to edit profile
  static Future<void> toEditProfile(BuildContext context) {
    return AppNavigation.pushNamed(context, AppRoutes.editProfile);
  }

  /// Navigate to settings
  static Future<void> toSettings(BuildContext context) {
    return AppNavigation.pushNamed(context, AppRoutes.settings);
  }

  /// Navigate to support
  static Future<void> toSupport(BuildContext context) {
    return AppNavigation.pushNamed(context, AppRoutes.support);
  }

  /// Navigate to my items with filter
  static Future<void> toMyItems(BuildContext context, {String? itemType}) {
    return AppNavigation.pushNamed(
      context,
      AppRoutes.myItems,
      arguments: itemType ?? 'active',
    );
  }

  // ============================================================================
  // DETAIL NAVIGATION
  // ============================================================================

  /// Navigate to item details
  static Future<void> toItemDetails(BuildContext context, String itemId) {
    return AppNavigation.pushNamed(
      context,
      AppRoutes.itemDetails,
      arguments: itemId,
    );
  }

  /// Navigate to matches detail
  static Future<void> toMatchesDetail(BuildContext context, String reportId) {
    return AppNavigation.pushNamed(
      context,
      AppRoutes.matchesDetail,
      arguments: reportId,
    );
  }

  // ============================================================================
  // UTILITY NAVIGATION
  // ============================================================================

  /// Navigate to search
  static Future<void> toSearch(BuildContext context, {String? query}) {
    return AppNavigation.pushNamed(context, AppRoutes.search, arguments: query);
  }

  /// Navigate to filters
  static Future<void> toFilters(BuildContext context) {
    return AppNavigation.pushNamed(context, AppRoutes.filters);
  }

  /// Navigate to camera
  static Future<void> toCamera(BuildContext context) {
    return AppNavigation.pushNamed(context, AppRoutes.camera);
  }

  /// Navigate to gallery
  static Future<void> toGallery(BuildContext context) {
    return AppNavigation.pushNamed(context, AppRoutes.gallery);
  }
}

/// Enhanced utility methods for route management
class AppRouteUtils {
  /// Get route name from context
  static String? getCurrentRoute(BuildContext context) {
    return ModalRoute.of(context)?.settings.name;
  }

  /// Check if current route matches
  static bool isCurrentRoute(BuildContext context, String routeName) {
    return getCurrentRoute(context) == routeName;
  }

  /// Get arguments from current route with type safety
  static T? getArguments<T>(BuildContext context) {
    return ModalRoute.of(context)?.settings.arguments as T?;
  }

  /// Check if route is in authentication flow
  static bool isAuthRoute(BuildContext context) {
    final currentRoute = getCurrentRoute(context);
    return currentRoute != null && !AppRoutes.requiresAuth(currentRoute);
  }

  /// Get route history
  static List<String> getRouteHistory(BuildContext context) {
    final navigator = Navigator.of(context);
    final routes = <String>[];

    navigator.popUntil((route) {
      routes.add(route.settings.name ?? 'unknown');
      return false;
    });

    return routes.reversed.toList();
  }

  /// Validate route arguments
  static bool validateArguments<T>(
    BuildContext context,
    T Function() validator,
  ) {
    try {
      validator();
      return true;
    } catch (e) {
      debugPrint('Route argument validation failed: $e');
      return false;
    }
  }
}

/// Enhanced route generator with better error handling and validation
class AppRouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Log route generation for debugging
    debugPrint(
      'Generating route: ${settings.name} with args: ${settings.arguments}',
    );

    switch (settings.name) {
      // ============================================================================
      // AUTHENTICATION ROUTES
      // ============================================================================
      case AppRoutes.splash:
        return _buildRoute(settings, const SplashScreen());

      case AppRoutes.landing:
        return _buildRoute(settings, const LandingScreen());

      case AppRoutes.login:
        return _buildRoute(settings, const LoginScreen());

      case AppRoutes.signup:
        return _buildRoute(settings, const SignUpScreen());

      // ============================================================================
      // MAIN APP ROUTES
      // ============================================================================
      case AppRoutes.home:
        return _buildRoute(settings, const AppShell());

      case AppRoutes.profile:
        return _buildRoute(settings, const ProfilePage());

      case AppRoutes.matches:
        return _buildRoute(settings, const MatchesPage());

      case AppRoutes.notifications:
        return _buildRoute(settings, const NotificationsPage());

      // ============================================================================
      // REPORT ROUTES
      // ============================================================================
      case AppRoutes.reportLost:
        return _buildRoute(settings, const ReportLostScreen());

      case AppRoutes.reportFound:
        return _buildRoute(settings, const ReportFoundScreen());

      case AppRoutes.success:
        return _buildRoute(settings, const ReportSuccessScreen());

      case AppRoutes.reportDetail:
        return _buildRouteWithValidation(settings, () {
          final reportId = settings.arguments as String?;
          if (reportId == null || reportId.isEmpty) {
            throw ArgumentError('Report ID is required');
          }
          return const ReportPage();
        });

      case AppRoutes.viewDetails:
        return _buildRouteWithValidation(settings, () {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args == null ||
              args['reportId'] == null ||
              args['reportType'] == null) {
            throw ArgumentError('Report ID and type are required');
          }
          return ViewDetailsScreen(
            reportId: args['reportId'] as String,
            reportType: args['reportType'] as String,
            reportData: args['reportData'] as Map<String, dynamic>?,
          );
        });

      // ============================================================================
      // COMMUNICATION ROUTES
      // ============================================================================
      case AppRoutes.chat:
        return _buildRouteWithValidation(settings, () {
          final conversationId = settings.arguments as String?;
          if (conversationId == null || conversationId.isEmpty) {
            throw ArgumentError('Conversation ID is required');
          }
          return const ChatPage();
        });

      // ============================================================================
      // PROFILE & SETTINGS ROUTES
      // ============================================================================
      case AppRoutes.myItems:
        final itemType = settings.arguments as String? ?? 'active';
        return _buildRoute(settings, MyItemsPage(itemType: itemType));

      case AppRoutes.settings:
        return _buildRoute(settings, const SettingsPage());

      case AppRoutes.support:
        return _buildRoute(settings, const SupportPage());

      // ============================================================================
      // DETAIL ROUTES
      // ============================================================================
      case AppRoutes.matchesDetail:
        return _buildRouteWithValidation(settings, () {
          final reportId = settings.arguments as String?;
          if (reportId == null || reportId.isEmpty) {
            throw ArgumentError('Report ID is required');
          }
          return MatchesDetailPage(reportId: reportId);
        });

      // ============================================================================
      // DEFAULT ROUTE (404)
      // ============================================================================
      default:
        return _buildErrorRoute(settings);
    }
  }

  /// Build a standard route with proper settings
  static MaterialPageRoute<T> _buildRoute<T>(
    RouteSettings settings,
    Widget page,
  ) {
    return MaterialPageRoute<T>(builder: (_) => page, settings: settings);
  }

  /// Build a route with validation and error handling
  static MaterialPageRoute<T> _buildRouteWithValidation<T>(
    RouteSettings settings,
    Widget Function() builder,
  ) {
    try {
      return MaterialPageRoute<T>(
        builder: (_) => builder(),
        settings: settings,
      );
    } catch (e) {
      return MaterialPageRoute<T>(
        builder: (_) => _buildErrorPage(
          'Invalid Arguments',
          'Required arguments are missing or invalid: $e',
          settings.name ?? 'unknown',
        ),
        settings: settings,
      );
    }
  }

  /// Build an error route for unknown routes
  static MaterialPageRoute<T> _buildErrorRoute<T>(RouteSettings settings) {
    return MaterialPageRoute<T>(
      builder: (_) => _buildErrorPage(
        'Page Not Found',
        'The requested page could not be found.',
        settings.name ?? 'unknown',
      ),
      settings: settings,
    );
  }

  /// Build error page widget
  static Widget _buildErrorPage(
    String title,
    String message,
    String routeName,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.red.shade50,
        foregroundColor: Colors.red.shade700,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Route: $routeName',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // This will be handled by the calling context
                },
                icon: const Icon(Icons.home),
                label: const Text('Go Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Deep linking support for handling external URLs
class DeepLinkHandler {
  /// Parse deep link URL and return route information
  static DeepLinkResult? parseDeepLink(String url) {
    try {
      final uri = Uri.parse(url);

      // Handle different URL schemes
      switch (uri.scheme) {
        case 'lostfinder':
          return _parseAppScheme(uri);
        case 'https':
        case 'http':
          return _parseWebScheme(uri);
        default:
          return null;
      }
    } catch (e) {
      debugPrint('Deep link parsing error: $e');
      return null;
    }
  }

  /// Parse app-specific scheme URLs
  static DeepLinkResult? _parseAppScheme(Uri uri) {
    switch (uri.host) {
      case 'report':
        final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
        return DeepLinkResult(route: AppRoutes.reportDetail, arguments: id);
      case 'chat':
        final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
        return DeepLinkResult(route: AppRoutes.chat, arguments: id);
      case 'profile':
        return const DeepLinkResult(route: AppRoutes.profile);
      default:
        return null;
    }
  }

  /// Parse web scheme URLs
  static DeepLinkResult? _parseWebScheme(Uri uri) {
    // Handle web URLs that should open specific app screens
    if (uri.host.contains('lostfinder')) {
      final path = uri.path;

      if (path.startsWith('/report/')) {
        final id = path.split('/').last;
        return DeepLinkResult(route: AppRoutes.reportDetail, arguments: id);
      }
    }

    return null;
  }
}

/// Result of deep link parsing
class DeepLinkResult {
  final String route;
  final Object? arguments;

  const DeepLinkResult({required this.route, this.arguments});
}

/// Route transition animations
class RouteTransitions {
  /// Slide transition from right
  static Widget slideFromRight(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: animation.drive(
        Tween(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOut)),
      ),
      child: child,
    );
  }

  /// Slide transition from bottom
  static Widget slideFromBottom(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: animation.drive(
        Tween(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOut)),
      ),
      child: child,
    );
  }

  /// Fade transition
  static Widget fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }

  /// Scale transition
  static Widget scaleTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: animation.drive(
        Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
      ),
      child: child,
    );
  }
}
