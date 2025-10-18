import 'package:flutter/material.dart';
import 'base_model.dart';

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

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type; // 'match', 'message', 'update', 'general'
  final DateTime timestamp;
  final bool isRead;
  final String? relatedId; // ID of related item, match, or message
  final String? conversationId; // ID of conversation for chat notifications
  final Map<String, dynamic>? data;
  final String notificationType;
  final String body;
  final DateTime createdAt;
  final String? referenceId;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.relatedId,
    this.conversationId,
    this.data,
    required this.notificationType,
    required this.body,
    required this.createdAt,
    this.referenceId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: BaseModel.parseStringWithDefault(json['id'], ''),
      title: BaseModel.parseStringWithDefault(json['title'], ''),
      message: BaseModel.parseStringWithDefault(json['message'], ''),
      type: BaseModel.parseStringWithDefault(json['type'], 'general'),
      timestamp:
          BaseModel.parseDateTimeWithDefault(json['timestamp'], DateTime.now()),
      isRead: BaseModel.parseBoolWithDefault(
          json['is_read'] ?? json['isRead'], false),
      relatedId: BaseModel.parseString(json['related_id'] ?? json['relatedId']),
      conversationId: BaseModel.parseString(
          json['conversation_id'] ?? json['conversationId']),
      data: BaseModel.parseMap(json['data']),
      notificationType: BaseModel.parseStringWithDefault(
          json['notification_type'] ?? json['notificationType'] ?? json['type'],
          'general'),
      body:
          BaseModel.parseStringWithDefault(json['body'] ?? json['message'], ''),
      createdAt: BaseModel.parseDateTimeWithDefault(
          json['created_at'], DateTime.now()),
      referenceId:
          BaseModel.parseString(json['reference_id'] ?? json['referenceId']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'related_id': relatedId,
      'conversation_id': conversationId,
      'data': data,
      'notification_type': notificationType,
      'body': body,
      'created_at': createdAt.toIso8601String(),
      'reference_id': referenceId,
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    DateTime? timestamp,
    bool? isRead,
    String? relatedId,
    String? conversationId,
    Map<String, dynamic>? data,
    String? notificationType,
    String? body,
    DateTime? createdAt,
    String? referenceId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId ?? this.relatedId,
      conversationId: conversationId ?? this.conversationId,
      data: data ?? this.data,
      notificationType: notificationType ?? this.notificationType,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      referenceId: referenceId ?? this.referenceId,
    );
  }

  // Getters for UI convenience
  String get content => body.isNotEmpty ? body : message;

  Color get typeColor {
    switch (notificationType.toLowerCase()) {
      case 'message':
        return const Color(0xFF2196F3); // Blue
      case 'match':
        return const Color(0xFF4CAF50); // Green
      case 'report':
        return const Color(0xFFFF9800); // Orange
      case 'system':
        return const Color(0xFF9C27B0); // Purple
      default:
        return const Color(0xFF757575); // Grey
    }
  }

  IconData get typeIcon {
    switch (notificationType.toLowerCase()) {
      case 'message':
        return Icons.chat_rounded;
      case 'match':
        return Icons.verified_user_rounded;
      case 'report':
        return Icons.description_rounded;
      case 'system':
        return Icons.settings_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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

  String get typeLabel {
    switch (notificationType.toLowerCase()) {
      case 'message':
        return 'Message';
      case 'match':
        return 'Match';
      case 'report':
        return 'Report';
      case 'system':
        return 'System';
      default:
        return 'Notification';
    }
  }

  String get priority {
    // Default priority based on type
    switch (notificationType.toLowerCase()) {
      case 'match':
        return 'high';
      case 'message':
        return 'normal';
      case 'report':
        return 'normal';
      case 'system':
        return 'low';
      default:
        return 'normal';
    }
  }

  Color get priorityColor {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFE53E3E); // Red
      case 'normal':
        return const Color(0xFF3182CE); // Blue
      case 'low':
        return const Color(0xFF68D391); // Green
      default:
        return const Color(0xFF3182CE); // Blue
    }
  }

  String get priorityLabel {
    switch (priority.toLowerCase()) {
      case 'high':
        return 'High';
      case 'normal':
        return 'Normal';
      case 'low':
        return 'Low';
      default:
        return 'Normal';
    }
  }
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
      isDestructive: json['is_destructive'] ?? json['isDestructive'] ?? false,
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

  NotificationAction copyWith({
    String? id,
    String? title,
    String? icon,
    bool? isDestructive,
    Map<String, dynamic>? data,
  }) {
    return NotificationAction(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      isDestructive: isDestructive ?? this.isDestructive,
      data: data ?? this.data,
    );
  }
}
