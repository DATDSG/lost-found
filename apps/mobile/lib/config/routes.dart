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
