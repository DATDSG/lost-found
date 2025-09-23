enum MessageKind { text, image, video, location }

class GeoPoint {
  final double lat;
  final double lng;
  const GeoPoint(this.lat, this.lng);
}

class ChatMessage {
  final String id;
  final String sender;
  final String avatarUrl; // can be empty offline
  final bool isMe;
  final MessageKind kind;
  final String? text;
  final String? mediaPath;
  final GeoPoint? location;

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.avatarUrl,
    required this.isMe,
    required this.kind,
    this.text,
    this.mediaPath,
    this.location,
  });

  ChatMessage copyWith({
    String? id,
    String? sender,
    String? avatarUrl,
    bool? isMe,
    MessageKind? kind,
    String? text,
    String? mediaPath,
    GeoPoint? location,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isMe: isMe ?? this.isMe,
      kind: kind ?? this.kind,
      text: text ?? this.text,
      mediaPath: mediaPath ?? this.mediaPath,
      location: location ?? this.location,
    );
  }
}

class ChatThread {
  final String id;
  final String name;
  final bool online;
  final DateTime? lastSeen;
  final List<ChatMessage> messages;

  const ChatThread({
    required this.id,
    required this.name,
    this.online = false,
    this.lastSeen,
    this.messages = const [],
  });
}
