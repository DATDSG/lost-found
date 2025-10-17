import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_response_validator.dart';
import 'data_transformation_service.dart';
import '../models/user.dart';
import '../models/report.dart';
import '../models/media.dart';
import '../models/match.dart';
import '../models/notification.dart';
import '../models/chat_models.dart';
import '../models/location_models.dart';
import '../models/search_models.dart';
import '../models/auth_token.dart';

/// API response handler that combines validation and transformation
class ApiResponseHandler {
  static final ApiResponseHandler _instance = ApiResponseHandler._internal();
  factory ApiResponseHandler() => _instance;
  ApiResponseHandler._internal();

  final ApiResponseValidator _validator = ApiResponseValidator();
  final DataTransformationService _transformer = DataTransformationService();

  /// Handle authentication response
  AuthToken? handleAuthResponse(dynamic response) {
    try {
      final validation = _validator.validateAuthResponse(response);
      _validator.logValidationErrors(validation, 'Auth Response');

      if (!validation.isValid) {
        debugPrint('❌ Auth response validation failed: ${validation.errors}');
        return null;
      }

      return _transformer.transformAuthToken(validation.sanitizedData);
    } catch (e) {
      debugPrint('❌ Error handling auth response: $e');
      return null;
    }
  }

  /// Handle user response
  User? handleUserResponse(dynamic response) {
    try {
      final validation = _validator.validateUserResponse(response);
      _validator.logValidationErrors(validation, 'User Response');

      if (!validation.isValid) {
        debugPrint('❌ User response validation failed: ${validation.errors}');
        return null;
      }

      return _transformer.transformUser(validation.sanitizedData);
    } catch (e) {
      debugPrint('❌ Error handling user response: $e');
      return null;
    }
  }

  /// Handle list of users response
  List<User> handleUsersResponse(dynamic response) {
    try {
      final validation = _validator.validateListResponse(
        response,
        endpoint: 'users',
        itemFieldTypes: {
          'id': String,
          'email': String,
          'display_name': String,
          'role': String,
        },
      );
      _validator.logValidationErrors(validation, 'Users Response');

      if (!validation.isValid) {
        debugPrint('❌ Users response validation failed: ${validation.errors}');
        return [];
      }

      return _transformer.transformUsers(
        validation.sanitizedData as List<dynamic>?,
      );
    } catch (e) {
      debugPrint('❌ Error handling users response: $e');
      return [];
    }
  }

  /// Handle report response
  Report? handleReportResponse(dynamic response) {
    try {
      final validation = _validator.validateReportResponse(response);
      _validator.logValidationErrors(validation, 'Report Response');

      if (!validation.isValid) {
        debugPrint('❌ Report response validation failed: ${validation.errors}');
        return null;
      }

      return _transformer.transformReport(validation.sanitizedData);
    } catch (e) {
      debugPrint('❌ Error handling report response: $e');
      return null;
    }
  }

  /// Handle list of reports response
  List<Report> handleReportsResponse(dynamic response) {
    try {
      final validation = _validator.validateListResponse(
        response,
        endpoint: 'reports',
        itemFieldTypes: {
          'id': String,
          'title': String,
          'description': String,
          'type': String,
          'category': String,
          'city': String,
          'status': String,
        },
      );
      _validator.logValidationErrors(validation, 'Reports Response');

      if (!validation.isValid) {
        debugPrint(
          '❌ Reports response validation failed: ${validation.errors}',
        );
        return [];
      }

      // Handle both direct list responses and wrapped responses
      List<dynamic>? reportsData;
      if (validation.sanitizedData is List) {
        reportsData = validation.sanitizedData as List<dynamic>?;
      } else if (validation.sanitizedData is Map) {
        reportsData = validation.sanitizedData?['items'] as List<dynamic>?;
      }

      return _transformer.transformReports(reportsData);
    } catch (e) {
      debugPrint('❌ Error handling reports response: $e');
      return [];
    }
  }

