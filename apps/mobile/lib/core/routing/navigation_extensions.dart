import 'package:flutter/material.dart';
import 'app_routes.dart';

/// Extension on BuildContext for easier navigation
extension NavigationExtension on BuildContext {
  /// Navigate to a route
  Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return AppNavigation.pushNamed<T>(this, routeName, arguments: arguments);
  }

  /// Navigate to a route and replace current
  Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    Object? arguments,
    TO? result,
  }) {
    return AppNavigation.pushReplacementNamed<T, TO>(
      this,
      routeName,
      arguments: arguments,
      result: result,
    );
  }

  /// Navigate to a route and clear stack
  Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    String routeName, {
    Object? arguments,
    bool Function(Route<dynamic>)? predicate,
  }) {
    return AppNavigation.pushNamedAndRemoveUntil<T>(
      this,
      routeName,
      arguments: arguments,
      predicate: predicate,
    );
  }

  /// Pop current route
  void pop<T extends Object?>([T? result]) {
    AppNavigation.pop<T>(this, result);
  }

  /// Pop until a specific route
  void popUntil(String routeName) {
    AppNavigation.popUntil(this, routeName);
  }

  /// Check if can pop
  bool get canPop => AppNavigation.canPop(this);

  /// Get current route name
  String? get currentRoute => AppRouteUtils.getCurrentRoute(this);

  /// Get arguments from current route
  T? getArguments<T>() => AppRouteUtils.getArguments<T>(this);

  /// Check if current route matches
  bool isCurrentRoute(String routeName) =>
      AppRouteUtils.isCurrentRoute(this, routeName);
}

/// Authentication flow navigation helpers
extension AuthNavigationExtension on BuildContext {
  /// Navigate to splash screen
  Future<void> toSplash() => AuthFlow.toSplash(this);

  /// Navigate to landing screen
  Future<void> toLanding() => AuthFlow.toLanding(this);

  /// Navigate to login screen
  Future<void> toLogin() => AuthFlow.toLogin(this);

  /// Navigate to signup screen
  Future<void> toSignup() => AuthFlow.toSignup(this);

  /// Navigate to home (main app)
  Future<void> toHome() => AuthFlow.toHome(this);

  /// Complete auth flow and go to home
  Future<void> completeAuth() => AuthFlow.completeAuth(this);
}

/// Main app navigation helpers
extension AppNavigationExtension on BuildContext {
  /// Navigate to report lost item
  Future<void> toReportLost() => AppFlow.toReportLost(this);

  /// Navigate to report found item
  Future<void> toReportFound() => AppFlow.toReportFound(this);

  /// Navigate to report detail
  Future<void> toReportDetail(String reportId) =>
      AppFlow.toReportDetail(this, reportId);

  /// Navigate to chat
  Future<void> toChat(String conversationId) =>
      AppFlow.toChat(this, conversationId);

  /// Navigate to conversations
  Future<void> toConversations() => AppFlow.toConversations(this);

  /// Navigate to profile
  Future<void> toProfile() => AppFlow.toProfile(this);

  /// Navigate to edit profile
  Future<void> toEditProfile() => AppFlow.toEditProfile(this);

  /// Navigate to settings
  Future<void> toSettings() => AppFlow.toSettings(this);

  /// Navigate to item details
  Future<void> toItemDetails(String itemId) =>
      AppFlow.toItemDetails(this, itemId);
}
