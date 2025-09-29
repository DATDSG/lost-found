class MatchDto {
  const MatchDto({
    required this.id,
    required this.lostItemId,
    required this.foundItemId,
    required this.score,
  });

  final int id;
  final int lostItemId;
  final int foundItemId;
  final double score;

  factory MatchDto.fromJson(Map<String, dynamic> json) {
    return MatchDto(
      id: json['id'] as int,
      lostItemId: json['lost_item_id'] as int,
      foundItemId: json['found_item_id'] as int,
      score: (json['score'] as num).toDouble(),
    );
  }

  int otherItemIdFor(int itemId) => itemId == lostItemId ? foundItemId : lostItemId;
}
