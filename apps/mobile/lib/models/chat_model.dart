class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final String? senderName;
  final String? senderAvatar;
  final DateTime createdAt;
  final String status;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.senderName,
    this.senderAvatar,
    required this.createdAt,
    this.status = 'sent',
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      senderId: json['sender_id'] ?? json['senderId'] ?? '',
      receiverId: json['receiver_id'] ?? json['receiverId'] ?? '',
      content: json['content'] ?? json['message'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      imageUrl: json['image_url'] ?? json['imageUrl'],
      senderName: json['sender_name'] ?? json['senderName'],
      senderAvatar: json['sender_avatar'] ?? json['senderAvatar'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      status: json['status'] ?? 'sent',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'message': content, // For backward compatibility
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'image_url': imageUrl,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'created_at': createdAt.toIso8601String(),
      'status': status,
    };
  }

  // Getters for backward compatibility
  String get message => content;
}

class ChatConversation {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String? participantAvatar;
  final ChatMessage? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isUnread;
  final String itemId;
  final List<String> participants;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? title;

  ChatConversation({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.participantAvatar,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isUnread = false,
    required this.itemId,
    required this.participants,
    required this.createdAt,
    required this.updatedAt,
    this.title,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      userName: json['user_name'] ?? json['userName'] ?? 'Unknown',
      userAvatar: json['user_avatar'] ?? json['userAvatar'],
      participantAvatar:
          json['participant_avatar'] ?? json['participantAvatar'],
      lastMessage: json['last_message'] != null
          ? ChatMessage.fromJson(json['last_message'])
          : null,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      unreadCount: json['unread_count'] ?? json['unreadCount'] ?? 0,
      isUnread: json['is_unread'] ?? json['isUnread'] ?? false,
      itemId: json['item_id'] ?? json['itemId'] ?? '',
      participants: (json['participants'] as List<dynamic>?)
              ?.map((p) => p.toString())
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      title: json['title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'participant_avatar': participantAvatar,
      'last_message': lastMessage?.toJson(),
      'last_message_at': lastMessageAt?.toIso8601String(),
      'unread_count': unreadCount,
      'is_unread': isUnread,
      'item_id': itemId,
      'participants': participants,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'title': title,
    };
  }

  ChatConversation copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? participantAvatar,
    ChatMessage? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? isUnread,
    String? itemId,
    List<String>? participants,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? title,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      participantAvatar: participantAvatar ?? this.participantAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isUnread: isUnread ?? this.isUnread,
      itemId: itemId ?? this.itemId,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      title: title ?? this.title,
    );
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

  factory TypingIndicator.fromJson(Map<String, dynamic> json) {
    return TypingIndicator(
      userId: json['user_id'] ?? json['userId'] ?? '',
      userName: json['user_name'] ?? json['userName'] ?? 'Unknown',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  TypingIndicator copyWith({
    String? userId,
    String? userName,
    DateTime? timestamp,
  }) {
    return TypingIndicator(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

/// Message status enum
enum MessageStatus {
  sending('sending', 'Sending'),
  sent('sent', 'Sent'),
  delivered('delivered', 'Delivered'),
  read('read', 'Read'),
  failed('failed', 'Failed');

  const MessageStatus(this.value, this.label);
  final String value;
  final String label;
}
