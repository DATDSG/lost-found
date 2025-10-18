import 'package:flutter/material.dart';

/// Search and filter models for the Lost & Found mobile app
/// Comprehensive filtering system with modern UI integration

/// Search filters with all necessary options
class SearchFilters {
  final String? search;
  final String? type;
  final String? category;
  final String? status;
  final String? city;
  final double? minLatitude;
  final double? maxLatitude;
  final double? minLongitude;
  final double? maxLongitude;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? colors;
  final bool? rewardOffered;
  final double? maxDistance; // in kilometers
  final String? sortBy; // 'date', 'distance', 'relevance'
  final int? page;
  final int? pageSize;

  SearchFilters({
    this.search,
    this.type,
    this.category,
    this.status,
    this.city,
    this.minLatitude,
    this.maxLatitude,
    this.minLongitude,
    this.maxLongitude,
    this.startDate,
    this.endDate,
    this.colors,
    this.rewardOffered,
    this.maxDistance,
    this.sortBy,
    this.page,
    this.pageSize,
  });

  /// Convert filters to query parameters
  Map<String, String> toQueryParams() {
    final params = <String, String>{};

    if (search != null && search!.isNotEmpty) {
      params['search'] = search!;
    }
    if (type != null && type!.isNotEmpty) {
      params['type'] = type!;
    }
    if (category != null && category!.isNotEmpty) {
      params['category'] = category!;
    }
    if (status != null && status!.isNotEmpty) {
      params['status'] = status!;
    }
    if (city != null && city!.isNotEmpty) {
      params['city'] = city!;
    }
    if (minLatitude != null) {
      params['min_latitude'] = minLatitude!.toString();
    }
    if (maxLatitude != null) {
      params['max_latitude'] = maxLatitude!.toString();
    }
    if (minLongitude != null) {
      params['min_longitude'] = minLongitude!.toString();
    }
    if (maxLongitude != null) {
      params['max_longitude'] = maxLongitude!.toString();
    }
    if (startDate != null) {
      params['start_date'] = startDate!.toIso8601String();
    }
    if (endDate != null) {
      params['end_date'] = endDate!.toIso8601String();
    }
    if (colors != null && colors!.isNotEmpty) {
      params['colors'] = colors!.join(',');
    }
    if (rewardOffered != null) {
      params['reward_offered'] = rewardOffered!.toString();
    }
    if (maxDistance != null) {
      params['max_distance'] = maxDistance!.toString();
    }
    if (sortBy != null && sortBy!.isNotEmpty) {
      params['sort_by'] = sortBy!;
    }
    if (page != null) {
      params['page'] = page!.toString();
    }
    if (pageSize != null) {
      params['page_size'] = pageSize!.toString();
    }

    return params;
  }