  /// Handle paginated reports response
  Map<String, dynamic> handlePaginatedReportsResponse(dynamic response) {
    try {
      final validation = _validator.validatePaginatedResponse(
        response,
        endpoint: 'paginated_reports',
        itemFieldTypes: {
          'id': String,
          'title': String,
          'description': String,
          'type': String,
          'category': String,
          'city': String,
          'status': String,
        },
      );
      _validator.logValidationErrors(validation, 'Paginated Reports Response');

      if (!validation.isValid) {
        debugPrint(
          '❌ Paginated reports response validation failed: ${validation.errors}',
        );
        return {
          'items': <Report>[],
          'total': 0,
          'page': 1,
          'page_size': 20,
          'has_next': false,
          'has_previous': false,
        };
      }

      return _transformer.transformPaginatedResponse(
        validation.sanitizedData as Map<String, dynamic>,
        itemTransformer: (item) =>
            _transformer.transformReport(item as Map<String, dynamic>?),
      );
    } catch (e) {
      debugPrint('❌ Error handling paginated reports response: $e');
      return {
        'items': <Report>[],
        'total': 0,
        'page': 1,
        'page_size': 20,
        'has_next': false,
        'has_previous': false,
      };
    }
  }

  /// Handle media response
  Media? handleMediaResponse(dynamic response) {
    try {
      final validation = _validator.validateMediaResponse(response);
      _validator.logValidationErrors(validation, 'Media Response');

      if (!validation.isValid) {
        debugPrint('❌ Media response validation failed: ${validation.errors}');
        return null;
      }

      return _transformer.transformMedia(validation.sanitizedData);
    } catch (e) {
      debugPrint('❌ Error handling media response: $e');
      return null;
    }
  }

  /// Handle list of media response
  List<Media> handleMediaListResponse(dynamic response) {
    try {
      final validation = _validator.validateListResponse(
        response,
        endpoint: 'media',
        itemFieldTypes: {
          'id': String,
          'url': String,
          'type': String,
          'filename': String,
          'size': int,
        },
      );
      _validator.logValidationErrors(validation, 'Media List Response');

      if (!validation.isValid) {
        debugPrint(
          '❌ Media list response validation failed: ${validation.errors}',
        );
        return [];
      }

      return _transformer.transformMediaList(
        validation.sanitizedData as List<dynamic>?,
      );
    } catch (e) {
      debugPrint('❌ Error handling media list response: $e');
      return [];
    }
  }

  /// Handle match response
  MatchCandidate? handleMatchResponse(dynamic response) {
    try {
      final validation = _validator.validateApiResponse(
        response,
        endpoint: 'match',
        requiredFields: [
          'id',
          'report_id',
          'matched_report_id',
          'confidence_score',
        ],
        fieldTypes: {
          'id': String,
          'report_id': String,
          'matched_report_id': String,
          'confidence_score': num,
          'status': String,
          'created_at': String,
          'confirmed_at': String,
          'notes': String,
        },
      );
      _validator.logValidationErrors(validation, 'Match Response');

      if (!validation.isValid) {
        debugPrint('❌ Match response validation failed: ${validation.errors}');
        return null;
      }

      return _transformer.transformMatch(validation.sanitizedData);
    } catch (e) {
      debugPrint('❌ Error handling match response: $e');
      return null;
    }
  }

  /// Handle list of matches response
  List<MatchCandidate> handleMatchesResponse(dynamic response) {
    try {
      final validation = _validator.validateListResponse(
        response,
        endpoint: 'matches',
        itemFieldTypes: {
          'id': String,
          'report_id': String,
          'matched_report_id': String,
          'confidence_score': num,
          'status': String,
        },
      );
      _validator.logValidationErrors(validation, 'Matches Response');

      if (!validation.isValid) {
        debugPrint(
          '❌ Matches response validation failed: ${validation.errors}',
        );
        return [];
      }

      return _transformer.transformMatches(
        validation.sanitizedData as List<dynamic>?,
      );
    } catch (e) {
      debugPrint('❌ Error handling matches response: $e');
      return [];
    }
  }

