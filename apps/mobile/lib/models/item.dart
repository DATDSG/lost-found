/// Item model for lost and found items
class Item {
  final String id;
  final String title;
  final String description;
  final String type; // 'lost' or 'found'
  final String category;
  final String? location;
  final DateTime dateReported;
  final DateTime? dateLost;
  final List<String> imageUrls;
  final String status; // 'active', 'resolved', 'draft'
  final String userId;

  Item({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    this.location,
    required this.dateReported,
    this.dateLost,
    this.imageUrls = const [],
    this.status = 'active',
    required this.userId,
  });

  /// Check if item is lost type
  bool get isLost => type == 'lost';

  /// Check if item is found type
  bool get isFound => type == 'found';

  /// Check if item is active
  bool get isActive => status == 'active';

  /// Create Item from JSON
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'lost',
      category: json['category'] ?? '',
      location: json['location'],
      dateReported: json['date_reported'] != null
          ? DateTime.parse(json['date_reported'])
          : DateTime.now(),
      dateLost:
          json['date_lost'] != null ? DateTime.parse(json['date_lost']) : null,
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'])
          : [],
      status: json['status'] ?? 'active',
      userId: json['user_id'] ?? json['userId'] ?? '',
    );
  }

  /// Convert Item to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'category': category,
      if (location != null) 'location': location,
      'date_reported': dateReported.toIso8601String(),
      if (dateLost != null) 'date_lost': dateLost!.toIso8601String(),
      'image_urls': imageUrls,
      'status': status,
      'user_id': userId,
    };
  }

  /// Create a copy with updated fields
  Item copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    String? category,
    String? location,
    DateTime? dateReported,
    DateTime? dateLost,
    List<String>? imageUrls,
    String? status,
    String? userId,
  }) {
    return Item(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      location: location ?? this.location,
      dateReported: dateReported ?? this.dateReported,
      dateLost: dateLost ?? this.dateLost,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      userId: userId ?? this.userId,
    );
  }
}
