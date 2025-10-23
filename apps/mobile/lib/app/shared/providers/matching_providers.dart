// Riverpod providers for matching functionality

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/repositories/repositories.dart';
import '../../core/services/matching_api_service.dart';
import '../models/matching_models.dart';

/// Provider for the matching API service
final matchingApiServiceProvider = Provider<MatchingApiService>((ref) {
  final service = MatchingApiService();
  final apiService = ref.read(apiServiceProvider);

  // Initialize with auth token from main API service
  service.initialize(authToken: apiService.authToken);

  if (kDebugMode) {
    print(
      'MatchingApiService initialized with token: ${apiService.authToken?.substring(0, 20)}...',
    );
  }

  return service;
});

/// Provider for user reports with matches (sorted by latest)
final userReportsWithMatchesProvider = FutureProvider<List<ReportWithMatches>>((
  ref,
) async {
  try {
    final reports = await ref
        .read(matchingApiServiceProvider)
        .getUserReportsWithMatches();

    // Sort reports by latest match creation date
    return _sortReportsByLatestMatches(reports);
  } catch (e) {
    // Re-throw the error to be handled by the UI
    rethrow;
  }
});

/// Sort reports by latest matches (most recent matches first)
List<ReportWithMatches> _sortReportsByLatestMatches(
  List<ReportWithMatches> reports,
) =>
    reports.map((reportWithMatches) {
        // Sort matches within each report by creation date (latest first)
        final sortedMatches = List<Match>.from(reportWithMatches.matches)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return ReportWithMatches(
          report: reportWithMatches.report,
          matches: sortedMatches,
        );
      }).toList()
      // Sort reports by their most recent match date
      ..sort((a, b) {
        if (a.matches.isEmpty && b.matches.isEmpty) {
          return 0;
        }
        if (a.matches.isEmpty) {
          return 1;
        }
        if (b.matches.isEmpty) {
          return -1;
        }

        final aLatestMatch = a.matches.first.createdAt;
        final bLatestMatch = b.matches.first.createdAt;
        return bLatestMatch.compareTo(aLatestMatch);
      });

/// Provider for reports with matches (filtered by type)
final reportsWithMatchesProvider =
    Provider<AsyncValue<List<ReportWithMatches>>>(
      (ref) => ref.watch(userReportsWithMatchesProvider),
    );

/// Provider for lost reports with matches
final lostReportsWithMatchesProvider =
    Provider<AsyncValue<List<ReportWithMatches>>>(
      (ref) => ref
          .watch(userReportsWithMatchesProvider)
          .when(
            data: (reports) => AsyncValue.data(
              reports.where((r) => r.report.type == ReportType.lost).toList(),
            ),
            loading: AsyncValue.loading,
            error: AsyncValue.error,
          ),
    );

/// Provider for found reports with matches
final foundReportsWithMatchesProvider =
    Provider<AsyncValue<List<ReportWithMatches>>>(
      (ref) => ref
          .watch(userReportsWithMatchesProvider)
          .when(
            data: (reports) => AsyncValue.data(
              reports.where((r) => r.report.type == ReportType.found).toList(),
            ),
            loading: AsyncValue.loading,
            error: AsyncValue.error,
          ),
    );

/// Provider for matches of a specific report
final reportMatchesProvider = FutureProvider.family<List<Match>, String>((
  ref,
  reportId,
) async {
  try {
    return await ref
        .read(matchingApiServiceProvider)
        .getMatchesForReport(reportId);
  } catch (e) {
    // Re-throw the error to be handled by the UI
    rethrow;
  }
});

/// Provider for pending matches count
final pendingMatchesCountProvider = Provider<AsyncValue<int>>(
  (ref) => ref
      .watch(userReportsWithMatchesProvider)
      .when(
        data: (reports) {
          final pendingCount = reports
              .expand((report) => report.matches)
              .where((match) => match.status == MatchStatus.pending)
              .length;
          return AsyncValue.data(pendingCount);
        },
        loading: AsyncValue.loading,
        error: AsyncValue.error,
      ),
);

/// Provider for accepted matches count
final acceptedMatchesCountProvider = Provider<AsyncValue<int>>(
  (ref) => ref
      .watch(userReportsWithMatchesProvider)
      .when(
        data: (reports) {
          final acceptedCount = reports
              .expand((report) => report.matches)
              .where((match) => match.status == MatchStatus.accepted)
              .length;
          return AsyncValue.data(acceptedCount);
        },
        loading: AsyncValue.loading,
        error: AsyncValue.error,
      ),
);

/// Provider for total matches count
final totalMatchesCountProvider = Provider<AsyncValue<int>>(
  (ref) => ref
      .watch(userReportsWithMatchesProvider)
      .when(
        data: (reports) {
          final totalCount = reports.expand((report) => report.matches).length;
          return AsyncValue.data(totalCount);
        },
        loading: AsyncValue.loading,
        error: AsyncValue.error,
      ),
);

/// Provider for unwatched matches count
final unwatchedMatchesCountProvider = Provider<AsyncValue<int>>(
  (ref) => ref
      .watch(userReportsWithMatchesProvider)
      .when(
        data: (reports) {
          final unwatchedCount = reports
              .expand((report) => report.matches)
              .where(
                (match) =>
                    !match.isViewed && match.status == MatchStatus.pending,
              )
              .length;
          return AsyncValue.data(unwatchedCount);
        },
        loading: AsyncValue.loading,
        error: AsyncValue.error,
      ),
);

/// Provider for reports with unwatched matches
final reportsWithUnwatchedMatchesProvider =
    Provider<AsyncValue<List<ReportWithMatches>>>(
      (ref) => ref
          .watch(userReportsWithMatchesProvider)
          .when(
            data: (reports) {
              final reportsWithUnwatched = reports
                  .where(
                    (report) => report.matches.any((match) => !match.isViewed),
                  )
                  .toList();
              return AsyncValue.data(reportsWithUnwatched);
            },
            loading: AsyncValue.loading,
            error: AsyncValue.error,
          ),
    );

/// Provider for match actions (accept/reject)
final matchActionsProvider = Provider<MatchActions>(
  (ref) => MatchActions(ref.read(matchingApiServiceProvider)),
);

/// Class for handling match actions
class MatchActions {
  /// Creates a new [MatchActions] instance
  const MatchActions(this._service);

  final MatchingApiService _service;

  /// Accept a match
  Future<bool> acceptMatch(String matchId) => _service.acceptMatch(matchId);

  /// Reject a match
  Future<bool> rejectMatch(String matchId) => _service.rejectMatch(matchId);

  /// Mark a match as viewed
  Future<bool> markAsViewed(String matchId) =>
      _service.markMatchAsViewed(matchId);
}