  /// Create a copy with updated values
  SearchFilters copyWith({
    String? search,
    String? type,
    String? category,
    String? status,
    String? city,
    double? minLatitude,
    double? maxLatitude,
    double? minLongitude,
    double? maxLongitude,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? colors,
    bool? rewardOffered,
    double? maxDistance,
    String? sortBy,
    int? page,
    int? pageSize,
  }) {
    return SearchFilters(
      search: search ?? this.search,
      type: type ?? this.type,
      category: category ?? this.category,
      status: status ?? this.status,
      city: city ?? this.city,
      minLatitude: minLatitude ?? this.minLatitude,
      maxLatitude: maxLatitude ?? this.maxLatitude,
      minLongitude: minLongitude ?? this.minLongitude,
      maxLongitude: maxLongitude ?? this.maxLongitude,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      colors: colors ?? this.colors,
      rewardOffered: rewardOffered ?? this.rewardOffered,
      maxDistance: maxDistance ?? this.maxDistance,
      sortBy: sortBy ?? this.sortBy,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  /// Check if any filters are active
  bool get hasActiveFilters {
    return search != null ||
        type != null ||
        category != null ||
        status != null ||
        city != null ||
        colors != null ||
        rewardOffered != null ||
        maxDistance != null ||
        sortBy != null ||
        startDate != null ||
        endDate != null;
  }

  /// Get count of active filters
  int get activeFilterCount {
    int count = 0;
    if (search != null && search!.isNotEmpty) count++;
    if (type != null) count++;
    if (category != null) count++;
    if (status != null) count++;
    if (city != null && city!.isNotEmpty) count++;
    if (colors != null && colors!.isNotEmpty) count++;
    if (rewardOffered != null) count++;
    if (maxDistance != null) count++;
    if (sortBy != null) count++;
    if (startDate != null) count++;
    if (endDate != null) count++;
    return count;
  }

  /// Reset all filters
  SearchFilters clear() {
    return SearchFilters();
  }

  /// Convert to Map for API calls
  Map<String, dynamic> toMap() {
    return {
      if (search != null && search!.isNotEmpty) 'search': search!,
      if (type != null && type!.isNotEmpty) 'type': type!,
      if (category != null && category!.isNotEmpty) 'category': category!,
      if (status != null && status!.isNotEmpty) 'status': status!,
      if (city != null && city!.isNotEmpty) 'city': city!,
      if (minLatitude != null) 'min_latitude': minLatitude!,
      if (maxLatitude != null) 'max_latitude': maxLatitude!,
      if (minLongitude != null) 'min_longitude': minLongitude!,
      if (maxLongitude != null) 'max_longitude': maxLongitude!,
      if (startDate != null) 'start_date': startDate!.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
      if (colors != null && colors!.isNotEmpty) 'colors': colors!,
      if (rewardOffered != null) 'reward_offered': rewardOffered!,
      if (maxDistance != null) 'max_distance': maxDistance!,
      if (sortBy != null && sortBy!.isNotEmpty) 'sort_by': sortBy!,
      if (page != null) 'page': page!,
      if (pageSize != null) 'page_size': pageSize!,
    };
  }

  /// Get query string for search
  String? get query => search;

  /// Get latitude bounds
  double? get latitude => minLatitude;
  double? get longitude => minLongitude;
  double? get radiusKm => maxDistance;
}

/// Search suggestion model
class SearchSuggestion {
  final String text;
  final String type; // 'recent', 'popular', 'category'
  final String? category;
  final int? count; // for popular searches

  SearchSuggestion({
    required this.text,
    required this.type,
    this.category,
    this.count,
  });

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      text: json['text'] as String,
      type: json['type'] as String,
      category: json['category'] as String?,
      count: json['count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'text': text, 'type': type, 'category': category, 'count': count};
  }
}

/// Filter option model for UI
class FilterOption {
  final String value;
  final String label;
  final IconData? icon;
  final Color? color;
  final int? count; // number of items with this filter

  FilterOption({
    required this.value,
    required this.label,
    this.icon,
    this.color,
    this.count,
  });
}

/// Search result model with additional metadata
class SearchResult {
  final String id;
  final String title;
  final String description;
  final String type;
  final String category;
  final String city;
  final DateTime createdAt;
  final DateTime occurredAt;
  final List<String>? colors;
  final bool? rewardOffered;
  final double? latitude;
  final double? longitude;
  final double? distance; // distance from user location
  final double? relevanceScore; // AI relevance score
  final List<String>? media;

  SearchResult({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.city,
    required this.createdAt,
    required this.occurredAt,
    this.colors,
    this.rewardOffered,
    this.latitude,
    this.longitude,
    this.distance,
    this.relevanceScore,
    this.media,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      category: json['category'] as String,
      city: json['city'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      colors: (json['colors'] as List<dynamic>?)?.cast<String>(),
      rewardOffered: json['reward_offered'] as bool?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distance: (json['distance'] as num?)?.toDouble(),
      relevanceScore: (json['relevance_score'] as num?)?.toDouble(),
      media: (json['media'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'category': category,
      'city': city,
      'created_at': createdAt.toIso8601String(),
      'occurred_at': occurredAt.toIso8601String(),
      'colors': colors,
      'reward_offered': rewardOffered,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'relevance_score': relevanceScore,
      'media': media,
    };
  }

  /// Check if this is a lost item
  bool get isLost => type.toLowerCase() == 'lost';

  /// Check if this is a found item
  bool get isFound => type.toLowerCase() == 'found';
}

/// Search analytics model
class SearchAnalytics {
  final int totalSearches;
  final int uniqueSearches;
  final Map<String, int> popularQueries;
  final Map<String, int> categoryBreakdown;
  final Map<String, int> typeBreakdown;
  final Map<String, int> monthlyTrend;
  final double averageResultsPerSearch;
  final double searchSuccessRate;

  SearchAnalytics({
    required this.totalSearches,
    required this.uniqueSearches,
    required this.popularQueries,
    required this.categoryBreakdown,
    required this.typeBreakdown,
    required this.monthlyTrend,
    required this.averageResultsPerSearch,
    required this.searchSuccessRate,
  });

  factory SearchAnalytics.fromJson(Map<String, dynamic> json) {
    return SearchAnalytics(
      totalSearches: json['total_searches'] ?? 0,
      uniqueSearches: json['unique_searches'] ?? 0,
      popularQueries: Map<String, int>.from(json['popular_queries'] ?? {}),
      categoryBreakdown: Map<String, int>.from(
        json['category_breakdown'] ?? {},
      ),
      typeBreakdown: Map<String, int>.from(json['type_breakdown'] ?? {}),
      monthlyTrend: Map<String, int>.from(json['monthly_trend'] ?? {}),
      averageResultsPerSearch:
          (json['average_results_per_search'] ?? 0.0).toDouble(),
      searchSuccessRate: (json['search_success_rate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_searches': totalSearches,
      'unique_searches': uniqueSearches,
      'popular_queries': popularQueries,
      'category_breakdown': categoryBreakdown,
      'type_breakdown': typeBreakdown,
      'monthly_trend': monthlyTrend,
      'average_results_per_search': averageResultsPerSearch,
      'search_success_rate': searchSuccessRate,
    };
  }

  // Computed properties
  String get searchSuccessRatePercentage =>
      '${(searchSuccessRate * 100).round()}%';
  String get averageResultsFormatted =>
      averageResultsPerSearch.toStringAsFixed(1);
}

/// Search state enum
enum SearchState { idle, searching, loadingMore, loaded, error, empty, success }

/// Search sort options
enum SearchSortOption {
  relevance('relevance', 'Most Relevant'),
  dateNewest('date_newest', 'Newest First'),
  dateOldest('date_oldest', 'Oldest First'),
  distance('distance', 'Nearest First'),
  title('title', 'Alphabetical');

  const SearchSortOption(this.value, this.label);
  final String value;
  final String label;
}

/// Filter categories for UI organization
enum FilterCategory {
  type('Type', Icons.category_rounded),
  category('Category', Icons.label_rounded),
  location('Location', Icons.location_on_rounded),
  time('Time', Icons.schedule_rounded),
  attributes('Attributes', Icons.tune_rounded),
  advanced('Advanced', Icons.settings_rounded);

  const FilterCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}
