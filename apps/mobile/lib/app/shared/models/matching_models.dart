// Models for the matching functionality

/// Type of report (lost or found)
enum ReportType {
  /// Lost item report
  lost,

  /// Found item report
  found,
}

/// Status of a match
enum MatchStatus {
  /// Match is pending review
  pending,

  /// Match has been accepted
  accepted,

  /// Match has been rejected
  rejected,

  /// Match is under review
  underReview,
}

/// Match score breakdown
class MatchScore {
  /// Creates a new [MatchScore] instance
  const MatchScore({
    required this.textSimilarity,
    required this.imageSimilarity,
    required this.locationProximity,
    required this.totalScore,
  });

  /// Creates a [MatchScore] instance from a JSON map
  factory MatchScore.fromJson(Map<String, dynamic> json) => MatchScore(
    textSimilarity: (json['text_similarity'] as num).toDouble(),
    imageSimilarity: (json['image_similarity'] as num).toDouble(),
    locationProximity: (json['location_proximity'] as num).toDouble(),
    totalScore: (json['total_score'] as num).toDouble(),
  );

  /// Text similarity score (0.0 to 1.0)
  final double textSimilarity;

  /// Image similarity score (0.0 to 1.0)
  final double imageSimilarity;

  /// Location proximity score (0.0 to 1.0)
  final double locationProximity;

  /// Total combined score (0.0 to 1.0)
  final double totalScore;

  /// Converts this [MatchScore] instance to a JSON map
  Map<String, dynamic> toJson() => {
    'text_similarity': textSimilarity,
    'image_similarity': imageSimilarity,
    'location_proximity': locationProximity,
    'total_score': totalScore,
  };
}

/// User's report model
class UserReport {
  /// Creates a new [UserReport] instance
  const UserReport({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.location,
    required this.createdAt,
    required this.status,
    required this.matchCount,
    this.imageUrl,
    this.colors = const [],
    this.isUrgent = false,
    this.rewardOffered = false,
    this.rewardAmount,
  });

  /// Creates a [UserReport] instance from a JSON map
  factory UserReport.fromJson(Map<String, dynamic> json) => UserReport(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    type: ReportType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => ReportType.lost,
    ),
    category: json['category'] as String,
    location: json['location'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    status: json['status'] as String,
    matchCount: json['match_count'] as int,
    imageUrl: json['image_url'] as String?,
    colors: (json['colors'] as List<dynamic>?)?.cast<String>() ?? const [],
    isUrgent: json['is_urgent'] as bool? ?? false,
    rewardOffered: json['reward_offered'] as bool? ?? false,
    rewardAmount: json['reward_amount'] as String?,
  );

  /// Unique identifier for the report
  final String id;

  /// Title of the report
  final String title;

  /// Description of the item
  final String description;

  /// Type of report (lost or found)
  final ReportType type;

  /// Category of the item
  final String category;

  /// Location where the item was lost/found
  final String location;

  /// When the report was created
  final DateTime createdAt;

  /// Current status of the report
  final String status;

  /// Number of matches found for this report
  final int matchCount;

  /// URL of the item's image
  final String? imageUrl;

  /// Colors of the item
  final List<String> colors;

  /// Whether this is urgent
  final bool isUrgent;

  /// Whether a reward is offered
  final bool rewardOffered;

  /// Amount of reward offered
  final String? rewardAmount;

  /// Converts this [UserReport] instance to a JSON map
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type.name,
    'category': category,
    'location': location,
    'created_at': createdAt.toIso8601String(),
    'status': status,
    'match_count': matchCount,
    'image_url': imageUrl,
    'colors': colors,
    'is_urgent': isUrgent,
    'reward_offered': rewardOffered,
    'reward_amount': rewardAmount,
  };
}

/// Match model representing a potential match between reports
class Match {
  /// Creates a new [Match] instance
  const Match({
    required this.id,
    required this.sourceReportId,
    required this.targetReportId,
    required this.score,
    required this.status,
    required this.createdAt,
    required this.sourceReport,
    required this.targetReport,
    this.notes,
    this.reviewedAt,
    this.isViewed = false,
  });

  /// Creates a [Match] instance from a JSON map
  factory Match.fromJson(Map<String, dynamic> json) => Match(
    id: json['id'] as String,
    sourceReportId: json['source_report_id'] as String,
    targetReportId: json['target_report_id'] as String,
    score: MatchScore.fromJson(json['score'] as Map<String, dynamic>),
    status: MatchStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => MatchStatus.pending,
    ),
    createdAt: DateTime.parse(json['created_at'] as String),
    sourceReport: UserReport.fromJson(
      json['source_report'] as Map<String, dynamic>,
    ),
    targetReport: UserReport.fromJson(
      json['target_report'] as Map<String, dynamic>,
    ),
    notes: json['notes'] as String?,
    reviewedAt: json['reviewed_at'] != null
        ? DateTime.parse(json['reviewed_at'] as String)
        : null,
    isViewed: json['is_viewed'] as bool? ?? false,
  );

  /// Unique identifier for the match
  final String id;

  /// ID of the source report (user's report)
  final String sourceReportId;

  /// ID of the target report (matched report)
  final String targetReportId;

  /// Match score breakdown
  final MatchScore score;

  /// Current status of the match
  final MatchStatus status;

  /// When the match was created
  final DateTime createdAt;

  /// Source report details
  final UserReport sourceReport;

  /// Target report details
  final UserReport targetReport;

  /// Additional notes about the match
  final String? notes;

  /// When the match was reviewed
  final DateTime? reviewedAt;

  /// Whether the match has been viewed by the user
  final bool isViewed;

  /// Converts this [Match] instance to a JSON map
  Map<String, dynamic> toJson() => {
    'id': id,
    'source_report_id': sourceReportId,
    'target_report_id': targetReportId,
    'score': score.toJson(),
    'status': status.name,
    'created_at': createdAt.toIso8601String(),
    'source_report': sourceReport.toJson(),
    'target_report': targetReport.toJson(),
    'notes': notes,
    'reviewed_at': reviewedAt?.toIso8601String(),
    'is_viewed': isViewed,
  };
}

/// Report with matches model
class ReportWithMatches {
  /// Creates a new [ReportWithMatches] instance
  const ReportWithMatches({required this.report, required this.matches});

  /// Creates a [ReportWithMatches] instance from a JSON map
  factory ReportWithMatches.fromJson(Map<String, dynamic> json) =>
      ReportWithMatches(
        report: UserReport.fromJson(json['report'] as Map<String, dynamic>),
        matches: (json['matches'] as List<dynamic>)
            .map((match) => Match.fromJson(match as Map<String, dynamic>))
            .toList(),
      );

  /// The user's report
  final UserReport report;

  /// List of matches for this report
  final List<Match> matches;

  /// Converts this [ReportWithMatches] instance to a JSON map
  Map<String, dynamic> toJson() => {
    'report': report.toJson(),
    'matches': matches.map((match) => match.toJson()).toList(),
  };
}
