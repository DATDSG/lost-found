class Match {
  final String id;
  final String itemName;
  final String description;
  final String category;
  final String location;
  final DateTime date;
  final String? imageUrl;
  final int matchScore;
  final String type; // 'lost' or 'found'
  final String matchedItemId;
  final String ownerId;
  final String ownerName;
  final String status; // 'pending', 'confirmed', 'rejected'
  final double overallScore;
  final DateTime createdAt;

  Match({
    required this.id,
    required this.itemName,
    required this.description,
    required this.category,
    required this.location,
    required this.date,
    this.imageUrl,
    required this.matchScore,
    required this.type,
    required this.matchedItemId,
    required this.ownerId,
    required this.ownerName,
    this.status = 'pending',
    this.overallScore = 0.0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] ?? '',
      itemName: json['item_name'] ?? json['itemName'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      location: json['location'] ?? '',
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      imageUrl: json['image_url'] ?? json['imageUrl'],
      matchScore: json['match_score'] ?? json['matchScore'] ?? 0,
      type: json['type'] ?? '',
      matchedItemId: json['matched_item_id'] ?? json['matchedItemId'] ?? '',
      ownerId: json['owner_id'] ?? json['ownerId'] ?? '',
      ownerName: json['owner_name'] ?? json['ownerName'] ?? 'Unknown',
      status: json['status'] ?? 'pending',
      overallScore:
          (json['overall_score'] ?? json['overallScore'] ?? 0.0).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_name': itemName,
      'description': description,
      'category': category,
      'location': location,
      'date': date.toIso8601String(),
      'image_url': imageUrl,
      'match_score': matchScore,
      'type': type,
      'matched_item_id': matchedItemId,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'status': status,
      'overall_score': overallScore,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Match copyWith({
    String? id,
    String? itemName,
    String? description,
    String? category,
    String? location,
    DateTime? date,
    String? imageUrl,
    int? matchScore,
    String? type,
    String? matchedItemId,
    String? ownerId,
    String? ownerName,
    String? status,
    double? overallScore,
    DateTime? createdAt,
  }) {
    return Match(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      date: date ?? this.date,
      imageUrl: imageUrl ?? this.imageUrl,
      matchScore: matchScore ?? this.matchScore,
      type: type ?? this.type,
      matchedItemId: matchedItemId ?? this.matchedItemId,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      status: status ?? this.status,
      overallScore: overallScore ?? this.overallScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Computed properties
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isRejected => status == 'rejected';

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Match statistics class
class MatchStats {
  final int totalMatches;
  final int confirmedMatches;
  final int pendingMatches;
  final int rejectedMatches;
  final double averageScore;
  final double confirmationRate;

  MatchStats({
    required this.totalMatches,
    required this.confirmedMatches,
    required this.pendingMatches,
    required this.rejectedMatches,
    required this.averageScore,
    required this.confirmationRate,
  });

  factory MatchStats.fromJson(Map<String, dynamic> json) {
    return MatchStats(
      totalMatches: json['total_matches'] ?? 0,
      confirmedMatches: json['confirmed_matches'] ?? 0,
      pendingMatches: json['pending_matches'] ?? 0,
      rejectedMatches: json['rejected_matches'] ?? 0,
      averageScore: (json['average_score'] ?? 0.0).toDouble(),
      confirmationRate: (json['confirmation_rate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_matches': totalMatches,
      'confirmed_matches': confirmedMatches,
      'pending_matches': pendingMatches,
      'rejected_matches': rejectedMatches,
      'average_score': averageScore,
      'confirmation_rate': confirmationRate,
    };
  }
}