  /// Handle notification response
  AppNotification? handleNotificationResponse(dynamic response) {
    try {
      final validation = _validator.validateNotificationResponse(response);
      _validator.logValidationErrors(validation, 'Notification Response');

      if (!validation.isValid) {
        debugPrint(
          '❌ Notification response validation failed: ${validation.errors}',
        );
        return null;
      }

      return _transformer.transformNotification(validation.sanitizedData);
    } catch (e) {
      debugPrint('❌ Error handling notification response: $e');
      return null;
    }
  }

  /// Handle list of notifications response
  List<AppNotification> handleNotificationsResponse(dynamic response) {
    try {
      final validation = _validator.validateListResponse(
        response,
        endpoint: 'notifications',
        itemFieldTypes: {
          'id': String,
          'title': String,
          'message': String,
          'type': String,
          'is_read': bool,
          'created_at': String,
        },
      );
      _validator.logValidationErrors(validation, 'Notifications Response');

      if (!validation.isValid) {
        debugPrint(
          '❌ Notifications response validation failed: ${validation.errors}',
        );
        return [];
      }

      return _transformer.transformNotifications(
        validation.sanitizedData as List<dynamic>?,
      );
    } catch (e) {
      debugPrint('❌ Error handling notifications response: $e');
      return [];
    }
  }

  /// Handle conversation response
  ChatConversation? handleConversationResponse(dynamic response) {
    try {
      final validation = _validator.validateApiResponse(
        response,
        endpoint: 'conversation',
        requiredFields: ['id', 'participant_one_id', 'participant_two_id'],
        fieldTypes: {
          'id': String,
          'match_id': String,
          'participant_one_id': String,
          'participant_two_id': String,
          'unread_count': int,
          'updated_at': String,
        },
      );
      _validator.logValidationErrors(validation, 'Conversation Response');

      if (!validation.isValid) {
        debugPrint(
          '❌ Conversation response validation failed: ${validation.errors}',
        );
        return null;
      }

      return _transformer.transformConversation(validation.sanitizedData);
    } catch (e) {
      debugPrint('❌ Error handling conversation response: $e');
      return null;
    }
  }

  /// Handle list of conversations response
  List<ChatConversation> handleConversationsResponse(dynamic response) {
    try {
      final validation = _validator.validateListResponse(
        response,
        endpoint: 'conversations',
        itemFieldTypes: {
          'id': String,
          'participant_one_id': String,
          'participant_two_id': String,
          'unread_count': int,
          'updated_at': String,
        },
      );
      _validator.logValidationErrors(validation, 'Conversations Response');

      if (!validation.isValid) {
        debugPrint(
          '❌ Conversations response validation failed: ${validation.errors}',
        );
        return [];
      }

      return _transformer.transformConversations(
        validation.sanitizedData as List<dynamic>?,
      );
    } catch (e) {
      debugPrint('❌ Error handling conversations response: $e');
      return [];
    }
  }

  /// Handle message response
  ChatMessage? handleMessageResponse(dynamic response) {
    try {
      final validation = _validator.validateMessageResponse(response);
      _validator.logValidationErrors(validation, 'Message Response');

      if (!validation.isValid) {
        debugPrint(
          '❌ Message response validation failed: ${validation.errors}',
        );
        return null;
      }

      return _transformer.transformMessage(validation.sanitizedData);
    } catch (e) {
      debugPrint('❌ Error handling message response: $e');
      return null;
    }
  }

  /// Handle list of messages response
  List<ChatMessage> handleMessagesResponse(dynamic response) {
    try {
      final validation = _validator.validateListResponse(
        response,
        endpoint: 'messages',
        itemFieldTypes: {
          'id': String,
          'conversation_id': String,
          'sender_id': String,
          'content': String,
          'is_read': bool,
          'created_at': String,
        },
      );
      _validator.logValidationErrors(validation, 'Messages Response');

      if (!validation.isValid) {
        debugPrint(
          '❌ Messages response validation failed: ${validation.errors}',
        );
        return [];
      }

      return _transformer.transformMessages(
        validation.sanitizedData as List<dynamic>?,
      );
    } catch (e) {
      debugPrint('❌ Error handling messages response: $e');
      return [];
    }
  }

