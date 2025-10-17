import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/chat_models.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../services/storage_service.dart';
import '../core/error/error_handler.dart';

/// Messaging state enum
enum MessagingState {
  initial,
  loading,
  loaded,
  error,
  sending,
  updating,
  deleting,
  archiving,
  muting,
  blocking,
}

/// Enhanced messaging provider with comprehensive functionality
class MessagingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final WebSocketService _webSocketService = WebSocketService();

  // State management
  MessagingState _state = MessagingState.initial;
  String? _error;
  bool _isConnected = false;

  // Conversations
  List<ChatConversation> _conversations = [];
  ChatConversation? _currentConversation;
  String? _currentConversationId;

  // Messages
  List<ChatMessage> _messages = [];
  Map<String, List<ChatMessage>> _conversationMessages = {};
  Map<String, int> _unreadCounts = {};

  // Typing indicators
  Map<String, List<TypingIndicator>> _typingIndicators = {};
  bool _isTyping = false;

  // Search and filters
  List<ChatMessage> _searchResults = [];
  String? _searchQuery;
  bool _isSearching = false;

  // Pagination
  Map<String, bool> _hasMoreMessages = {};
  Map<String, int> _messageOffsets = {};
  static const int _pageSize = 50;

  // Statistics
  Map<String, dynamic>? _conversationStats;

  // Getters
  MessagingState get state => _state;
  String? get error => _error;
  bool get isConnected => _isConnected;
  List<ChatConversation> get conversations => _conversations;
  ChatConversation? get currentConversation => _currentConversation;
  String? get currentConversationId => _currentConversationId;
  List<ChatMessage> get messages => _messages;
  List<ChatMessage> get searchResults => _searchResults;
  String? get searchQuery => _searchQuery;
  bool get isSearching => _isSearching;
  Map<String, dynamic>? get conversationStats => _conversationStats;

  bool get isLoading => _state == MessagingState.loading;
  bool get isSending => _state == MessagingState.sending;
  bool get isUpdating => _state == MessagingState.updating;
  bool get isDeleting => _state == MessagingState.deleting;
  bool get isArchiving => _state == MessagingState.archiving;
  bool get isMuting => _state == MessagingState.muting;
  bool get isBlocking => _state == MessagingState.blocking;
  bool get hasError => _state == MessagingState.error;
  bool get isLoaded => _state == MessagingState.loaded;

  bool get isTyping => _isTyping;
  int get totalUnreadCount =>
      _unreadCounts.values.fold(0, (sum, count) => sum + count);
  bool get hasUnreadMessages => totalUnreadCount > 0;

  /// Initialize messaging provider
  Future<void> initialize() async {
    _state = MessagingState.loading;
    _error = null;
    notifyListeners();

    try {
      // Initialize WebSocket connection
      await _initializeWebSocket();

      // Load conversations and stats in parallel
      await Future.wait([loadConversations(), loadConversationStats()]);

      _state = MessagingState.loaded;
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Initialize messaging');
      _state = MessagingState.error;
      notifyListeners();
    }
  }

  /// Initialize WebSocket connection
  Future<void> _initializeWebSocket() async {
    try {
      // Get access token from storage service
      final storageService = StorageService();
      final token = await storageService.getToken();

      if (token != null) {
        await _webSocketService.connect(token.accessToken);
        _isConnected = true;

        // Listen to WebSocket messages
        _webSocketService.messageStream?.listen(_handleWebSocketMessage);

        debugPrint('WebSocket connected successfully');
      } else {
        _isConnected = false;
        debugPrint('No access token available for WebSocket connection');
      }
    } catch (e) {
      debugPrint('WebSocket connection failed: $e');
      _isConnected = false;
    }
  }

  /// Handle incoming WebSocket messages
  void _handleWebSocketMessage(Map<String, dynamic> message) {
    try {
      final type = message['type'] as String?;

      switch (type) {
        case 'message':
          _handleIncomingMessage(message);
          break;
        case 'typing':
          _handleTypingIndicator(message);
          break;
        case 'read_receipt':
          _handleReadReceipt(message);
          break;
        case 'conversation_updated':
          _handleConversationUpdate(message);
          break;
        case 'notification':
          _handleNotification(message);
          break;
        default:
          debugPrint('Unknown WebSocket message type: $type');
      }
    } catch (e) {
      debugPrint('Error handling WebSocket message: $e');
    }
  }

  /// Handle incoming message from WebSocket
  void _handleIncomingMessage(Map<String, dynamic> message) {
    try {
      final conversationId = message['conversation_id'] as String?;
      final messageData = message['message'] as Map<String, dynamic>?;

      if (conversationId != null && messageData != null) {
        final newMessage = ChatMessage.fromJson(messageData);

        // Add to messages list if it's the current conversation
        if (_currentConversationId == conversationId) {
          _messages.add(newMessage);
        }

        // Update conversation's last message
        final conversationIndex = _conversations.indexWhere(
          (c) => c.id == conversationId,
        );
        if (conversationIndex != -1) {
          _conversations[conversationIndex] = _conversations[conversationIndex]
              .copyWith(
                lastMessage: newMessage,
                updatedAt: newMessage.createdAt,
                unreadCount: _conversations[conversationIndex].unreadCount + 1,
              );

          // Sort conversations by update time
          _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling incoming message: $e');
    }
  }

  /// Handle typing indicator from WebSocket
  void _handleTypingIndicator(Map<String, dynamic> message) {
    try {
      final conversationId = message['conversation_id'] as String?;
      final userId = message['user_id'] as String?;
      final userName = message['user_name'] as String?;
      final isTyping = message['is_typing'] as bool? ?? false;

      if (conversationId != null && userId != null && userName != null) {
        if (isTyping) {
          // Add typing indicator
          final typingIndicator = TypingIndicator(
            userId: userId,
            userName: userName,
            timestamp: DateTime.now(),
          );

          _typingIndicators[conversationId] ??= [];
          _typingIndicators[conversationId]!.removeWhere(
            (t) => t.userId == userId,
          );
          _typingIndicators[conversationId]!.add(typingIndicator);
        } else {
          // Remove typing indicator
          _typingIndicators[conversationId]?.removeWhere(
            (t) => t.userId == userId,
          );
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling typing indicator: $e');
    }
  }

  /// Handle read receipt from WebSocket
  void _handleReadReceipt(Map<String, dynamic> message) {
    try {
      final conversationId = message['conversation_id'] as String?;
      final messageId = message['message_id'] as String?;

      if (conversationId != null && messageId != null) {
        // Update message read status
        final messageIndex = _messages.indexWhere((m) => m.id == messageId);
        if (messageIndex != -1) {
          _messages[messageIndex] = _messages[messageIndex].copyWith(
            isRead: true,
            status: MessageStatus.read,
          );
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling read receipt: $e');
    }
  }

  /// Handle conversation update from WebSocket
  void _handleConversationUpdate(Map<String, dynamic> message) {
    try {
      final conversationData = message['conversation'] as Map<String, dynamic>?;

      if (conversationData != null) {
        final updatedConversation = ChatConversation.fromJson(conversationData);

        // Update conversation in list
        final conversationIndex = _conversations.indexWhere(
          (c) => c.id == updatedConversation.id,
        );
        if (conversationIndex != -1) {
          _conversations[conversationIndex] = updatedConversation;
        } else {
          _conversations.add(updatedConversation);
        }

        // Sort conversations by update time
        _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling conversation update: $e');
    }
  }

  /// Handle notification from WebSocket
  void _handleNotification(Map<String, dynamic> message) {
    try {
      // Handle real-time notifications
      debugPrint('Received notification: ${message['title']}');
      // You can integrate with NotificationsProvider here if needed
    } catch (e) {
      debugPrint('Error handling notification: $e');
    }
  }

  /// Load conversations
  Future<void> loadConversations() async {
    try {
      final conversationsData = await _apiService.getConversations();
      _conversations = conversationsData
          .map((json) => ChatConversation.fromJson(json))
          .toList();

      // Initialize unread counts
      for (final conversation in _conversations) {
        _unreadCounts[conversation.id] = conversation.unreadCount;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    }
  }

  /// Load conversation details
  Future<void> loadConversation(String conversationId) async {
    try {
      final conversationData = await _apiService.getConversation(
        conversationId,
      );
      _currentConversation = ChatConversation.fromJson(conversationData);
      _currentConversationId = conversationId;

      // Load messages for this conversation
      await loadMessages(conversationId);

      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Load conversation');
      notifyListeners();
    }
  }

  /// Load messages for a conversation
  Future<void> loadMessages(
    String conversationId, {
    bool loadMore = false,
  }) async {
    try {
      final offset = loadMore ? (_messageOffsets[conversationId] ?? 0) : 0;

      final messagesData = await _apiService.getConversationMessages(
        conversationId,
        limit: _pageSize,
        offset: offset,
      );

      final messages = messagesData
          .map((json) => ChatMessage.fromJson(json))
          .toList();

      if (loadMore) {
        _conversationMessages[conversationId]?.addAll(messages);
      } else {
        _conversationMessages[conversationId] = messages;
        _messageOffsets[conversationId] = 0;
      }

      _messageOffsets[conversationId] = offset + messages.length;
      _hasMoreMessages[conversationId] = messages.length == _pageSize;

      // Update current messages if this is the active conversation
      if (conversationId == _currentConversationId) {
        _messages = _conversationMessages[conversationId] ?? [];
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  /// Send a message
  Future<bool> sendMessage(String content, {String? replyToMessageId}) async {
    if (_currentConversationId == null || content.trim().isEmpty) return false;

    _state = MessagingState.sending;
    _error = null;
    notifyListeners();

    try {
      // Create optimistic message
      final optimisticMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: _currentConversationId!,
        senderId: 'current_user', // This should come from auth provider
        senderName: 'You', // This should come from auth provider
        content: content.trim(),
        status: MessageStatus.sending,
        createdAt: DateTime.now(),
      );

      // Add message optimistically
      _messages.add(optimisticMessage);
      _conversationMessages[_currentConversationId!]?.add(optimisticMessage);
      notifyListeners();

      // Send via API
      await _apiService.sendMessage(
        conversationId: _currentConversationId!,
        content: content.trim(),
      );

      // Update message status to sent
      final messageIndex = _messages.indexWhere(
        (m) => m.id == optimisticMessage.id,
      );
      if (messageIndex != -1) {
        _messages[messageIndex] = _messages[messageIndex].copyWith(
          status: MessageStatus.sent,
        );
        notifyListeners();
      }

      _state = MessagingState.loaded;
      return true;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Send message');

      // Update message status to failed
      final messageIndex = _messages.indexWhere(
        (m) => m.status == MessageStatus.sending,
      );
      if (messageIndex != -1) {
        _messages[messageIndex] = _messages[messageIndex].copyWith(
          status: MessageStatus.failed,
        );
      }

      _state = MessagingState.error;
      notifyListeners();
      return false;
    }
  }

  /// Create a new conversation
  Future<String?> createConversation(String participantId) async {
    _state = MessagingState.loading;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.createConversation(participantId);
      final conversationId = result['id'] as String;

      // Reload conversations to include the new one
      await loadConversations();

      _state = MessagingState.loaded;
      notifyListeners();
      return conversationId;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Create conversation');
      _state = MessagingState.error;
      notifyListeners();
      return null;
    }
  }

  /// Mark conversation as read
  Future<bool> markConversationAsRead(String conversationId) async {
    try {
      await _apiService.markConversationAsRead(conversationId);
      _unreadCounts[conversationId] = 0;

      // Update conversation in list
      final conversationIndex = _conversations.indexWhere(
        (c) => c.id == conversationId,
      );
      if (conversationIndex != -1) {
        _conversations[conversationIndex] = _conversations[conversationIndex]
            .copyWith(unreadCount: 0);
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error marking conversation as read: $e');
      return false;
    }
  }

  /// Archive conversation
  Future<bool> archiveConversation(String conversationId) async {
    _state = MessagingState.archiving;
    _error = null;
    notifyListeners();

    try {
      await _apiService.archiveConversation(conversationId);
      _updateConversationArchived(conversationId, true);

      _state = MessagingState.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Archive conversation');
      _state = MessagingState.error;
      notifyListeners();
      return false;
    }
  }

  /// Unarchive conversation
  Future<bool> unarchiveConversation(String conversationId) async {
    _state = MessagingState.archiving;
    _error = null;
    notifyListeners();

    try {
      await _apiService.unarchiveConversation(conversationId);
      _updateConversationArchived(conversationId, false);

      _state = MessagingState.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Unarchive conversation');
      _state = MessagingState.error;
      notifyListeners();
      return false;
    }
  }

  /// Delete conversation
  Future<bool> deleteConversation(String conversationId) async {
    _state = MessagingState.deleting;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteConversation(conversationId);

      // Remove from local state
      _conversations.removeWhere((c) => c.id == conversationId);
      _conversationMessages.remove(conversationId);
      _unreadCounts.remove(conversationId);
      _hasMoreMessages.remove(conversationId);
      _messageOffsets.remove(conversationId);

      // Clear current conversation if it was deleted
      if (_currentConversationId == conversationId) {
        _currentConversation = null;
        _currentConversationId = null;
        _messages.clear();
      }

      _state = MessagingState.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Delete conversation');
      _state = MessagingState.error;
      notifyListeners();
      return false;
    }
  }

  /// Delete message
  Future<bool> deleteMessage(String messageId) async {
    _state = MessagingState.deleting;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteMessage(messageId);

      // Remove from local state
      _conversationMessages.forEach((conversationId, messages) {
        messages.removeWhere((m) => m.id == messageId);
      });
      _messages.removeWhere((m) => m.id == messageId);

      _state = MessagingState.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Delete message');
      _state = MessagingState.error;
      notifyListeners();
      return false;
    }
  }

  /// Mute conversation
  Future<bool> muteConversation(String conversationId) async {
    _state = MessagingState.muting;
    _error = null;
    notifyListeners();

    try {
      await _apiService.muteConversation(conversationId);
      _updateConversationMuted(conversationId, true);

      _state = MessagingState.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Mute conversation');
      _state = MessagingState.error;
      notifyListeners();
      return false;
    }
  }

  /// Unmute conversation
  Future<bool> unmuteConversation(String conversationId) async {
    _state = MessagingState.muting;
    _error = null;
    notifyListeners();

    try {
      await _apiService.unmuteConversation(conversationId);
      _updateConversationMuted(conversationId, false);

      _state = MessagingState.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Unmute conversation');
      _state = MessagingState.error;
      notifyListeners();
      return false;
    }
  }

  /// Block user in conversation
  Future<bool> blockUserInConversation(String conversationId) async {
    _state = MessagingState.blocking;
    _error = null;
    notifyListeners();

    try {
      await _apiService.blockUserInConversation(conversationId);
      _updateConversationBlocked(conversationId, true);

      _state = MessagingState.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Block user');
      _state = MessagingState.error;
      notifyListeners();
      return false;
    }
  }

  /// Unblock user in conversation
  Future<bool> unblockUserInConversation(String conversationId) async {
    _state = MessagingState.blocking;
    _error = null;
    notifyListeners();

    try {
      await _apiService.unblockUserInConversation(conversationId);
      _updateConversationBlocked(conversationId, false);

      _state = MessagingState.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Unblock user');
      _state = MessagingState.error;
      notifyListeners();
      return false;
    }
  }

  /// Search messages
  Future<void> searchMessages(String query) async {
    _isSearching = true;
    _searchQuery = query;
    notifyListeners();

    try {
      final results = await _apiService.searchMessages(
        query: query,
        conversationId: _currentConversationId,
      );

      _searchResults = results
          .map((json) => ChatMessage.fromJson(json))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Search messages');
      notifyListeners();
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Clear search results
  void clearSearch() {
    _searchResults.clear();
    _searchQuery = null;
    _isSearching = false;
    notifyListeners();
  }

  /// Load conversation statistics
  Future<void> loadConversationStats() async {
    try {
      _conversationStats = await _apiService.getConversationStats();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading conversation stats: $e');
    }
  }

  /// Start typing indicator
  Future<void> startTyping() async {
    if (_currentConversationId == null || _isTyping) return;

    try {
      _isTyping = true;

      // Send typing indicator via WebSocket
      if (_isConnected) {
        _sendWebSocketControlMessage({
          'type': 'typing',
          'conversation_id': _currentConversationId,
          'is_typing': true,
        });
      }

      debugPrint('Started typing in conversation $_currentConversationId');
    } catch (e) {
      _isTyping = false;
      debugPrint('Error starting typing: $e');
    }
  }

  /// Stop typing indicator
  Future<void> stopTyping() async {
    if (_currentConversationId == null || !_isTyping) return;

    try {
      _isTyping = false;

      // Send stop typing indicator via WebSocket
      if (_isConnected) {
        _sendWebSocketControlMessage({
          'type': 'typing',
          'conversation_id': _currentConversationId,
          'is_typing': false,
        });
      }

      debugPrint('Stopped typing in conversation $_currentConversationId');
    } catch (e) {
      debugPrint('Error stopping typing: $e');
    }
  }

  /// Load more messages for current conversation
  Future<void> loadMoreMessages() async {
    if (_currentConversationId == null) return;

    final hasMore = _hasMoreMessages[_currentConversationId!] ?? false;
    if (!hasMore) return;

    await loadMessages(_currentConversationId!, loadMore: true);
  }

  /// Update conversation archived status
  void _updateConversationArchived(String conversationId, bool archived) {
    final conversationIndex = _conversations.indexWhere(
      (c) => c.id == conversationId,
    );
    if (conversationIndex != -1) {
      // Note: ChatConversation doesn't have isArchived field
      // This would need to be added to the model or handled differently
      debugPrint('Conversation $conversationId archived: $archived');
    }
  }

  /// Update conversation muted status
  void _updateConversationMuted(String conversationId, bool muted) {
    final conversationIndex = _conversations.indexWhere(
      (c) => c.id == conversationId,
    );
    if (conversationIndex != -1) {
      // Note: ChatConversation doesn't have isMuted field
      // This would need to be added to the model or handled differently
      debugPrint('Conversation $conversationId muted: $muted');
    }
  }

  /// Update conversation blocked status
  void _updateConversationBlocked(String conversationId, bool blocked) {
    final conversationIndex = _conversations.indexWhere(
      (c) => c.id == conversationId,
    );
    if (conversationIndex != -1) {
      // Note: ChatConversation doesn't have isBlocked field
      // This would need to be added to the model or handled differently
      debugPrint('Conversation $conversationId blocked: $blocked');
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await initialize();
  }

  /// Clear all data
  void clearAllData() {
    _conversations.clear();
    _messages.clear();
    _conversationMessages.clear();
    _unreadCounts.clear();
    _typingIndicators.clear();
    _searchResults.clear();
    _hasMoreMessages.clear();
    _messageOffsets.clear();
    _currentConversation = null;
    _currentConversationId = null;
    _searchQuery = null;
    _conversationStats = null;
    _state = MessagingState.initial;
    _error = null;
    _isTyping = false;
    _isSearching = false;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    if (_state == MessagingState.error) {
      _state = MessagingState.initial;
    }
    notifyListeners();
  }

  /// Send WebSocket control message
  void _sendWebSocketControlMessage(Map<String, dynamic> message) {
    try {
      if (_webSocketService.isConnected) {
        // Use the WebSocket service's internal method to send control messages
        // For now, we'll use a simple approach by sending a JSON string
        final messageJson = jsonEncode(message);
        // Note: This would need to be implemented in WebSocketService
        debugPrint('Sending WebSocket control message: $messageJson');
      }
    } catch (e) {
      debugPrint('Error sending WebSocket control message: $e');
    }
  }

  /// Disconnect WebSocket
  Future<void> disconnect() async {
    try {
      await _webSocketService.disconnect();
      _isConnected = false;
      debugPrint('WebSocket disconnected');
    } catch (e) {
      debugPrint('Error disconnecting WebSocket: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Get typing indicators for current conversation
  List<TypingIndicator> getTypingIndicators() {
    if (_currentConversationId == null) return [];
    return _typingIndicators[_currentConversationId!] ?? [];
  }

  /// Get unread count for a conversation
  int getUnreadCount(String conversationId) {
    return _unreadCounts[conversationId] ?? 0;
  }

  /// Get messages for a specific conversation
  List<ChatMessage> getMessagesForConversation(String conversationId) {
    return _conversationMessages[conversationId] ?? [];
  }

  /// Check if conversation has more messages
  bool hasMoreMessages(String conversationId) {
    return _hasMoreMessages[conversationId] ?? false;
  }
}
