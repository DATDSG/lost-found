import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../config/api_config.dart';
import '../models/match_model.dart';
import '../models/chat_model.dart';
import '../models/item.dart';
import '../models/notification_model.dart';
import 'storage_service.dart';
import 'base_api_service.dart';

/// Simple API service using Dio
class ApiService extends BaseApiService {
  final StorageService _storage = StorageService();

  ApiService() : super() {
    _initializeDio();
  }

  void _initializeDio() {
    // Reinitialize _dio with proper configuration
    dio = Dio(
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
    dio.interceptors.add(
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

  // Authentication methods
  /// Login user
  Future<Map<String, dynamic>?> login(
      {required String email, required String password}) async {
    return await executeRequest(
      () => post('/auth/login', data: {
        'email': email,
        'password': password,
      }),
      operation: 'logging in',
    );
  }

  /// Register user
  Future<Map<String, dynamic>?> register(
      {required String email,
      required String password,
      required String displayName}) async {
    return await executeRequest(
      () => post('/auth/register', data: {
        'email': email,
        'password': password,
        'display_name': displayName,
      }),
      operation: 'registering',
    );
  }

  /// Logout user
  Future<void> logout() async {
    await executeVoidRequest(
      () => post('/auth/logout'),
      operation: 'logging out',
    );
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getProfile() async {
    return await executeRequest(
      () => get('/auth/me'),
      operation: 'getting profile',
    );
  }

  /// Update user profile
  Future<Map<String, dynamic>?> updateProfile(
      Map<String, dynamic> profileData) async {
    return await executeRequest(
      () => put('/auth/profile', data: profileData),
      operation: 'updating profile',
    );
  }

  /// Change password
  Future<void> changePassword(
      {required String currentPassword, required String newPassword}) async {
    try {
      await put('/auth/change-password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error changing password: $e');
      }
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await post('/auth/forgot-password', data: {
        'email': email,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error sending password reset email: $e');
      }
      rethrow;
    }
  }

  /// Send support message
  Future<void> sendSupportMessage({
    required String email,
    required String message,
  }) async {
    try {
      await post('/support/message', data: {
        'email': email,
        'message': message,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error sending support message: $e');
      }
      rethrow;
    }
  }

  // Match methods
  /// Get matches for a report
  Future<List<Match>> getMatchesForReport(String reportId) async {
    try {
      final response = await get('/matches/report/$reportId');
      return (response.data as List)
          .map((json) => Match.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting matches for report: $e');
      }
      rethrow;
    }
  }

  /// Get match statistics
  Future<Map<String, dynamic>?> getMatchStats() async {
    try {
      final response = await get('/matches/stats');
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting match stats: $e');
      }
      rethrow;
    }
  }

  /// Confirm a match
  Future<bool> confirmMatch(String matchId) async {
    try {
      final response = await post('/matches/$matchId/confirm');
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Error confirming match: $e');
      }
      rethrow;
    }
  }

  /// Reject a match
  Future<bool> rejectMatch(String matchId) async {
    try {
      final response = await post('/matches/$matchId/reject');
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Error rejecting match: $e');
      }
      rethrow;
    }
  }

  // Matches API
  Future<List<Match>> getMatches() async {
    return await executeListRequest(
      () => get('/matches'),
      operation: 'loading matches',
      fromJson: Match.fromJson,
    );
  }

  // Chat API
  Future<List<ChatConversation>> getConversations() async {
    return await executeListRequest(
      () => get('/chat/conversations'),
      operation: 'loading conversations',
      fromJson: ChatConversation.fromJson,
    );
  }

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    return await executeListRequest(
      () => get('/chat/conversations/$conversationId/messages'),
      operation: 'loading messages',
      fromJson: ChatMessage.fromJson,
    );
  }

  Future<void> sendMessage(
      {required String conversationId, required String content}) async {
    await executeVoidRequest(
      () => post(
        '/chat/conversations/$conversationId/messages',
        data: {'message': content},
      ),
      operation: 'sending message',
    );
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

  Future<bool> deleteNotification(String notificationId) async {
    try {
      await delete('/notifications/$notificationId');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting notification: $e');
      }
      rethrow;
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

  // ==================== LOCATION METHODS ====================

  /// Get current location
  Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      final response = await get('/location/current');
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current location: $e');
      }
      return null;
    }
  }

