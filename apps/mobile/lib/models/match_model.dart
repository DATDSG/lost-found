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
  });

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
    };
  }
}
