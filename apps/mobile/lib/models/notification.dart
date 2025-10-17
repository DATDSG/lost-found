/// Notification models for the Lost & Found mobile app
/// Comprehensive notification system with different types and actions

import 'package:flutter/material.dart';

/// Notification type enum
enum NotificationType {
  message('message', 'Message'),
  match('match', 'Match'),
  report('report', 'Report'),
  system('system', 'System');

  const NotificationType(this.value, this.label);
  final String value;
  final String label;
}

/// Notification priority enum
enum NotificationPriority {
  low('low', 'Low'),
  normal('normal', 'Normal'),
  high('high', 'High'),
  urgent('urgent', 'Urgent');

  const NotificationPriority(this.value, this.label);
  final String value;
  final String label;
}

/// Notification action for interactive notifications
class NotificationAction {
  final String id;
  final String title;
  final String? icon;
  final bool isDestructive;
  final Map<String, dynamic>? data;

  NotificationAction({
    required this.id,
    required this.title,
    this.icon,
    this.isDestructive = false,
    this.data,
  });

  factory NotificationAction.fromJson(Map<String, dynamic> json) {
    return NotificationAction(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      icon: json['icon'],
      isDestructive: json['is_destructive'] ?? false,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'icon': icon,
      'is_destructive': isDestructive,
      'data': data,
    };
  }
}

/// Main notification model
class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final NotificationPriority priority;
  final String title;
  final String content;
  final String? referenceId; // ID of related object (report, match, etc.)
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;
  final List<NotificationAction>? actions;
  final String? imageUrl;
  final String? deepLink;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.priority,
    required this.title,
    required this.content,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.metadata,
    this.actions,
    this.imageUrl,
    this.deepLink,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      type: NotificationType.values.firstWhere(
        (t) => t.value == json['type'],
        orElse: () => NotificationType.system,
      ),
      priority: NotificationPriority.values.firstWhere(
        (p) => p.value == (json['priority'] ?? 'normal'),
        orElse: () => NotificationPriority.normal,
      ),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      referenceId: json['reference_id'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      metadata: json['metadata'],
      actions: (json['actions'] as List<dynamic>?)
          ?.map((a) => NotificationAction.fromJson(a as Map<String, dynamic>))
          .toList(),
      imageUrl: json['image_url'],
      deepLink: json['deep_link'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.value,
      'priority': priority.value,
      'title': title,
      'content': content,
      'reference_id': referenceId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'metadata': metadata,
      'actions': actions?.map((a) => a.toJson()).toList(),
      'image_url': imageUrl,
      'deep_link': deepLink,
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    NotificationPriority? priority,
    String? title,
    String? content,
    String? referenceId,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    Map<String, dynamic>? metadata,
    List<NotificationAction>? actions,
    String? imageUrl,
    String? deepLink,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      content: content ?? this.content,
      referenceId: referenceId ?? this.referenceId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      metadata: metadata ?? this.metadata,
      actions: actions ?? this.actions,
      imageUrl: imageUrl ?? this.imageUrl,
      deepLink: deepLink ?? this.deepLink,
    );
  }

  // Computed properties for UI
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get typeLabel => type.label;
  String get priorityLabel => priority.label;

  Color get typeColor {
    switch (type) {
      case NotificationType.message:
        return Colors.blue;
      case NotificationType.match:
        return Colors.green;
      case NotificationType.report:
        return Colors.orange;
      case NotificationType.system:
        return Colors.purple;
    }
  }

  Color get priorityColor {
    switch (priority) {
      case NotificationPriority.low:
        return Colors.grey;
      case NotificationPriority.normal:
        return Colors.blue;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.urgent:
        return Colors.red;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case NotificationType.message:
        return Icons.chat_rounded;
      case NotificationType.match:
        return Icons.verified_user_rounded;
      case NotificationType.report:
        return Icons.receipt_long_rounded;
      case NotificationType.system:
        return Icons.info_rounded;
    }
  }

  bool get hasActions => actions != null && actions!.isNotEmpty;
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasDeepLink => deepLink != null && deepLink!.isNotEmpty;
}

/// Notification statistics for dashboard
class NotificationStats {
  final int totalNotifications;
  final int unreadNotifications;
  final int readNotifications;
  final Map<NotificationType, int> typeBreakdown;
  final Map<NotificationPriority, int> priorityBreakdown;
  final DateTime lastNotificationAt;
  final double readRate;

  NotificationStats({
    required this.totalNotifications,
    required this.unreadNotifications,
    required this.readNotifications,
    required this.typeBreakdown,
    required this.priorityBreakdown,
    required this.lastNotificationAt,
    required this.readRate,
  });

  factory NotificationStats.fromJson(Map<String, dynamic> json) {
    return NotificationStats(
      totalNotifications: json['total_notifications'] ?? 0,
      unreadNotifications: json['unread_notifications'] ?? 0,
      readNotifications: json['read_notifications'] ?? 0,
      typeBreakdown: Map<NotificationType, int>.from(
        (json['type_breakdown'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(
                NotificationType.values.firstWhere(
                  (t) => t.value == key,
                  orElse: () => NotificationType.system,
                ),
                value as int,
              ),
            ) ??
            {},
      ),
      priorityBreakdown: Map<NotificationPriority, int>.from(
        (json['priority_breakdown'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(
                NotificationPriority.values.firstWhere(
                  (p) => p.value == key,
                  orElse: () => NotificationPriority.normal,
                ),
                value as int,
              ),
            ) ??
            {},
      ),
      lastNotificationAt: DateTime.parse(
        json['last_notification_at'] ?? DateTime.now().toIso8601String(),
      ),
      readRate: (json['read_rate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_notifications': totalNotifications,
      'unread_notifications': unreadNotifications,
      'read_notifications': readNotifications,
      'type_breakdown': typeBreakdown.map(
        (key, value) => MapEntry(key.value, value),
      ),
      'priority_breakdown': priorityBreakdown.map(
        (key, value) => MapEntry(key.value, value),
      ),
      'last_notification_at': lastNotificationAt.toIso8601String(),
      'read_rate': readRate,
    };
  }

  // Computed properties
  String get readRatePercentage => '${(readRate * 100).round()}%';
  bool get hasUnreadNotifications => unreadNotifications > 0;
  int get totalNotificationsCount => totalNotifications;
}
