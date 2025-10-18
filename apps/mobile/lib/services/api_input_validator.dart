import 'package:flutter/foundation.dart';

/// Input validation result
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

/// API input validation service
class ApiInputValidator {
  static final ApiInputValidator _instance = ApiInputValidator._internal();
  factory ApiInputValidator() => _instance;
  ApiInputValidator._internal();

  /// Validate email format
  ValidationResult validateEmail(String email) {
    final errors = <String>[];

    if (email.isEmpty) {
      errors.add('Email is required');
      return ValidationResult.failure(errors);
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email.trim())) {
      errors.add('Invalid email format');
    }

    if (email.length > 254) {
      errors.add('Email is too long (max 254 characters)');
    }

    return errors.isEmpty
        ? ValidationResult.success(data: {'email': email.trim().toLowerCase()})
        : ValidationResult.failure(errors);
  }

  /// Validate password strength
  ValidationResult validatePassword(String password) {
    final errors = <String>[];

    if (password.isEmpty) {
      errors.add('Password is required');
      return ValidationResult.failure(errors);
    }

    if (password.length < 8) {
      errors.add('Password must be at least 8 characters long');
    }

    if (password.length > 128) {
      errors.add('Password is too long (max 128 characters)');
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      errors.add('Password must contain at least one lowercase letter');
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      errors.add('Password must contain at least one uppercase letter');
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      errors.add('Password must contain at least one number');
    }

    return errors.isEmpty
        ? ValidationResult.success(data: {'password': password})
        : ValidationResult.failure(errors);
  }

  /// Validate display name
  ValidationResult validateDisplayName(String displayName) {
    final errors = <String>[];

    if (displayName.isEmpty) {
      errors.add('Display name is required');
      return ValidationResult.failure(errors);
    }

    final trimmed = displayName.trim();
    if (trimmed.length < 2) {
      errors.add('Display name must be at least 2 characters long');
    }

    if (trimmed.length > 50) {
      errors.add('Display name is too long (max 50 characters)');
    }

    if (!RegExp(r'^[a-zA-Z0-9\s\-_\.]+$').hasMatch(trimmed)) {
      errors.add('Display name contains invalid characters');
    }

    return errors.isEmpty
        ? ValidationResult.success(data: {'display_name': trimmed})
        : ValidationResult.failure(errors);
  }

  /// Validate phone number
  ValidationResult validatePhoneNumber(String phoneNumber) {
    final errors = <String>[];

    if (phoneNumber.isEmpty) {
      return ValidationResult.success(data: {'phone_number': null});
    }

    final cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (!RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(cleaned)) {
      errors.add('Invalid phone number format');
    }

    if (cleaned.length < 10 || cleaned.length > 15) {
      errors.add('Phone number must be between 10 and 15 digits');
    }

    return errors.isEmpty
        ? ValidationResult.success(data: {'phone_number': cleaned})
        : ValidationResult.failure(errors);
  }

  /// Validate report data
  ValidationResult validateReportData(Map<String, dynamic> data) {
    final errors = <String>[];

    // Validate required fields
    if (data['title'] == null || (data['title'] as String).isEmpty) {
      errors.add('Title is required');
    } else {
      final title = (data['title'] as String).trim();
      if (title.length < 3) {
        errors.add('Title must be at least 3 characters long');
      }
      if (title.length > 200) {
        errors.add('Title is too long (max 200 characters)');
      }
    }

    if (data['description'] == null ||
        (data['description'] as String).isEmpty) {
      errors.add('Description is required');
    } else {
      final description = (data['description'] as String).trim();
      if (description.length < 10) {
        errors.add('Description must be at least 10 characters long');
      }
      if (description.length > 2000) {
        errors.add('Description is too long (max 2000 characters)');
      }
    }

    if (data['type'] == null || (data['type'] as String).isEmpty) {
      errors.add('Report type is required');
    } else {
      final type = data['type'] as String;
      if (!['lost', 'found'].contains(type.toLowerCase())) {
        errors.add('Report type must be either "lost" or "found"');
      }
    }

    if (data['category'] == null || (data['category'] as String).isEmpty) {
      errors.add('Category is required');
    }

    if (data['city'] == null || (data['city'] as String).isEmpty) {
      errors.add('City is required');
    }

    // Validate optional fields
    if (data['colors'] != null) {
      if (data['colors'] is! List) {
        errors.add('Colors must be a list');
      } else {
        final colors = data['colors'] as List;
        if (colors.length > 10) {
          errors.add('Too many colors (max 10)');
        }
        for (final color in colors) {
          if (color is! String || color.isEmpty) {
            errors.add('Each color must be a non-empty string');
            break;
          }
        }
      }
    }

    if (data['latitude'] != null) {
      final lat = data['latitude'];
      if (lat is! num || lat < -90 || lat > 90) {
        errors.add('Latitude must be between -90 and 90');
      }
    }

    if (data['longitude'] != null) {
      final lng = data['longitude'];
      if (lng is! num || lng < -180 || lng > 180) {
        errors.add('Longitude must be between -180 and 180');
      }
    }

    if (data['occurred_at'] != null) {
      try {
        DateTime.parse(data['occurred_at'] as String);
      } catch (e) {
        errors.add('Invalid occurred_at date format');
      }
    }

    return errors.isEmpty
        ? ValidationResult.success(data: _sanitizeReportData(data))
        : ValidationResult.failure(errors);
  }

  /// Validate message data
  ValidationResult validateMessageData(Map<String, dynamic> data) {
    final errors = <String>[];

    if (data['conversation_id'] == null ||
        (data['conversation_id'] as String).isEmpty) {
      errors.add('Conversation ID is required');
    }

    if (data['content'] == null || (data['content'] as String).isEmpty) {
      errors.add('Message content is required');
    } else {
      final content = (data['content'] as String).trim();
      if (content.isEmpty) {
        errors.add('Message content cannot be empty');
      }
      if (content.length > 2000) {
        errors.add('Message content is too long (max 2000 characters)');
      }
    }

    return errors.isEmpty
        ? ValidationResult.success(data: _sanitizeMessageData(data))
        : ValidationResult.failure(errors);
  }

  /// Validate search filters
  ValidationResult validateSearchFilters(Map<String, dynamic> filters) {
    final errors = <String>[];

    if (filters['query'] != null) {
      final query = filters['query'] as String;
      if (query.trim().length > 100) {
        errors.add('Search query is too long (max 100 characters)');
      }
    }

    if (filters['type'] != null) {
      final type = filters['type'] as String;
      if (!['lost', 'found', 'all'].contains(type.toLowerCase())) {
        errors.add('Invalid search type');
      }
    }

    if (filters['category'] != null) {
      final category = filters['category'] as String;
      if (category.trim().isEmpty) {
        errors.add('Category cannot be empty');
      }
    }

    if (filters['city'] != null) {
      final city = filters['city'] as String;
      if (city.trim().isEmpty) {
        errors.add('City cannot be empty');
      }
    }

    if (filters['latitude'] != null) {
      final lat = filters['latitude'];
      if (lat is! num || lat < -90 || lat > 90) {
        errors.add('Latitude must be between -90 and 90');
      }
    }

    if (filters['longitude'] != null) {
      final lng = filters['longitude'];
      if (lng is! num || lng < -180 || lng > 180) {
        errors.add('Longitude must be between -180 and 180');
      }
    }

    if (filters['radius_km'] != null) {
      final radius = filters['radius_km'];
      if (radius is! num || radius < 0.1 || radius > 1000) {
        errors.add('Radius must be between 0.1 and 1000 km');
      }
    }

    if (filters['page'] != null) {
      final page = filters['page'];
      if (page is! int || page < 1) {
        errors.add('Page must be a positive integer');
      }
    }

    if (filters['page_size'] != null) {
      final pageSize = filters['page_size'];
      if (pageSize is! int || pageSize < 1 || pageSize > 100) {
        errors.add('Page size must be between 1 and 100');
      }
    }

    return errors.isEmpty
        ? ValidationResult.success(data: _sanitizeSearchFilters(filters))
        : ValidationResult.failure(errors);
  }

  /// Validate media upload data
  ValidationResult validateMediaUpload(Map<String, dynamic> data) {
    final errors = <String>[];

    if (data['file_path'] == null || (data['file_path'] as String).isEmpty) {
      errors.add('File path is required');
    }

    if (data['report_id'] == null || (data['report_id'] as String).isEmpty) {
      errors.add('Report ID is required');
    }

    if (data['file_type'] != null) {
      final fileType = data['file_type'] as String;
      final allowedTypes = ['image', 'video', 'document'];
      if (!allowedTypes.contains(fileType.toLowerCase())) {
        errors.add('Invalid file type');
      }
    }

    return errors.isEmpty
        ? ValidationResult.success(data: _sanitizeMediaUploadData(data))
        : ValidationResult.failure(errors);
  }

  /// Validate location data
  ValidationResult validateLocationData(Map<String, dynamic> data) {
    final errors = <String>[];

    if (data['latitude'] == null) {
      errors.add('Latitude is required');
    } else {
      final lat = data['latitude'];
      if (lat is! num || lat < -90 || lat > 90) {
        errors.add('Latitude must be between -90 and 90');
      }
    }

    if (data['longitude'] == null) {
      errors.add('Longitude is required');
    } else {
      final lng = data['longitude'];
      if (lng is! num || lng < -180 || lng > 180) {
        errors.add('Longitude must be between -180 and 180');
      }
    }

    if (data['address'] != null) {
      final address = data['address'] as String;
      if (address.trim().length > 500) {
        errors.add('Address is too long (max 500 characters)');
      }
    }

    return errors.isEmpty
        ? ValidationResult.success(data: _sanitizeLocationData(data))
        : ValidationResult.failure(errors);
  }

  /// Validate pagination parameters
  ValidationResult validatePagination({int page = 1, int pageSize = 20}) {
    final errors = <String>[];

    if (page < 1) {
      errors.add('Page must be >= 1');
    }

    if (pageSize < 1 || pageSize > 100) {
      errors.add('Page size must be between 1 and 100');
    }

    return errors.isEmpty
        ? ValidationResult.success(data: {'page': page, 'page_size': pageSize})
        : ValidationResult.failure(errors);
  }

  // Helper methods for data sanitization

  Map<String, dynamic> _sanitizeReportData(Map<String, dynamic> data) {
    return {
      'title': (data['title'] as String?)?.trim(),
      'description': (data['description'] as String?)?.trim(),
      'type': (data['type'] as String?)?.toLowerCase(),
      'category': (data['category'] as String?)?.trim(),
      'city': (data['city'] as String?)?.trim(),
      'colors': data['colors'] as List<String>?,
      'latitude': data['latitude'] as num?,
      'longitude': data['longitude'] as num?,
      'location_address': (data['location_address'] as String?)?.trim(),
      'occurred_at': data['occurred_at'] as String?,
      'reward_offered': data['reward_offered'] as bool? ?? false,
    };
  }

  Map<String, dynamic> _sanitizeMessageData(Map<String, dynamic> data) {
    return {
      'conversation_id': data['conversation_id'] as String?,
      'content': (data['content'] as String?)?.trim(),
    };
  }

  Map<String, dynamic> _sanitizeSearchFilters(Map<String, dynamic> filters) {
    return {
      'query': (filters['query'] as String?)?.trim(),
      'type': (filters['type'] as String?)?.toLowerCase(),
      'category': (filters['category'] as String?)?.trim(),
      'city': (filters['city'] as String?)?.trim(),
      'latitude': filters['latitude'] as num?,
      'longitude': filters['longitude'] as num?,
      'radius_km': filters['radius_km'] as num?,
      'page': filters['page'] as int? ?? 1,
      'page_size': filters['page_size'] as int? ?? 20,
    };
  }

  Map<String, dynamic> _sanitizeMediaUploadData(Map<String, dynamic> data) {
    return {
      'file_path': data['file_path'] as String?,
      'report_id': data['report_id'] as String?,
      'file_type': (data['file_type'] as String?)?.toLowerCase(),
    };
  }

  Map<String, dynamic> _sanitizeLocationData(Map<String, dynamic> data) {
    return {
      'latitude': data['latitude'] as num?,
      'longitude': data['longitude'] as num?,
      'address': (data['address'] as String?)?.trim(),
      'city': (data['city'] as String?)?.trim(),
      'state': (data['state'] as String?)?.trim(),
      'country': (data['country'] as String?)?.trim(),
    };
  }

  /// Log validation errors for debugging
  void logValidationErrors(ValidationResult result, String context) {
    if (!result.isValid && kDebugMode) {
      debugPrint('🚨 Input validation failed for $context:');
      for (final error in result.errors) {
        debugPrint('  ❌ $error');
      }
    }
  }
}


