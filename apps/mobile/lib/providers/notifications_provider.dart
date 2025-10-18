import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';

/// Notifications state
class NotificationsState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final String? error;
  final int notificationCount;
  final bool hasNotifications;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.notificationCount = 0,
    this.hasNotifications = false,
  });

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? error,
    int? notificationCount,
    bool? hasNotifications,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      notificationCount: notificationCount ?? this.notificationCount,
      hasNotifications: hasNotifications ?? this.hasNotifications,
    );
  }
}

/// Notifications provider
class NotificationsProvider extends StateNotifier<NotificationsState> {
  final ApiService _apiService;

  NotificationsProvider(this._apiService) : super(const NotificationsState());

  /// Load notifications
  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final notifications = await _apiService.getNotifications();
      state = state.copyWith(
        notifications: notifications,
        isLoading: false,
        notificationCount: notifications.length,
        hasNotifications: notifications.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Refresh notifications
  Future<void> refresh() async {
    await loadNotifications();
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiService.markNotificationAsRead(notificationId);
      
      // Update the notification in the state
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == notificationId) {
          return notification.copyWith(isRead: true);
        }
        return notification;
      }).toList();
      
      state = state.copyWith(notifications: updatedNotifications);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _apiService.deleteNotification(notificationId);
      
      // Remove the notification from the state
      final updatedNotifications = state.notifications
          .where((notification) => notification.id != notificationId)
          .toList();
      
      state = state.copyWith(
        notifications: updatedNotifications,
        notificationCount: updatedNotifications.length,
        hasNotifications: updatedNotifications.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _apiService.markAllNotificationsAsRead();
      
      // Update all notifications to read
      final updatedNotifications = state.notifications.map((notification) {
        return notification.copyWith(isRead: true);
      }).toList();
      
      state = state.copyWith(notifications: updatedNotifications);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final count = await _apiService.getUnreadNotificationCount();
      state = state.copyWith(notificationCount: count);
      return count;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return 0;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Notifications provider instance
final notificationsProvider = StateNotifierProvider<NotificationsProvider, NotificationsState>((ref) {
  final apiService = ApiService();
  return NotificationsProvider(apiService);
});