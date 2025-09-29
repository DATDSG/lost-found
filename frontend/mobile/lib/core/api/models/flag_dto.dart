class FlagDto {
  const FlagDto({
    required this.id,
    required this.itemId,
    required this.source,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final int itemId;
  final String source;
  final String reason;
  final String status;
  final DateTime createdAt;

  factory FlagDto.fromJson(Map<String, dynamic> json) {
    return FlagDto(
      id: json['id'] as int,
      itemId: json['item_id'] as int,
      source: json['source'] as String,
      reason: json['reason'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
