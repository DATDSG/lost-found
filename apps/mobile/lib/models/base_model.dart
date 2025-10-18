/// Base model class with common serialization patterns
abstract class BaseModel {
  /// Convert model to JSON
  Map<String, dynamic> toJson();

  /// Create model from JSON
  static T fromJson<T extends BaseModel>(Map<String, dynamic> json) {
    throw UnimplementedError('fromJson must be implemented by subclasses');
  }

  /// Create a copy of the model with updated fields
  T copyWith<T extends BaseModel>();

  /// Parse DateTime from JSON with fallback
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Parse DateTime from JSON with default value
  static DateTime parseDateTimeWithDefault(
      dynamic value, DateTime defaultValue) {
    return parseDateTime(value) ?? defaultValue;
  }

  /// Parse double from JSON with fallback
  static double? parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Parse double from JSON with default value
  static double parseDoubleWithDefault(dynamic value, double defaultValue) {
    return parseDouble(value) ?? defaultValue;
  }

  /// Parse int from JSON with fallback
  static int? parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Parse int from JSON with default value
  static int parseIntWithDefault(dynamic value, int defaultValue) {
    return parseInt(value) ?? defaultValue;
  }

  /// Parse bool from JSON with fallback
  static bool? parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return null;
  }

  /// Parse bool from JSON with default value
  static bool parseBoolWithDefault(dynamic value, bool defaultValue) {
    return parseBool(value) ?? defaultValue;
  }

  /// Parse string from JSON with fallback
  static String? parseString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  /// Parse string from JSON with default value
  static String parseStringWithDefault(dynamic value, String defaultValue) {
    return parseString(value) ?? defaultValue;
  }

  /// Parse list from JSON with fallback
  static List<T>? parseList<T>(dynamic value, T Function(dynamic) fromJson) {
    if (value == null) return null;
    if (value is List) {
      return value.map((item) => fromJson(item)).toList();
    }
    return null;
  }

  /// Parse list from JSON with default value
  static List<T> parseListWithDefault<T>(
      dynamic value, T Function(dynamic) fromJson, List<T> defaultValue) {
    return parseList(value, fromJson) ?? defaultValue;
  }

  /// Parse map from JSON with fallback
  static Map<String, dynamic>? parseMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  /// Parse map from JSON with default value
  static Map<String, dynamic> parseMapWithDefault(
      dynamic value, Map<String, dynamic> defaultValue) {
    return parseMap(value) ?? defaultValue;
  }
}
