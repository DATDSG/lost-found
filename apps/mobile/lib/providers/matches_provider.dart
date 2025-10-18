import 'package:flutter/foundation.dart';
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

  const MatchesState({
    this.matches = const [],
    this.reportMatches = const {},
    this.isLoading = false,
    this.error,
    this.stats,
  });

  MatchesState copyWith({
    List<Match>? matches,
    Map<String, List<Match>>? reportMatches,
    bool? isLoading,
    String? error,
    MatchStats? stats,
  }) {
    return MatchesState(
      matches: matches ?? this.matches,
      reportMatches: reportMatches ?? this.reportMatches,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      stats: stats ?? this.stats,
    );
  }
}

/// Matches provider
class MatchesProvider extends StateNotifier<MatchesState> {
  final ApiService _apiService;

  MatchesProvider(this._apiService) : super(const MatchesState());

  /// Load matches for a report
  Future<void> getMatchesForReport(String reportId) async {
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
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
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
  Future<void> getMatchStats() async {
    try {
      final stats = await _apiService.getMatchStats();
      state = state.copyWith(stats: stats);
    } catch (e) {
      state = state.copyWith(error: e.toString());
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
            return match.copyWith(status: MatchStatus.confirmed);
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
            return match.copyWith(status: MatchStatus.rejected);
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
  List<Match> getMatchesForReport(String reportId) {
    return state.reportMatches[reportId] ?? [];
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Matches provider instance
final matchesProvider = StateNotifierProvider<MatchesProvider, MatchesState>((ref) {
  final apiService = ApiService();
  return MatchesProvider(apiService);
});