  /// Update current location
  Future<bool> updateCurrentLocation({
    required double latitude,
    required double longitude,
    String? address,
    String? city,
    String? country,
  }) async {
    try {
      await dio.post('/location/current', data: {
        'latitude': latitude,
        'longitude': longitude,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (country != null) 'country': country,
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating current location: $e');
      }
      rethrow;
    }
  }

  /// Geocode address to coordinates
  Future<List<Map<String, dynamic>>> geocodeAddress(String address) async {
    try {
      final response = await get('/location/geocode', queryParameters: {
        'address': address,
      });
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error geocoding address: $e');
      }
      return [];
    }
  }

  /// Reverse geocode coordinates to address
  Future<Map<String, dynamic>> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await get('/location/reverse-geocode', queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
      });
      final data = response.data;
      if (data is List && data.isNotEmpty) {
        return data.first as Map<String, dynamic>;
      } else if (data is Map<String, dynamic>) {
        return data;
      }
      throw Exception('Invalid response format');
    } catch (e) {
      if (kDebugMode) {
        print('Error reverse geocoding: $e');
      }
      rethrow;
    }
  }

  /// Search locations
  Future<List<Map<String, dynamic>>> searchLocations({
    required String query,
    String? country,
    String? city,
    double? latitude,
    double? longitude,
    double? radiusKm,
    int? limit,
  }) async {
    try {
      final response = await get('/location/search', queryParameters: {
        'query': query,
        if (country != null) 'country': country,
        if (city != null) 'city': city,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (radiusKm != null) 'radius_km': radiusKm,
        if (limit != null) 'limit': limit,
      });
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error searching locations: $e');
      }
      rethrow;
    }
  }

  /// Get location autocomplete suggestions
  Future<List<String>> getLocationAutocomplete({
    required String query,
    String? country,
    String? city,
    int? limit,
  }) async {
    try {
      final response = await get('/location/autocomplete', queryParameters: {
        'query': query,
        if (country != null) 'country': country,
        if (city != null) 'city': city,
        if (limit != null) 'limit': limit,
      });
      return List<String>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location autocomplete: $e');
      }
      rethrow;
    }
  }

  /// Get nearby locations
  Future<List<Map<String, dynamic>>> getNearbyLocations({
    required double latitude,
    required double longitude,
    required double radiusKm,
    String? type,
    int? limit,
  }) async {
    try {
      final response = await get('/location/nearby', queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius_km': radiusKm,
        if (type != null) 'type': type,
        if (limit != null) 'limit': limit,
      });
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting nearby locations: $e');
      }
      rethrow;
    }
  }

  /// Get location details
  Future<Map<String, dynamic>?> getLocationDetails(String locationId) async {
    try {
      final response = await get('/location/$locationId');
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location details: $e');
      }
      return null;
    }
  }

  /// Calculate distance between two points
  Future<Map<String, dynamic>> calculateDistance({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
    String? unit,
  }) async {
    try {
      final response = await get('/location/distance', queryParameters: {
        'from_latitude': fromLatitude,
        'from_longitude': fromLongitude,
        'to_latitude': toLatitude,
        'to_longitude': toLongitude,
        if (unit != null) 'unit': unit,
      });
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating distance: $e');
      }
      rethrow;
    }
  }

  /// Get location bounds
  Future<Map<String, dynamic>?> getLocationBounds({
    required String query,
    String? country,
  }) async {
    try {
      final response = await post('/location/bounds', data: {
        'query': query,
        if (country != null) 'country': country,
      });
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location bounds: $e');
      }
      rethrow;
    }
  }

  /// Validate location
  Future<bool> validateLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await get('/location/validate', queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
      });
      return response.data['valid'] ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Error validating location: $e');
      }
      rethrow;
    }
  }

  /// Get location history
  Future<List<Map<String, dynamic>>> getLocationHistory() async {
    try {
      final response = await get('/location/history');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location history: $e');
      }
      return [];
    }
  }

  /// Save location to history
  Future<bool> saveLocationToHistory({
    required double latitude,
    required double longitude,
    required String address,
    String? city,
    String? country,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await post('/location/history', data: {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        if (city != null) 'city': city,
        if (country != null) 'country': country,
        if (metadata != null) 'metadata': metadata,
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving location to history: $e');
      }
      rethrow;
    }
  }

  /// Clear location history
  Future<void> clearLocationHistory() async {
    try {
      await delete('/location/history');
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing location history: $e');
      }
    }
  }

  /// Get location stats
  Future<Map<String, dynamic>?> getLocationStats() async {
    try {
      final response = await get('/location/stats');
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location stats: $e');
      }
      return null;
    }
  }

  // ==================== MEDIA METHODS ====================

  /// List media files
  Future<List<Map<String, dynamic>>> listMedia() async {
    try {
      final response = await get('/media');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error listing media: $e');
      }
      return [];
    }
  }

  /// Get media stats
  Future<Map<String, dynamic>?> getMediaStats() async {
    try {
      final response = await get('/media/stats');
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting media stats: $e');
      }
      return null;
    }
  }

  /// Upload media file
  Future<Map<String, dynamic>?> uploadMedia({
    required String filePath,
    required String reportId,
    Function(double)? onProgress,
  }) async {
    try {
      final response = await uploadFile('/media/upload', filePath, 'file');
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading media: $e');
      }
      rethrow;
    }
  }

  /// Delete media file
  Future<void> deleteMedia(String mediaId) async {
    try {
      await delete('/media/$mediaId');
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting media: $e');
      }
    }
  }

  /// Get media file
  Future<Map<String, dynamic>?> getMedia(String mediaId) async {
    try {
      final response = await get('/media/$mediaId');
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting media: $e');
      }
      return null;
    }
  }

  // ==================== CONVERSATION METHODS ====================

  /// Get conversation details
  Future<Map<String, dynamic>?> getConversation(String conversationId) async {
    try {
      final response = await get('/conversations/$conversationId');
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting conversation: $e');
      }
      return null;
    }
  }

  /// Get conversation messages
  Future<List<Map<String, dynamic>>> getConversationMessages(
      String conversationId) async {
    try {
      final response = await get('/conversations/$conversationId/messages');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting conversation messages: $e');
      }
      return [];
    }
  }

  /// Mark conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      await put('/conversations/$conversationId/read');
    } catch (e) {
      if (kDebugMode) {
        print('Error marking conversation as read: $e');
      }
    }
  }

  /// Archive conversation
  Future<void> archiveConversation(String conversationId) async {
    try {
      await put('/conversations/$conversationId/archive');
    } catch (e) {
      if (kDebugMode) {
        print('Error archiving conversation: $e');
      }
    }
  }

  /// Unarchive conversation
  Future<void> unarchiveConversation(String conversationId) async {
    try {
      await put('/conversations/$conversationId/unarchive');
    } catch (e) {
      if (kDebugMode) {
        print('Error unarchiving conversation: $e');
      }
    }
  }

  /// Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      await delete('/conversations/$conversationId');
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting conversation: $e');
      }
    }
  }

  /// Delete message
  Future<void> deleteMessage(String messageId) async {
    try {
      await delete('/messages/$messageId');
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting message: $e');
      }
    }
  }

  /// Mute conversation
  Future<void> muteConversation(String conversationId) async {
    try {
      await put('/conversations/$conversationId/mute');
    } catch (e) {
      if (kDebugMode) {
        print('Error muting conversation: $e');
      }
    }
  }

  /// Unmute conversation
  Future<void> unmuteConversation(String conversationId) async {
    try {
      await put('/conversations/$conversationId/unmute');
    } catch (e) {
      if (kDebugMode) {
        print('Error unmuting conversation: $e');
      }
    }
  }

  /// Block user in conversation
  Future<void> blockUserInConversation(
      String conversationId, String userId) async {
    try {
      await put('/conversations/$conversationId/block', data: {
        'user_id': userId,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error blocking user in conversation: $e');
      }
    }
  }

  /// Unblock user in conversation
  Future<void> unblockUserInConversation(
      String conversationId, String userId) async {
    try {
      await put('/conversations/$conversationId/unblock', data: {
        'user_id': userId,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error unblocking user in conversation: $e');
      }
    }
  }

  /// Search messages
  Future<List<Map<String, dynamic>>> searchMessages(String query) async {
    try {
      final response = await get('/messages/search', queryParameters: {
        'query': query,
      });
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error searching messages: $e');
      }
      return [];
    }
  }

  /// Get conversation stats
  Future<Map<String, dynamic>?> getConversationStats() async {
    try {
      final response = await get('/conversations/stats');
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting conversation stats: $e');
      }
      return null;
    }
  }

  // ==================== REPORTS METHODS ====================

  /// Get reports with filters
  Future<Map<String, dynamic>> getReportsWithFilters({
    int? page,
    int? pageSize,
    String? search,
    String? type,
    String? category,
    String? status,
    String? city,
    double? latitude,
    double? longitude,
    double? radiusKm,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? colors,
    bool? rewardOffered,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final filters = <String, dynamic>{};
      if (page != null) filters['page'] = page;
      if (pageSize != null) filters['page_size'] = pageSize;
      if (search != null) filters['search'] = search;
      if (type != null) filters['type'] = type;
      if (category != null) filters['category'] = category;
      if (status != null) filters['status'] = status;
      if (city != null) filters['city'] = city;
      if (latitude != null) filters['latitude'] = latitude;
      if (longitude != null) filters['longitude'] = longitude;
      if (radiusKm != null) filters['radius_km'] = radiusKm;
      if (startDate != null) {
        filters['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) filters['end_date'] = endDate.toIso8601String();
      if (colors != null) filters['colors'] = colors;
      if (rewardOffered != null) filters['reward_offered'] = rewardOffered;
      if (sortBy != null) filters['sort_by'] = sortBy;
      if (sortOrder != null) filters['sort_order'] = sortOrder;

      final response = await get('/reports', queryParameters: filters);
      final data = response.data as Map<String, dynamic>;

      return {
        'reports': data['items'] ?? data['reports'] ?? [],
        'pagination': data['pagination'] ??
            {
              'has_more': false,
              'total': 0,
              'page': page ?? 1,
              'page_size': pageSize ?? 20,
            },
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting reports with filters: $e');
      }
      rethrow;
    }
  }

  /// Get my reports
  Future<List<Map<String, dynamic>>> getMyReports() async {
    try {
      final response = await get('/reports/my');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting my reports: $e');
      }
      return [];
    }
  }

  /// Get nearby reports
  Future<List<Map<String, dynamic>>> getNearbyReports({
    required double latitude,
    required double longitude,
    required double radiusKm,
    String? type,
    String? category,
  }) async {
    try {
      final response = await get('/reports/nearby', queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius_km': radiusKm,
        if (type != null) 'type': type,
        if (category != null) 'category': category,
      });
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting nearby reports: $e');
      }
      rethrow;
    }
  }

  /// Get report details
  Future<Map<String, dynamic>?> getReport(String reportId) async {
    try {
      final response = await get('/reports/$reportId');
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting report: $e');
      }
      return null;
    }
  }

  /// Create report with media
  Future<Map<String, dynamic>?> createReportWithMedia({
    required String type,
    required String title,
    required String description,
    required String category,
    required String city,
    required DateTime occurredAt,
    List<String>? colors,
    String? locationAddress,
    double? latitude,
    double? longitude,
    double? rewardOffered,
    required List<String> imagePaths,
    Function(double)? onProgress,
  }) async {
    try {
      final formData = FormData();

      // Add report data
      formData.fields.addAll([
        MapEntry('type', type),
        MapEntry('title', title),
        MapEntry('description', description),
        MapEntry('category', category),
        MapEntry('city', city),
        MapEntry('occurred_at', occurredAt.toIso8601String()),
        if (colors != null) MapEntry('colors', colors.join(',')),
        if (locationAddress != null)
          MapEntry('location_address', locationAddress),
        if (latitude != null) MapEntry('latitude', latitude.toString()),
        if (longitude != null) MapEntry('longitude', longitude.toString()),
        if (rewardOffered != null)
          MapEntry('reward_offered', rewardOffered.toString()),
      ]);

      // Add media files
      for (int i = 0; i < imagePaths.length; i++) {
        formData.files.add(MapEntry(
          'media_$i',
          await MultipartFile.fromFile(imagePaths[i]),
        ));
      }

      final response = await dio.post('/reports', data: formData);
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating report with media: $e');
      }
      rethrow;
    }
  }

  /// Create report
  Future<Map<String, dynamic>?> createReport({
    required String type,
    required String title,
    required String description,
    required String category,
    required String city,
    required DateTime occurredAt,
    List<String>? colors,
    String? locationAddress,
    double? latitude,
    double? longitude,
    double? rewardOffered,
  }) async {
    try {
      final response = await post('/reports', data: {
        'type': type,
        'title': title,
        'description': description,
        'category': category,
        'city': city,
        'occurred_at': occurredAt.toIso8601String(),
        if (colors != null) 'colors': colors,
        if (locationAddress != null) 'location_address': locationAddress,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (rewardOffered != null) 'reward_offered': rewardOffered,
      });
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating report: $e');
      }
      rethrow;
    }
  }

  /// Update report
  Future<Map<String, dynamic>?> updateReport(
      String reportId, Map<String, dynamic> reportData) async {
    try {
      final response = await put('/reports/$reportId', data: reportData);
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating report: $e');
      }
      return null;
    }
  }

  /// Delete report
  Future<bool> deleteReport(String reportId) async {
    try {
      await delete('/reports/$reportId');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting report: $e');
      }
      rethrow;
    }
  }

  /// Resolve report
  Future<bool> resolveReport(String reportId) async {
    try {
      await put('/reports/$reportId/resolve');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error resolving report: $e');
      }
      rethrow;
    }
  }

  /// Duplicate report
  Future<Map<String, dynamic>?> duplicateReport(String reportId) async {
    try {
      final response = await post('/reports/$reportId/duplicate');
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error duplicating report: $e');
      }
      rethrow;
    }
  }

  /// Archive report
  Future<bool> archiveReport(String reportId) async {
    try {
      await put('/reports/$reportId/archive');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error archiving report: $e');
      }
      rethrow;
    }
  }

  /// Restore report
  Future<bool> restoreReport(String reportId) async {
    try {
      await put('/reports/$reportId/restore');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error restoring report: $e');
      }
      rethrow;
    }
  }

  /// Get report stats
  Future<Map<String, dynamic>?> getReportStats() async {
    try {
      final response = await get('/reports/stats');
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting report stats: $e');
      }
      return null;
    }
  }

  /// Get report analytics
  Future<Map<String, dynamic>?> getReportAnalytics() async {
    try {
      final response = await get('/reports/analytics');
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting report analytics: $e');
      }
      return null;
    }
  }

  /// Get my report stats
  Future<Map<String, dynamic>?> getMyReportStats() async {
    try {
      final response = await get('/reports/my/stats');
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting my report stats: $e');
      }
      return null;
    }
  }

  // ==================== SEARCH METHODS ====================

  /// Semantic search
  Future<List<Map<String, dynamic>>> semanticSearch(String query) async {
    try {
      final response = await get('/search/semantic', queryParameters: {
        'query': query,
      });
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error performing semantic search: $e');
      }
      return [];
    }
  }

  /// Search reports
  Future<List<Map<String, dynamic>>> searchReports({
    required String query,
    String? category,
    String? status,
    String? type,
    double? latitude,
    double? longitude,
    double? radiusKm,
    Map<String, dynamic>? additionalFilters,
    int? page,
    int? pageSize,
  }) async {
    try {
      final queryParams = {
        'query': query,
        if (category != null) 'category': category,
        if (status != null) 'status': status,
        if (type != null) 'type': type,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (radiusKm != null) 'radius_km': radiusKm,
        if (page != null) 'page': page,
        if (pageSize != null) 'page_size': pageSize,
      };
      if (additionalFilters != null) {
        queryParams.addAll(additionalFilters.map((key, value) => MapEntry(
            key, value is int || value is double ? value : value.toString())));
      }
      final response =
          await get('/search/reports', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error searching reports: $e');
      }
      rethrow;
    }
  }

  /// Get search suggestions
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      final response = await get('/search/suggestions', queryParameters: {
        'query': query,
      });
      return List<String>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting search suggestions: $e');
      }
      return [];
    }
  }

  /// Get recent searches
  Future<List<String>> getRecentSearches() async {
    try {
      final response = await get('/search/recent');
      return List<String>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting recent searches: $e');
      }
      return [];
    }
  }

  /// Save search query
  Future<void> saveSearchQuery(String query) async {
    try {
      await post('/search/save', data: {'query': query});
    } catch (e) {
      if (kDebugMode) {
        print('Error saving search query: $e');
      }
    }
  }

  /// Get search analytics
  Future<Map<String, dynamic>?> getSearchAnalytics() async {
    try {
      final response = await get('/search/analytics');
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting search analytics: $e');
      }
      return null;
    }
  }

  /// Get search trends
  Future<List<Map<String, dynamic>>> getSearchTrends() async {
    try {
      final response = await get('/search/trends');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting search trends: $e');
      }
      return [];
    }
  }

  /// Get filter options
  Future<Map<String, dynamic>?> getFilterOptions() async {
    try {
      final response = await get('/search/filters');
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting filter options: $e');
      }
      return null;
    }
  }

  /// Advanced search
  Future<List<Map<String, dynamic>>> advancedSearch(
      Map<String, dynamic> searchCriteria) async {
    try {
      final response = await post('/search/advanced', data: searchCriteria);
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error performing advanced search: $e');
      }
      return [];
    }
  }

  /// Search by location
  Future<List<Map<String, dynamic>>> searchByLocation({
    required double latitude,
    required double longitude,
    required double radiusKm,
    Map<String, dynamic>? additionalFilters,
    int? page,
    int? pageSize,
  }) async {
    try {
      final queryParams = {
        'latitude': latitude,
        'longitude': longitude,
        'radius_km': radiusKm,
        if (page != null) 'page': page,
        if (pageSize != null) 'page_size': pageSize,
      };
      if (additionalFilters != null) {
        queryParams.addAll(additionalFilters.map((key, value) => MapEntry(
            key, value is int || value is double ? value : value.toString())));
      }
      final response =
          await get('/search/location', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error searching by location: $e');
      }
      rethrow;
    }
  }

  /// Search by image
  Future<List<Map<String, dynamic>>> searchByImage({
    required String imageUrl,
    double? threshold,
    Map<String, dynamic>? additionalFilters,
    int? page,
    int? pageSize,
  }) async {
    try {
      final response = await uploadFile('/search/image', imageUrl, 'image');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error searching by image: $e');
      }
      rethrow;
    }
  }

  /// Get popular searches
  Future<List<String>> getPopularSearches() async {
    try {
      final response = await get('/search/popular');
      return List<String>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting popular searches: $e');
      }
      return [];
    }
  }

  // ==================== USER PROFILE METHODS ====================

  /// Get user stats
  Future<Map<String, dynamic>?> getUserStats() async {
    try {
      final response = await get('/user/stats');
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user stats: $e');
      }
      return null;
    }
  }

  /// Get user preferences
  Future<Map<String, dynamic>?> getUserPreferences() async {
    try {
      final response = await get('/user/preferences');
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user preferences: $e');
      }
      return null;
    }
  }

  /// Update user preferences
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      await put('/user/preferences', data: preferences);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user preferences: $e');
      }
    }
  }

  /// Get user settings
  Future<Map<String, dynamic>?> getUserSettings() async {
    try {
      final response = await get('/user/settings');
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user settings: $e');
      }
      return null;
    }
  }

  /// Update user settings
  Future<void> updateUserSettings(Map<String, dynamic> settings) async {
    try {
      await put('/user/settings', data: settings);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user settings: $e');
      }
    }
  }

  /// Get user activity
  Future<List<Map<String, dynamic>>> getUserActivity() async {
    try {
      final response = await get('/user/activity');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user activity: $e');
      }
      return [];
    }
  }

  /// Get user reports
  Future<List<Map<String, dynamic>>> getUserReports() async {
    try {
      final response = await get('/user/reports');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user reports: $e');
      }
      return [];
    }
  }

  /// Get user matches
  Future<List<Map<String, dynamic>>> getUserMatches() async {
    try {
      final response = await get('/user/matches');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user matches: $e');
      }
      return [];
    }
  }

  /// Get user notifications
  Future<List<Map<String, dynamic>>> getUserNotifications() async {
    try {
      final response = await get('/user/notifications');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user notifications: $e');
      }
      return [];
    }
  }

  /// Update profile with validation
  Future<Map<String, dynamic>?> updateProfileWithValidation(
      Map<String, dynamic> profileData) async {
    try {
      final response = await post('/user/profile/validate', data: profileData);
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating profile with validation: $e');
      }
      return null;
    }
  }

  /// Upload avatar
  Future<Map<String, dynamic>?> uploadAvatar(String imagePath) async {
    try {
      final response = await uploadFile('/user/avatar', imagePath, 'avatar');
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading avatar: $e');
      }
      return null;
    }
  }

  /// Delete user account
  Future<void> deleteUserAccount() async {
    try {
      await delete('/user/account');
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting user account: $e');
      }
    }
  }

  /// Upload profile picture
  Future<void> uploadProfilePicture(File imageFile) async {
    try {
      await uploadFile(
          '/user/profile-picture', imageFile.path, 'profile_picture');
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading profile picture: $e');
      }
      rethrow;
    }
  }

  /// Remove profile picture
  Future<void> removeProfilePicture() async {
    try {
      await delete('/user/profile-picture');
    } catch (e) {
      if (kDebugMode) {
        print('Error removing profile picture: $e');
      }
      rethrow;
    }
  }

  /// Export user data
  Future<Map<String, dynamic>?> exportUserData() async {
    try {
      final response = await get('/user/export');
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error exporting user data: $e');
      }
      return null;
    }
  }
}

// Provider for ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
