import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_model.dart';
import '../services/api_service.dart';

/// Matches state
class MatchesState {
  final List<Match> matches;
  final Map<String, List<Match>> reportMatches;
  final bool isLoading;
  final String? error;
  final MatchStats? stats;
  final List<Match> lostMatches;
  final List<Match> foundMatches;

  const MatchesState({
    this.matches = const [],
    this.reportMatches = const {},
    this.isLoading = false,
    this.error,
    this.stats,
    this.lostMatches = const [],
    this.foundMatches = const [],
  });

  MatchesState copyWith({
    List<Match>? matches,
    Map<String, List<Match>>? reportMatches,
    bool? isLoading,
    String? error,
    MatchStats? stats,
    List<Match>? lostMatches,
    List<Match>? foundMatches,
  }) {
    return MatchesState(
      matches: matches ?? this.matches,
      reportMatches: reportMatches ?? this.reportMatches,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      stats: stats ?? this.stats,
      lostMatches: lostMatches ?? this.lostMatches,
      foundMatches: foundMatches ?? this.foundMatches,
    );
  }
}

/// Matches provider
class MatchesProvider extends StateNotifier<MatchesState> {
  final ApiService _apiService;

  MatchesProvider(this._apiService) : super(const MatchesState());

  /// Load matches for a report
  Future<List<Match>> getMatchesForReport(String reportId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final matches = await _apiService.getMatchesForReport(reportId);
      state = state.copyWith(
        reportMatches: {
          ...state.reportMatches,
          reportId: matches,
        },
        isLoading: false,
      );
      return matches;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return [];
    }
  }

  /// Load all matches
  Future<void> loadMatches() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final matches = await _apiService.getMatches();
      state = state.copyWith(
        matches: matches,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Get match statistics
  Future<MatchStats?> getMatchStats() async {
    try {
      final statsData = await _apiService.getMatchStats();
      if (statsData != null) {
        final stats = MatchStats.fromJson(statsData);
        state = state.copyWith(stats: stats);
        return stats;
      }
      return null;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Confirm a match
  Future<bool> confirmMatch(String matchId) async {
    try {
      final success = await _apiService.confirmMatch(matchId);
      if (success) {
        // Update the match in the state
        final updatedMatches = state.matches.map((match) {
          if (match.id == matchId) {
            return match.copyWith(status: 'confirmed');
          }
          return match;
        }).toList();

        state = state.copyWith(matches: updatedMatches);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Reject a match
  Future<bool> rejectMatch(String matchId) async {
    try {
      final success = await _apiService.rejectMatch(matchId);
      if (success) {
        // Update the match in the state
        final updatedMatches = state.matches.map((match) {
          if (match.id == matchId) {
            return match.copyWith(status: 'rejected');
          }
          return match;
        }).toList();

        state = state.copyWith(matches: updatedMatches);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Get matches for a specific report
  List<Match> getMatchesForReportList(String reportId) {
    return state.reportMatches[reportId] ?? [];
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Load matches for a specific report
  Future<void> loadMatchesForReport(String reportId) async {
    await getMatchesForReport(reportId);
  }

  /// Load all matches
  Future<void> loadAllMatches() async {
    await loadMatches();
  }

  /// Load analytics data
  Future<void> loadAnalytics() async {
    await getMatchStats();
  }

  /// Get lost matches
  List<Match> get lostMatches => state.lostMatches;

  /// Get found matches
  List<Match> get foundMatches => state.foundMatches;
}

/// Matches provider instance
final matchesProvider =
    StateNotifierProvider<MatchesProvider, MatchesState>((ref) {
  final apiService = ApiService();
  return MatchesProvider(apiService);
});
