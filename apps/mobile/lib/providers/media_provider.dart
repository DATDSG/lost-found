import 'package:flutter/foundation.dart';
import '../models/media.dart';
import '../services/api_service.dart';
import '../core/error/error_handler.dart';

/// Media Provider - State management for media uploads and management
class MediaProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Media state
  List<Media> _mediaList = [];
  MediaStats? _stats;
  bool _isLoading = false;
  String? _error;
  bool _hasMoreMedia = false;
  static const int _pageSize = 20;

  // Upload progress tracking
  final Map<String, MediaUploadProgress> _uploadProgress = {};

  // Getters
  List<Media> get mediaList => _mediaList;
  MediaStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMoreMedia => _hasMoreMedia;
  Map<String, MediaUploadProgress> get uploadProgress => _uploadProgress;

  // Computed getters
  List<Media> get images => _mediaList.where((m) => m.isImage).toList();
  List<Media> get videos => _mediaList.where((m) => m.isVideo).toList();
  List<Media> get documents => _mediaList.where((m) => m.isDocument).toList();

  int get totalMedia => _mediaList.length;
  int get totalImages => images.length;
  int get totalVideos => videos.length;
  int get totalDocuments => documents.length;

  List<MediaUploadProgress> get activeUploads => _uploadProgress.values
      .where((p) => p.isUploading || p.isProcessing)
      .toList();

  List<MediaUploadProgress> get completedUploads =>
      _uploadProgress.values.where((p) => p.isCompleted).toList();

  List<MediaUploadProgress> get failedUploads =>
      _uploadProgress.values.where((p) => p.isFailed).toList();

  // Get media by type
  List<Media> getMediaByType(MediaType type) {
    return _mediaList.where((m) => m.type == type).toList();
  }

  // Get media by report ID
  List<Media> getMediaByReport(String reportId) {
    return _mediaList.where((m) => m.reportId == reportId).toList();
  }

  // Get recent media (last 7 days)
  List<Media> getRecentMedia() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _mediaList
        .where((m) => m.createdAt != null && m.createdAt!.isAfter(weekAgo))
        .toList();
  }

  /// Load media files
  Future<void> loadMedia({bool loadMore = false, String? reportId}) async {
    if (!loadMore) {
      _mediaList.clear();
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final media = await _apiService.listMedia(reportId: reportId);

      if (loadMore) {
        _mediaList.addAll(media);
      } else {
        _mediaList = media;
      }

      _hasMoreMedia = media.length == _pageSize;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Load media');
      _isLoading = false;

      // If it's an authentication error, don't show error to user
      if (e.toString().contains('Not authenticated') ||
          e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        _error = null; // Clear error for auth issues
      }

      notifyListeners();
    }
  }

  /// Load more media (pagination)
  Future<void> loadMoreMedia({String? reportId}) async {
    if (!_hasMoreMedia || _isLoading) return;
    await loadMedia(loadMore: true, reportId: reportId);
  }

  /// Load media statistics
  Future<void> loadStats() async {
    try {
      _stats = await _apiService.getMediaStats();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading media stats: $e');
      // Don't set error for stats as it's not critical
      // Also don't show auth errors for stats
      if (!e.toString().contains('Not authenticated') &&
          !e.toString().contains('401') &&
          !e.toString().contains('Unauthorized')) {
        debugPrint('Non-auth error loading media stats: $e');
      }
    }
  }

  /// Upload single media file
  Future<Media?> uploadMedia({
    required String filePath,
    String? reportId,
    Function(double)? onProgress,
  }) async {
    final mediaId = DateTime.now().millisecondsSinceEpoch.toString();
    final filename = filePath.split('/').last;

    // Initialize upload progress
    _uploadProgress[mediaId] = MediaUploadProgress(
      mediaId: mediaId,
      filename: filename,
      status: MediaUploadStatus.pending,
      progress: 0.0,
      startedAt: DateTime.now(),
    );
    notifyListeners();

    try {
      // Update status to uploading
      _uploadProgress[mediaId] = _uploadProgress[mediaId]!.copyWith(
        status: MediaUploadStatus.uploading,
        progress: 0.1,
      );
      notifyListeners();

      final media = await _apiService.uploadMedia(
        filePath: filePath,
        reportId: reportId,
        onProgress: (progress) {
          _uploadProgress[mediaId] = _uploadProgress[mediaId]!.copyWith(
            progress: 0.1 + (progress * 0.8), // 10% to 90%
          );
          notifyListeners();
          onProgress?.call(0.1 + (progress * 0.8));
        },
      );

      // Update status to completed
      _uploadProgress[mediaId] = _uploadProgress[mediaId]!.copyWith(
        status: MediaUploadStatus.completed,
        progress: 1.0,
        media: media,
        completedAt: DateTime.now(),
      );
      notifyListeners();

      // Add to media list
      _mediaList.insert(0, media);
      notifyListeners();

      return media;
    } catch (e) {
      // Update status to failed
      _uploadProgress[mediaId] = _uploadProgress[mediaId]!.copyWith(
        status: MediaUploadStatus.failed,
        error: ErrorHandler.handleError(e, context: 'Upload media'),
        completedAt: DateTime.now(),
      );
      notifyListeners();
      return null;
    }
  }

  /// Upload multiple media files
  Future<List<Media>> uploadMultipleMedia({
    required List<String> filePaths,
    String? reportId,
    Function(int, double)? onProgress,
  }) async {
    final List<Media> uploadedMedia = [];

    for (int i = 0; i < filePaths.length; i++) {
      try {
        onProgress?.call(i, (i / filePaths.length));

        final media = await uploadMedia(
          filePath: filePaths[i],
          reportId: reportId,
        );

        if (media != null) {
          uploadedMedia.add(media);
        }
      } catch (e) {
        debugPrint('Failed to upload file ${filePaths[i]}: $e');
      }
    }

    onProgress?.call(filePaths.length, 1.0);
    return uploadedMedia;
  }

  /// Delete media file
  Future<bool> deleteMedia(String mediaId) async {
    try {
      await _apiService.deleteMedia(mediaId);

      // Remove from local state
      _mediaList.removeWhere((m) => m.id == mediaId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Delete media');
      notifyListeners();
      return false;
    }
  }

  /// Get media by ID
  Future<Media?> getMedia(String mediaId) async {
    try {
      return await _apiService.getMedia(mediaId);
    } catch (e) {
      debugPrint('Error getting media: $e');
      return null;
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await Future.wait([loadMedia(), loadStats()]);
  }

  /// Clear all data
  void clearAll() {
    _mediaList.clear();
    _stats = null;
    _hasMoreMedia = false;
    _error = null;
    _uploadProgress.clear();
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear upload progress
  void clearUploadProgress(String mediaId) {
    _uploadProgress.remove(mediaId);
    notifyListeners();
  }

  /// Clear all upload progress
  void clearAllUploadProgress() {
    _uploadProgress.clear();
    notifyListeners();
  }

  /// Get media statistics for dashboard
  Map<String, dynamic> getMediaStats() {
    return {
      'total': totalMedia,
      'images': totalImages,
      'videos': totalVideos,
      'documents': totalDocuments,
    };
  }

  /// Get media by type breakdown
  Map<MediaType, int> getTypeBreakdown() {
    final typeCount = <MediaType, int>{};
    for (final media in _mediaList) {
      typeCount[media.type] = (typeCount[media.type] ?? 0) + 1;
    }
    return typeCount;
  }

  /// Get monthly media trend
  Map<String, int> getMonthlyTrend() {
    final monthlyCount = <String, int>{};
    for (final media in _mediaList) {
      if (media.createdAt != null) {
        final monthKey =
            '${media.createdAt!.year}-${media.createdAt!.month.toString().padLeft(2, '0')}';
        monthlyCount[monthKey] = (monthlyCount[monthKey] ?? 0) + 1;
      }
    }
    return monthlyCount;
  }

  /// Get media for a specific date range
  List<Media> getMediaInRange(DateTime start, DateTime end) {
    return _mediaList
        .where(
          (m) =>
              m.createdAt != null &&
              m.createdAt!.isAfter(start) &&
              m.createdAt!.isBefore(end),
        )
        .toList();
  }

  /// Search media by filename
  List<Media> searchMedia(String query) {
    if (query.isEmpty) return _mediaList;

    final lowercaseQuery = query.toLowerCase();
    return _mediaList
        .where((m) => m.filename.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  /// Get media with specific dimensions
  List<Media> getMediaByDimensions({
    int? minWidth,
    int? maxWidth,
    int? minHeight,
    int? maxHeight,
  }) {
    return _mediaList.where((m) {
      if (m.width == null || m.height == null) return false;

      if (minWidth != null && m.width! < minWidth) return false;
      if (maxWidth != null && m.width! > maxWidth) return false;
      if (minHeight != null && m.height! < minHeight) return false;
      if (maxHeight != null && m.height! > maxHeight) return false;

      return true;
    }).toList();
  }

  /// Get media by file size range
  List<Media> getMediaBySize({int? minSizeBytes, int? maxSizeBytes}) {
    return _mediaList.where((m) {
      if (m.sizeBytes == null) return false;

      if (minSizeBytes != null && m.sizeBytes! < minSizeBytes) return false;
      if (maxSizeBytes != null && m.sizeBytes! > maxSizeBytes) return false;

      return true;
    }).toList();
  }

  /// Get media by aspect ratio
  List<Media> getMediaByAspectRatio({double? minRatio, double? maxRatio}) {
    return _mediaList.where((m) {
      final ratio = m.aspectRatio;

      if (minRatio != null && ratio < minRatio) return false;
      if (maxRatio != null && ratio > maxRatio) return false;

      return true;
    }).toList();
  }

  /// Get landscape media
  List<Media> getLandscapeMedia() {
    return _mediaList.where((m) => m.isLandscape).toList();
  }

  /// Get portrait media
  List<Media> getPortraitMedia() {
    return _mediaList.where((m) => m.isPortrait).toList();
  }

  /// Get square media
  List<Media> getSquareMedia() {
    return _mediaList.where((m) => m.isSquare).toList();
  }

  /// Get total storage used
  int get totalStorageUsed {
    return _mediaList.fold(0, (sum, media) => sum + (media.sizeBytes ?? 0));
  }

  /// Get formatted total storage used
  String get totalStorageUsedFormatted {
    const units = ['B', 'KB', 'MB', 'GB'];
    int unitIndex = 0;
    double size = totalStorageUsed.toDouble();

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(unitIndex == 0 ? 0 : 1)} ${units[unitIndex]}';
  }

  /// Get average file size
  double get averageFileSize {
    if (_mediaList.isEmpty) return 0.0;
    return totalStorageUsed / _mediaList.length;
  }

  /// Get formatted average file size
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
