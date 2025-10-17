import 'package:flutter/foundation.dart';

/// Validation result model
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final Map<String, dynamic>? sanitizedData;

  ValidationResult({
    required this.isValid,
    required this.errors,
    this.sanitizedData,
  });

  factory ValidationResult.success({Map<String, dynamic>? data}) {
    return ValidationResult(isValid: true, errors: [], sanitizedData: data);
  }

  factory ValidationResult.failure(List<String> errors) {
    return ValidationResult(isValid: false, errors: errors);
  }
}

/// API response validation service
class ApiResponseValidator {
  static final ApiResponseValidator _instance =
      ApiResponseValidator._internal();
  factory ApiResponseValidator() => _instance;
  ApiResponseValidator._internal();

  /// Validate API response structure
  ValidationResult validateApiResponse(
    dynamic response, {
    required String endpoint,
    List<String>? requiredFields,
    Map<String, Type>? fieldTypes,
    bool allowNull = false,
  }) {
    final errors = <String>[];

    try {
      // Check if response is null
      if (response == null) {
        if (!allowNull) {
          errors.add('Response is null for endpoint: $endpoint');
        }
        return ValidationResult.failure(errors);
      }

      // Check if response is a Map
      if (response is! Map<String, dynamic>) {
        errors.add(
          'Response is not a valid JSON object for endpoint: $endpoint',
        );
        return ValidationResult.failure(errors);
      }

      final responseMap = response;

      // Validate required fields
      if (requiredFields != null) {
        for (final field in requiredFields) {
          if (!responseMap.containsKey(field)) {
            errors.add('Missing required field: $field');
          }
        }
      }

      // Validate field types
      if (fieldTypes != null) {
        for (final entry in fieldTypes.entries) {
          final field = entry.key;
          final expectedType = entry.value;

          if (responseMap.containsKey(field)) {
            final value = responseMap[field];
            if (!_isValidType(value, expectedType)) {
              errors.add(
                'Field "$field" has invalid type. Expected: ${expectedType.toString()}, Got: ${value.runtimeType}',
              );
            }
          }
        }
      }

      if (errors.isNotEmpty) {
        return ValidationResult.failure(errors);
      }

      return ValidationResult.success(data: responseMap);
    } catch (e) {
      errors.add('Validation error: $e');
      return ValidationResult.failure(errors);
    }
  }

  /// Validate list response
  ValidationResult validateListResponse(
    dynamic response, {
    required String endpoint,
    Map<String, Type>? itemFieldTypes,
    int? minItems,
    int? maxItems,
  }) {
    final errors = <String>[];

    try {
      if (response == null) {
        errors.add('Response is null for endpoint: $endpoint');
        return ValidationResult.failure(errors);
      }

      if (response is! List) {
        errors.add('Response is not a list for endpoint: $endpoint');
        return ValidationResult.failure(errors);
      }

      final responseList = response;

      // Check item count constraints
      if (minItems != null && responseList.length < minItems) {
        errors.add(
          'List has fewer items than minimum required: ${responseList.length} < $minItems',
        );
      }

      if (maxItems != null && responseList.length > maxItems) {
        errors.add(
          'List has more items than maximum allowed: ${responseList.length} > $maxItems',
        );
      }

      // Validate each item if field types are specified
      if (itemFieldTypes != null) {
        for (int i = 0; i < responseList.length; i++) {
          final item = responseList[i];
          if (item is! Map<String, dynamic>) {
            errors.add('Item at index $i is not a valid object');
            continue;
          }

          final itemMap = item;
          for (final entry in itemFieldTypes.entries) {
            final field = entry.key;
            final expectedType = entry.value;

            if (itemMap.containsKey(field)) {
              final value = itemMap[field];
              if (!_isValidType(value, expectedType)) {
                errors.add(
                  'Item $i, field "$field" has invalid type. Expected: ${expectedType.toString()}, Got: ${value.runtimeType}',
                );
              }
            }
          }
        }
      }

      if (errors.isNotEmpty) {
        return ValidationResult.failure(errors);
      }

      return ValidationResult.success(data: {'items': responseList});
    } catch (e) {
      errors.add('List validation error: $e');
      return ValidationResult.failure(errors);
    }
  }

