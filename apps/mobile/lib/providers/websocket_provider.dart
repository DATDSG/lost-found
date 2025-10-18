import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/websocket_service.dart';
import '../services/storage_service.dart';
import 'package:flutter/foundation.dart';

/// WebSocket connection state
class WebSocketState {
  final WebSocketStatus status;
  final String? error;

  const WebSocketState({
    this.status = WebSocketStatus.disconnected,
    this.error,
  });

  WebSocketState copyWith({
    WebSocketStatus? status,
    String? error,
  }) {
    return WebSocketState(
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }
}

/// WebSocket notifier
class WebSocketNotifier extends StateNotifier<WebSocketState> {
  final WebSocketService _wsService;
  final StorageService _storageService;

  WebSocketNotifier(this._wsService, this._storageService)
      : super(const WebSocketState()) {
    _initialize();
  }

  void _initialize() {
    // Listen to connection status changes
    _wsService.statusStream.listen((status) {
      state = state.copyWith(status: status);

      if (status == WebSocketStatus.connected) {
        _subscribeToChannels();
      }
    });

    // Auto-connect if user is authenticated
    _connectIfAuthenticated();
  }

  Future<void> _connectIfAuthenticated() async {
    try {
      final token = await _storageService.getToken();
      if (token != null) {
        // Use WebSocket URL from environment or default
        const wsUrl = String.fromEnvironment(
          'WS_URL',
          defaultValue: 'ws://localhost:3000/ws',
        );
        await _wsService.connect(wsUrl, token: token.accessToken);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error connecting WebSocket: $e');
      }
      state = state.copyWith(error: 'Failed to connect');
    }
  }

  void _subscribeToChannels() {
    // Subscribe to relevant channels
    _wsService.subscribe([
      'notifications',
      'messages',
      'items',
    ]);
  }

  /// Manually connect to WebSocket
  Future<void> connect() async {
    await _connectIfAuthenticated();
  }

  /// Disconnect from WebSocket
  void disconnect() {
    _wsService.disconnect();
  }

  /// Get message stream
  Stream<Map<String, dynamic>> get messageStream => _wsService.messageStream;

  @override
  void dispose() {
    _wsService.dispose();
    super.dispose();
  }
}

/// WebSocket provider
final webSocketProvider =
    StateNotifierProvider<WebSocketNotifier, WebSocketState>((ref) {
  final wsService = WebSocketService();
  final storageService = StorageService();
  return WebSocketNotifier(wsService, storageService);
});
