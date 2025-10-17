import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';

/// WebSocket Service - Manages WebSocket connections for real-time messaging
class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  String? _accessToken;
  bool _isConnected = false;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  // Singleton pattern
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  bool get isConnected => _isConnected;
  Stream<Map<String, dynamic>>? get messageStream => _messageController?.stream;

  /// Connect to WebSocket server
  Future<void> connect(String accessToken) async {
    if (_isConnected) {
      debugPrint('WebSocket already connected');
      return;
    }

    _accessToken = accessToken;
    _messageController = StreamController<Map<String, dynamic>>.broadcast();

    try {
      final wsUrl =
          '${ApiConfig.wsBaseUrl}${ApiConfig.wsChat}?token=$accessToken';
      debugPrint('🔌 Connecting to WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;
      _reconnectAttempts = 0;

      // Listen to messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      // Start ping timer to keep connection alive
      _startPingTimer();

      debugPrint('✅ WebSocket connected successfully');
    } catch (e) {
      debugPrint('❌ WebSocket connection error: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  /// Handle incoming messages
  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      debugPrint('📨 WebSocket message received: ${data['type']}');
      _messageController?.add(data);
    } catch (e) {
      debugPrint('❌ Error parsing WebSocket message: $e');
    }
  }

  /// Handle WebSocket errors
  void _onError(dynamic error) {
    debugPrint('❌ WebSocket error: $error');
    _isConnected = false;
    _scheduleReconnect();
  }

  /// Handle WebSocket closure
  void _onDone() {
    debugPrint('🔌 WebSocket connection closed');
    _isConnected = false;
    _scheduleReconnect();
  }

  /// Join a conversation
  void joinConversation(String conversationId) {
    if (!_isConnected || _channel == null) {
      debugPrint('⚠️ Cannot join conversation: WebSocket not connected');
      return;
    }

    try {
      final message = jsonEncode({
        'type': 'join',
        'conversation_id': conversationId,
      });

      _channel!.sink.add(message);
      debugPrint('🚪 Joined conversation: $conversationId');
    } catch (e) {
      debugPrint('❌ Error joining conversation: $e');
    }
  }

  /// Leave a conversation
  void leaveConversation(String conversationId) {
    if (!_isConnected || _channel == null) return;

    try {
      final message = jsonEncode({
        'type': 'leave',
        'conversation_id': conversationId,
      });

      _channel!.sink.add(message);
      debugPrint('🚪 Left conversation: $conversationId');
    } catch (e) {
      debugPrint('❌ Error leaving conversation: $e');
    }
  }

  /// Send a message through WebSocket
  void sendMessage(String conversationId, String content) {
    if (!_isConnected || _channel == null) {
      debugPrint('⚠️ Cannot send message: WebSocket not connected');
      return;
    }

    try {
      final message = jsonEncode({
        'type': 'message',
        'conversation_id': conversationId,
        'content': content,
      });

      _channel!.sink.add(message);
      debugPrint('📤 Message sent via WebSocket');
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
    }
  }

  /// Send typing indicator
  void sendTypingIndicator(String conversationId, bool isTyping) {
    if (!_isConnected || _channel == null) return;

    try {
      final message = jsonEncode({
        'type': 'typing',
        'conversation_id': conversationId,
        'is_typing': isTyping,
      });

      _channel!.sink.add(message);
    } catch (e) {
      debugPrint('❌ Error sending typing indicator: $e');
    }
  }

  /// Mark messages as read
  void markAsRead(String conversationId, List<String> messageIds) {
    if (!_isConnected || _channel == null) return;

    try {
      final message = jsonEncode({
        'type': 'read',
        'conversation_id': conversationId,
        'message_ids': messageIds,
      });

      _channel!.sink.add(message);
      debugPrint('✅ Marked ${messageIds.length} messages as read');
    } catch (e) {
      debugPrint('❌ Error marking messages as read: $e');
    }
  }

  /// Start ping timer to keep connection alive
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected && _channel != null) {
        try {
          _channel!.sink.add(jsonEncode({'type': 'ping'}));
          debugPrint('🏓 Ping sent');
        } catch (e) {
          debugPrint('❌ Error sending ping: $e');
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('❌ Max reconnect attempts reached. Giving up.');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      _reconnectAttempts++;
      debugPrint(
        '🔄 Reconnect attempt $_reconnectAttempts/$_maxReconnectAttempts',
      );
      if (_accessToken != null) {
        connect(_accessToken!);
      }
    });
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    debugPrint('🔌 Disconnecting WebSocket');
    _isConnected = false;
    _reconnectAttempts = 0;

    _pingTimer?.cancel();
    _reconnectTimer?.cancel();

    try {
      await _channel?.sink.close();
    } catch (e) {
      debugPrint('❌ Error closing WebSocket: $e');
    }

    await _messageController?.close();
    _channel = null;
    _messageController = null;

    debugPrint('✅ WebSocket disconnected');
  }

  /// Reset reconnection attempts (call after successful manual reconnection)
  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
  }
}
