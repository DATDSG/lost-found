/// Media Model - represents uploaded images/videos
/// Comprehensive media management with upload, processing, and metadata
library;
import 'package:flutter/material.dart';

/// Media type enum
enum MediaType {
  image('image', 'Image'),
  video('video', 'Video'),
  document('document', 'Document');

  const MediaType(this.value, this.label);
  final String value;
  final String label;
}

/// Media upload status
enum MediaUploadStatus {
  pending('pending', 'Pending'),
  uploading('uploading', 'Uploading'),
  processing('processing', 'Processing'),
  completed('completed', 'Completed'),
  failed('failed', 'Failed');

  const MediaUploadStatus(this.value, this.label);
  final String value;
  final String label;
}

/// Media model with comprehensive properties
class Media {
  final String id;
  final String? reportId;
  final String filename;
  final String url;
  final MediaType type;
  final String mimeType;
  final int? sizeBytes;
  final int? width;
  final int? height;
  final String? phashHex;
  final String? dhashHex;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Media({
    required this.id,
    this.reportId,
    required this.filename,
    required this.url,
    required this.type,
    required this.mimeType,
    this.sizeBytes,
    this.width,
    this.height,
    this.phashHex,
    this.dhashHex,
    this.createdAt,
    this.updatedAt,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'] ?? '',
      reportId: json['report_id'],
      filename: json['filename'] ?? '',
      url: json['url'] ?? '',
      type: MediaType.values.firstWhere(
        (t) => t.value == (json['type'] ?? json['media_type']),
        orElse: () => MediaType.image,
      ),
      mimeType: json['mime_type'] ?? 'image/jpeg',
      sizeBytes: json['size_bytes'],
      width: json['width'],
      height: json['height'],
      phashHex: json['phash_hex'],
      dhashHex: json['dhash_hex'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_id': reportId,
      'filename': filename,
      'url': url,
      'type': type.value,
      'media_type': type.value,
      'mime_type': mimeType,
      'size_bytes': sizeBytes,
      'width': width,
      'height': height,
      'phash_hex': phashHex,
      'dhash_hex': dhashHex,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Media copyWith({
    String? id,
    String? reportId,
    String? filename,
    String? url,
    MediaType? type,
    String? mimeType,
    int? sizeBytes,
    int? width,
    int? height,
    String? phashHex,
    String? dhashHex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Media(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      filename: filename ?? this.filename,
      url: url ?? this.url,
      type: type ?? this.type,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      width: width ?? this.width,
      height: height ?? this.height,
      phashHex: phashHex ?? this.phashHex,
      dhashHex: dhashHex ?? this.dhashHex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Computed properties
  bool get isImage => type == MediaType.image;
  bool get isVideo => type == MediaType.video;
  bool get isDocument => type == MediaType.document;

  String get fileExtension {
    final parts = filename.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  String get sizeFormatted {
    if (sizeBytes == null) return 'Unknown size';

    const units = ['B', 'KB', 'MB', 'GB'];
    int unitIndex = 0;
    double size = sizeBytes!.toDouble();

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(unitIndex == 0 ? 0 : 1)} ${units[unitIndex]}';
  }

  String get dimensionsFormatted {
    if (width == null || height == null) return 'Unknown dimensions';
    return '${width}x$height';
  }

  double get aspectRatio {
    if (width == null || height == null || height == 0) return 1.0;
    return width! / height!;
  }

  bool get isLandscape => aspectRatio > 1.0;
  bool get isPortrait => aspectRatio < 1.0;
  bool get isSquare => aspectRatio == 1.0;

  Color get typeColor {
    switch (type) {
      case MediaType.image:
        return Colors.blue;
      case MediaType.video:
        return Colors.purple;
      case MediaType.document:
        return Colors.orange;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case MediaType.image:
        return Icons.image_rounded;
      case MediaType.video:
        return Icons.videocam_rounded;
      case MediaType.document:
        return Icons.description_rounded;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Media && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Media(id: $id, filename: $filename, type: ${type.value}, url: $url)';
  }
}

/// Media upload progress tracking
class MediaUploadProgress {
  final String mediaId;
  final String filename;
  final MediaUploadStatus status;
  final double progress; // 0.0 to 1.0
  final String? error;
  final Media? media;
  final DateTime startedAt;
  final DateTime? completedAt;

  MediaUploadProgress({
    required this.mediaId,
    required this.filename,
    required this.status,
    required this.progress,
    this.error,
    this.media,
    required this.startedAt,
    this.completedAt,
  });

  MediaUploadProgress copyWith({
    String? mediaId,
    String? filename,
    MediaUploadStatus? status,
    double? progress,
    String? error,
    Media? media,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return MediaUploadProgress(
      mediaId: mediaId ?? this.mediaId,
      filename: filename ?? this.filename,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      media: media ?? this.media,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  bool get isCompleted => status == MediaUploadStatus.completed;
  bool get isFailed => status == MediaUploadStatus.failed;
  bool get isUploading => status == MediaUploadStatus.uploading;
  bool get isProcessing => status == MediaUploadStatus.processing;
  bool get isPending => status == MediaUploadStatus.pending;

  Duration? get duration {
    if (completedAt == null) return null;
    return completedAt!.difference(startedAt);
  }
}

/// Media statistics for dashboard
class MediaStats {
  final int totalMedia;
  final int totalImages;
  final int totalVideos;
  final int totalDocuments;
  final int totalSizeBytes;
  final Map<String, int> typeBreakdown;
  final Map<String, int> monthlyTrend;
  final double averageFileSize;

  MediaStats({
    required this.totalMedia,
    required this.totalImages,
    required this.totalVideos,
    required this.totalDocuments,
    required this.totalSizeBytes,
    required this.typeBreakdown,
    required this.monthlyTrend,
    required this.averageFileSize,
  });

  factory MediaStats.fromJson(Map<String, dynamic> json) {
    return MediaStats(
      totalMedia: json['total_media'] ?? 0,
      totalImages: json['total_images'] ?? 0,
      totalVideos: json['total_videos'] ?? 0,
      totalDocuments: json['total_documents'] ?? 0,
      totalSizeBytes: json['total_size_bytes'] ?? 0,
      typeBreakdown: Map<String, int>.from(json['type_breakdown'] ?? {}),
      monthlyTrend: Map<String, int>.from(json['monthly_trend'] ?? {}),
      averageFileSize: (json['average_file_size'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_media': totalMedia,
      'total_images': totalImages,
      'total_videos': totalVideos,
      'total_documents': totalDocuments,
      'total_size_bytes': totalSizeBytes,
      'type_breakdown': typeBreakdown,
      'monthly_trend': monthlyTrend,
      'average_file_size': averageFileSize,
    };
  }

  // Computed properties
  String get totalSizeFormatted {
    const units = ['B', 'KB', 'MB', 'GB'];
    int unitIndex = 0;
    double size = totalSizeBytes.toDouble();

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(unitIndex == 0 ? 0 : 1)} ${units[unitIndex]}';
  }

  String get averageFileSizeFormatted {
    const units = ['B', 'KB', 'MB', 'GB'];
    int unitIndex = 0;
    double size = averageFileSize;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(unitIndex == 0 ? 0 : 1)} ${units[unitIndex]}';
  }
}
