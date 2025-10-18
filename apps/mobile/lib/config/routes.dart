import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/chat/chat_detail_screen.dart';
import '../screens/item_details/item_details_screen.dart';
import '../screens/matches/matches_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/report/report_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/support_screen.dart';
import '../screens/my_items_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';

/// Route names constants
class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String notifications = '/notifications';
  static const String chat = '/chat';
  static const String chatDetail = '/chat/detail';
  static const String itemDetails = '/item/details';
  static const String matches = '/matches';
  static const String profile = '/profile';
  static const String report = '/report';
  static const String settings = '/settings';
  static const String support = '/support';
  static const String myItems = '/my-items';
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
}

/// Generate routes for the app
class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Extract arguments
    final args = settings.arguments;

    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case AppRoutes.signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());

      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());

      case AppRoutes.chat:
        return MaterialPageRoute(builder: (_) => const ChatScreen());

      case AppRoutes.chatDetail:
        if (args is Map<String, String>) {
          return MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              conversationId: args['conversationId'] ?? '',
              userName: args['userName'] ?? 'User',
            ),
          );
        }
        return _errorRoute(
            'Chat detail requires conversation ID and user name');

      case AppRoutes.itemDetails:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => ItemDetailsScreen(itemId: args),
          );
        }
        return _errorRoute('Item details requires item ID');

      case AppRoutes.matches:
        return MaterialPageRoute(builder: (_) => const MatchesScreen());

      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case AppRoutes.report:
        return MaterialPageRoute(builder: (_) => const ReportScreen());

      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsPage());

      case AppRoutes.support:
        return MaterialPageRoute(builder: (_) => const SupportPage());

      case AppRoutes.myItems:
        return MaterialPageRoute(
            builder: (_) => const MyItemsPage(itemType: 'active'));

      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case AppRoutes.onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());

      default:
        return _errorRoute('Route not found: ${settings.name}');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text(message),
        ),
      ),
    );
  }
}

/// Navigation helper class for easy navigation throughout the app
class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Get current context
  static BuildContext? get currentContext => navigatorKey.currentContext;

  /// Navigate to a named route
  static Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return navigatorKey.currentState!
        .pushNamed<T>(routeName, arguments: arguments);
  }

  /// Navigate to a named route and replace current route
  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    Object? arguments,
    TO? result,
  }) {
    return navigatorKey.currentState!.pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
      result: result,
    );
  }

  /// Navigate to a named route and clear all previous routes
  static Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    String routeName, {
    Object? arguments,
    bool Function(Route<dynamic>)? predicate,
  }) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil<T>(
      routeName,
      predicate ?? (route) => false,
      arguments: arguments,
    );
  }

  /// Pop current route
  static void pop<T extends Object?>([T? result]) {
    navigatorKey.currentState!.pop<T>(result);
  }

  /// Pop until a specific route
  static void popUntil(RoutePredicate predicate) {
    navigatorKey.currentState!.popUntil(predicate);
  }

  /// Pop to root
  static void popToRoot() {
    navigatorKey.currentState!.popUntil((route) => route.isFirst);
  }

  /// Navigate to home screen
  static Future<void> goToHome() {
    return pushNamedAndRemoveUntil(AppRoutes.home);
  }

  /// Navigate to login screen
  static Future<void> goToLogin() {
    return pushNamedAndRemoveUntil(AppRoutes.login);
  }

  /// Navigate to item details
  static Future<void> goToItemDetails(String itemId) {
    return pushNamed(AppRoutes.itemDetails, arguments: itemId);
  }

  /// Navigate to chat detail
  static Future<void> goToChatDetail(String conversationId, String userName) {
    return pushNamed(AppRoutes.chatDetail, arguments: {
      'conversationId': conversationId,
      'userName': userName,
    });
  }

  /// Navigate to notifications
  static Future<void> goToNotifications() {
    return pushNamed(AppRoutes.notifications);
  }

  /// Navigate to chat
  static Future<void> goToChat() {
    return pushNamed(AppRoutes.chat);
  }

  /// Navigate to profile
  static Future<void> goToProfile() {
    return pushNamed(AppRoutes.profile);
  }

  /// Navigate to settings
  static Future<void> goToSettings() {
    return pushNamed(AppRoutes.settings);
  }

  /// Navigate to support
  static Future<void> goToSupport() {
    return pushNamed(AppRoutes.support);
  }

  /// Navigate to my items
  static Future<void> goToMyItems() {
    return pushNamed(AppRoutes.myItems);
  }

  /// Navigate to report screen
  static Future<void> goToReport() {
    return pushNamed(AppRoutes.report);
  }

  /// Navigate to matches
  static Future<void> goToMatches() {
    return pushNamed(AppRoutes.matches);
  }

  /// Show a dialog
  static Future<T?> showDialog<T extends Object?>({
    required Widget Function(BuildContext) builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useSafeArea = true,
    bool useRootNavigator = false,
    RouteSettings? routeSettings,
  }) {
    return showGeneralDialog<T>(
      context: currentContext!,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      barrierLabel: barrierLabel,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return builder(context);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
    );
  }

  /// Show a bottom sheet
  static Future<T?> showBottomSheet<T extends Object?>({
    required Widget Function(BuildContext) builder,
    bool isScrollControlled = false,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    Color? barrierColor,
    bool useSafeArea = false,
    bool useRootNavigator = false,
    bool isPersistent = false,
    RouteSettings? routeSettings,
  }) {
    return showModalBottomSheet<T>(
      context: currentContext!,
      builder: builder,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      constraints: constraints,
      barrierColor: barrierColor,
      useSafeArea: useSafeArea,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
    );
  }

  /// Show a snackbar
  static void showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    Color? backgroundColor,
    Color? textColor,
    double? elevation,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    double? width,
    ShapeBorder? shape,
    SnackBarBehavior? behavior,
    Animation<double>? animation,
    VoidCallback? onVisible,
  }) {
    ScaffoldMessenger.of(currentContext!).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        backgroundColor: backgroundColor,
        behavior: behavior ?? SnackBarBehavior.floating,
        margin: margin,
        padding: padding,
        width: width,
        shape: shape,
        elevation: elevation,
        animation: animation,
        onVisible: onVisible,
      ),
    );
  }
}
