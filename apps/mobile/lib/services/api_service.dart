import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../models/match_model.dart';
import '../models/chat_model.dart';
import '../models/item.dart';
import '../models/notification_model.dart';
import 'storage_service.dart';

/// Simple API service using Dio
class ApiService {
  late final Dio _dio;
  final StorageService _storage = StorageService();

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.timeout,
        receiveTimeout: ApiConfig.timeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptor to attach token to requests
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add token if available
          final token = await _storage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          if (kDebugMode) {
            print('📤 ${options.method} ${options.uri}');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('📥 ${response.statusCode} ${response.requestOptions.uri}');
          }
          return handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            print('❌ Error: ${error.message}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// GET request
  Future<Response> get(String path) async {
    try {
      return await _dio.get(path);
    } catch (e) {
      rethrow;
    }
  }

  /// POST request
  Future<Response> post(String path, {Map<String, dynamic>? data}) async {
    try {
      return await _dio.post(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  /// PUT request
  Future<Response> put(String path, {Map<String, dynamic>? data}) async {
    try {
      return await _dio.put(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE request
  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } catch (e) {
      rethrow;
    }
  }

  /// Upload file with multipart
  Future<Response> uploadFile(
    String path,
    String filePath,
    String fieldName,
  ) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
      });
      return await _dio.post(path, data: formData);
    } catch (e) {
      rethrow;
    }
  }

  // Matches API
  Future<List<Match>> getMatches() async {
    try {
      final response = await get('/matches');
      final data = response.data as List;
      return data.map((json) => Match.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading matches: $e');
      }
      // Return empty list for now during development
      return [];
    }
  }

  // Chat API
  Future<List<ChatConversation>> getConversations() async {
    try {
      final response = await get('/chat/conversations');
      final data = response.data as List;
      return data.map((json) => ChatConversation.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading conversations: $e');
      }
      // Return empty list for now during development
      return [];
    }
  }

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    try {
      final response =
          await get('/chat/conversations/$conversationId/messages');
      final data = response.data as List;
      return data.map((json) => ChatMessage.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading messages: $e');
      }
      return [];
    }
  }

  Future<ChatMessage> sendMessage(String conversationId, String message) async {
    try {
      final response = await post(
        '/chat/conversations/$conversationId/messages',
        data: {'message': message},
      );
      return ChatMessage.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // Items API with search and filters
  Future<List<Item>> searchItems({
    String? query,
    String? type,
    String? time,
    String? distance,
    String? category,
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (query != null && query.isNotEmpty) params['q'] = query;
      if (type != null) params['type'] = type;
      if (time != null && time != 'Any Time') params['time'] = time;
      if (distance != null && distance != 'Any Distance') {
        params['distance'] = distance;
      }
      if (category != null && category != 'All') params['category'] = category;
      if (location != null && location.isNotEmpty) {
        params['location'] = location;
      }
      if (latitude != null) params['lat'] = latitude;
      if (longitude != null) params['lon'] = longitude;

      final response = await get(
          '/items${params.isNotEmpty ? '?' : ''}${_buildQueryString(params)}');
      final data = response.data as List;
      return data.map((json) => Item.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error searching items: $e');
      }
      return [];
    }
  }

  String _buildQueryString(Map<String, dynamic> params) {
    return params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
  }

  // Get item details
  Future<Item?> getItemDetails(String itemId) async {
    try {
      final response = await get('/items/$itemId');
      return Item.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading item details: $e');
      }
      return null;
    }
  }

  // Create chat conversation
  Future<String?> createConversation(String itemId, String recipientId) async {
    try {
      final response = await post(
        '/chat/conversations',
        data: {
          'item_id': itemId,
          'recipient_id': recipientId,
        },
      );
      return response.data['id'] ?? response.data['conversation_id'];
    } catch (e) {
      if (kDebugMode) {
        print('Error creating conversation: $e');
      }
      return null;
    }
  }

  // Notifications API
  Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await get('/notifications');
      final data = response.data as List;
      return data.map((json) => AppNotification.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading notifications: $e');
      }
      return [];
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await put('/notifications/$notificationId/read');
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      await put('/notifications/read-all');
    } catch (e) {
      if (kDebugMode) {
        print('Error marking all notifications as read: $e');
      }
    }
  }

  Future<int> getUnreadNotificationCount() async {
    try {
      final response = await get('/notifications/unread-count');
      return response.data['count'] ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting unread count: $e');
      }
      return 0;
    }
  }

  // Get unread message count
  Future<int> getUnreadMessageCount() async {
    try {
      final response = await get('/chat/unread-count');
      return response.data['count'] ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting unread message count: $e');
      }
      return 0;
    }
  }
}

// Provider for ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
