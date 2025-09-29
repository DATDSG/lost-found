import 'item.dart';

enum ClaimStatus { pending, approved, rejected, expired }

class ClaimEvidence {
  final String type; // 'image', 'text', 'document'
  final String content; // URL for images/documents, text for descriptions
  final String? description;
  final bool
  isSensitive; // Whether this contains personal info that should be hashed

  const ClaimEvidence({
    required this.type,
    required this.content,
    this.description,
    this.isSensitive = false,
  });
}

class Claim {
  final String id;
  final String itemId;
  final String claimantId;
  final String? claimantName;
  final ClaimStatus status;
  final String description;
  final List<ClaimEvidence> evidence;
  final Map<String, dynamic> contactInfo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? reviewedAt;
  final String? reviewerNotes;
  final Item? item; // Populated when fetching claim details

  const Claim({
    required this.id,
    required this.itemId,
    required this.claimantId,
    this.claimantName,
    required this.status,
    required this.description,
    required this.evidence,
    required this.contactInfo,
    required this.createdAt,
    required this.updatedAt,
    this.reviewedAt,
    this.reviewerNotes,
    this.item,
  });

  Claim copyWith({
    String? id,
    String? itemId,
    String? claimantId,
    String? claimantName,
    ClaimStatus? status,
    String? description,
    List<ClaimEvidence>? evidence,
    Map<String, dynamic>? contactInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? reviewedAt,
    String? reviewerNotes,
    Item? item,
  }) {
    return Claim(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      claimantId: claimantId ?? this.claimantId,
      claimantName: claimantName ?? this.claimantName,
      status: status ?? this.status,
      description: description ?? this.description,
      evidence: evidence ?? this.evidence,
      contactInfo: contactInfo ?? this.contactInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewerNotes: reviewerNotes ?? this.reviewerNotes,
      item: item ?? this.item,
    );
  }
}
