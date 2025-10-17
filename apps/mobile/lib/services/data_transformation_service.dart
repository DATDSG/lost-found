import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/report.dart';
import '../models/media.dart';
import '../models/match.dart';
import '../models/notification.dart' as notification_models;
import '../models/chat_models.dart';
import '../models/location_models.dart';
import '../models/search_models.dart';
import '../models/auth_token.dart';

/// Data transformation service for API responses
class DataTransformationService {
  static final DataTransformationService _instance =
      DataTransformationService._internal();
  factory DataTransformationService() => _instance;
  DataTransformationService._internal();

  /// Transform authentication response to AuthToken
  AuthToken? transformAuthToken(Map<String, dynamic>? data) {
    if (data == null) return null;

    try {
      return AuthToken(
        accessToken: data['access_token'] as String? ?? '',
        refreshToken: data['refresh_token'] as String? ?? '',
        tokenType: data['token_type'] as String? ?? 'Bearer',
      );
    } catch (e) {
      debugPrint('❌ Error transforming auth token: $e');
      return null;
    }
  }

  /// Transform user response to User model
  User? transformUser(Map<String, dynamic>? data) {
    if (data == null) return null;

    try {
      return User(
        id: data['id'] as String? ?? '',
        email: data['email'] as String? ?? '',
        displayName: data['display_name'] as String? ?? '',
        phoneNumber: data['phone_number'] as String?,
        avatarUrl: data['avatar_url'] as String?,
        role: data['role'] as String? ?? 'user',
        isActive: data['is_active'] as bool? ?? true,
        createdAt: data['created_at'] != null
            ? DateTime.parse(data['created_at'] as String)
            : DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error transforming user: $e');
      return null;
    }
  }

  /// Transform list of users
  List<User> transformUsers(List<dynamic>? data) {
    if (data == null) return [];

    return data
        .map((item) => transformUser(item as Map<String, dynamic>?))
        .where((user) => user != null)
        .cast<User>()
        .toList();
  }

  /// Transform report response to Report model
  Report? transformReport(Map<String, dynamic>? data) {
    if (data == null) return null;

    try {
      // Parse coordinates from geo field if available
      double? latitude;
      double? longitude;
      if (data['geo'] != null && data['geo'].toString().startsWith('POINT(')) {
        try {
          final geoStr = data['geo'].toString();
          final coords = geoStr
              .replaceAll('POINT(', '')
              .replaceAll(')', '')
              .split(' ');
          if (coords.length == 2) {
            longitude = double.parse(coords[0]);
            latitude = double.parse(coords[1]);
          }
        } catch (e) {
          debugPrint('Error parsing geo coordinates: $e');
        }
      }

      return Report(
        id: data['id'] as String? ?? '',
        type: data['type'] as String? ?? 'lost',
        title: data['title'] as String? ?? '',
        description: data['description'] as String? ?? '',
        category: data['category'] as String? ?? '',
        city: data['city'] as String? ?? '',
        status: data['status'] as String? ?? 'active',
        createdAt: data['created_at'] != null
            ? DateTime.parse(data['created_at'] as String)
            : DateTime.now(),
        occurredAt: data['occurred_at'] != null
            ? DateTime.parse(data['occurred_at'] as String)
            : DateTime.now(),
        colors: (data['colors'] as List<dynamic>?)?.cast<String>() ?? [],
        locationAddress: data['location_address'] as String?,
        latitude: latitude ?? (data['latitude'] as num?)?.toDouble(),
        longitude: longitude ?? (data['longitude'] as num?)?.toDouble(),
        rewardOffered: data['reward_offered'] as bool? ?? false,
        media: transformMediaList(data['media'] as List<dynamic>?),
      );
    } catch (e) {
      debugPrint('❌ Error transforming report: $e');
      return null;
    }
  }

  /// Transform list of reports
  List<Report> transformReports(List<dynamic>? data) {
    if (data == null) return [];

    return data
        .map((item) => transformReport(item as Map<String, dynamic>?))
        .where((report) => report != null)
        .cast<Report>()
        .toList();
  }

  /// Transform media response to Media model
  Media? transformMedia(Map<String, dynamic>? data) {
    if (data == null) return null;

    try {
      return Media(
        id: data['id'] as String? ?? '',
        reportId: data['report_id'] as String?,
        filename: data['filename'] as String? ?? '',
        url: data['url'] as String? ?? '',
        type: _parseMediaType(data['type'] as String?),
        mimeType: data['mime_type'] as String? ?? 'image/jpeg',
        sizeBytes: (data['size'] as num?)?.toInt(),
        createdAt: data['created_at'] != null
            ? DateTime.parse(data['created_at'] as String)
            : DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error transforming media: $e');
      return null;
    }
  }

  /// Transform list of media
  List<Media> transformMediaList(List<dynamic>? data) {
    if (data == null) return [];

    return data
        .map((item) => transformMedia(item as Map<String, dynamic>?))
        .where((media) => media != null)
        .cast<Media>()
        .toList();
  }

  /// Transform match response to MatchCandidate model
  MatchCandidate? transformMatch(Map<String, dynamic>? data) {
    if (data == null) return null;

    try {
      return MatchCandidate(
        id: data['id'] as String? ?? '',
        reportId: data['report_id'] as String? ?? '',
        matchedReportId: data['matched_report_id'] as String? ?? '',
        overallScore: (data['overall_score'] as num?)?.toDouble() ?? 0.0,
        components: _transformMatchComponents(
          data['components'] as List<dynamic>?,
        ),
        status: _parseMatchStatus(data['status'] as String?),
        createdAt: data['created_at'] != null
            ? DateTime.parse(data['created_at'] as String)
            : DateTime.now(),
        confirmedAt: data['confirmed_at'] != null
            ? DateTime.parse(data['confirmed_at'] as String)
            : null,
        notes: data['notes'] as String?,
        matchedReportTitle: data['matched_report_title'] as String? ?? '',
        matchedReportDescription:
            data['matched_report_description'] as String? ?? '',
        matchedReportCategory: data['matched_report_category'] as String? ?? '',
        matchedReportCity: data['matched_report_city'] as String? ?? '',
        matchedReportCreatedAt: data['matched_report_created_at'] != null
            ? DateTime.parse(data['matched_report_created_at'] as String)
            : DateTime.now(),
        matchedReportImages:
            (data['matched_report_images'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        matchedReportOwnerName:
            data['matched_report_owner_name'] as String? ?? '',
        matchedReportOwnerId: data['matched_report_owner_id'] as String? ?? '',
      );
    } catch (e) {
      debugPrint('❌ Error transforming match: $e');
      return null;
    }
  }

  /// Transform list of matches
  List<MatchCandidate> transformMatches(List<dynamic>? data) {
    if (data == null) return [];

    return data
        .map((item) => transformMatch(item as Map<String, dynamic>?))
        .where((match) => match != null)
        .cast<MatchCandidate>()
        .toList();
  }

  /// Transform notification response to AppNotification model
  notification_models.AppNotification? transformNotification(
    Map<String, dynamic>? data,
  ) {
    if (data == null) return null;

    try {
      return notification_models.AppNotification(
        id: data['id'] as String? ?? '',
        userId: data['user_id'] as String? ?? '',
        type: _parseNotificationType(data['type'] as String?),
        priority: _parseNotificationPriority(data['priority'] as String?),
        title: data['title'] as String? ?? '',
        content: data['content'] as String? ?? '',
        referenceId: data['reference_id'] as String?,
        isRead: data['is_read'] as bool? ?? false,
        createdAt: data['created_at'] != null
            ? DateTime.parse(data['created_at'] as String)
            : DateTime.now(),
        readAt: data['read_at'] != null
            ? DateTime.parse(data['read_at'] as String)
            : null,
        metadata: data['metadata'] as Map<String, dynamic>?,
        actions: _transformNotificationActions(
          data['actions'] as List<dynamic>?,
        ),
        imageUrl: data['image_url'] as String?,
        deepLink: data['deep_link'] as String?,
      );
    } catch (e) {
      debugPrint('❌ Error transforming notification: $e');
      return null;
    }
  }

  /// Transform list of notifications
  List<notification_models.AppNotification> transformNotifications(
    List<dynamic>? data,
  ) {
    if (data == null) return [];

    return data
        .map((item) => transformNotification(item as Map<String, dynamic>?))
        .where((notification) => notification != null)
        .cast<notification_models.AppNotification>()
        .toList();
  }

  /// Transform conversation response to ChatConversation model
  ChatConversation? transformConversation(Map<String, dynamic>? data) {
    if (data == null) return null;

    try {
      return ChatConversation(
        id: data['id'] as String? ?? '',
        matchId: data['match_id'] as String?,
        participantOneId: data['participant_one_id'] as String? ?? '',
        participantTwoId: data['participant_two_id'] as String? ?? '',
        lastMessage: data['last_message'] != null
            ? transformMessage(data['last_message'] as Map<String, dynamic>)
            : null,
        unreadCount: (data['unread_count'] as num?)?.toInt() ?? 0,
        updatedAt: data['updated_at'] != null
            ? DateTime.parse(data['updated_at'] as String)
            : DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error transforming conversation: $e');
      return null;
    }
  }

  /// Transform list of conversations
  List<ChatConversation> transformConversations(List<dynamic>? data) {
    if (data == null) return [];

    return data
        .map((item) => transformConversation(item as Map<String, dynamic>?))
        .where((conversation) => conversation != null)
        .cast<ChatConversation>()
        .toList();
  }

  /// Transform message response to ChatMessage model
  ChatMessage? transformMessage(Map<String, dynamic>? data) {
    if (data == null) return null;

    try {
      return ChatMessage(
        id: data['id'] as String? ?? '',
        conversationId: data['conversation_id'] as String? ?? '',
        senderId: data['sender_id'] as String? ?? '',
        senderName: data['sender_name'] as String? ?? 'Unknown',
        senderAvatar: data['sender_avatar'] as String?,
        content: data['content'] as String? ?? '',
        isRead: data['is_read'] as bool? ?? false,
        createdAt: data['created_at'] != null
            ? DateTime.parse(data['created_at'] as String)
            : DateTime.now(),
        status: _parseMessageStatus(data['status'] as String?),
      );
    } catch (e) {
      debugPrint('❌ Error transforming message: $e');
      return null;
    }
  }

  /// Transform list of messages
  List<ChatMessage> transformMessages(List<dynamic>? data) {
    if (data == null) return [];

    return data
        .map((item) => transformMessage(item as Map<String, dynamic>?))
        .where((message) => message != null)
        .cast<ChatMessage>()
        .toList();
  }

  /// Transform location response to LocationData model
  LocationData? transformLocation(Map<String, dynamic>? data) {
    if (data == null) return null;

    try {
      return LocationData(
        latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
        address: data['address'] as String?,
        city: data['city'] as String?,
        state: data['state'] as String?,
        country: data['country'] as String?,
        postalCode: data['postal_code'] as String?,
        placeId: data['place_id'] as String?,
        metadata: data['metadata'] as Map<String, dynamic>?,
        timestamp: data['timestamp'] != null
            ? DateTime.parse(data['timestamp'] as String)
            : null,
      );
    } catch (e) {
      debugPrint('❌ Error transforming location: $e');
      return null;
    }
  }

  /// Transform search result to SearchResult model
  SearchResult? transformSearchResult(Map<String, dynamic>? data) {
    if (data == null) return null;

    try {
      return SearchResult(
        id: data['id'] as String? ?? '',
        title: data['title'] as String? ?? '',
        description: data['description'] as String? ?? '',
        type: data['type'] as String? ?? '',
        category: data['category'] as String? ?? '',
        city: data['city'] as String? ?? '',
        createdAt: data['created_at'] != null
            ? DateTime.parse(data['created_at'] as String)
            : DateTime.now(),
        occurredAt: data['occurred_at'] != null
            ? DateTime.parse(data['occurred_at'] as String)
            : DateTime.now(),
        colors: (data['colors'] as List<dynamic>?)?.cast<String>(),
        rewardOffered: data['reward_offered'] as bool?,
        latitude: (data['latitude'] as num?)?.toDouble(),
        longitude: (data['longitude'] as num?)?.toDouble(),
        distance: (data['distance'] as num?)?.toDouble(),
        relevanceScore: (data['relevance_score'] as num?)?.toDouble(),
        media: (data['media'] as List<dynamic>?)?.cast<String>(),
      );
    } catch (e) {
      debugPrint('❌ Error transforming search result: $e');
      return null;
    }
  }

  /// Transform list of search results
  List<SearchResult> transformSearchResults(List<dynamic>? data) {
    if (data == null) return [];

    return data
        .map((item) => transformSearchResult(item as Map<String, dynamic>?))
        .where((result) => result != null)
        .cast<SearchResult>()
        .toList();
  }

  /// Transform paginated response
  Map<String, dynamic> transformPaginatedResponse(
    Map<String, dynamic> data, {
    String? itemsKey,
    Function(dynamic)? itemTransformer,
  }) {
    try {
      final itemsKeyName = itemsKey ?? 'items';
      final items = data[itemsKeyName] as List<dynamic>? ?? [];

      final transformedItems = itemTransformer != null
          ? items.map(itemTransformer).toList()
          : items;

      return {
        'items': transformedItems,
        'total': data['total'] as int? ?? 0,
        'page': data['page'] as int? ?? 1,
        'page_size': data['page_size'] as int? ?? 20,
        'has_next': data['has_next'] as bool? ?? false,
        'has_previous': data['has_previous'] as bool? ?? false,
      };
    } catch (e) {
      debugPrint('❌ Error transforming paginated response: $e');
      return {
        'items': [],
        'total': 0,
        'page': 1,
        'page_size': 20,
        'has_next': false,
        'has_previous': false,
      };
    }
  }

  // Helper methods for parsing enums

  MediaType _parseMediaType(String? type) {
    if (type == null) return MediaType.image;

    switch (type.toLowerCase()) {
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return MediaType.image;
      case 'video':
      case 'mp4':
      case 'avi':
      case 'mov':
        return MediaType.video;
      case 'document':
      case 'pdf':
      case 'doc':
      case 'docx':
        return MediaType.document;
      default:
        return MediaType.image;
    }
  }

  MatchStatus _parseMatchStatus(String? status) {
    if (status == null) return MatchStatus.pending;

    switch (status.toLowerCase()) {
      case 'pending':
        return MatchStatus.pending;
      case 'confirmed':
        return MatchStatus.confirmed;
      case 'rejected':
        return MatchStatus.rejected;
      default:
        return MatchStatus.pending;
    }
  }

  notification_models.NotificationType _parseNotificationType(String? type) {
    if (type == null) return notification_models.NotificationType.system;

    switch (type.toLowerCase()) {
      case 'message':
        return notification_models.NotificationType.message;
      case 'match':
        return notification_models.NotificationType.match;
      case 'report':
        return notification_models.NotificationType.report;
      case 'system':
        return notification_models.NotificationType.system;
      default:
        return notification_models.NotificationType.system;
    }
  }

  notification_models.NotificationPriority _parseNotificationPriority(
    String? priority,
  ) {
    if (priority == null)
      return notification_models.NotificationPriority.normal;

    switch (priority.toLowerCase()) {
      case 'low':
        return notification_models.NotificationPriority.low;
      case 'normal':
        return notification_models.NotificationPriority.normal;
      case 'high':
        return notification_models.NotificationPriority.high;
      case 'urgent':
        return notification_models.NotificationPriority.urgent;
      default:
        return notification_models.NotificationPriority.normal;
    }
  }

  List<notification_models.NotificationAction> _transformNotificationActions(
    List<dynamic>? data,
  ) {
    if (data == null) return [];

    return data
        .map(
          (item) => notification_models.NotificationAction.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  MessageStatus _parseMessageStatus(String? status) {
    if (status == null) return MessageStatus.sent;

    switch (status.toLowerCase()) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }

  List<MatchComponent> _transformMatchComponents(List<dynamic>? data) {
    if (data == null) return [];

    return data
        .map((item) {
          try {
            return MatchComponent(
              name: item['name'] as String? ?? '',
              score: (item['score'] as num?)?.toDouble() ?? 0.0,
              weight: (item['weight'] as num?)?.toDouble() ?? 1.0,
              description: item['description'] as String? ?? '',
              color: _parseColor(item['color'] as String?),
            );
          } catch (e) {
            debugPrint('❌ Error transforming match component: $e');
            return null;
          }
        })
        .where((component) => component != null)
        .cast<MatchComponent>()
        .toList();
  }

  Color _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return Colors.blue;
    }

    try {
      // Handle hex colors
      if (colorString.startsWith('#')) {
        return Color(
          int.parse(colorString.substring(1), radix: 16) + 0xFF000000,
        );
      }

      // Handle named colors
      switch (colorString.toLowerCase()) {
        case 'red':
          return Colors.red;
        case 'green':
          return Colors.green;
        case 'blue':
          return Colors.blue;
        case 'yellow':
          return Colors.yellow;
        case 'orange':
          return Colors.orange;
        case 'purple':
          return Colors.purple;
        case 'pink':
          return Colors.pink;
        case 'teal':
          return Colors.teal;
        case 'cyan':
          return Colors.cyan;
        case 'amber':
          return Colors.amber;
        case 'indigo':
          return Colors.indigo;
        case 'brown':
          return Colors.brown;
        case 'grey':
        case 'gray':
          return Colors.grey;
        default:
          return Colors.blue;
      }
    } catch (e) {
      return Colors.blue;
    }
  }
}
