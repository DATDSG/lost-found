import 'package:flutter/material.dart';
import '../models/chat_models.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../core/error/error_handler.dart';
import '../core/error/api_error_handler.dart';
import '../core/loading/loading_state_manager.dart';

/// Chat Provider - Manages chat conversations and messages
class ChatProvider with ChangeNotifier, LoadingStateMixin {
  final ApiService _apiService = ApiService();
  final WebSocketService _webSocketService = WebSocketService();

  // Chat state
  List<ChatConversation> _conversations = [];
  List<ChatMessage> _messages = [];
  List<ChatNotification> _notifications = [];
  String? _currentConversationId;
  ChatState _chatState = ChatState.idle;
  String? _error;
  bool _isTyping = false;
  List<TypingIndicator> _typingUsers = [];

  // Getters
  List<ChatConversation> get conversations => _conversations;
  List<ChatMessage> get messages => _messages;
  List<ChatNotification> get notifications => _notifications;
  String? get currentConversationId => _currentConversationId;
  ChatState get chatState => _chatState;
  String? get error => _error;
  bool get isTyping => _isTyping;
  List<TypingIndicator> get typingUsers => _typingUsers;

  // Computed getters
  int get totalUnreadCount =>
      _conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
  int get notificationCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnreadMessages => totalUnreadCount > 0;
  bool get hasNotifications => notificationCount > 0;

  /// Initialize chat provider
  Future<void> initialize() async {
    try {
      _chatState = ChatState.loading;
      setLoading('initialize', true);
      notifyListeners();

      // Load conversations and notifications
      await Future.wait([loadConversations(), loadNotifications()]);

      // Connect to WebSocket for real-time updates
      await _connectWebSocket();

      _chatState = ChatState.success;
      setLoading('initialize', false);
      notifyListeners();
    } catch (e) {
      _error = ApiErrorHandler.handleApiError(
        e,
        context: 'Chat Initialization',
      );
      _chatState = ChatState.error;
      setError('initialize', _error);
      setLoading('initialize', false);
      notifyListeners();

      ApiErrorHandler.logError(e, context: 'Chat Initialization');
    }
  }

  /// Connect to WebSocket for real-time chat updates
  Future<void> _connectWebSocket() async {
    try {
      // Get access token from API service
      final accessToken = _apiService.accessToken;
      if (accessToken != null) {
        await _webSocketService.connect(accessToken);

        // Listen for new messages
        _webSocketService.messageStream?.listen((data) {
          if (data['type'] == 'chat_message') {
            _handleNewMessage(data);
          } else if (data['type'] == 'typing') {
            _handleTypingIndicator(data);
          } else if (data['type'] == 'message_status') {
            _handleMessageStatus(data);
          }
        });
      }
    } catch (e) {
      // WebSocket connection failed, but don't block the app
      print('WebSocket connection failed: $e');
    }
  }

  /// Handle new message from WebSocket
  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      final message = ChatMessage.fromJson(data['message']);

      // Add message to current conversation if it matches
      if (_currentConversationId == message.conversationId) {
        _messages.add(message);
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }

      // Update conversation's last message
      final conversationIndex = _conversations.indexWhere(
        (c) => c.id == message.conversationId,
      );

      if (conversationIndex != -1) {
        _conversations[conversationIndex] = _conversations[conversationIndex]
            .copyWith(
              lastMessage: message,
              unreadCount: _currentConversationId != message.conversationId
                  ? _conversations[conversationIndex].unreadCount + 1
                  : _conversations[conversationIndex].unreadCount,
              updatedAt: DateTime.now(),
            );
      }

