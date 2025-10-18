class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      senderId: json['sender_id'] ?? json['senderId'] ?? '',
      receiverId: json['receiver_id'] ?? json['receiverId'] ?? '',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      imageUrl: json['image_url'] ?? json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'image_url': imageUrl,
    };
  }
}

class ChatConversation {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final String itemId;
  final List<String> participants;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatConversation({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.lastMessage,
    this.unreadCount = 0,
    required this.itemId,
    required this.participants,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      userName: json['user_name'] ?? json['userName'] ?? 'Unknown',
      userAvatar: json['user_avatar'] ?? json['userAvatar'],
      lastMessage: json['last_message'] != null
          ? ChatMessage.fromJson(json['last_message'])
          : null,
      unreadCount: json['unread_count'] ?? json['unreadCount'] ?? 0,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'item_id': itemId,
      'participants': participants,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ChatConversation copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    ChatMessage? lastMessage,
    int? unreadCount,
    String? itemId,
    List<String>? participants,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      itemId: itemId ?? this.itemId,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
