import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/real_time_statistics_service.dart';
import '../../core/theme/design_tokens.dart';
import '../providers/api_providers.dart';

/// Enhanced statistics widget with real-time updates and trend analysis
class EnhancedStatisticsWidget extends ConsumerStatefulWidget {
  /// Creates a new enhanced statistics widget
  const EnhancedStatisticsWidget({
    super.key,
    this.showControls = true,
    this.showLastUpdated = true,
    this.compactMode = false,
    this.customStats,
  });

  /// Whether to show refresh controls
  final bool showControls;

  /// Whether to show last updated timestamp
  final bool showLastUpdated;

  /// Whether to use compact mode for smaller spaces
  final bool compactMode;

  /// Custom statistics to display instead of global stats
  final Map<String, dynamic>? customStats;

  @override
  ConsumerState<EnhancedStatisticsWidget> createState() =>
      _EnhancedStatisticsWidgetState();
}

class _EnhancedStatisticsWidgetState
    extends ConsumerState<EnhancedStatisticsWidget> {
  Timer? _refreshTimer;
  bool _isAutoRefreshing = false;

  @override
  void initState() {
    super.initState();
    if (widget.showControls) {
      _startAutoRefresh();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Refresh every 2 minutes for real-time updates
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (mounted && !_isAutoRefreshing) {
        _refreshData();
      }
    });
  }

  Future<void> _refreshData() async {
    if (_isAutoRefreshing) {
      return;
    }

    setState(() {
      _isAutoRefreshing = true;
    });

    try {
      // Refresh statistics using the notifier
      await ref.read(statisticsProvider.notifier).refresh();

      // Wait a bit for the refresh to complete
      await Future<void>.delayed(const Duration(milliseconds: 500));
    } finally {
      if (mounted) {
        setState(() {
          _isAutoRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statisticsState = ref.watch(statisticsProvider);
    final statisticsNotifier = ref.read(statisticsProvider.notifier);

    return Container(
      padding: EdgeInsets.all(widget.compactMode ? DT.s.md : DT.s.lg),
      decoration: BoxDecoration(
        color: DT.c.card,
        borderRadius: BorderRadius.circular(DT.r.lg),
        boxShadow: DT.e.card,
        border: Border.all(color: DT.c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with controls
          if (widget.showControls) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Live Statistics',
                    style: DT.t.titleLarge.copyWith(
                      color: DT.c.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Auto-refresh toggle
                GestureDetector(
                  onTap: statisticsNotifier.toggleAutoRefresh,
                  child: Container(
                    padding: EdgeInsets.all(DT.s.xs),
                    decoration: BoxDecoration(
                      color: statisticsState.isAutoRefreshEnabled
                          ? DT.c.brand.withValues(alpha: 0.1)
                          : DT.c.card,
                      borderRadius: BorderRadius.circular(DT.r.sm),
                      border: Border.all(
                        color: statisticsState.isAutoRefreshEnabled
                            ? DT.c.brand
                            : DT.c.border,
                      ),
                    ),
                    child: Icon(
                      statisticsState.isAutoRefreshEnabled
                          ? Icons.refresh
                          : Icons.refresh_outlined,
                      size: 16,
                      color: statisticsState.isAutoRefreshEnabled
                          ? DT.c.brand
                          : DT.c.textMuted,
                    ),
                  ),
                ),
                SizedBox(width: DT.s.xs),
                // Manual refresh button
                GestureDetector(
                  onTap: _refreshData,
                  child: Container(
                    padding: EdgeInsets.all(DT.s.xs),
                    decoration: BoxDecoration(
                      color: DT.c.card,
                      borderRadius: BorderRadius.circular(DT.r.sm),
                      border: Border.all(color: DT.c.border),
                    ),
                    child: _isAutoRefreshing
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                DT.c.brand.withValues(alpha: 0.7),
                              ),
                            ),
                          )
                        : Icon(
                            Icons.refresh_outlined,
                            size: 16,
                            color: DT.c.textMuted,
                          ),
                  ),
                ),
              ],
            ),
            // Last updated info
            if (widget.showLastUpdated &&
                statisticsState.lastRefresh != null) ...[
              SizedBox(height: DT.s.xs),
              Text(
                'Last updated: ${_formatLastUpdated(statisticsState.lastRefresh!)}',
                style: DT.t.bodySmall.copyWith(
                  color: DT.c.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
            SizedBox(height: DT.s.md),
          ],

          // Statistics cards
          if (statisticsState.data != null) ...[
            _buildStatisticsGrid(statisticsState.data!, widget.compactMode),
          ] else if (statisticsState.isLoading) ...[
            _buildLoadingSkeleton(widget.compactMode),
          ] else if (statisticsState.error != null) ...[
            _buildErrorState(statisticsState.error!),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid(StatisticsData stats, bool compactMode) {
    if (widget.customStats != null) {
      return _buildCustomStatsGrid(widget.customStats!, compactMode);
    }

    // Cast stats to the proper type to access methods
    final statisticsData = stats;

    return Column(
      children: [
        // First row with primary stats
        Row(
          children: [
            Expanded(
              child: _buildModernStatCard(
                title: '${statisticsData.found}',
                subtitle: 'Found',
                color: DT.c.accentGreen,
                icon: Icons.check_circle_outline,
                trend: _formatTrend(statisticsData.getTrendPercentage('found')),
                trendIndicator: statisticsData.getTrendIndicator('found'),
                compactMode: compactMode,
              ),
            ),
            SizedBox(width: DT.s.sm),
            Expanded(
              child: _buildModernStatCard(
                title: '${statisticsData.lost}',
                subtitle: 'Lost',
                color: DT.c.accentRed,
                icon: Icons.search_off,
                trend: _formatTrend(statisticsData.getTrendPercentage('lost')),
                trendIndicator: statisticsData.getTrendIndicator('lost'),
                compactMode: compactMode,
              ),
            ),
            SizedBox(width: DT.s.sm),
            Expanded(
              child: _buildModernStatCard(
                title: '${statisticsData.total}',
                subtitle: 'Total',
                color: DT.c.brand,
                icon: Icons.description_outlined,
                trend: _formatTrend(statisticsData.getTrendPercentage('total')),
                trendIndicator: statisticsData.getTrendIndicator('total'),
                compactMode: compactMode,
              ),
            ),
          ],
        ),
        if (!compactMode) ...[
          SizedBox(height: DT.s.sm),
          // Additional stats row
          Row(
            children: [
              Expanded(
                child: _buildModernStatCard(
                  title: '${statisticsData.active}',
                  subtitle: 'Active',
                  color: DT.c.brand,
                  icon: Icons.trending_up,
                  trend: _formatTrend(
                    statisticsData.getTrendPercentage('active'),
                  ),
                  trendIndicator: statisticsData.getTrendIndicator('active'),
                  compactMode: compactMode,
                ),
              ),
              SizedBox(width: DT.s.sm),
              Expanded(
                child: _buildModernStatCard(
                  title: '${statisticsData.resolved}',
                  subtitle: 'Resolved',
                  color: DT.c.accentGreen,
                  icon: Icons.task_alt,
                  trend: _formatTrend(
                    statisticsData.getTrendPercentage('resolved'),
                  ),
                  trendIndicator: statisticsData.getTrendIndicator('resolved'),
                  compactMode: compactMode,
                ),
              ),
              SizedBox(width: DT.s.sm),
              Expanded(
                child: _buildModernStatCard(
                  title:
                      '${(statisticsData.successRate * 100).toStringAsFixed(1)}%',
                  subtitle: 'Success Rate',
                  color: DT.c.accentRed,
                  icon: Icons.star,
                  trendIndicator: 'stable',
                  compactMode: compactMode,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCustomStatsGrid(
    Map<String, dynamic> customStats,
    bool compactMode,
  ) {
    final statsList = customStats.entries.toList();
    final rows = <Widget>[];

    for (var i = 0; i < statsList.length; i += 3) {
      final rowStats = statsList.skip(i).take(3).toList();
      final rowChildren = <Widget>[];

      for (final stat in rowStats) {
        rowChildren.add(
          Expanded(
            child: _buildModernStatCard(
              title: '${stat.value}',
              subtitle: stat.key,
              color: _getColorForStat(stat.key),
              icon: _getIconForStat(stat.key),
              trendIndicator: 'stable',
              compactMode: compactMode,
            ),
          ),
        );
      }

      // Add empty spaces if needed
      while (rowChildren.length < 3) {
        rowChildren.add(const Expanded(child: SizedBox()));
      }

      rows.add(Row(children: rowChildren));

      if (i + 3 < statsList.length) {
        rows.add(SizedBox(height: DT.s.sm));
      }
    }

    return Column(children: rows);
  }

  Widget _buildModernStatCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required String trendIndicator,
    String? trend,
    bool compactMode = false,
  }) => Container(
    padding: EdgeInsets.all(compactMode ? DT.s.sm : DT.s.md),
    decoration: BoxDecoration(
      color: DT.c.surface,
      borderRadius: BorderRadius.circular(DT.r.md),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: compactMode ? 24 : 32,
              height: compactMode ? 24 : 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DT.r.sm),
              ),
              child: Icon(icon, color: color, size: compactMode ? 14 : 18),
            ),
            const Spacer(),
            if (trendIndicator != 'stable') ...[
              Icon(
                _getTrendIcon(trendIndicator),
                color: _getTrendColor(trendIndicator),
                size: compactMode ? 12 : 14,
              ),
              SizedBox(width: DT.s.xs),
            ],
          ],
        ),
        SizedBox(height: DT.s.sm),
        Text(
          title,
          style: DT.t.headlineSmall.copyWith(
            color: DT.c.text,
            fontWeight: FontWeight.w800,
            fontSize: compactMode ? 16 : 20,
          ),
        ),
        SizedBox(height: DT.s.xs),
        Text(
          subtitle,
          style: DT.t.bodySmall.copyWith(
            color: DT.c.textMuted,
            fontSize: compactMode ? 10 : 12,
          ),
        ),
        if (trend != null && trend.isNotEmpty) ...[
          SizedBox(height: DT.s.xs),
          Text(
            trend,
            style: DT.t.labelSmall.copyWith(
              color: _getTrendColor(trendIndicator),
              fontWeight: FontWeight.w500,
              fontSize: compactMode ? 9 : 10,
            ),
          ),
        ],
      ],
    ),
  );

  Widget _buildLoadingSkeleton(bool compactMode) => Row(
    children: List.generate(
      3,
      (index) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: index < 2 ? DT.s.sm : 0),
          padding: EdgeInsets.all(compactMode ? DT.s.sm : DT.s.md),
          decoration: BoxDecoration(
            color: DT.c.surface,
            borderRadius: BorderRadius.circular(DT.r.md),
            border: Border.all(color: DT.c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compactMode ? 24 : 32,
                height: compactMode ? 24 : 32,
                decoration: BoxDecoration(
                  color: DT.c.border,
                  borderRadius: BorderRadius.circular(DT.r.sm),
                ),
              ),
              SizedBox(height: DT.s.sm),
              Container(
                width: 40,
                height: compactMode ? 16 : 20,
                decoration: BoxDecoration(
                  color: DT.c.border,
                  borderRadius: BorderRadius.circular(DT.r.xs),
                ),
              ),
              SizedBox(height: DT.s.xs),
              Container(
                width: 60,
                height: compactMode ? 10 : 12,
                decoration: BoxDecoration(
                  color: DT.c.border,
                  borderRadius: BorderRadius.circular(DT.r.xs),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildErrorState(String error) => Container(
    padding: EdgeInsets.all(DT.s.lg),
    decoration: BoxDecoration(
      color: DT.c.accentRed.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(DT.r.md),
      border: Border.all(color: DT.c.accentRed.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, color: DT.c.accentRed, size: 20),
        SizedBox(width: DT.s.sm),
        Expanded(
          child: Text(
            'Failed to load statistics: $error',
            style: DT.t.bodySmall.copyWith(color: DT.c.accentRed),
          ),
        ),
        GestureDetector(
          onTap: _refreshData,
          child: Icon(Icons.refresh, color: DT.c.accentRed, size: 16),
        ),
      ],
    ),
  );

  String _formatTrend(double? trendPercentage) => trendPercentage == null
      ? ''
      : trendPercentage.abs() < 0.1
      ? 'Stable'
      : trendPercentage > 0
      ? '+${trendPercentage.abs().toStringAsFixed(1)}%'
      : '-${trendPercentage.abs().toStringAsFixed(1)}%';

  String _formatLastUpdated(DateTime lastUpdated) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  IconData _getTrendIcon(String trendIndicator) {
    switch (trendIndicator) {
      case 'up':
        return Icons.trending_up;
      case 'down':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  Color _getTrendColor(String trendIndicator) {
    switch (trendIndicator) {
      case 'up':
        return DT.c.accentGreen;
      case 'down':
        return DT.c.accentRed;
      default:
        return DT.c.textMuted;
    }
  }

  Color _getColorForStat(String statName) {
    switch (statName.toLowerCase()) {
      case 'found':
      case 'resolved':
        return DT.c.accentGreen;
      case 'lost':
      case 'pending':
        return DT.c.accentRed;
      case 'total':
      case 'active':
        return DT.c.brand;
      default:
        return DT.c.textMuted;
    }
  }

  IconData _getIconForStat(String statName) {
    switch (statName.toLowerCase()) {
      case 'found':
        return Icons.check_circle_outline;
      case 'lost':
        return Icons.search_off;
      case 'total':
        return Icons.description_outlined;
      case 'active':
        return Icons.trending_up;
      case 'resolved':
        return Icons.task_alt;
      case 'pending':
        return Icons.schedule_outlined;
      default:
        return Icons.info_outline;
    }
  }
}