  /// Validate paginated response
  ValidationResult validatePaginatedResponse(
    dynamic response, {
    required String endpoint,
    Map<String, Type>? itemFieldTypes,
  }) {
    final errors = <String>[];

    try {
      // First validate as a regular response with pagination fields
      final baseValidation = validateApiResponse(
        response,
        endpoint: endpoint,
        requiredFields: ['items', 'total', 'page', 'page_size'],
        fieldTypes: {
          'items': List,
          'total': int,
          'page': int,
          'page_size': int,
        },
      );

      if (!baseValidation.isValid) {
        return baseValidation;
      }

      final responseMap = response;
      final items = responseMap['items'] as List;

      // Validate items if field types are specified
      if (itemFieldTypes != null) {
        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          if (item is! Map<String, dynamic>) {
            errors.add('Item at index $i is not a valid object');
            continue;
          }

          final itemMap = item;
          for (final entry in itemFieldTypes.entries) {
            final field = entry.key;
            final expectedType = entry.value;

            if (itemMap.containsKey(field)) {
              final value = itemMap[field];
              if (!_isValidType(value, expectedType)) {
                errors.add(
                  'Item $i, field "$field" has invalid type. Expected: ${expectedType.toString()}, Got: ${value.runtimeType}',
                );
              }
            }
          }
        }
      }

      // Validate pagination consistency
      final page = responseMap['page'] as int;
      final pageSize = responseMap['page_size'] as int;

      if (page < 1) {
        errors.add('Page number must be >= 1');
      }

      if (pageSize < 1) {
        errors.add('Page size must be >= 1');
      }

      if (items.length > pageSize) {
        errors.add('Items count exceeds page size');
      }

      if (errors.isNotEmpty) {
        return ValidationResult.failure(errors);
      }

      return ValidationResult.success(data: responseMap);
    } catch (e) {
      errors.add('Paginated response validation error: $e');
      return ValidationResult.failure(errors);
    }
  }

  /// Validate authentication response
  ValidationResult validateAuthResponse(dynamic response) {
    return validateApiResponse(
      response,
      endpoint: 'auth',
      requiredFields: ['access_token', 'token_type'],
      fieldTypes: {
        'access_token': String,
        'token_type': String,
        'refresh_token': String,
        'expires_in': int,
      },
    );
  }

  /// Validate user response
  ValidationResult validateUserResponse(dynamic response) {
    return validateApiResponse(
      response,
      endpoint: 'user',
      requiredFields: ['id', 'email'],
      fieldTypes: {
        'id': String,
        'email': String,
        'display_name': String,
        'phone_number': String,
        'avatar_url': String,
        'role': String,
        'is_active': bool,
        'created_at': String,
      },
    );
  }

  /// Validate report response
  ValidationResult validateReportResponse(dynamic response) {
    return validateApiResponse(
      response,
      endpoint: 'report',
      requiredFields: [
        'id',
        'title',
        'description',
        'type',
        'category',
        'city',
      ],
      fieldTypes: {
        'id': String,
        'title': String,
        'description': String,
        'type': String,
        'category': String,
        'city': String,
        'status': String,
        'created_at': String,
        'occurred_at': String,
        'colors': List,
        'latitude': num,
        'longitude': num,
        'location_address': String,
        'reward_offered': bool,
        'media': List,
      },
    );
  }

  /// Validate media response
  ValidationResult validateMediaResponse(dynamic response) {
    return validateApiResponse(
      response,
      endpoint: 'media',
      requiredFields: ['id', 'url', 'type'],
      fieldTypes: {
        'id': String,
        'url': String,
        'type': String,
        'filename': String,
        'size': int,
        'created_at': String,
        'report_id': String,
      },
    );
  }

  /// Validate message response
  ValidationResult validateMessageResponse(dynamic response) {
    return validateApiResponse(
      response,
      endpoint: 'message',
      requiredFields: ['id', 'conversation_id', 'sender_id', 'content'],
      fieldTypes: {
        'id': String,
        'conversation_id': String,
        'sender_id': String,
        'content': String,
        'is_read': bool,
        'created_at': String,
        'status': String,
      },
    );
  }

  /// Validate notification response
  ValidationResult validateNotificationResponse(dynamic response) {
    return validateApiResponse(
      response,
      endpoint: 'notification',
      requiredFields: ['id', 'title', 'type'],
      fieldTypes: {
        'id': String,
        'title': String,
        'message': String,
        'type': String,
        'is_read': bool,
        'created_at': String,
        'data': Map,
      },
    );
  }

  /// Validate location response
  ValidationResult validateLocationResponse(dynamic response) {
    return validateApiResponse(
      response,
      endpoint: 'location',
      requiredFields: ['latitude', 'longitude'],
      fieldTypes: {
        'latitude': num,
        'longitude': num,
        'address': String,
        'city': String,
        'state': String,
        'country': String,
        'postal_code': String,
        'place_id': String,
      },
    );
  }

  /// Check if value matches expected type
  bool _isValidType(dynamic value, Type expectedType) {
    if (value == null) return true; // Allow null values

    switch (expectedType) {
      case String:
        return value is String;
      case int:
        return value is int;
      case double:
        return value is double || value is int;
      case num:
        return value is num;
      case bool:
        return value is bool;
      case List:
        return value is List;
      case Map:
        return value is Map;
      case DateTime:
        return value is String && _isValidDateTime(value);
      default:
        return false;
    }
  }

  /// Check if string is a valid DateTime
  bool _isValidDateTime(String dateString) {
    try {
      DateTime.parse(dateString);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Sanitize and transform data
  Map<String, dynamic> sanitizeData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      // Skip null values
      if (value == null) continue;

      // Handle different data types
      if (value is String) {
        sanitized[key] = value.trim();
      } else if (value is List) {
        sanitized[key] = _sanitizeList(value);
      } else if (value is Map) {
        sanitized[key] = sanitizeData(value as Map<String, dynamic>);
      } else {
        sanitized[key] = value;
      }
    }

    return sanitized;
  }

  /// Sanitize list data
  List<dynamic> _sanitizeList(List<dynamic> list) {
    return list.map((item) {
      if (item is String) {
        return item.trim();
      } else if (item is Map) {
        return sanitizeData(item as Map<String, dynamic>);
      } else if (item is List) {
        return _sanitizeList(item);
      } else {
        return item;
      }
    }).toList();
  }

  /// Transform API response to standardized format
  Map<String, dynamic> transformResponse(
    Map<String, dynamic> response, {
    String? endpoint,
    Map<String, String>? fieldMappings,
    List<String>? excludeFields,
  }) {
    final transformed = <String, dynamic>{};

    for (final entry in response.entries) {
      final key = entry.key;
      final value = entry.value;

      // Skip excluded fields
      if (excludeFields != null && excludeFields.contains(key)) {
        continue;
      }

      // Apply field mapping
      final transformedKey = fieldMappings?[key] ?? key;
      transformed[transformedKey] = value;
    }

    return transformed;
  }

  /// Log validation errors for debugging
  void logValidationErrors(ValidationResult result, String context) {
    if (!result.isValid && kDebugMode) {
      debugPrint('🚨 Validation failed for $context:');
      for (final error in result.errors) {
        debugPrint('  ❌ $error');
      }
    }
  }
}
