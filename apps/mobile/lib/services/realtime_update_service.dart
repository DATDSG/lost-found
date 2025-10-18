import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../config/api_config.dart';

class WebSocketService {
  static WebSocketService? _instance;
  static WebSocketService get instance => _instance ??= WebSocketService._();

  WebSocketService._();

  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  bool _isConnected = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  Stream<Map<String, dynamic>> get messageStream {
    _messageController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _messageController!.stream;
  }

  bool get isConnected => _isConnected;

  /// Connect to WebSocket server
  Future<void> connect({String? token}) async {
    if (_isConnecting || _isConnected) return;

    _isConnecting = true;

    try {
      final wsUrl = _buildWebSocketUrl(token);
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Listen to messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );

      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;

      // Start heartbeat
      _startHeartbeat();

      print('WebSocket connected successfully');
    } catch (e) {
      _isConnecting = false;
      _handleError(e);
    }
  }

  /// Disconnect from WebSocket server
  Future<void> disconnect() async {
    _stopHeartbeat();
    _stopReconnectTimer();

    if (_channel != null) {
      await _channel!.sink.close(status.goingAway);
      _channel = null;
    }

    _isConnected = false;
    _isConnecting = false;

    print('WebSocket disconnected');
  }

  /// Send message through WebSocket
  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(json.encode(message));
      } catch (e) {
        print('Error sending WebSocket message: $e');
      }
    }
  }

  /// Send heartbeat ping
  void _sendHeartbeat() {
    sendMessage({
      'type': 'ping',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Handle incoming messages
  void _handleMessage(dynamic data) {
    try {
      final message = json.decode(data.toString());
      _messageController?.add(Map<String, dynamic>.from(message));
    } catch (e) {
      print('Error parsing WebSocket message: $e');
    }
  }

  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    print('WebSocket error: $error');
    _isConnected = false;
    _isConnecting = false;

    if (_reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    }
  }

  /// Handle disconnection
  void _handleDisconnection() {
    print('WebSocket disconnected');
    _isConnected = false;
    _isConnecting = false;

    if (_reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    }
  }

  /// Schedule reconnection
  void _scheduleReconnect() {
    _reconnectAttempts++;
    _reconnectTimer = Timer(_reconnectDelay, () {
      print('Attempting to reconnect... (attempt $_reconnectAttempts)');
      connect();
    });
  }

  /// Start heartbeat timer
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _sendHeartbeat();
    });
  }

  /// Stop heartbeat timer
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Stop reconnect timer
  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// Build WebSocket URL
  String _buildWebSocketUrl(String? token) {
    final baseUrl = ApiConfig.baseUrl.replaceFirst('http', 'ws');
    final wsUrl = '$baseUrl/ws';

    if (token != null) {
      return '$wsUrl?token=$token';
    }

    return wsUrl;
  }

  /// Subscribe to specific event types
  Stream<Map<String, dynamic>> subscribeToEvent(String eventType) {
    return messageStream.where((message) {
      return message['type'] == eventType;
    });
  }

  /// Subscribe to notifications
  Stream<Map<String, dynamic>> get notificationsStream {
    return subscribeToEvent('notification');
  }

  /// Subscribe to chat messages
  Stream<Map<String, dynamic>> get chatMessagesStream {
    return subscribeToEvent('chat_message');
  }

  /// Subscribe to item updates
  Stream<Map<String, dynamic>> get itemUpdatesStream {
    return subscribeToEvent('item_update');
  }

  /// Subscribe to match updates
  Stream<Map<String, dynamic>> get matchUpdatesStream {
    return subscribeToEvent('match_update');
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _messageController?.close();
    _messageController = null;
  }
}

class RealtimeUpdateService {
  static RealtimeUpdateService? _instance;
  static RealtimeUpdateService get instance =>
      _instance ??= RealtimeUpdateService._();

  RealtimeUpdateService._();

  final WebSocketService _wsService = WebSocketService.instance;
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;
  StreamSubscription<Map<String, dynamic>>? _chatSubscription;
  StreamSubscription<Map<String, dynamic>>? _itemUpdateSubscription;
  StreamSubscription<Map<String, dynamic>>? _matchUpdateSubscription;

  /// Initialize real-time updates
  Future<void> initialize({String? token}) async {
    await _wsService.connect(token: token);
    _setupSubscriptions();
  }

  /// Setup event subscriptions
  void _setupSubscriptions() {
    // Subscribe to notifications
    _notificationSubscription =
        _wsService.notificationsStream.listen(_handleNotification);

    // Subscribe to chat messages
    _chatSubscription =
        _wsService.chatMessagesStream.listen(_handleChatMessage);

    // Subscribe to item updates
    _itemUpdateSubscription =
        _wsService.itemUpdatesStream.listen(_handleItemUpdate);

    // Subscribe to match updates
    _matchUpdateSubscription =
        _wsService.matchUpdatesStream.listen(_handleMatchUpdate);
  }

  /// Handle notification updates
  void _handleNotification(Map<String, dynamic> data) {
    // Update notifications provider
    // This would typically trigger a provider update
    print('Received notification: $data');
  }

  /// Handle chat message updates
  void _handleChatMessage(Map<String, dynamic> data) {
    // Update chat provider
    // This would typically trigger a provider update
    print('Received chat message: $data');
  }

  /// Handle item update
  void _handleItemUpdate(Map<String, dynamic> data) {
    // Update items provider
    // This would typically trigger a provider update
    print('Received item update: $data');
  }

  /// Handle match update
  void _handleMatchUpdate(Map<String, dynamic> data) {
    // Update matches provider
    // This would typically trigger a provider update
    print('Received match update: $data');
  }

  /// Send typing indicator
  void sendTypingIndicator(String conversationId, bool isTyping) {
    _wsService.sendMessage({
      'type': 'typing',
      'conversationId': conversationId,
      'isTyping': isTyping,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Send message read status
  void sendMessageReadStatus(String messageId, String conversationId) {
    _wsService.sendMessage({
      'type': 'message_read',
      'messageId': messageId,
      'conversationId': conversationId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Send online status
  void sendOnlineStatus(bool isOnline) {
    _wsService.sendMessage({
      'type': 'online_status',
      'isOnline': isOnline,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Disconnect and cleanup
  Future<void> disconnect() async {
    await _notificationSubscription?.cancel();
    await _chatSubscription?.cancel();
    await _itemUpdateSubscription?.cancel();
    await _matchUpdateSubscription?.cancel();

    await _wsService.disconnect();
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _wsService.dispose();
  }
}