      notifyListeners();
    } catch (e) {
      print('Error handling new message: $e');
    }
  }

  /// Handle typing indicator from WebSocket
  void _handleTypingIndicator(Map<String, dynamic> data) {
    try {
      final typingUser = TypingIndicator(
        userId: data['user_id'],
        userName: data['user_name'],
        timestamp: DateTime.now(),
      );

      // Remove old typing indicators for this user
      _typingUsers.removeWhere((t) => t.userId == typingUser.userId);

      // Add new typing indicator
      _typingUsers.add(typingUser);

      // Remove typing indicators after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        _typingUsers.removeWhere((t) => t.userId == typingUser.userId);
        notifyListeners();
      });

      notifyListeners();
    } catch (e) {
      print('Error handling typing indicator: $e');
    }
  }

  /// Handle message status update from WebSocket
  void _handleMessageStatus(Map<String, dynamic> data) {
    try {
      final messageId = data['message_id'];
      final status = MessageStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => MessageStatus.sent,
      );

      // Update message status
      final messageIndex = _messages.indexWhere((m) => m.id == messageId);
      if (messageIndex != -1) {
        _messages[messageIndex] = _messages[messageIndex].copyWith(
          status: status,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error handling message status: $e');
    }
  }

  /// Load conversations
  Future<void> loadConversations() async {
    try {
      setLoading('load_conversations', true);
      notifyListeners();

      final conversations = await _apiService.getChatConversations();
      _conversations = conversations;

      setLoading('load_conversations', false);
      notifyListeners();
    } catch (e) {
      final error = ApiErrorHandler.handleApiError(
        e,
        context: 'Load Conversations',
      );
      setError('load_conversations', error);
      setLoading('load_conversations', false);
      notifyListeners();

      ApiErrorHandler.logError(e, context: 'Load Conversations');
    }
  }

  /// Load messages for a conversation
  Future<void> loadMessages(String conversationId) async {
    try {
      setLoading('load_messages', true);
      _currentConversationId = conversationId;
      notifyListeners();

      final messages = await _apiService.getChatMessages(conversationId);
      _messages = messages;

      // Mark conversation as read
      await markConversationAsRead(conversationId);

      setLoading('load_messages', false);
      notifyListeners();
    } catch (e) {
      final error = ApiErrorHandler.handleApiError(e, context: 'Load Messages');
      setError('load_messages', error);
      setLoading('load_messages', false);
      notifyListeners();

      ApiErrorHandler.logError(e, context: 'Load Messages');
    }
  }

  /// Send a message
  Future<void> sendMessage(String content, {String? replyToMessageId}) async {
    if (_currentConversationId == null || content.trim().isEmpty) return;

    ChatMessage? message;
    try {
      message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: _currentConversationId!,
        senderId: 'current_user', // This should come from auth provider
        senderName: 'You', // This should come from auth provider
        content: content.trim(),
        status: MessageStatus.sending,
        createdAt: DateTime.now(),
      );

      // Add message optimistically
      _messages.add(message);
      notifyListeners();

      // Send via WebSocket
      _webSocketService.sendMessage(_currentConversationId!, content.trim());

      // Update message status to sent
      final messageIndex = _messages.indexWhere((m) => m.id == message!.id);
      if (messageIndex != -1) {
        _messages[messageIndex] = _messages[messageIndex].copyWith(
          status: MessageStatus.sent,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Send Message');

      // Update message status to failed
      if (message != null) {
        final messageIndex = _messages.indexWhere((m) => m.id == message!.id);
        if (messageIndex != -1) {
          _messages[messageIndex] = _messages[messageIndex].copyWith(
            status: MessageStatus.failed,
          );
          notifyListeners();
        }
      }
    }
  }

  /// Start typing indicator
  Future<void> startTyping() async {
    if (_currentConversationId == null || _isTyping) return;

    try {
      _isTyping = true;
      _webSocketService.sendMessage(_currentConversationId!, 'typing_start');
    } catch (e) {
      _isTyping = false;
    }
  }

  /// Stop typing indicator
  Future<void> stopTyping() async {
    if (_currentConversationId == null || !_isTyping) return;

    try {
      _isTyping = false;
      _webSocketService.sendMessage(_currentConversationId!, 'typing_stop');
    } catch (e) {
      _isTyping = false;
    }
  }

  /// Mark conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      await _apiService.markConversationAsRead(conversationId);

      // Update local state
      final conversationIndex = _conversations.indexWhere(
        (c) => c.id == conversationId,
      );

      if (conversationIndex != -1) {
        _conversations[conversationIndex] = _conversations[conversationIndex]
            .copyWith(unreadCount: 0);
        notifyListeners();
      }
    } catch (e) {
      print('Error marking conversation as read: $e');
    }
  }

  /// Load notifications
  Future<void> loadNotifications() async {
    try {
      final notifications = await _apiService.getChatNotifications();
      _notifications = notifications;
      notifyListeners();
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _apiService.markNotificationAsRead(notificationId);

      // Update local state
      final notificationIndex = _notifications.indexWhere(
        (n) => n.id == notificationId,
      );

      if (notificationIndex != -1) {
        _notifications[notificationIndex] = ChatNotification(
          id: _notifications[notificationIndex].id,
          type: _notifications[notificationIndex].type,
          title: _notifications[notificationIndex].title,
          content: _notifications[notificationIndex].content,
          referenceId: _notifications[notificationIndex].referenceId,
          isRead: true,
          createdAt: _notifications[notificationIndex].createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Create new conversation
  Future<ChatConversation?> createConversation({
    required String participantId,
    String? matchId,
    String? reportId,
  }) async {
    try {
      final conversation = await _apiService.createChatConversation(
        participantId: participantId,
        matchId: matchId,
        reportId: reportId,
      );

      _conversations.insert(0, conversation);
      notifyListeners();

      return conversation;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Create Conversation');
      notifyListeners();
      return null;
    }
  }

  /// Clear current conversation
  void clearCurrentConversation() {
    _currentConversationId = null;
    _messages.clear();
    _typingUsers.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    super.dispose();
  }
}

/// Chat state enum
enum ChatState { idle, loading, success, error }
