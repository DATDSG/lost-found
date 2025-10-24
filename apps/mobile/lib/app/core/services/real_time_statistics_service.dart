import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../services/debug_service.dart';

/// Real-time statistics data model
class StatisticsData {
  /// Creates a new statistics data instance
  StatisticsData({
    required this.found,
    required this.lost,
    required this.total,
    required this.active,
    required this.pending,
    required this.resolved,
    required this.successRate,
    required this.lastUpdated,
    this.previousData,
  });

  /// Create from JSON
  factory StatisticsData.fromJson(Map<String, dynamic> json) => StatisticsData(
    found: json['found'] as int? ?? 0,
    lost: json['lost'] as int? ?? 0,
    total: json['total'] as int? ?? 0,
    active: json['active'] as int? ?? 0,
    pending: json['pending'] as int? ?? 0,
    resolved: json['resolved'] as int? ?? 0,
    successRate: (json['successRate'] as num?)?.toDouble() ?? 0.0,
    lastUpdated: DateTime.parse(json['lastUpdated'] as String),
  );

  /// Create a copy with previous data for trend calculation
  StatisticsData copyWithPrevious(StatisticsData? previous) => StatisticsData(
    found: found,
    lost: lost,
    total: total,
    active: active,
    pending: pending,
    resolved: resolved,
    successRate: successRate,
    lastUpdated: lastUpdated,
    previousData: previous,
  );

  /// Number of found items
  final int found;

  /// Number of lost items
  final int lost;

  /// Total number of reports
  final int total;

  /// Number of active reports
  final int active;

  /// Number of pending reports
  final int pending;

  /// Number of resolved reports
  final int resolved;

  /// Success rate as a decimal (0.0 to 1.0)
  final double successRate;

  /// When this data was last updated
  final DateTime lastUpdated;

  /// Previous data for trend calculation
  final StatisticsData? previousData;

  /// Calculate trend percentage for a metric
  double? getTrendPercentage(String metric) {
    if (previousData == null) {
      return null;
    }

    int currentValue;
    int previousValue;

    switch (metric) {
      case 'found':
        currentValue = found;
        previousValue = previousData!.found;
        break;
      case 'lost':
        currentValue = lost;
        previousValue = previousData!.lost;
        break;
      case 'total':
        currentValue = total;
        previousValue = previousData!.total;
        break;
      case 'active':
        currentValue = active;
        previousValue = previousData!.active;
        break;
      case 'pending':
        currentValue = pending;
        previousValue = previousData!.pending;
        break;
      case 'resolved':
        currentValue = resolved;
        previousValue = previousData!.resolved;
        break;
      default:
        return null;
    }

    if (previousValue == 0) {
      return currentValue > 0 ? 100.0 : 0.0;
    }

    return ((currentValue - previousValue) / previousValue) * 100;
  }

  /// Get trend indicator (up, down, stable)
  String getTrendIndicator(String metric) {
    final trend = getTrendPercentage(metric);
    if (trend == null) {
      return 'stable';
    }
    if (trend > 0) {
      return 'up';
    }
    if (trend < 0) {
      return 'down';
    }
    return 'stable';
  }

  /// Convert to JSON for caching
  Map<String, dynamic> toJson() => {
    'found': found,
    'lost': lost,
    'total': total,
    'active': active,
    'pending': pending,
    'resolved': resolved,
    'successRate': successRate,
    'lastUpdated': lastUpdated.toIso8601String(),
  };
}

/// Real-time statistics service
class RealTimeStatisticsService {
  /// Creates a new real-time statistics service
  RealTimeStatisticsService() {
    _debugService = DebugService();
    _apiService = ApiService();
    _timer = null;
    _isActive = false;
    _updateInterval = const Duration(minutes: 2); // Default 2 minutes
  }

  late final DebugService _debugService;
  late final ApiService _apiService;
  Timer? _timer;
  bool _isActive = false;
  Duration _updateInterval = const Duration(minutes: 2);

  /// Stream controller for statistics updates
  final StreamController<StatisticsData> _statisticsController =
      StreamController<StatisticsData>.broadcast();

  /// Stream of statistics updates
  Stream<StatisticsData> get statisticsStream => _statisticsController.stream;

  /// Current statistics data
  StatisticsData? _currentData;

  /// Get current statistics data
  StatisticsData? get currentData => _currentData;

  /// Check if service is active
  bool get isActive => _isActive;

  /// Get update interval
  Duration get updateInterval => _updateInterval;

  /// Set update interval
  void setUpdateInterval(Duration interval) {
    _updateInterval = interval;
    if (_isActive) {
      _restartTimer();
    }
  }

