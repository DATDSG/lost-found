/// Match models for the Lost & Found mobile app
/// Comprehensive matching system with multi-signal scoring

import 'package:flutter/material.dart';

/// Match status enum
enum MatchStatus {
  pending('pending', 'Pending'),
  confirmed('confirmed', 'Confirmed'),
  rejected('rejected', 'Rejected'),
  expired('expired', 'Expired');

  const MatchStatus(this.value, this.label);
  final String value;
  final String label;
}

/// Match component for detailed scoring breakdown
class MatchComponent {
  final String name;
  final double score;
  final double weight;
  final String description;
  final Color color;

  MatchComponent({
    required this.name,
    required this.score,
    required this.weight,
    required this.description,
    required this.color,
  });

  factory MatchComponent.fromJson(Map<String, dynamic> json) {
    return MatchComponent(
      name: json['name'] ?? '',
      score: (json['score'] ?? 0.0).toDouble(),
      weight: (json['weight'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      color: _parseColor(json['color']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'score': score,
      'weight': weight,
      'description': description,
      'color': color.value.toRadixString(16),
    };
  }

  static Color _parseColor(dynamic colorValue) {
    if (colorValue is String) {
      try {
        return Color(int.parse(colorValue.replaceFirst('#', '0x')));
      } catch (e) {
        return Colors.blue;
      }
    }
    return Colors.blue;
  }
}

/// Match candidate representing a potential match
class MatchCandidate {
  final String id;
  final String reportId;
  final String matchedReportId;
  final double overallScore;
  final List<MatchComponent> components;
  final MatchStatus status;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final String? notes;

  // Related report information
  final String matchedReportTitle;
  final String matchedReportDescription;
  final String matchedReportCategory;
  final String matchedReportCity;
  final DateTime matchedReportCreatedAt;
  final List<String> matchedReportImages;
  final String matchedReportOwnerName;
  final String matchedReportOwnerId;

  MatchCandidate({
    required this.id,
    required this.reportId,
    required this.matchedReportId,
    required this.overallScore,
    required this.components,
    required this.status,
    required this.createdAt,
    this.confirmedAt,
    this.notes,
    required this.matchedReportTitle,
    required this.matchedReportDescription,
    required this.matchedReportCategory,
    required this.matchedReportCity,
    required this.matchedReportCreatedAt,
    required this.matchedReportImages,
    required this.matchedReportOwnerName,
    required this.matchedReportOwnerId,
  });

  factory MatchCandidate.fromJson(Map<String, dynamic> json) {
    return MatchCandidate(
      id: json['id'] ?? '',
      reportId: json['report_id'] ?? '',
      matchedReportId: json['matched_report_id'] ?? '',
      overallScore: (json['overall_score'] ?? 0.0).toDouble(),
      components:
          (json['components'] as List<dynamic>?)
              ?.map((c) => MatchComponent.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      status: MatchStatus.values.firstWhere(
        (s) => s.value == json['status'],
        orElse: () => MatchStatus.pending,
      ),
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'])
          : null,
      notes: json['notes'],
      matchedReportTitle: json['matched_report']?['title'] ?? '',
      matchedReportDescription: json['matched_report']?['description'] ?? '',
      matchedReportCategory: json['matched_report']?['category'] ?? '',
      matchedReportCity: json['matched_report']?['city'] ?? '',
      matchedReportCreatedAt: DateTime.parse(
        json['matched_report']?['created_at'] ??
            DateTime.now().toIso8601String(),
      ),
      matchedReportImages:
          (json['matched_report']?['images'] as List<dynamic>?)
              ?.map((img) => img.toString())
              .toList() ??
          [],
      matchedReportOwnerName:
          json['matched_report']?['owner']?['display_name'] ?? 'Anonymous',
      matchedReportOwnerId: json['matched_report']?['owner']?['id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_id': reportId,
      'matched_report_id': matchedReportId,
      'overall_score': overallScore,
      'components': components.map((c) => c.toJson()).toList(),
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'confirmed_at': confirmedAt?.toIso8601String(),
      'notes': notes,
      'matched_report': {
        'title': matchedReportTitle,
        'description': matchedReportDescription,
        'category': matchedReportCategory,
        'city': matchedReportCity,
        'created_at': matchedReportCreatedAt.toIso8601String(),
        'images': matchedReportImages,
        'owner': {
          'id': matchedReportOwnerId,
          'display_name': matchedReportOwnerName,
        },
      },
    };
  }

  MatchCandidate copyWith({
    String? id,
    String? reportId,
    String? matchedReportId,
    double? overallScore,
    List<MatchComponent>? components,
    MatchStatus? status,
    DateTime? createdAt,
    DateTime? confirmedAt,
    String? notes,
    String? matchedReportTitle,
    String? matchedReportDescription,
    String? matchedReportCategory,
    String? matchedReportCity,
    DateTime? matchedReportCreatedAt,
    List<String>? matchedReportImages,
    String? matchedReportOwnerName,
    String? matchedReportOwnerId,
  }) {
    return MatchCandidate(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      matchedReportId: matchedReportId ?? this.matchedReportId,
      overallScore: overallScore ?? this.overallScore,
      components: components ?? this.components,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      notes: notes ?? this.notes,
      matchedReportTitle: matchedReportTitle ?? this.matchedReportTitle,
      matchedReportDescription:
          matchedReportDescription ?? this.matchedReportDescription,
      matchedReportCategory:
          matchedReportCategory ?? this.matchedReportCategory,
      matchedReportCity: matchedReportCity ?? this.matchedReportCity,
      matchedReportCreatedAt:
          matchedReportCreatedAt ?? this.matchedReportCreatedAt,
      matchedReportImages: matchedReportImages ?? this.matchedReportImages,
      matchedReportOwnerName:
          matchedReportOwnerName ?? this.matchedReportOwnerName,
      matchedReportOwnerId: matchedReportOwnerId ?? this.matchedReportOwnerId,
    );
  }

  // Computed properties for UI
  bool get isConfirmed => status == MatchStatus.confirmed;
  bool get isRejected => status == MatchStatus.rejected;
  bool get isPending => status == MatchStatus.pending;
  bool get isExpired => status == MatchStatus.expired;

  String get scorePercentage => '${(overallScore * 100).round()}%';
  String get statusLabel => status.label;

  Color get statusColor {
    switch (status) {
      case MatchStatus.confirmed:
        return Colors.green;
      case MatchStatus.rejected:
        return Colors.red;
      case MatchStatus.pending:
        return Colors.orange;
      case MatchStatus.expired:
        return Colors.grey;
    }
  }

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

/// Match analytics for dashboard and insights
class MatchAnalytics {
  final int totalMatches;
  final int confirmedMatches;
  final int pendingMatches;
  final int rejectedMatches;
  final double averageScore;
  final double confirmationRate;
  final List<MatchComponent> topComponents;
  final Map<String, int> categoryBreakdown;
  final Map<String, int> monthlyTrend;

  MatchAnalytics({
    required this.totalMatches,
    required this.confirmedMatches,
    required this.pendingMatches,
    required this.rejectedMatches,
    required this.averageScore,
    required this.confirmationRate,
    required this.topComponents,
    required this.categoryBreakdown,
    required this.monthlyTrend,
  });

  factory MatchAnalytics.fromJson(Map<String, dynamic> json) {
    return MatchAnalytics(
      totalMatches: json['total_matches'] ?? 0,
      confirmedMatches: json['confirmed_matches'] ?? 0,
      pendingMatches: json['pending_matches'] ?? 0,
      rejectedMatches: json['rejected_matches'] ?? 0,
      averageScore: (json['average_score'] ?? 0.0).toDouble(),
      confirmationRate: (json['confirmation_rate'] ?? 0.0).toDouble(),
      topComponents:
          (json['top_components'] as List<dynamic>?)
              ?.map((c) => MatchComponent.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      categoryBreakdown: Map<String, int>.from(
        json['category_breakdown'] ?? {},
      ),
      monthlyTrend: Map<String, int>.from(json['monthly_trend'] ?? {}),
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
      'top_components': topComponents.map((c) => c.toJson()).toList(),
      'category_breakdown': categoryBreakdown,
      'monthly_trend': monthlyTrend,
    };
  }

  // Computed properties
  int get activeMatches => pendingMatches;
  String get confirmationRatePercentage =>
      '${(confirmationRate * 100).round()}%';
  String get averageScorePercentage => '${(averageScore * 100).round()}%';
}
