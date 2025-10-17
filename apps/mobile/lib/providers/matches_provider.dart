import 'package:flutter/foundation.dart';
import '../models/match.dart';
import '../services/api_service.dart';
import '../core/error/error_handler.dart';

/// Matches Provider - State management for match recommendations and analytics
class MatchesProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Match state
  final Map<String, List<MatchCandidate>> _matchesByReport = {};
  List<MatchCandidate> _allMatches = [];
  MatchAnalytics? _analytics;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMoreMatches = false;
  static const int _pageSize = 20;

  // Getters
  Map<String, List<MatchCandidate>> get matchesByReport => _matchesByReport;
  List<MatchCandidate> get allMatches => _allMatches;
  MatchAnalytics? get analytics => _analytics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMoreMatches => _hasMoreMatches;

  // Computed getters
  List<MatchCandidate> get confirmedMatches =>
      _allMatches.where((m) => m.isConfirmed).toList();
  List<MatchCandidate> get pendingMatches =>
      _allMatches.where((m) => m.isPending).toList();
  List<MatchCandidate> get rejectedMatches =>
      _allMatches.where((m) => m.isRejected).toList();

  int get totalMatches => _allMatches.length;
  int get totalConfirmedMatches => confirmedMatches.length;
  int get totalPendingMatches => pendingMatches.length;
  int get totalRejectedMatches => rejectedMatches.length;

  double get confirmationRate {
    if (totalMatches == 0) return 0.0;
    return totalConfirmedMatches / totalMatches;
  }

  double get averageScore {
    if (_allMatches.isEmpty) return 0.0;
    final totalScore = _allMatches.fold<double>(
      0.0,
      (sum, match) => sum + match.overallScore,
    );
    return totalScore / _allMatches.length;
  }

  /// Get matches for a specific report
  Future<void> loadMatchesForReport(
    String reportId, {
    int maxResults = 20,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final matches = await _apiService.getMatchesForReport(
        reportId,
        maxResults: maxResults,
      );

      _matchesByReport[reportId] = matches;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Load matches for report');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load all matches for current user
  Future<void> loadAllMatches({
    MatchStatus? status,
    bool loadMore = false,
  }) async {
    if (loadMore) {
      _currentPage++;
    } else {
      _currentPage = 1;
      _allMatches.clear();
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final matches = await _apiService.getAllMatches(
        status: status,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (loadMore) {
        _allMatches.addAll(matches);
      } else {
        _allMatches = matches;
      }

      _hasMoreMatches = matches.length == _pageSize;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Load all matches');
      _isLoading = false;
      if (loadMore) {
        _currentPage--; // Revert page increment on error
      }

      // If it's an authentication error, don't show error to user
      if (e.toString().contains('Not authenticated') ||
          e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        _error = null; // Clear error for auth issues
      }

      notifyListeners();
    }
  }

  /// Load more matches (pagination)
  Future<void> loadMoreMatches({MatchStatus? status}) async {
    if (!_hasMoreMatches || _isLoading) return;
    await loadAllMatches(status: status, loadMore: true);
  }

  /// Load match analytics
  Future<void> loadAnalytics({DateTime? startDate, DateTime? endDate}) async {
    try {
      _analytics = await _apiService.getMatchAnalytics(
        startDate: startDate,
        endDate: endDate,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      // Don't set error for analytics as it's not critical
      // Also don't show auth errors for analytics
      if (!e.toString().contains('Not authenticated') &&
          !e.toString().contains('401') &&
          !e.toString().contains('Unauthorized')) {
        debugPrint('Non-auth error loading analytics: $e');
      }
    }
  }

  /// Confirm a match
  Future<bool> confirmMatch(String matchId, {String? notes}) async {
    try {
      final updatedMatch = await _apiService.confirmMatch(
        matchId,
        notes: notes,
      );

      // Update local state
      _updateMatchInLists(updatedMatch);
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Confirm match');
      notifyListeners();
      return false;
    }
  }

  /// Reject a match
  Future<bool> rejectMatch(String matchId, {String? reason}) async {
    try {
      final updatedMatch = await _apiService.rejectMatch(
        matchId,
        reason: reason,
      );

      // Update local state
      _updateMatchInLists(updatedMatch);
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Reject match');
      notifyListeners();
      return false;
    }
  }

  /// Get match details
  Future<MatchCandidate?> getMatchDetails(String matchId) async {
    try {
      return await _apiService.getMatchDetails(matchId);
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Get match details');
      notifyListeners();
      return null;
    }
  }

  /// Update match notes
  Future<bool> updateMatchNotes(String matchId, String notes) async {
    try {
      final updatedMatch = await _apiService.updateMatchNotes(matchId, notes);

      // Update local state
      _updateMatchInLists(updatedMatch);
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Update match notes');
      notifyListeners();
      return false;
    }
  }

  /// Update match in all local lists
  void _updateMatchInLists(MatchCandidate updatedMatch) {
    // Update in allMatches
    final allMatchesIndex = _allMatches.indexWhere(
      (m) => m.id == updatedMatch.id,
    );
    if (allMatchesIndex != -1) {
      _allMatches[allMatchesIndex] = updatedMatch;
    }

    // Update in matchesByReport
    for (final reportId in _matchesByReport.keys) {
      final reportMatches = _matchesByReport[reportId]!;
      final reportIndex = reportMatches.indexWhere(
        (m) => m.id == updatedMatch.id,
      );
      if (reportIndex != -1) {
        reportMatches[reportIndex] = updatedMatch;
      }
    }
  }

  /// Get matches for a specific report (from cache)
  List<MatchCandidate> getMatchesForReport(String reportId) {
    return _matchesByReport[reportId] ?? [];
  }

  /// Get matches by status
  List<MatchCandidate> getMatchesByStatus(MatchStatus status) {
    return _allMatches.where((match) => match.status == status).toList();
  }

  /// Get high-score matches (score > 0.8)
  List<MatchCandidate> getHighScoreMatches() {
    return _allMatches.where((match) => match.overallScore > 0.8).toList();
  }

  /// Get recent matches (last 7 days)
  List<MatchCandidate> getRecentMatches() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _allMatches
        .where((match) => match.createdAt.isAfter(weekAgo))
        .toList();
  }

  /// Get matches for a specific category
  List<MatchCandidate> getMatchesByCategory(String category) {
    return _allMatches
        .where((match) => match.matchedReportCategory == category)
        .toList();
  }

  /// Get matches for a specific city
  List<MatchCandidate> getMatchesByCity(String city) {
    return _allMatches
        .where(
          (match) =>
              match.matchedReportCity.toLowerCase() == city.toLowerCase(),
        )
        .toList();
  }

  /// Refresh all data
  Future<void> refresh() async {
    await Future.wait([loadAllMatches(), loadAnalytics()]);
  }

  /// Clear all data
  void clearAll() {
    _matchesByReport.clear();
    _allMatches.clear();
    _analytics = null;
    _currentPage = 1;
    _hasMoreMatches = false;
    _error = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get match statistics for dashboard
  Map<String, dynamic> getMatchStats() {
    return {
      'total': totalMatches,
      'confirmed': totalConfirmedMatches,
      'pending': totalPendingMatches,
      'rejected': totalRejectedMatches,
      'confirmation_rate': confirmationRate,
      'average_score': averageScore,
    };
  }

  /// Get top matching categories
  Map<String, int> getTopCategories() {
    final categoryCount = <String, int>{};
    for (final match in _allMatches) {
      final category = match.matchedReportCategory;
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }

    // Sort by count and return top 5
    final sortedCategories = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedCategories.take(5));
  }

  /// Get monthly match trend
  Map<String, int> getMonthlyTrend() {
    final monthlyCount = <String, int>{};
    for (final match in _allMatches) {
      final monthKey =
          '${match.createdAt.year}-${match.createdAt.month.toString().padLeft(2, '0')}';
      monthlyCount[monthKey] = (monthlyCount[monthKey] ?? 0) + 1;
    }

    return monthlyCount;
  }
}
