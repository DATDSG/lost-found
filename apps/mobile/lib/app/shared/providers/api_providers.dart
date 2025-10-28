import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/api_models.dart';
import '../../core/repositories/repositories.dart';
import '../../core/services/location_service.dart';
import '../../core/services/real_time_statistics_service.dart';
import '../../core/utils/time_utils.dart';
import '../models/home_models.dart';

// Report service provider is defined in repositories.dart

/// Location service provider
final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

/// Current location provider
final currentLocationProvider =
    FutureProvider<({double? latitude, double? longitude})>((ref) async {
      final locationService = ref.read(locationServiceProvider);
      return locationService.getCoordinates();
    });

/// Location permission provider
final locationPermissionProvider = FutureProvider<bool>((ref) async {
  final locationService = ref.read(locationServiceProvider);
  return locationService.hasLocationPermission();
});

/// Real API reports provider
final reportsProvider = FutureProvider<List<ReportItem>>((ref) async {
  final reportsRepository = ref.watch(reportsRepositoryProvider);

  try {
    final reports = await reportsRepository.getReports(
      pageSize: 50,
      status: 'approved', // Only show approved reports
    );

    // Convert API models to local models
    final convertedReports = reports
        .map(
          (apiReport) => ReportItem(
            id: apiReport.id,
            name: apiReport.title,
            description: apiReport.description ?? '', // Use actual description
            category: apiReport.category,
            location: apiReport.city, // Use city field
            imageUrl: apiReport.images.isNotEmpty
                ? apiReport.images.first
                : null, // Use images array
            itemType: apiReport.type == 'lost'
                ? ItemType.lost
                : ItemType.found, // Compare with string
            contactInfo: apiReport.contactInfo ?? 'Contact via app',
            createdAt: apiReport.createdAt,
            distance:
                'Unknown', // This would be calculated based on user location
            timeAgo: formatTimeAgo(apiReport.createdAt),
          ),
        )
        .toList();

    return convertedReports;
  } on Exception {
    // Return empty list if API fails - no more fallback to sample data
    return [];
  }
});

/// Categories provider
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final taxonomyRepository = ref.watch(taxonomyRepositoryProvider);

  try {
    return await taxonomyRepository.getCategories();
  } on Exception {
    // Return empty list if API fails - no more fallback to sample data
    return [];
  }
});

/// Colors provider
final colorsProvider = FutureProvider<List<Color>>((ref) async {
  final taxonomyRepository = ref.watch(taxonomyRepositoryProvider);

  try {
    return await taxonomyRepository.getColors();
  } on Exception {
    // Return empty list if API fails - no more fallback to sample data
    return [];
  }
});

/// Filter state provider
final filterProvider = StateProvider<FilterOptions?>((ref) => null);

/// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Loading state provider
final isLoadingProvider = StateProvider<bool>((ref) => false);

/// Real-time statistics provider
final realTimeStatisticsProvider = StreamProvider<StatisticsData>((ref) {
  final service = realTimeStatisticsService;

  // Start the service when first accessed and set up cleanup
  service.start();
  ref.onDispose(service.stop);

  return service.statisticsStream;
});

/// Real-time statistics provider with manual refresh capability
final statisticsProvider =
    StateNotifierProvider<StatisticsNotifier, StatisticsState>((ref) {
      final service = realTimeStatisticsService;
      return StatisticsNotifier(service);
    });

/// Statistics state
class StatisticsState {
  /// Creates a new statistics state
  StatisticsState({
    this.data,
    this.isLoading = false,
    this.error,
    this.lastRefresh,
    this.isAutoRefreshEnabled = true,
  });

  /// Current statistics data
  final StatisticsData? data;

  /// Whether statistics are currently loading
  final bool isLoading;

  /// Error message if any
  final String? error;

  /// Last refresh timestamp
  final DateTime? lastRefresh;

  /// Whether auto-refresh is enabled
  final bool isAutoRefreshEnabled;

  /// Creates a copy of this state with updated values
  StatisticsState copyWith({
    StatisticsData? data,
    bool? isLoading,
    String? error,
    DateTime? lastRefresh,
    bool? isAutoRefreshEnabled,
  }) => StatisticsState(
    data: data ?? this.data,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
    lastRefresh: lastRefresh ?? this.lastRefresh,
    isAutoRefreshEnabled: isAutoRefreshEnabled ?? this.isAutoRefreshEnabled,
  );
}

/// Statistics notifier for managing real-time statistics
class StatisticsNotifier extends StateNotifier<StatisticsState> {
  /// Creates a new statistics notifier
  StatisticsNotifier(this._service) : super(StatisticsState()) {
    _initialize();
  }

