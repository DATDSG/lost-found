import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_model.dart';
import '../services/api_service.dart';

class ChatState {
  final List<ChatConversation> conversations;
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final String? activeConversationId;
  final int unreadCount;

  ChatState({
    this.conversations = const [],
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.activeConversationId,
    this.unreadCount = 0,
  });

  ChatState copyWith({
    List<ChatConversation>? conversations,
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    String? activeConversationId,
    int? unreadCount,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      activeConversationId: activeConversationId ?? this.activeConversationId,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ApiService _apiService;

  ChatNotifier(this._apiService) : super(ChatState()) {
    // Load unread count on initialization
    loadUnreadCount();
  }

  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final conversations = await _apiService.getConversations();

      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
      );

      // Update unread count
      await loadUnreadCount();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMessages(String conversationId) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      activeConversationId: conversationId,
    );

    try {
      final messages = await _apiService.getMessages(conversationId);

      state = state.copyWith(
        messages: messages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> sendMessage(String conversationId, String message) async {
    try {
      final newMessage = await _apiService.sendMessage(conversationId, message);

      state = state.copyWith(
        messages: [...state.messages, newMessage],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Load unread message count
  Future<void> loadUnreadCount() async {
    try {
      final count = await _apiService.getUnreadMessageCount();
      state = state.copyWith(unreadCount: count);
    } catch (e) {
      // Silently fail, keep current count
    }
  }

  void clearActiveConversation() {
    state = state.copyWith(
      activeConversationId: null,
      messages: [],
    );
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ChatNotifier(apiService);
});
