import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_model.dart';
import '../models/notification.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

/// Chat state
class ChatState {
  final List<ChatConversation> conversations;
  final Map<String, List<ChatMessage>> conversationMessages;
  final Map<String, List<String>> typingUsers;
  final bool isAnyLoading;
  final String? error;
  final int totalUnreadCount;
  final bool hasUnreadMessages;
  final List<Notification> notifications;
  final int notificationCount;
  final bool hasNotifications;

  const ChatState({
    this.conversations = const [],
    this.conversationMessages = const {},
    this.typingUsers = const {},
    this.isAnyLoading = false,
    this.error,
    this.totalUnreadCount = 0,
    this.hasUnreadMessages = false,
    this.notifications = const [],
    this.notificationCount = 0,
    this.hasNotifications = false,
  });

  ChatState copyWith({
    List<ChatConversation>? conversations,
    Map<String, List<ChatMessage>>? conversationMessages,
    Map<String, List<String>>? typingUsers,
    bool? isAnyLoading,
    String? error,
    int? totalUnreadCount,
    bool? hasUnreadMessages,
    List<Notification>? notifications,
    int? notificationCount,
    bool? hasNotifications,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      conversationMessages: conversationMessages ?? this.conversationMessages,
      typingUsers: typingUsers ?? this.typingUsers,
      isAnyLoading: isAnyLoading ?? this.isAnyLoading,
      error: error ?? this.error,
      totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
      hasUnreadMessages: hasUnreadMessages ?? this.hasUnreadMessages,
      notifications: notifications ?? this.notifications,
      notificationCount: notificationCount ?? this.notificationCount,
      hasNotifications: hasNotifications ?? this.hasNotifications,
    );
  }
}

/// Chat provider
class ChatProvider extends StateNotifier<ChatState> {
  final ApiService _apiService;
  final WebSocketService _wsService;

  ChatProvider(this._apiService, this._wsService) : super(const ChatState()) {
    _initialize();
  }

  void _initialize() {
    // Listen to WebSocket messages
    _wsService.messageStream.listen((message) {
      _handleWebSocketMessage(message);
    });
  }

  void _handleWebSocketMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;

    switch (type) {
      case 'message':
        _handleNewMessage(message);
        break;
      case 'typing':
        _handleTypingIndicator(message);
        break;
      case 'mark_read':
        _handleMarkAsRead(message);
        break;
    }
  }

  void _handleNewMessage(Map<String, dynamic> message) {
    final conversationId = message['conversation_id'] as String?;
    final messageData = message['message'] as Map<String, dynamic>?;

    if (conversationId != null && messageData != null) {
      final newMessage = ChatMessage.fromJson(messageData);
      final currentMessages = state.conversationMessages[conversationId] ?? [];

      state = state.copyWith(
        conversationMessages: {
          ...state.conversationMessages,
          conversationId: [...currentMessages, newMessage],
        },
      );
    }
  }

  void _handleTypingIndicator(Map<String, dynamic> message) {
    final conversationId = message['conversation_id'] as String?;
    final userId = message['user_id'] as String?;
    final isTyping = message['is_typing'] as bool?;

    if (conversationId != null && userId != null) {
      final currentTypingUsers = state.typingUsers[conversationId] ?? [];
      List<String> updatedTypingUsers;

      if (isTyping == true) {
        updatedTypingUsers = [...currentTypingUsers, userId];
      } else {
        updatedTypingUsers =
            currentTypingUsers.where((id) => id != userId).toList();
      }

      state = state.copyWith(
        typingUsers: {
          ...state.typingUsers,
          conversationId: updatedTypingUsers,
        },
      );
    }
  }

  void _handleMarkAsRead(Map<String, dynamic> message) {
    final conversationId = message['conversation_id'] as String?;

    if (conversationId != null) {
      // Update conversation unread count
      final updatedConversations = state.conversations.map((conv) {
        if (conv.id == conversationId) {
          return conv.copyWith(unreadCount: 0);
        }
        return conv;
      }).toList();

      state = state.copyWith(conversations: updatedConversations);
    }
  }

  /// Load conversations
  Future<void> loadConversations() async {
    state = state.copyWith(isAnyLoading: true, error: null);
    try {
      final conversations = await _apiService.getConversations();
      state = state.copyWith(
        conversations: conversations,
        isAnyLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isAnyLoading: false,
      );
    }
  }

  /// Load messages for a conversation
  Future<void> loadMessages(String conversationId) async {
    state = state.copyWith(isAnyLoading: true, error: null);
    try {
      final messages =
          await _apiService.getConversationMessages(conversationId);
      state = state.copyWith(
        conversationMessages: {
          ...state.conversationMessages,
          conversationId: messages,
        },
        isAnyLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isAnyLoading: false,
      );
    }
  }

  /// Send a message
  Future<void> sendMessage(String conversationId, String content) async {
    try {
      // Send via WebSocket if connected
      if (_wsService.isConnected) {
        _wsService.sendMessage(conversationId, content);
      } else {
        // Fallback to API
        await _apiService.sendMessage(conversationId, content);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Start typing indicator
  void startTyping(String conversationId) {
    if (_wsService.isConnected) {
      _wsService.sendTypingIndicator(conversationId, true);
    }
  }

  /// Stop typing indicator
  void stopTyping(String conversationId) {
    if (_wsService.isConnected) {
      _wsService.sendTypingIndicator(conversationId, false);
    }
  }

  /// Mark conversation as read
  Future<void> markAsRead(String conversationId) async {
    try {
      if (_wsService.isConnected) {
        _wsService.markAsRead(conversationId);
      } else {
        await _apiService.markConversationAsRead(conversationId);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Create a new conversation
  Future<ChatConversation?> createConversation(
      String itemId, String recipientId) async {
    try {
      final conversationId =
          await _apiService.createConversation(itemId, recipientId);
      if (conversationId != null) {
        // Load the new conversation
        await loadConversations();
        return state.conversations.firstWhere(
          (conv) => conv.id == conversationId,
          orElse: () => ChatConversation(
            id: conversationId,
            itemId: itemId,
            participants: [recipientId],
            lastMessage: null,
            unreadCount: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }
      return null;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Initialize the chat provider
  Future<void> initialize() async {
    await loadConversations();
    await loadNotifications();
  }

  /// Clear current conversation
  void clearCurrentConversation() {
    // Implementation depends on your specific needs
    // This could clear the current conversation selection
  }

  /// Get conversations
  List<ChatConversation> get conversations => state.conversations;

  /// Get messages for a conversation
  List<ChatMessage> getMessages(String conversationId) {
    return state.conversationMessages[conversationId] ?? [];
  }

  /// Get typing users for a conversation
  List<String> getTypingUsers(String conversationId) {
    return state.typingUsers[conversationId] ?? [];
  }

  /// Get notifications
  List<Notification> get notifications => state.notifications;

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _apiService.markNotificationAsRead(notificationId);
      // Update local state
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

  /// Load notifications
  Future<void> loadNotifications() async {
    try {
      final notifications = await _apiService.getNotifications();
      state = state.copyWith(
        notifications: notifications,
        notificationCount: notifications.length,
        hasNotifications: notifications.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Chat provider instance
final chatProvider = StateNotifierProvider<ChatProvider, ChatState>((ref) {
  final apiService = ApiService();
  final wsService = WebSocketService();
  return ChatProvider(apiService, wsService);
});