  final RealTimeStatisticsService _service;
  StreamSubscription<StatisticsData>? _subscription;

  void _initialize() {
    // Start the service
    _service.start();

    // Listen to statistics updates
    _subscription = _service.statisticsStream.listen(
      (data) {
        state = state.copyWith(data: data, lastRefresh: DateTime.now());
      },
      onError: (Object error) {
        state = state.copyWith(error: error.toString());
      },
    );
  }

  /// Refresh statistics manually
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _service.refresh();
  }

  /// Toggle auto-refresh
  void toggleAutoRefresh() {
    final newState = !state.isAutoRefreshEnabled;
    state = state.copyWith(isAutoRefreshEnabled: newState);

    if (newState) {
      _service.start();
    } else {
      _service.stop();
    }
  }

  /// Set update interval
  void setUpdateInterval(Duration interval) {
    _service.setUpdateInterval(interval);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _service.stop();
    super.dispose();
  }
}

/// User's own reports provider
final userReportsProvider = FutureProvider<List<ReportItem>>((ref) async {
  final reportsRepository = ref.watch(reportsRepositoryProvider);

  try {
    final reports = await reportsRepository.getUserReports();

    // Convert API models to local models
    final convertedReports = reports
        .map(
          (apiReport) => ReportItem(
            id: apiReport.id,
            name: apiReport.title,
            description: '', // ReportSummary doesn't include description
            category: apiReport.category,
            colors: apiReport.colors ?? [],
            location: apiReport.city,
            imageUrl: apiReport.images.isNotEmpty
                ? apiReport.images.first
                : null,
            itemType: apiReport.type == 'lost' ? ItemType.lost : ItemType.found,
            contactInfo: 'Contact via app',
            createdAt: apiReport.createdAt,
            distance: 'Unknown',
            timeAgo: formatTimeAgo(apiReport.createdAt),
          ),
        )
        .toList();

    return convertedReports;
  } on Exception {
    return [];
  }
});

/// User's active reports provider
final userActiveReportsProvider = FutureProvider<List<ReportItem>>((ref) async {
  final reportsAsync = ref.watch(userReportsProvider);

  return reportsAsync.when(
    data: (reports) => reports
        .where(
          (report) =>
              report.itemType == ItemType.lost ||
              report.itemType == ItemType.found,
        )
        .toList(),
    loading: () => [],
    error: (error, stackTrace) => [],
  );
});

/// User's draft reports provider
final userDraftReportsProvider = FutureProvider<List<ReportItem>>((ref) async {
  final reportsRepository = ref.watch(reportsRepositoryProvider);

  try {
    final reports = await reportsRepository.getReports(
      pageSize: 50,
      status: 'draft',
    );

    // Convert API models to local models
    final convertedReports = reports
        .map(
          (apiReport) => ReportItem(
            id: apiReport.id,
            name: apiReport.title,
            description: '', // ReportSummary doesn't include description
            category: apiReport.category,
            location: apiReport.city,
            imageUrl: apiReport.images.isNotEmpty
                ? apiReport.images.first
                : null,
            itemType: apiReport.type == 'lost' ? ItemType.lost : ItemType.found,
            contactInfo: 'Contact via app',
            createdAt: apiReport.createdAt,
            distance: 'Unknown',
            timeAgo: formatTimeAgo(apiReport.createdAt),
          ),
        )
        .toList();

    return convertedReports;
  } on Exception {
    return [];
  }
});

/// User's resolved reports provider
final userResolvedReportsProvider = FutureProvider<List<ReportItem>>((
  ref,
) async {
  final reportsRepository = ref.watch(reportsRepositoryProvider);

  try {
    final reports = await reportsRepository.getReports(
      pageSize: 50,
      status: 'resolved',
    );

    // Convert API models to local models
    final convertedReports = reports
        .map(
          (apiReport) => ReportItem(
            id: apiReport.id,
            name: apiReport.title,
            description: '', // ReportSummary doesn't include description
            category: apiReport.category,
            location: apiReport.city,
            imageUrl: apiReport.images.isNotEmpty
                ? apiReport.images.first
                : null,
            itemType: apiReport.type == 'lost' ? ItemType.lost : ItemType.found,
            contactInfo: 'Contact via app',
            createdAt: apiReport.createdAt,
            distance: 'Unknown',
            timeAgo: formatTimeAgo(apiReport.createdAt),
          ),
        )
        .toList();

    return convertedReports;
  } on Exception {
    return [];
  }
});

/// Matches provider
final matchesProvider = FutureProvider<List<MatchSummary>>((ref) async {
  final matchesRepository = ref.watch(matchesRepositoryProvider);

  try {
    return await matchesRepository.getMatches(pageSize: 50);
  } on Exception {
    return [];
  }
});

