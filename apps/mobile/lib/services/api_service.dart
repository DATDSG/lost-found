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
  Future<void> updateCurrentLocation({
    required double latitude,
    required double longitude,
    String? address,
    String? city,
    String? country,
  }) async {
    try {
      await _dio.post('/location/current', data: {
        'latitude': latitude,
        'longitude': longitude,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (country != null) 'country': country,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating current location: $e');
      }
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
  Future<List<Map<String, dynamic>>> reverseGeocode(double latitude, double longitude) async {
    try {
      final response = await get('/location/reverse-geocode', queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
      });
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error reverse geocoding: $e');
      }
      return [];
    }
  }

  /// Search locations
  Future<List<Map<String, dynamic>>> searchLocations(String query) async {
    try {
      final response = await get('/location/search', queryParameters: {
        'query': query,
      });
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error searching locations: $e');
      }
      return [];
    }
  }

  /// Get location autocomplete suggestions
  Future<List<String>> getLocationAutocomplete(String query) async {
    try {
      final response = await get('/location/autocomplete', queryParameters: {
        'query': query,
      });
      return List<String>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location autocomplete: $e');
      }
      return [];
    }
  }

  /// Get nearby locations
  Future<List<Map<String, dynamic>>> getNearbyLocations(double latitude, double longitude, double radius) async {
    try {
      final response = await get('/location/nearby', queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
      });
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting nearby locations: $e');
      }
      return [];
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
  Future<double> calculateDistance(double lat1, double lon1, double lat2, double lon2) async {
    try {
      final response = await get('/location/distance', queryParameters: {
        'lat1': lat1,
        'lon1': lon1,
        'lat2': lat2,
        'lon2': lon2,
      });
      return response.data['distance']?.toDouble() ?? 0.0;
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating distance: $e');
      }
      return 0.0;
    }
  }

  /// Get location bounds
  Future<Map<String, dynamic>?> getLocationBounds(List<Map<String, double>> points) async {
    try {
      final response = await post('/location/bounds', data: {
        'points': points,
      });
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location bounds: $e');
      }
      return null;
    }
  }

  /// Validate location
  Future<bool> validateLocation(double latitude, double longitude) async {
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
      return false;
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
  Future<void> saveLocationToHistory(Map<String, dynamic> location) async {
    try {
      await post('/location/history', data: location);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving location to history: $e');
      }
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
  Future<Map<String, dynamic>?> uploadMedia(String filePath, String fieldName) async {
    try {
      final response = await uploadFile('/media/upload', filePath, fieldName);
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading media: $e');
      }
      return null;
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
  Future<List<Map<String, dynamic>>> getConversationMessages(String conversationId) async {
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
  Future<void> blockUserInConversation(String conversationId, String userId) async {
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
  Future<void> unblockUserInConversation(String conversationId, String userId) async {
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
  Future<List<Map<String, dynamic>>> getReportsWithFilters(Map<String, dynamic> filters) async {
    try {
      final response = await get('/reports', queryParameters: filters);
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting reports with filters: $e');
      }
      return [];
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
  Future<List<Map<String, dynamic>>> getNearbyReports(double latitude, double longitude, double radius) async {
    try {
      final response = await get('/reports/nearby', queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
      });
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting nearby reports: $e');
      }
      return [];
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
  Future<Map<String, dynamic>?> createReportWithMedia(Map<String, dynamic> reportData, List<String> mediaPaths) async {
    try {
      final formData = FormData();
      
      // Add report data
      formData.fields.addAll(reportData.entries.map((e) => MapEntry(e.key, e.value.toString())));
      
      // Add media files
      for (int i = 0; i < mediaPaths.length; i++) {
        formData.files.add(MapEntry(
          'media_$i',
          await MultipartFile.fromFile(mediaPaths[i]),
        ));
      }
      
      final response = await _dio.post('/reports', data: formData);
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating report with media: $e');
      }
      return null;
    }
  }

  /// Create report
  Future<Map<String, dynamic>?> createReport(Map<String, dynamic> reportData) async {
    try {
      final response = await post('/reports', data: reportData);
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating report: $e');
      }
      return null;
    }
  }

  /// Update report
  Future<Map<String, dynamic>?> updateReport(String reportId, Map<String, dynamic> reportData) async {
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
  Future<void> deleteReport(String reportId) async {
    try {
      await delete('/reports/$reportId');
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting report: $e');
      }
    }
  }

  /// Resolve report
  Future<void> resolveReport(String reportId) async {
    try {
      await put('/reports/$reportId/resolve');
    } catch (e) {
      if (kDebugMode) {
        print('Error resolving report: $e');
      }
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
      return null;
    }
  }

  /// Archive report
  Future<void> archiveReport(String reportId) async {
    try {
      await put('/reports/$reportId/archive');
    } catch (e) {
      if (kDebugMode) {
        print('Error archiving report: $e');
      }
    }
  }

  /// Restore report
  Future<void> restoreReport(String reportId) async {
    try {
      await put('/reports/$reportId/restore');
    } catch (e) {
      if (kDebugMode) {
        print('Error restoring report: $e');
      }
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
  Future<List<Map<String, dynamic>>> searchReports(String query, Map<String, dynamic>? filters) async {
    try {
      final queryParams = {'query': query};
      if (filters != null) {
        queryParams.addAll(filters);
      }
      final response = await get('/search/reports', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error searching reports: $e');
      }
      return [];
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
  Future<List<Map<String, dynamic>>> advancedSearch(Map<String, dynamic> searchCriteria) async {
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
  Future<List<Map<String, dynamic>>> searchByLocation(double latitude, double longitude, double radius) async {
    try {
      final response = await get('/search/location', queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
      });
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error searching by location: $e');
      }
      return [];
    }
  }

  /// Search by image
  Future<List<Map<String, dynamic>>> searchByImage(String imagePath) async {
    try {
      final response = await uploadFile('/search/image', imagePath, 'image');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error searching by image: $e');
      }
      return [];
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
  Future<Map<String, dynamic>?> updateProfileWithValidation(Map<String, dynamic> profileData) async {
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

  /// Update profile
  Future<Map<String, dynamic>?> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await put('/user/profile', data: profileData);
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating profile: $e');
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