  /// Handle location response
  LocationData? handleLocationResponse(dynamic response) {
    try {
      final validation = _validator.validateLocationResponse(response);
      _validator.logValidationErrors(validation, 'Location Response');

      if (!validation.isValid) {
        debugPrint(
          '❌ Location response validation failed: ${validation.errors}',
        );
        return null;
      }

      return _transformer.transformLocation(validation.sanitizedData);
    } catch (e) {
      debugPrint('❌ Error handling location response: $e');
      return null;
    }
  }

  /// Handle search results response
  List<SearchResult> handleSearchResultsResponse(dynamic response) {
    try {
      final validation = _validator.validateListResponse(
        response,
        endpoint: 'search_results',
        itemFieldTypes: {
          'id': String,
          'title': String,
          'description': String,
          'type': String,
          'category': String,
          'city': String,
          'created_at': String,
          'occurred_at': String,
        },
      );
      _validator.logValidationErrors(validation, 'Search Results Response');

      if (!validation.isValid) {
        debugPrint(
          '❌ Search results response validation failed: ${validation.errors}',
        );
        return [];
      }

      return _transformer.transformSearchResults(
        validation.sanitizedData as List<dynamic>?,
      );
    } catch (e) {
      debugPrint('❌ Error handling search results response: $e');
      return [];
    }
  }

  /// Handle generic success response
  Map<String, dynamic>? handleSuccessResponse(dynamic response) {
    try {
      final validation = _validator.validateApiResponse(
        response,
        endpoint: 'success',
        requiredFields: ['message'],
        fieldTypes: {'message': String, 'data': Map},
      );
      _validator.logValidationErrors(validation, 'Success Response');

      if (!validation.isValid) {
        debugPrint(
          '❌ Success response validation failed: ${validation.errors}',
        );
        return null;
      }

      return validation.sanitizedData;
    } catch (e) {
      debugPrint('❌ Error handling success response: $e');
      return null;
    }
  }

  /// Handle error response
  Map<String, dynamic>? handleErrorResponse(dynamic response) {
    try {
      if (response == null) return null;

      final validation = _validator.validateApiResponse(
        response,
        endpoint: 'error',
        requiredFields: ['detail'],
        fieldTypes: {
          'detail': String,
          'error_code': String,
          'field_errors': Map,
        },
      );

      if (!validation.isValid) {
        debugPrint('❌ Error response validation failed: ${validation.errors}');
        return null;
      }

      return validation.sanitizedData;
    } catch (e) {
      debugPrint('❌ Error handling error response: $e');
      return null;
    }
  }

  /// Handle raw JSON response with basic validation
  Map<String, dynamic>? handleRawResponse(dynamic response) {
    try {
      if (response == null) return null;

      if (response is Map<String, dynamic>) {
        return _validator.sanitizeData(response);
      } else if (response is String) {
        final decoded = jsonDecode(response);
        if (decoded is Map<String, dynamic>) {
          return _validator.sanitizeData(decoded);
        }
      }

      debugPrint('❌ Invalid response format: ${response.runtimeType}');
      return null;
    } catch (e) {
      debugPrint('❌ Error handling raw response: $e');
      return null;
    }
  }

  /// Handle list response with basic validation
  List<dynamic>? handleRawListResponse(dynamic response) {
    try {
      if (response == null) return null;

      if (response is List) {
        return response;
      } else if (response is String) {
        final decoded = jsonDecode(response);
        if (decoded is List) {
          return decoded;
        }
      }

      debugPrint('❌ Invalid list response format: ${response.runtimeType}');
      return null;
    } catch (e) {
      debugPrint('❌ Error handling raw list response: $e');
      return null;
    }
  }
}