/// Found items matches provider
final foundMatchesProvider = FutureProvider<List<MatchSummary>>((ref) async {
  final matchesAsync = ref.watch(matchesProvider);

  return matchesAsync.when(
    data: (matches) =>
        matches.where((match) => match.status == 'pending').toList(),
    loading: () => [],
    error: (error, stackTrace) => [],
  );
});

/// Lost items matches provider
final lostMatchesProvider = FutureProvider<List<MatchSummary>>((ref) async {
  final matchesAsync = ref.watch(matchesProvider);

  return matchesAsync.when(
    data: (matches) =>
        matches.where((match) => match.status == 'pending').toList(),
    loading: () => [],
    error: (error, stackTrace) => [],
  );
});

/// Filtered reports provider
final filteredReportsProvider = Provider<List<ReportItem>>((ref) {
  final reportsAsync = ref.watch(reportsProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final filters = ref.watch(filterProvider);

  return reportsAsync.when(
    data: (reports) {
      var filteredReports = reports;

      // Apply search filter (optimized to avoid repeated toLowerCase calls)
      if (searchQuery.isNotEmpty) {
        final searchQueryLower = searchQuery.toLowerCase();
        filteredReports = filteredReports
            .where(
              (report) =>
                  report.name.toLowerCase().contains(searchQueryLower) ||
                  report.category.toLowerCase().contains(searchQueryLower) ||
                  report.location.toLowerCase().contains(searchQueryLower) ||
                  report.description.toLowerCase().contains(searchQueryLower),
            )
            .toList();
      }

      // Apply other filters
      if (filters != null) {
        if (filters.itemType != null) {
          filteredReports = filteredReports
              .where((report) => report.itemType == filters.itemType)
              .toList();
        }

        if (filters.categoryFilter != null && filters.categoryFilter != 'All') {
          filteredReports = filteredReports
              .where(
                (report) =>
                    report.category.toLowerCase() ==
                    filters.categoryFilter!.toLowerCase(),
              )
              .toList();
        }

        if (filters.locationFilter != null &&
            filters.locationFilter!.isNotEmpty) {
          filteredReports = filteredReports
              .where(
                (report) => report.location.toLowerCase().contains(
                  filters.locationFilter!.toLowerCase(),
                ),
              )
              .toList();
        }

        // Apply time filter
        if (filters.timeFilter != null && filters.timeFilter != 'Any Time') {
          final now = DateTime.now();
          switch (filters.timeFilter) {
            case 'Today':
              filteredReports = filteredReports
                  .where(
                    (report) => report.createdAt.isAfter(
                      now.subtract(const Duration(days: 1)),
                    ),
                  )
                  .toList();
              break;
            case 'This Week':
              filteredReports = filteredReports
                  .where(
                    (report) => report.createdAt.isAfter(
                      now.subtract(const Duration(days: 7)),
                    ),
                  )
                  .toList();
              break;
            case 'This Month':
              filteredReports = filteredReports
                  .where(
                    (report) => report.createdAt.isAfter(
                      now.subtract(const Duration(days: 30)),
                    ),
                  )
                  .toList();
              break;
            case 'Older':
              filteredReports = filteredReports
                  .where(
                    (report) => report.createdAt.isBefore(
                      now.subtract(const Duration(days: 30)),
                    ),
                  )
                  .toList();
              break;
          }
        }

        // Apply distance filter
        if (filters.distanceFilter != null &&
            filters.distanceFilter != 'Any Distance') {
          switch (filters.distanceFilter) {
            case 'Within 1 mi':
              filteredReports = filteredReports.where((report) {
                final distance =
                    double.tryParse(report.distance.replaceAll(' mi', '')) ?? 0;
                return distance <= 1.0;
              }).toList();
              break;
            case 'Within 5 mi':
              filteredReports = filteredReports.where((report) {
                final distance =
                    double.tryParse(report.distance.replaceAll(' mi', '')) ?? 0;
                return distance <= 5.0;
              }).toList();
              break;
            case 'Within 10 mi':
              filteredReports = filteredReports.where((report) {
                final distance =
                    double.tryParse(report.distance.replaceAll(' mi', '')) ?? 0;
                return distance <= 10.0;
              }).toList();
              break;
            case 'Within 25 mi':
              filteredReports = filteredReports.where((report) {
                final distance =
                    double.tryParse(report.distance.replaceAll(' mi', '')) ?? 0;
                return distance <= 25.0;
              }).toList();
              break;
          }
        }
      }

      return filteredReports;
    },
    loading: () => [],
    error: (error, stackTrace) => [],
  );
});
