import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';

enum WebSocketStatus {
  connecting,
  connected,
  disconnected,
  error,
}

/// Service for handling WebSocket connections for real-time updates
class WebSocketService {
  WebSocketChannel? _channel;
  WebSocketStatus _status = WebSocketStatus.disconnected;
  final _statusController = StreamController<WebSocketStatus>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  String? _url;
  String? _token;

  /// Stream of connection status changes
  Stream<WebSocketStatus> get statusStream => _statusController.stream;

  /// Stream of incoming messages
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  /// Current connection status
  WebSocketStatus get status => _status;

  /// Connect to WebSocket server
  Future<void> connect(String url, {String? token}) async {
    if (_status == WebSocketStatus.connected ||
        _status == WebSocketStatus.connecting) {
      if (kDebugMode) {
        print('WebSocket already connected or connecting');
      }
      return;
    }

    _url = url;
    _token = token;
    _reconnectAttempts = 0;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    try {
      _updateStatus(WebSocketStatus.connecting);

      // Build WebSocket URL with auth token if provided
      final wsUrl = _token != null ? '$_url?token=$_token' : _url!;

      if (kDebugMode) {
        print('Connecting to WebSocket: $wsUrl');
      }

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Listen to messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      _updateStatus(WebSocketStatus.connected);
      _reconnectAttempts = 0;
      _startHeartbeat();

      if (kDebugMode) {
        print('WebSocket connected successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('WebSocket connection error: $e');
      }
      _updateStatus(WebSocketStatus.error);
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic message) {
    try {
      if (message is String) {
        final data = jsonDecode(message) as Map<String, dynamic>;

        // Handle heartbeat/ping messages
        if (data['type'] == 'ping') {
          send({'type': 'pong'});
          return;
        }

        _messageController.add(data);

        if (kDebugMode) {
          print('WebSocket message received: ${data['type']}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing WebSocket message: $e');
      }
    }
  }

  void _handleError(dynamic error) {
    if (kDebugMode) {
      print('WebSocket error: $error');
    }
    _updateStatus(WebSocketStatus.error);
    _scheduleReconnect();
  }

  void _handleDisconnect() {
    if (kDebugMode) {
      print('WebSocket disconnected');
    }
    _updateStatus(WebSocketStatus.disconnected);
    _stopHeartbeat();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      if (kDebugMode) {
        print('Max reconnect attempts reached. Giving up.');
      }
      return;
    }

    _reconnectAttempts++;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      if (kDebugMode) {
        print(
            'Attempting to reconnect (attempt $_reconnectAttempts/$_maxReconnectAttempts)');
      }
      _doConnect();
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      send({'type': 'ping', 'timestamp': DateTime.now().toIso8601String()});
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _updateStatus(WebSocketStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }

  /// Send message to server
  void send(Map<String, dynamic> message) {
    if (_status == WebSocketStatus.connected) {
      try {
        _channel?.sink.add(jsonEncode(message));
        if (kDebugMode &&
            message['type'] != 'ping' &&
            message['type'] != 'pong') {
          print('WebSocket message sent: ${message['type']}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error sending WebSocket message: $e');
        }
      }
    } else {
      if (kDebugMode) {
        print('Cannot send message: WebSocket not connected');
      }
    }
  }

  /// Subscribe to specific channels
  void subscribe(List<String> channels) {
    send({
      'type': 'subscribe',
      'channels': channels,
    });
  }

  /// Unsubscribe from specific channels
  void unsubscribe(List<String> channels) {
    send({
      'type': 'unsubscribe',
      'channels': channels,
    });
  }

  /// Disconnect from WebSocket
  void disconnect() {
    if (kDebugMode) {
      print('Disconnecting WebSocket');
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _stopHeartbeat();

    _channel?.sink.close();
    _channel = null;

    _updateStatus(WebSocketStatus.disconnected);
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _statusController.close();
    _messageController.close();
  }
}
