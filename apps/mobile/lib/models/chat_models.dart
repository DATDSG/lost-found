/// Chat and messaging models for the Lost & Found mobile app

/// Chat conversation model
class ChatConversation {
  final String id;
  final String? matchId;
  final String participantOneId;
  final String participantTwoId;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  ChatConversation({
    required this.id,
    this.matchId,
    required this.participantOneId,
    required this.participantTwoId,
    this.lastMessage,
    required this.unreadCount,
    required this.updatedAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'],
      matchId: json['match_id'],
      participantOneId: json['participant_one_id'],
      participantTwoId: json['participant_two_id'],
      lastMessage: json['last_message'] != null
          ? ChatMessage.fromJson(json['last_message'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  ChatConversation copyWith({
    String? id,
    String? matchId,
    String? participantOneId,
    String? participantTwoId,
    ChatMessage? lastMessage,
    int? unreadCount,
    DateTime? updatedAt,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      participantOneId: participantOneId ?? this.participantOneId,
      participantTwoId: participantTwoId ?? this.participantTwoId,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Computed properties for UI
  String get title =>
      'Conversation'; // This should be enhanced to show participant names
  String? get lastMessageText => lastMessage?.content;
  DateTime? get lastMessageAt => lastMessage?.createdAt;
  bool get isUnread => unreadCount > 0;
  String? get participantAvatar =>
      null; // This should be enhanced to get actual avatar
}

/// Chat message model
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final MessageStatus status;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    this.isRead = false,
    required this.createdAt,
    this.status = MessageStatus.sent,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      senderName: json['sender_name'] ?? 'Unknown',
      senderAvatar: json['sender_avatar'],
      content: json['content'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
    );
  }

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    bool? isRead,
    DateTime? createdAt,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}

/// Chat notification model
class ChatNotification {
  final String id;
  final String type;
  final String title;
  final String content;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  ChatNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    this.referenceId,
    this.isRead = false,
    required this.createdAt,
  });

  factory ChatNotification.fromJson(Map<String, dynamic> json) {
    return ChatNotification(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      content: json['content'],
      referenceId: json['reference_id'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // Computed properties for UI
  String get conversationId => referenceId ?? '';
  String get body => content;

  // Convert string type to enum for UI
  NotificationType get notificationType {
    switch (type.toLowerCase()) {
      case 'message':
        return NotificationType.message;
      case 'match':
        return NotificationType.match;
      case 'system':
        return NotificationType.system;
      case 'report':
        return NotificationType.report;
      default:
        return NotificationType.system;
    }
  }
}

/// Typing indicator model
class TypingIndicator {
  final String userId;
  final String userName;
  final DateTime timestamp;

  TypingIndicator({
    required this.userId,
    required this.userName,
    required this.timestamp,
  });
}

/// Chat status enum
enum ChatStatus { active, archived, blocked }

/// Message status enum
enum MessageStatus { sending, sent, delivered, read, failed }

/// Message type enum
enum MessageType { text, image, file, system }

/// Notification type enum
enum NotificationType { message, match, system, report }
