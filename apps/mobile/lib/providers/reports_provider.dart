import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/report.dart';
import '../services/api_service.dart';
import '../core/error/error_handler.dart';

/// Report state enum
enum ReportState {
  initial,
  loading,
  loaded,
  error,
  creating,
  updating,
  deleting,
}

/// Report filter options
class ReportFilters {
  final String? search;
  final String? type;
  final String? category;
  final String? status;
  final String? city;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? colors;
  final bool? rewardOffered;
  final String? sortBy;
  final String? sortOrder;
  final int page;
  final int pageSize;

  ReportFilters({
    this.search,
    this.type,
    this.category,
    this.status,
    this.city,
    this.latitude,
    this.longitude,
    this.radiusKm,
    this.startDate,
    this.endDate,
    this.colors,
    this.rewardOffered,
    this.sortBy = 'created_at',
    this.sortOrder = 'desc',
    this.page = 1,
    this.pageSize = 20,
  });

  ReportFilters copyWith({
    String? search,
    String? type,
    String? category,
    String? status,
    String? city,
    double? latitude,
    double? longitude,
    double? radiusKm,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? colors,
    bool? rewardOffered,
    String? sortBy,
    String? sortOrder,
    int? page,
    int? pageSize,
  }) {
    return ReportFilters(
      search: search ?? this.search,
      type: type ?? this.type,
      category: category ?? this.category,
      status: status ?? this.status,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusKm: radiusKm ?? this.radiusKm,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      colors: colors ?? this.colors,
      rewardOffered: rewardOffered ?? this.rewardOffered,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (search != null) params['search'] = search;
    if (type != null) params['type'] = type;
    if (category != null) params['category'] = category;
    if (status != null) params['status'] = status;
    if (city != null) params['city'] = city;
    if (latitude != null) params['latitude'] = latitude;
    if (longitude != null) params['longitude'] = longitude;
    if (radiusKm != null) params['radius_km'] = radiusKm;
    if (startDate != null) params['start_date'] = startDate!.toIso8601String();
    if (endDate != null) params['end_date'] = endDate!.toIso8601String();
    if (colors != null) params['colors'] = colors!.join(',');
    if (rewardOffered != null) params['reward_offered'] = rewardOffered;
    if (sortBy != null) params['sort_by'] = sortBy;
    if (sortOrder != null) params['sort_order'] = sortOrder;
    params['page'] = page;
    params['page_size'] = pageSize;
    return params;
  }
}

/// Simple retry helper for API calls
class RetryHelper {
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }
        await Future.delayed(delay);
      }
    }
    throw Exception('Max retries exceeded');
  }
}

