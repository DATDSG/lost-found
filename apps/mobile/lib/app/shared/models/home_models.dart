// Models for the home screen

/// Type of item in the report
enum ItemType {
  /// Lost item
  lost,

  /// Found item
  found,
}

/// Report item model for home screen display
class ReportItem {
  /// Creates a new [ReportItem] instance
  ReportItem({
    required this.id,
    required this.name,
    required this.category,
    required this.itemType,
    required this.location,
    required this.distance,
    required this.timeAgo,
    required this.description,
    required this.contactInfo,
    required this.createdAt,
    this.imageUrl,
    this.colors = const [],
  });

  /// Unique identifier for the report
  final String id;

  /// Name of the item
  final String name;

  /// Category of the item
  final String category;

  /// Colors of the item
  final List<String> colors;

  /// Type of the item (lost or found)
  final ItemType itemType;

  /// Location where the item was lost/found
  final String location;

  /// Distance from user's location
  final String distance;

  /// Time ago when the item was reported
  final String timeAgo;

  /// URL of the item's image
  final String? imageUrl;

  /// Description of the item
  final String description;

  /// Contact information for the reporter
  final String contactInfo;

  /// When the report was created
  final DateTime createdAt;
}

/// Filter options for home screen reports
class FilterOptions {
  /// Creates a new [FilterOptions] instance
  FilterOptions({
    this.itemType,
    this.timeFilter,
    this.distanceFilter,
    this.categoryFilter,
    this.colorFilter,
    this.locationFilter,
  });

  /// Filter by item type
  final ItemType? itemType;

  /// Filter by time range
  final String? timeFilter;

  /// Filter by distance range
  final String? distanceFilter;

  /// Filter by category
  final String? categoryFilter;

  /// Filter by color
  final String? colorFilter;

  /// Filter by location
  final String? locationFilter;

  /// Whether any filters are currently active
  bool get hasActiveFilters =>
      itemType != null ||
      (timeFilter != null && timeFilter != 'Any Time') ||
      (distanceFilter != null && distanceFilter != 'Any Distance') ||
      (categoryFilter != null && categoryFilter != 'All') ||
      (colorFilter != null && colorFilter != 'All') ||
      (locationFilter != null && locationFilter!.isNotEmpty);

  /// Creates a copy of this [FilterOptions] with the given fields replaced
  FilterOptions copyWith({
    ItemType? itemType,
    String? timeFilter,
    String? distanceFilter,
    String? categoryFilter,
    String? colorFilter,
    String? locationFilter,
  }) => FilterOptions(
    itemType: itemType ?? this.itemType,
    timeFilter: timeFilter ?? this.timeFilter,
    distanceFilter: distanceFilter ?? this.distanceFilter,
    categoryFilter: categoryFilter ?? this.categoryFilter,
    colorFilter: colorFilter ?? this.colorFilter,
    locationFilter: locationFilter ?? this.locationFilter,
  );
}