  /// Start real-time updates
  Future<void> start() async {
    if (_isActive) {
      return;
    }

    _isActive = true;
    _debugService.info(
      'Starting real-time statistics service',
      category: 'stats',
    );

    // Load cached data first
    await _loadCachedData();

    // Fetch fresh data immediately
    await _fetchStatistics();

    // Start periodic updates
    _startTimer();
  }

  /// Stop real-time updates
  void stop() {
    if (!_isActive) {
      return;
    }

    _isActive = false;
    _timer?.cancel();
    _timer = null;
    _debugService.info(
      'Stopped real-time statistics service',
      category: 'stats',
    );
  }

  /// Force refresh statistics
  Future<void> refresh() async {
    _debugService.info('Force refreshing statistics', category: 'stats');
    await _fetchStatistics();
  }

  /// Start the periodic timer
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_updateInterval, (_) {
      if (_isActive) {
        _fetchStatistics();
      }
    });
  }

  /// Restart timer with new interval
  void _restartTimer() {
    if (_isActive) {
      _startTimer();
    }
  }

  /// Fetch statistics from API
  Future<void> _fetchStatistics() async {
    try {
      _debugService.debug('Fetching statistics from API', category: 'stats');

      final response = await _apiService.getReportsStats();

      // Parse the response
      final stats = response['reports'] as Map<String, dynamic>? ?? {};
      final matches = response['matches'] as Map<String, dynamic>? ?? {};
      final successRate = (response['success_rate'] as num?)?.toDouble() ?? 0.0;

      final newData = StatisticsData(
        found: _getIntValue(stats, 'found') ?? 0,
        lost: _getIntValue(stats, 'lost') ?? 0,
        total: _getIntValue(stats, 'total') ?? 0,
        active: _getIntValue(stats, 'active') ?? 0,
        pending: _getIntValue(stats, 'pending') ?? 0,
        resolved: _getIntValue(matches, 'resolved') ?? 0,
        successRate: successRate,
        lastUpdated: DateTime.now(),
      );

      // Add previous data for trend calculation
      final dataWithTrends = newData.copyWithPrevious(_currentData);

      // Update current data
      _currentData = dataWithTrends;

      // Cache the data
      await _cacheData(dataWithTrends);

      // Emit the update
      _statisticsController.add(dataWithTrends);

      _debugService.info(
        'Statistics updated successfully',
        category: 'stats',
        data: {
          'found': dataWithTrends.found,
          'lost': dataWithTrends.lost,
          'total': dataWithTrends.total,
          'active': dataWithTrends.active,
          'pending': dataWithTrends.pending,
          'resolved': dataWithTrends.resolved,
          'successRate': dataWithTrends.successRate,
        },
      );
    } on Exception catch (e) {
      _debugService.error(
        'Failed to fetch statistics',
        category: 'stats',
        data: {'error': e.toString()},
      );

      // If we have cached data, emit it to maintain UI state
      if (_currentData != null) {
        _statisticsController.add(_currentData!);
      }
    }
  }

  /// Load cached statistics data
  Future<void> _loadCachedData() async {
    try {
      // cspell:ignore prefs
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cached_statistics');

      if (cachedJson != null) {
        final cachedData = StatisticsData.fromJson(
          json.decode(cachedJson) as Map<String, dynamic>,
        );

        _currentData = cachedData;
        _statisticsController.add(cachedData);

        _debugService.debug(
          'Loaded cached statistics',
          category: 'stats',
          data: {
            'found': cachedData.found,
            'lost': cachedData.lost,
            'total': cachedData.total,
            'lastUpdated': cachedData.lastUpdated.toIso8601String(),
          },
        );
      }
    } on Exception catch (e) {
      _debugService.warning(
        'Failed to load cached statistics',
        category: 'stats',
        data: {'error': e.toString()},
      );
    }
  }

  /// Cache statistics data
  Future<void> _cacheData(StatisticsData data) async {
    try {
      // cspell:ignore prefs
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_statistics', json.encode(data.toJson()));

      _debugService.debug('Cached statistics data', category: 'stats');
    } on Exception catch (e) {
      _debugService.warning(
        'Failed to cache statistics',
        category: 'stats',
        data: {'error': e.toString()},
      );
    }
  }

  /// Helper to safely get int value from map
  int? _getIntValue(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  /// Dispose resources
  void dispose() {
    stop();
    _statisticsController.close();
  }
}

/// Singleton instance of the real-time statistics service
final RealTimeStatisticsService _realTimeStatsService =
    RealTimeStatisticsService();

/// Get the singleton instance
RealTimeStatisticsService get realTimeStatisticsService =>
    _realTimeStatsService;