/// Enhanced Reports Provider with comprehensive functionality
class ReportsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // State management
  List<Report> _reports = [];
  List<Report> _myReports = [];
  List<Report> _nearbyReports = [];
  ReportState _state = ReportState.initial;
  ReportFilters _currentFilters = ReportFilters();
  String? _error;
  double _uploadProgress = 0.0;
  bool _hasMoreReports = false;
  int _currentPage = 1;
  static const int _pageSize = 20;

  // Statistics and analytics
  Map<String, dynamic>? _reportStats;
  Map<String, dynamic>? _reportAnalytics;
  Map<String, dynamic>? _myReportStats;

  // Getters
  List<Report> get reports => _reports;
  List<Report> get myReports => _myReports;
  List<Report> get nearbyReports => _nearbyReports;
  ReportState get state => _state;
  ReportFilters get currentFilters => _currentFilters;
  String? get error => _error;
  double get uploadProgress => _uploadProgress;
  bool get hasMoreReports => _hasMoreReports;
  Map<String, dynamic>? get reportStats => _reportStats;
  Map<String, dynamic>? get reportAnalytics => _reportAnalytics;
  Map<String, dynamic>? get myReportStats => _myReportStats;

  bool get isLoading => _state == ReportState.loading;
  bool get isCreating => _state == ReportState.creating;
  bool get isUpdating => _state == ReportState.updating;
  bool get isDeleting => _state == ReportState.deleting;
  bool get hasError => _state == ReportState.error;
  bool get isLoaded => _state == ReportState.loaded;

  /// Load all reports with current filters
  Future<void> loadReports({bool loadMore = false}) async {
    if (loadMore) {
      _currentPage++;
    } else {
      _currentPage = 1;
      _reports.clear();
    }

    _state = ReportState.loading;
    _error = null;
    notifyListeners();

    try {
      final result = await RetryHelper.retry(
        () => _apiService.getReportsWithFilters(
          page: _currentPage,
          pageSize: _pageSize,
          search: _currentFilters.search,
          type: _currentFilters.type,
          category: _currentFilters.category,
          status: _currentFilters.status,
          city: _currentFilters.city,
          latitude: _currentFilters.latitude,
          longitude: _currentFilters.longitude,
          radiusKm: _currentFilters.radiusKm,
          startDate: _currentFilters.startDate,
          endDate: _currentFilters.endDate,
          colors: _currentFilters.colors,
          rewardOffered: _currentFilters.rewardOffered,
          sortBy: _currentFilters.sortBy,
          sortOrder: _currentFilters.sortOrder,
        ),
      );

      final newReports = result['reports'] as List<Report>;
      final pagination = result['pagination'] as Map<String, dynamic>;

      if (loadMore) {
        _reports.addAll(newReports);
      } else {
        _reports = newReports;
      }

      _hasMoreReports = pagination['has_more'] as bool;
      _state = ReportState.loaded;
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Load reports');
      _state = ReportState.error;
      if (loadMore) {
        _currentPage--; // Revert page increment on error
      }
      notifyListeners();
    }
  }

  /// Load user's own reports
  Future<void> loadMyReports({bool loadMore = false}) async {
    if (loadMore) {
      _currentPage++;
    } else {
      _currentPage = 1;
      _myReports.clear();
    }

    _state = ReportState.loading;
    _error = null;
    notifyListeners();

    try {
      final rawReports =
          await RetryHelper.retry(() => _apiService.getMyReports());
      _myReports = rawReports.map((json) => Report.fromJson(json)).toList();
      _state = ReportState.loaded;
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Load my reports');
      _state = ReportState.error;

      // If it's an authentication error, don't show error to user
      if (e.toString().contains('Not authenticated') ||
          e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        _error = null; // Clear error for auth issues
      }

      notifyListeners();
    }
  }

  /// Load nearby reports
  Future<void> loadNearbyReports({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int limit = 50,
    String? type,
    String? category,
  }) async {
    _state = ReportState.loading;
    _error = null;
    notifyListeners();

    try {
      final rawReports = await RetryHelper.retry(
        () => _apiService.getNearbyReports(
          latitude: latitude,
          longitude: longitude,
          radiusKm: radiusKm,
          type: type,
          category: category,
        ),
      );
      _nearbyReports = rawReports.map((json) => Report.fromJson(json)).toList();
      _state = ReportState.loaded;
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Load nearby reports');
      _state = ReportState.error;
      notifyListeners();
    }
  }

  /// Get a specific report by ID
  Future<Report?> getReport(String reportId, {int maxRetries = 3}) async {
    try {
      final rawReport = await RetryHelper.retry(
        () => _apiService.getReport(reportId),
        maxRetries: maxRetries,
      );
      return rawReport != null ? Report.fromJson(rawReport) : null;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Get report');
      notifyListeners();
      return null;
    }
  }

  /// Create a new report
  Future<bool> createReport({
    required String type,
    required String title,
    required String description,
    required String category,
    required String city,
    required DateTime occurredAt,
    List<String>? colors,
    String? locationAddress,
    double? latitude,
    double? longitude,
    List<File>? photos,
    bool? rewardOffered,
    int maxRetries = 3,
  }) async {
    _state = ReportState.creating;
    _error = null;
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      Report report;

      if (photos != null && photos.isNotEmpty) {
        // Create report with media upload
        final imagePaths = photos.map((file) => file.path).toList();
        final rawReport = await RetryHelper.retry(
          () => _apiService.createReportWithMedia(
            type: type,
            title: title,
            description: description,
            category: category,
            city: city,
            occurredAt: occurredAt,
            colors: colors,
            locationAddress: locationAddress,
            latitude: latitude,
            longitude: longitude,
            rewardOffered:
                rewardOffered != null ? (rewardOffered ? 0.0 : null) : null,
            imagePaths: imagePaths,
            onProgress: (progress) {
              _uploadProgress = progress;
              notifyListeners();
            },
          ),
          maxRetries: maxRetries,
        );
        report = Report.fromJson(rawReport!);
      } else {
        // Create report without media
        final rawReport = await RetryHelper.retry(
          () => _apiService.createReport(
            type: type,
            title: title,
            description: description,
            category: category,
            city: city,
            occurredAt: occurredAt,
            colors: colors,
            locationAddress: locationAddress,
            latitude: latitude,
            longitude: longitude,
            rewardOffered:
                rewardOffered != null ? (rewardOffered ? 0.0 : null) : null,
          ),
          maxRetries: maxRetries,
        );
        report = Report.fromJson(rawReport!);
      }

      // Add to local lists
      _myReports.insert(0, report);
      _reports.insert(0, report);
      _state = ReportState.loaded;
      _uploadProgress = 0.0;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Create report');
      _state = ReportState.error;
      _uploadProgress = 0.0;
      notifyListeners();
      return false;
    }
  }

  /// Update an existing report
  Future<bool> updateReport(
    String reportId,
    Map<String, dynamic> updates,
  ) async {
    _state = ReportState.updating;
    _error = null;
    notifyListeners();

    try {
      final updatedReportData = await RetryHelper.retry(
        () => _apiService.updateReport(reportId, updates),
      );

      if (updatedReportData == null) {
        throw Exception('Update failed - no data returned');
      }

      final updatedReport = Report.fromJson(updatedReportData);

      // Update in local lists
      _updateReportInLists(updatedReport);
      _state = ReportState.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Update report');
      _state = ReportState.error;
      notifyListeners();
      return false;
    }
  }

  /// Delete a report
  Future<bool> deleteReport(String reportId) async {
    _state = ReportState.deleting;
    _error = null;
    notifyListeners();

    try {
      final success = await RetryHelper.retry(
        () => _apiService.deleteReport(reportId),
      );

      if (success) {
        // Remove from local lists
        _reports.removeWhere((report) => report.id == reportId);
        _myReports.removeWhere((report) => report.id == reportId);
        _nearbyReports.removeWhere((report) => report.id == reportId);
      }

      _state = ReportState.loaded;
      notifyListeners();
      return success;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Delete report');
      _state = ReportState.error;
      notifyListeners();
      return false;
    }
  }

  /// Resolve a report
  Future<bool> resolveReport(String reportId) async {
    try {
      final success = await RetryHelper.retry(
        () => _apiService.resolveReport(reportId),
      );

      if (success) {
        // Update report in local lists
        final reportIndex = _myReports.indexWhere((r) => r.id == reportId);
        if (reportIndex != -1) {
          // Create a new report with updated isResolved field
          final oldReport = _myReports[reportIndex];
          final updatedReport = Report(
            id: oldReport.id,
            title: oldReport.title,
            description: oldReport.description,
            type: oldReport.type,
            status: oldReport.status,
            category: oldReport.category,
            city: oldReport.city,
            occurredAt: oldReport.occurredAt,
            createdAt: oldReport.createdAt,
            media: oldReport.media,
            colors: oldReport.colors,
            rewardOffered: oldReport.rewardOffered,
            latitude: oldReport.latitude,
            longitude: oldReport.longitude,
            locationAddress: oldReport.locationAddress,
            isResolved: true, // Updated field
          );
          _myReports[reportIndex] = updatedReport;
          notifyListeners();
        }
      }

      return success;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Resolve report');
      notifyListeners();
      return false;
    }
  }

  /// Duplicate a report
  Future<Report?> duplicateReport(String reportId) async {
    try {
      final duplicatedReportData = await RetryHelper.retry(
        () => _apiService.duplicateReport(reportId),
      );

      if (duplicatedReportData == null) {
        throw Exception('Duplicate failed - no data returned');
      }

      final duplicatedReport = Report.fromJson(duplicatedReportData);

      // Add to local lists
      _myReports.insert(0, duplicatedReport);
      _reports.insert(0, duplicatedReport);
      notifyListeners();

      return duplicatedReport;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Duplicate report');
      notifyListeners();
      return null;
    }
  }

  /// Archive a report
  Future<bool> archiveReport(String reportId) async {
    try {
      final success = await RetryHelper.retry(
        () => _apiService.archiveReport(reportId),
      );

      if (success) {
        // Remove from active lists
        _reports.removeWhere((report) => report.id == reportId);
        _nearbyReports.removeWhere((report) => report.id == reportId);
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Archive report');
      notifyListeners();
      return false;
    }
  }

  /// Restore an archived report
  Future<bool> restoreReport(String reportId) async {
    try {
      final success = await RetryHelper.retry(
        () => _apiService.restoreReport(reportId),
      );

      if (success) {
        // Reload reports to include restored report
        await loadReports();
      }

      return success;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Restore report');
      notifyListeners();
      return false;
    }
  }

  /// Load report statistics
  Future<void> loadReportStats() async {
    try {
      _reportStats = await RetryHelper.retry(
        () => _apiService.getReportStats(),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading report stats: $e');
    }
  }

  /// Load report analytics
  Future<void> loadReportAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String? groupBy = 'day',
  }) async {
    try {
      _reportAnalytics = await RetryHelper.retry(
        () => _apiService.getReportAnalytics(),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading report analytics: $e');
    }
  }

  /// Load user's report statistics
  Future<void> loadMyReportStats() async {
    try {
      _myReportStats = await RetryHelper.retry(
        () => _apiService.getMyReportStats(),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading my report stats: $e');
    }
  }

  /// Update filters and reload reports
  void updateFilters(ReportFilters filters) {
    _currentFilters = filters;
    loadReports();
  }

  /// Apply a single filter
  void applyFilter(String key, dynamic value) {
    ReportFilters newFilters;

    switch (key) {
      case 'search':
        newFilters = _currentFilters.copyWith(search: value);
        break;
      case 'type':
        newFilters = _currentFilters.copyWith(type: value);
        break;
      case 'category':
        newFilters = _currentFilters.copyWith(category: value);
        break;
      case 'status':
        newFilters = _currentFilters.copyWith(status: value);
        break;
      case 'city':
        newFilters = _currentFilters.copyWith(city: value);
        break;
      case 'rewardOffered':
        newFilters = _currentFilters.copyWith(rewardOffered: value);
        break;
      case 'sortBy':
        newFilters = _currentFilters.copyWith(sortBy: value);
        break;
      case 'sortOrder':
        newFilters = _currentFilters.copyWith(sortOrder: value);
        break;
      default:
        return;
    }

    updateFilters(newFilters);
  }

  /// Clear all filters
  void clearFilters() {
    _currentFilters = ReportFilters();
    loadReports();
  }

  /// Load more reports (pagination)
  Future<void> loadMoreReports() async {
    if (!_hasMoreReports || isLoading) return;
    await loadReports(loadMore: true);
  }

  /// Refresh reports
  Future<void> refresh() async {
    await loadReports();
  }

  /// Clear all data
  void clearAll() {
    _reports.clear();
    _myReports.clear();
    _nearbyReports.clear();
    _state = ReportState.initial;
    _error = null;
    _uploadProgress = 0.0;
    _hasMoreReports = false;
    _currentPage = 1;
    _reportStats = null;
    _reportAnalytics = null;
    _myReportStats = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    if (_state == ReportState.error) {
      _state = ReportState.initial;
    }
    notifyListeners();
  }

  // Private helper methods

  void _updateReportInLists(Report updatedReport) {
    // Update in reports list
    final reportsIndex = _reports.indexWhere((r) => r.id == updatedReport.id);
    if (reportsIndex != -1) {
      _reports[reportsIndex] = updatedReport;
    }

    // Update in my reports list
    final myReportsIndex = _myReports.indexWhere(
      (r) => r.id == updatedReport.id,
    );
    if (myReportsIndex != -1) {
      _myReports[myReportsIndex] = updatedReport;
    }

    // Update in nearby reports list
    final nearbyIndex = _nearbyReports.indexWhere(
      (r) => r.id == updatedReport.id,
    );
    if (nearbyIndex != -1) {
      _nearbyReports[nearbyIndex] = updatedReport;
    }
  }
}
