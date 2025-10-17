import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../services/api_service.dart';
import '../core/error/error_handler.dart';

/// Notifications Provider - State management for user notifications
class NotificationsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Notification state
  List<AppNotification> _notifications = [];
  NotificationStats? _stats;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMoreNotifications = false;
  static const int _pageSize = 20;

  // Getters
  List<AppNotification> get notifications => _notifications;
  NotificationStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMoreNotifications => _hasMoreNotifications;

  // Computed getters
  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  List<AppNotification> get readNotifications =>
      _notifications.where((n) => n.isRead).toList();

  int get totalNotifications => _notifications.length;
  int get unreadCount => unreadNotifications.length;
  int get readCount => readNotifications.length;

  double get readRate {
    if (totalNotifications == 0) return 0.0;
    return readCount / totalNotifications;
  }

  // Get notifications by type
  List<AppNotification> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  // Get notifications by priority
  List<AppNotification> getNotificationsByPriority(
    NotificationPriority priority,
  ) {
    return _notifications.where((n) => n.priority == priority).toList();
  }

  // Get recent notifications (last 7 days)
  List<AppNotification> getRecentNotifications() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _notifications.where((n) => n.createdAt.isAfter(weekAgo)).toList();
  }

  /// Load notifications
  Future<void> loadNotifications({
    bool loadMore = false,
    bool unreadOnly = false,
  }) async {
    if (loadMore) {
      _currentPage++;
    } else {
      _currentPage = 1;
      _notifications.clear();
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final notifications = await _apiService.getNotifications(
        page: _currentPage,
        pageSize: _pageSize,
        unreadOnly: unreadOnly,
      );

      if (loadMore) {
        _notifications.addAll(notifications);
      } else {
        _notifications = notifications;
      }

      _hasMoreNotifications = notifications.length == _pageSize;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Load notifications');
      _isLoading = false;
      if (loadMore) {
        _currentPage--; // Revert page increment on error
      }

      // If it's an authentication error, don't show error to user
      if (e.toString().contains('Not authenticated') ||
          e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        _error = null; // Clear error for auth issues
      }

      notifyListeners();
    }
  }

  /// Load more notifications (pagination)
  Future<void> loadMoreNotifications({bool unreadOnly = false}) async {
    if (!_hasMoreNotifications || _isLoading) return;
    await loadNotifications(loadMore: true, unreadOnly: unreadOnly);
  }

  /// Load notification statistics
  Future<void> loadStats() async {
    try {
      _stats = await _apiService.getNotificationStats();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notification stats: $e');
      // Don't set error for stats as it's not critical
      // Also don't show auth errors for stats
      if (!e.toString().contains('Not authenticated') &&
          !e.toString().contains('401') &&
          !e.toString().contains('Unauthorized')) {
        debugPrint('Non-auth error loading notification stats: $e');
      }
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _apiService.markNotificationAsRead(notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = ErrorHandler.handleError(
        e,
        context: 'Mark notification as read',
      );
      notifyListeners();
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      await _apiService.markAllNotificationsAsRead();

      // Update local state
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true, readAt: DateTime.now()))
          .toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.handleError(
        e,
        context: 'Mark all notifications as read',
      );
      notifyListeners();
      return false;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _apiService.deleteNotification(notificationId);

      // Remove from local state
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Delete notification');
      notifyListeners();
      return false;
    }
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    try {
      return await _apiService.getUnreadNotificationCount();
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return unreadCount; // Return local count as fallback
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await Future.wait([loadNotifications(), loadStats()]);
  }

  /// Clear all data
  void clearAll() {
    _notifications.clear();
    _stats = null;
    _currentPage = 1;
    _hasMoreNotifications = false;
    _error = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get notification statistics for dashboard
  Map<String, dynamic> getNotificationStats() {
    return {
      'total': totalNotifications,
      'unread': unreadCount,
      'read': readCount,
      'read_rate': readRate,
    };
  }

  /// Get notifications by type breakdown
  Map<NotificationType, int> getTypeBreakdown() {
    final typeCount = <NotificationType, int>{};
    for (final notification in _notifications) {
      typeCount[notification.type] = (typeCount[notification.type] ?? 0) + 1;
    }
    return typeCount;
  }

  /// Get notifications by priority breakdown
  Map<NotificationPriority, int> getPriorityBreakdown() {
    final priorityCount = <NotificationPriority, int>{};
    for (final notification in _notifications) {
      priorityCount[notification.priority] =
          (priorityCount[notification.priority] ?? 0) + 1;
    }
    return priorityCount;
  }

  /// Get monthly notification trend
  Map<String, int> getMonthlyTrend() {
    final monthlyCount = <String, int>{};
    for (final notification in _notifications) {
      final monthKey =
          '${notification.createdAt.year}-${notification.createdAt.month.toString().padLeft(2, '0')}';
      monthlyCount[monthKey] = (monthlyCount[monthKey] ?? 0) + 1;
    }
    return monthlyCount;
  }

  /// Get notifications for a specific date range
  List<AppNotification> getNotificationsInRange(DateTime start, DateTime end) {
    return _notifications
        .where((n) => n.createdAt.isAfter(start) && n.createdAt.isBefore(end))
        .toList();
  }

  /// Search notifications by title or content
  List<AppNotification> searchNotifications(String query) {
    if (query.isEmpty) return _notifications;

    final lowercaseQuery = query.toLowerCase();
    return _notifications
        .where(
          (n) =>
              n.title.toLowerCase().contains(lowercaseQuery) ||
              n.content.toLowerCase().contains(lowercaseQuery),
        )
        .toList();
  }

  /// Get high priority notifications
  List<AppNotification> getHighPriorityNotifications() {
    return _notifications
        .where(
          (n) =>
              n.priority == NotificationPriority.high ||
              n.priority == NotificationPriority.urgent,
        )
        .toList();
  }

  /// Get notifications with actions
  List<AppNotification> getNotificationsWithActions() {
    return _notifications.where((n) => n.hasActions).toList();
  }

  /// Get notifications with images
  List<AppNotification> getNotificationsWithImages() {
    return _notifications.where((n) => n.hasImage).toList();
  }

  /// Get notifications with deep links
  List<AppNotification> getNotificationsWithDeepLinks() {
    return _notifications.where((n) => n.hasDeepLink).toList();
  }
}
