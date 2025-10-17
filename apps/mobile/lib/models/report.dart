import 'media.dart';

/// Report Model - matches backend ReportSummary and ReportDetail schemas
class Report {
  final String id;
  final String type; // 'lost' or 'found'
  final String status;
  final String title;
  final String description;
  final String category;
  final String city; // Backend uses 'city' in ReportSummary
  final List<String>? colors;
  final DateTime occurredAt;
  final String? locationAddress;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final bool? rewardOffered;
  final bool isResolved;
  final List<Media> media; // Array of Media objects

  Report({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.description,
    required this.category,
    required this.city,
    this.colors,
    required this.occurredAt,
    this.locationAddress,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.rewardOffered,
    this.isResolved = false,
    this.media = const [],
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String,
      city:
          json['city'] as String? ??
          json['location_city'] as String? ??
          'Unknown',
      colors: json['colors'] != null
          ? List<String>.from(json['colors'] as List)
          : null,
      // Handle both ReportSummary (no occurred_at) and ReportDetail (has occurred_at)
      occurredAt: json['occurred_at'] != null
          ? DateTime.parse(json['occurred_at'] as String)
          : DateTime.parse(
              json['created_at'] as String,
            ), // Fallback to created_at
      locationAddress: json['location_address'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      createdAt: DateTime.parse(json['created_at'] as String),
      rewardOffered: json['reward_offered'] as bool?,
      isResolved: json['is_resolved'] as bool? ?? false,
      media: json['media'] != null
          ? (json['media'] as List).map((m) => Media.fromJson(m)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'status': status,
      'title': title,
      'description': description,
      'category': category,
      'city': city,
      'colors': colors,
      'occurred_at': occurredAt.toIso8601String(),
      'location_address': locationAddress,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
      'reward_offered': rewardOffered,
      'is_resolved': isResolved,
      'media': media.map((m) => m.toJson()).toList(),
    };
  }

  bool get isLost => type == 'lost';
  bool get isFound => type == 'found';
}
