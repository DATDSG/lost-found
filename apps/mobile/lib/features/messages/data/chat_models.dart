import 'package:flutter/foundation.dart';

@immutable
class GeoPoint {
  final double lat;
  final double lng;
  const GeoPoint(this.lat, this.lng);
}

enum MessageKind { text, image, video, location }

@immutable
class ChatMessage {
  final String id;
  final String sender;       // display name
  final String avatarUrl;    // can be empty for "me"
  final bool isMe;
  final MessageKind kind;
  final String? text;        // for text
  final String? mediaPath;   // local path for image/video
  final GeoPoint? location;  // for location

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

@immutable
class ChatThread {
  final String id;
  final String name;
  final String avatarUrl;
  final DateTime date;       // last message date
  final String preview1;
  final String preview2;
  final List<ChatMessage> messages;
  final bool online;         // for presence
  final DateTime? lastSeen;  // if not online
  final int unread;

  const ChatThread({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.date,
    required this.preview1,
    required this.preview2,
    required this.messages,
    this.online = false,
    this.lastSeen,
    this.unread = 0,
  });

  ChatThread copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    DateTime? date,
    String? preview1,
    String? preview2,
    List<ChatMessage>? messages,
    bool? online,
    DateTime? lastSeen,
    int? unread,
  }) {
    return ChatThread(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      date: date ?? this.date,
      preview1: preview1 ?? this.preview1,
      preview2: preview2 ?? this.preview2,
      messages: messages ?? this.messages,
      online: online ?? this.online,
      lastSeen: lastSeen ?? this.lastSeen,
      unread: unread ?? this.unread,
    );
  }
}
