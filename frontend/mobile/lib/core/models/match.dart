import 'item.dart';

class MatchScore {
  final double category;
  final double distance;
  final double time;
  final double attributes;
  final double? text;
  final double? image;
  final double total;

  const MatchScore({
    required this.category,
    required this.distance,
    required this.time,
    required this.attributes,
    this.text,
    this.image,
    required this.total,
  });
}

class MatchExplanation {
  final double distanceKm;
  final double timeDiffHours;
  final bool categoryMatch;
  final List<String> attributeMatches;
  final String confidenceLevel;
  final String summary;

  const MatchExplanation({
    required this.distanceKm,
    required this.timeDiffHours,
    required this.categoryMatch,
    required this.attributeMatches,
    required this.confidenceLevel,
    required this.summary,
  });
}

class ItemMatch {
  final String id;
  final String sourceItemId;
  final Item matchedItem;
  final MatchScore score;
  final MatchExplanation explanation;
  final DateTime createdAt;
  final bool viewed;
  final bool dismissed;

  const ItemMatch({
    required this.id,
    required this.sourceItemId,
    required this.matchedItem,
    required this.score,
    required this.explanation,
    required this.createdAt,
    this.viewed = false,
    this.dismissed = false,
  });

  ItemMatch copyWith({
    String? id,
    String? sourceItemId,
    Item? matchedItem,
    MatchScore? score,
    MatchExplanation? explanation,
    DateTime? createdAt,
    bool? viewed,
    bool? dismissed,
  }) {
    return ItemMatch(
      id: id ?? this.id,
      sourceItemId: sourceItemId ?? this.sourceItemId,
      matchedItem: matchedItem ?? this.matchedItem,
      score: score ?? this.score,
      explanation: explanation ?? this.explanation,
      createdAt: createdAt ?? this.createdAt,
      viewed: viewed ?? this.viewed,
      dismissed: dismissed ?? this.dismissed,
    );
  }
}
