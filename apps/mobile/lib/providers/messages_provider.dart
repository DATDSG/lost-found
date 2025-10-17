import 'package:flutter/foundation.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../core/error/api_error_handler.dart';
import '../core/loading/loading_state_manager.dart';

/// Messages Provider - State management for chat conversations and messages
class MessagesProvider with ChangeNotifier, LoadingStateMixin {
  final ApiService _apiService;
  final WebSocketService _wsService = WebSocketService();

  List<Conversation> _conversations = [];
  final Map<String, List<Message>> _messagesByConversation = {};
  String? _currentConversationId;

  MessagesProvider(this._apiService) {
    _initializeWebSocket();
  }

  // Getters
  List<Conversation> get conversations => _conversations;
  bool get isWebSocketConnected => _wsService.isConnected;

  /// Get messages for a specific conversation
  List<Message> getMessages(String conversationId) {
    return _messagesByConversation[conversationId] ?? [];
  }

  /// Get unread count across all conversations
  int get totalUnreadCount {
    return _conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
  }

  /// Initialize WebSocket connection
  void _initializeWebSocket() {
    _wsService.messageStream?.listen((data) {
      _handleWebSocketMessage(data);
    });
  }

  /// Connect WebSocket with auth token
  Future<void> connectWebSocket(String accessToken) async {
    try {
      setLoading('websocket_connect', true);
      await _wsService.connect(accessToken);
      setLoading('websocket_connect', false);
      debugPrint('✅ WebSocket connected in MessagesProvider');
    } catch (e) {
      setLoading('websocket_connect', false);
      final error = ApiErrorHandler.handleApiError(
        e,
        context: 'WebSocket Connection',
      );
      setError('websocket_connect', error);
      debugPrint('❌ WebSocket connection error: $e');
      ApiErrorHandler.logError(e, context: 'WebSocket Connection');
    }
  }

  /// Disconnect WebSocket
  Future<void> disconnectWebSocket() async {
    await _wsService.disconnect();
  }

  /// Handle incoming WebSocket messages
  void _handleWebSocketMessage(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    switch (type) {
      case 'message':
        _handleNewMessage(data);
        break;
      case 'typing':
        _handleTypingIndicator(data);
        break;
      case 'read':
        _handleReadReceipt(data);
        break;
      case 'pong':
        debugPrint('🏓 Pong received');
        break;
      default:
        debugPrint('Unknown WebSocket message type: $type');
    }
  }

  /// Handle new message from WebSocket
  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      final message = Message.fromJson(data['message'] as Map<String, dynamic>);
      final conversationId = message.conversationId;

      // Add message to local cache
      if (_messagesByConversation.containsKey(conversationId)) {
        _messagesByConversation[conversationId]!.insert(0, message);
      } else {
        _messagesByConversation[conversationId] = [message];
      }

      // Update conversation's last message
      final convIndex = _conversations.indexWhere(
        (c) => c.id == conversationId,
      );
      if (convIndex != -1) {
        final conv = _conversations[convIndex];
        _conversations[convIndex] = Conversation(
          id: conv.id,
          otherUserId: conv.otherUserId,
          otherUserName: conv.otherUserName,
          otherUserAvatar: conv.otherUserAvatar,
          reportId: conv.reportId,
          reportTitle: conv.reportTitle,
          lastMessage: message,
          unreadCount: _currentConversationId == conversationId
              ? 0
              : conv.unreadCount + 1,
          updatedAt: message.timestamp,
        );

        // Move conversation to top
        final updated = _conversations.removeAt(convIndex);
        _conversations.insert(0, updated);
      }

