import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_model.dart';
import '../services/api_service.dart';

class MatchesState {
  final List<Match> matches;
  final List<Match> lostMatches;
  final List<Match> foundMatches;
  final bool isLoading;
  final String? error;

  MatchesState({
    this.matches = const [],
    this.lostMatches = const [],
    this.foundMatches = const [],
    this.isLoading = false,
    this.error,
  });

  MatchesState copyWith({
    List<Match>? matches,
    List<Match>? lostMatches,
    List<Match>? foundMatches,
    bool? isLoading,
    String? error,
  }) {
    return MatchesState(
      matches: matches ?? this.matches,
      lostMatches: lostMatches ?? this.lostMatches,
      foundMatches: foundMatches ?? this.foundMatches,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MatchesNotifier extends StateNotifier<MatchesState> {
  final ApiService _apiService;

  MatchesNotifier(this._apiService) : super(MatchesState());

  Future<void> loadMatches() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final matches = await _apiService.getMatches();

      final lostMatches = matches.where((m) => m.type == 'lost').toList();
      final foundMatches = matches.where((m) => m.type == 'found').toList();

      state = state.copyWith(
        matches: matches,
        lostMatches: lostMatches,
        foundMatches: foundMatches,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshMatches() async {
    await loadMatches();
  }
}

final matchesProvider =
    StateNotifierProvider<MatchesNotifier, MatchesState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return MatchesNotifier(apiService);
});
