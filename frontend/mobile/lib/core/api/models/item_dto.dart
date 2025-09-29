class ItemDto {
  const ItemDto({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    this.description,
    this.ownerId,
    this.lat,
    this.lng,
  });

  final int id;
  final String title;
  final String status;
  final DateTime createdAt;
  final String? description;
  final int? ownerId;
  final double? lat;
  final double? lng;

  factory ItemDto.fromJson(Map<String, dynamic> json) {
    return ItemDto(
      id: json['id'] as int,
      title: json['title'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      description: json['description'] as String?,
      ownerId: json['owner_id'] as int?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }
}