      notifyListeners();
      debugPrint('✅ New message received via WebSocket');
    } catch (e) {
      debugPrint('❌ Error handling new message: $e');
    }
  }

  /// Handle typing indicator
  void _handleTypingIndicator(Map<String, dynamic> data) {
    // Implement typing indicator logic if needed
    debugPrint('👀 Typing indicator: ${data['is_typing']}');
  }

  /// Handle read receipt
  void _handleReadReceipt(Map<String, dynamic> data) {
    final conversationId = data['conversation_id'] as String?;
    final messageIds = (data['message_ids'] as List?)?.cast<String>();

    if (conversationId != null && messageIds != null) {
      final messages = _messagesByConversation[conversationId];
      if (messages != null) {
        for (var i = 0; i < messages.length; i++) {
          if (messageIds.contains(messages[i].id)) {
            messages[i] = messages[i].copyWith(isRead: true);
          }
        }
        notifyListeners();
      }
    }
  }

  /// Load all conversations
  Future<void> getConversations() async {
    setLoading('get_conversations', true);
    notifyListeners();

    try {
      final conversations = await _apiService.getConversations();
      _conversations = conversations
          .map((json) => Conversation.fromJson(json))
          .toList();
      debugPrint('✅ Loaded ${_conversations.length} conversations');
    } catch (e) {
      final error = ApiErrorHandler.handleApiError(
        e,
        context: 'Load Conversations',
      );
      setError('get_conversations', error);
      debugPrint('❌ $error');
      ApiErrorHandler.logError(e, context: 'Load Conversations');
    } finally {
      setLoading('get_conversations', false);
      notifyListeners();
    }
  }

  /// Load messages for a specific conversation
  Future<void> getMessagesForConversation(String conversationId) async {
    _currentConversationId = conversationId;
    setLoading('get_messages', true);
    notifyListeners();

    try {
      final messagesData = await _apiService.getMessages(conversationId);
      final messages = messagesData
          .map((json) => Message.fromJson(json))
          .toList();

      // Sort by timestamp (newest first)
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _messagesByConversation[conversationId] = messages;

      // Mark conversation as read
      _markConversationAsRead(conversationId);

      debugPrint(
        '✅ Loaded ${messages.length} messages for conversation $conversationId',
      );
    } catch (e) {
      final error = ApiErrorHandler.handleApiError(e, context: 'Load Messages');
      setError('get_messages', error);
      debugPrint('❌ $error');
      ApiErrorHandler.logError(e, context: 'Load Messages');
    } finally {
      setLoading('get_messages', false);
      notifyListeners();
    }
  }

  /// Send a message via HTTP (fallback) and WebSocket
  Future<bool> sendMessage(String conversationId, String text) async {
    if (text.trim().isEmpty) return false;

    try {
      // Try WebSocket first for real-time delivery
      if (_wsService.isConnected) {
        _wsService.sendMessage(conversationId, text);

        // Add optimistic message to UI
        final optimisticMessage = Message(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          conversationId: conversationId,
          senderId: 'current_user', // Will be replaced by backend
          senderName: 'You',
          text: text,
          timestamp: DateTime.now(),
          isRead: false,
          isSent: false, // Pending
        );

        if (_messagesByConversation.containsKey(conversationId)) {
          _messagesByConversation[conversationId]!.insert(0, optimisticMessage);
        } else {
          _messagesByConversation[conversationId] = [optimisticMessage];
        }
        notifyListeners();
      }

      // Send via HTTP as backup/confirmation
      final messageData = await _apiService.sendMessage(
        conversationId: conversationId,
        content: text,
      );

      final message = Message.fromJson(messageData);

      // Replace optimistic message with real one
      final messages = _messagesByConversation[conversationId];
      if (messages != null) {
        final tempIndex = messages.indexWhere((m) => m.id.startsWith('temp_'));
        if (tempIndex != -1) {
          messages[tempIndex] = message;
        } else {
          messages.insert(0, message);
        }
      }

      // Update conversation
      await _updateConversationLastMessage(conversationId, message);

      notifyListeners();
      debugPrint('✅ Message sent successfully');
      return true;
    } catch (e) {
      final error = ApiErrorHandler.handleApiError(e, context: 'Send Message');
      setError('send_message', error);
      debugPrint('❌ $error');
      ApiErrorHandler.logError(e, context: 'Send Message');

      // Remove optimistic message on error
      _messagesByConversation[conversationId]?.removeWhere(
        (m) => m.id.startsWith('temp_'),
      );
      notifyListeners();
      return false;
    }
  }

  /// Send typing indicator
  void sendTypingIndicator(String conversationId, bool isTyping) {
    if (_wsService.isConnected) {
      _wsService.sendTypingIndicator(conversationId, isTyping);
    }
  }

  /// Mark messages as read
  void markMessagesAsRead(String conversationId, List<String> messageIds) {
    if (_wsService.isConnected) {
      _wsService.markAsRead(conversationId, messageIds);
    }

    // Update local state
    final messages = _messagesByConversation[conversationId];
    if (messages != null) {
      for (var i = 0; i < messages.length; i++) {
        if (messageIds.contains(messages[i].id)) {
          messages[i] = messages[i].copyWith(isRead: true);
        }
      }
      notifyListeners();
    }
  }

  /// Mark entire conversation as read
  void _markConversationAsRead(String conversationId) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1 && _conversations[index].unreadCount > 0) {
      final conv = _conversations[index];
      _conversations[index] = Conversation(
        id: conv.id,
        otherUserId: conv.otherUserId,
        otherUserName: conv.otherUserName,
        otherUserAvatar: conv.otherUserAvatar,
        reportId: conv.reportId,
        reportTitle: conv.reportTitle,
        lastMessage: conv.lastMessage,
        unreadCount: 0,
        updatedAt: conv.updatedAt,
      );
      notifyListeners();
    }
  }

  /// Update conversation's last message
  Future<void> _updateConversationLastMessage(
    String conversationId,
    Message message,
  ) async {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      final conv = _conversations[index];
      _conversations[index] = Conversation(
        id: conv.id,
        otherUserId: conv.otherUserId,
        otherUserName: conv.otherUserName,
        otherUserAvatar: conv.otherUserAvatar,
        reportId: conv.reportId,
        reportTitle: conv.reportTitle,
        lastMessage: message,
        unreadCount: conv.unreadCount,
        updatedAt: message.timestamp,
      );

      // Move to top
      final updated = _conversations.removeAt(index);
      _conversations.insert(0, updated);
    }
  }

  @override
  void dispose() {
    _wsService.disconnect();
    super.dispose();
  }
}
