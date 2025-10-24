import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/models/home_models.dart';
import '../../../../shared/providers/api_providers.dart';
import '../../../../shared/widgets/filter_sheet.dart';
import '../../../../shared/widgets/main_layout.dart';
import '../../../../shared/widgets/optimized_report_card.dart';

/// Enhanced home screen with search, filter, and report cards
class HomeScreen extends ConsumerStatefulWidget {
  /// Creates a new home screen widget
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _refreshTimer;
  bool _isAutoRefreshing = false;

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Refresh every 30 seconds for real-time updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
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
      // Invalidate and refresh all data providers
      ref
        ..invalidate(reportsProvider)
        ..invalidate(categoriesProvider)
        ..invalidate(colorsProvider);

      // Refresh statistics using the notifier
      unawaited(ref.read(statisticsProvider.notifier).refresh());

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
    final reportsAsync = ref.watch(reportsProvider);

    return MainLayout(
      currentIndex: 0, // Home is index 0
      child: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          slivers: [
            // Modern Header with Gradient
            SliverToBoxAdapter(child: _buildModernHeader()),

            // Quick Actions Section
            SliverToBoxAdapter(child: _buildQuickActionsSection()),

            // Statistics Cards
            SliverToBoxAdapter(child: _buildModernStatisticsSection()),

            // Reports Section Header
            SliverToBoxAdapter(child: _buildReportsSectionHeader()),

            // Reports List
            reportsAsync.when(
              data: (reports) => reports.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyState())
                  : Consumer(
                      builder: (context, ref, child) {
                        final filteredReports = ref.watch(
                          filteredReportsProvider,
                        );
                        return SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final report = filteredReports[index];
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: DT.s.md,
                                vertical: DT.s.xs,
                              ),
                              child: OptimizedReportCard(
                                key: ValueKey(report.id),
                                report: report,
                                onContact: () => _showContactDialog(report),
                                onViewDetails: () => _showDetailsDialog(report),
                              ),
                            );
                          }, childCount: filteredReports.length),
                        );
                      },
                    ),
              loading: () => SliverToBoxAdapter(child: _buildLoadingState()),
              error: (error, stackTrace) =>
                  SliverToBoxAdapter(child: _buildErrorState(error)),
            ),

            // Bottom spacing
            SliverToBoxAdapter(child: SizedBox(height: DT.s.xl)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [DT.c.gradientStart, DT.c.gradientEnd],
      ),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(DT.r.xl),
        bottomRight: Radius.circular(DT.r.xl),
      ),
    ),
    child: SafeArea(
      child: Padding(
        padding: EdgeInsets.all(DT.s.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting and Profile
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Good ${_getGreeting()}!',
                          style: DT.t.headlineSmall.copyWith(
                            color: DT.c.textOnBrand,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_isAutoRefreshing) ...[
                          SizedBox(width: DT.s.sm),
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                DT.c.textOnBrand.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: DT.s.xs),
                    Text(
                      _isAutoRefreshing
                          ? 'Updating reports...'
                          : "Find what you're looking for",
                      style: DT.t.bodyMedium.copyWith(
                        color: DT.c.textOnBrand.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                // Profile Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: DT.c.textOnBrand.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(DT.r.full),
                    border: Border.all(
                      color: DT.c.textOnBrand.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(Icons.person, color: DT.c.textOnBrand, size: 24),
                ),
              ],
            ),

            SizedBox(height: DT.s.lg),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: DT.c.textOnBrand.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(DT.r.xl),
                border: Border.all(
                  color: DT.c.textOnBrand.withValues(alpha: 0.2),
                ),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search lost or found items...',
                  hintStyle: DT.t.bodyMedium.copyWith(
                    color: DT.c.textOnBrand.withValues(alpha: 0.7),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: DT.c.textOnBrand.withValues(alpha: 0.7),
                  ),
                  suffixIcon: Consumer(
                    builder: (context, ref, child) => IconButton(
                      icon: Icon(
                        Icons.tune,
                        color: DT.c.textOnBrand.withValues(alpha: 0.7),
                      ),
                      onPressed: _showFilterSheet,
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: DT.s.md,
                    vertical: DT.s.md,
                  ),
                ),
                style: DT.t.bodyMedium.copyWith(color: DT.c.textOnBrand),
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Morning';
    }
    if (hour < 17) {
      return 'Afternoon';
    }
    return 'Evening';
  }

  Widget _buildQuickActionsSection() => Container(
    margin: EdgeInsets.symmetric(horizontal: DT.s.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with Better Typography
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: DT.c.brand,
                borderRadius: BorderRadius.circular(DT.r.sm),
              ),
            ),
            SizedBox(width: DT.s.sm),
            Text(
              'Quick Actions',
              style: DT.t.titleLarge.copyWith(
                color: DT.c.text,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const Spacer(),
            Text(
              'Tap to get started',
              style: DT.t.bodySmall.copyWith(
                color: DT.c.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),

        SizedBox(height: DT.s.lg),

        // Enhanced Action Cards with Better Visual Design
        Row(
          children: [
            Expanded(
              child: _buildEnhancedActionCard(
                title: 'Report Lost Item',
                subtitle: 'Lost something?',
                description: 'Help others find your item',
                icon: Icons.search_off_rounded,
                color: DT.c.accentRed,
                gradientColors: [
                  DT.c.accentRed.withValues(alpha: 0.1),
                  DT.c.accentRed.withValues(alpha: 0.05),
                ],
                onTap: () => context.go('/report-lost'),
              ),
            ),
            SizedBox(width: DT.s.md),
            Expanded(
              child: _buildEnhancedActionCard(
                title: 'Report Found Item',
                subtitle: 'Found something?',
                description: 'Help reunite with owner',
                icon: Icons.check_circle_rounded,
                color: DT.c.accentGreen,
                gradientColors: [
                  DT.c.accentGreen.withValues(alpha: 0.1),
                  DT.c.accentGreen.withValues(alpha: 0.05),
                ],
                onTap: () => context.go('/report-found'),
              ),
            ),
          ],
        ),

        SizedBox(height: DT.s.md),

        // Additional Action Row
        Row(
          children: [
            Expanded(
              child: _buildSecondaryActionCard(
                title: 'My Reports',
                icon: Icons.list_alt_rounded,
                color: DT.c.brand,
                onTap: () => context.go('/my-reports'),
              ),
            ),
            SizedBox(width: DT.s.md),
            Expanded(
              child: _buildSecondaryActionCard(
                title: 'Matches',
                icon: Icons.handshake_rounded,
                color: DT.c.accentPurple,
                onTap: () => context.go('/matches'),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildEnhancedActionCard({
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color color,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.all(DT.s.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(DT.r.xl),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(DT.s.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(DT.r.md),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color.withValues(alpha: 0.6),
                size: 16,
              ),
            ],
          ),
          SizedBox(height: DT.s.md),
          Text(
            title,
            style: DT.t.titleMedium.copyWith(
              color: DT.c.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: DT.s.xs),
          Text(
            subtitle,
            style: DT.t.bodyMedium.copyWith(
              color: DT.c.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: DT.s.xs),
          Text(
            description,
            style: DT.t.bodySmall.copyWith(color: DT.c.textMuted),
          ),
        ],
      ),
    ),
  );

  Widget _buildSecondaryActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.all(DT.s.md),
      decoration: BoxDecoration(
        color: DT.c.card,
        borderRadius: BorderRadius.circular(DT.r.lg),
        boxShadow: const [BoxShadow()],
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(DT.s.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DT.r.sm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: DT.s.sm),
          Expanded(
            child: Text(
              title,
              style: DT.t.bodyMedium.copyWith(
                color: DT.c.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: DT.c.textMuted,
            size: 14,
          ),
        ],
      ),
    ),
  );

  Widget _buildModernStatisticsSection() {
    final statisticsState = ref.watch(statisticsProvider);
    final statisticsNotifier = ref.read(statisticsProvider.notifier);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DT.s.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with controls
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
                onTap: statisticsNotifier.refresh,
                child: Container(
                  padding: EdgeInsets.all(DT.s.xs),
                  decoration: BoxDecoration(
                    color: DT.c.card,
                    borderRadius: BorderRadius.circular(DT.r.sm),
                    border: Border.all(color: DT.c.border),
                  ),
                  child: statisticsState.isLoading
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
          if (statisticsState.lastRefresh != null) ...[
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
          // Statistics cards
          if (statisticsState.data != null) ...[
            Row(
              children: [
                Expanded(
                  child: _buildModernStatCard(
                    title: '${statisticsState.data!.found}',
                    subtitle: 'Found',
                    color: DT.c.accentGreen,
                    icon: Icons.check_circle_outline,
                    trend: _formatTrend(
                      statisticsState.data!.getTrendPercentage('found'),
                    ),
                    trendIndicator: statisticsState.data!.getTrendIndicator(
                      'found',
                    ),
                  ),
                ),
                SizedBox(width: DT.s.sm),
                Expanded(
                  child: _buildModernStatCard(
                    title: '${statisticsState.data!.lost}',
                    subtitle: 'Lost',
                    color: DT.c.accentRed,
                    icon: Icons.search_off,
                    trend: _formatTrend(
                      statisticsState.data!.getTrendPercentage('lost'),
                    ),
                    trendIndicator: statisticsState.data!.getTrendIndicator(
                      'lost',
                    ),
                  ),
                ),
                SizedBox(width: DT.s.sm),
                Expanded(
                  child: _buildModernStatCard(
                    title: '${statisticsState.data!.total}',
                    subtitle: 'Total',
                    color: DT.c.brand,
                    icon: Icons.description_outlined,
                    trend: _formatTrend(
                      statisticsState.data!.getTrendPercentage('total'),
                    ),
                    trendIndicator: statisticsState.data!.getTrendIndicator(
                      'total',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: DT.s.sm),
            // Additional stats row
            Row(
              children: [
                Expanded(
                  child: _buildModernStatCard(
                    title: '${statisticsState.data!.active}',
                    subtitle: 'Active',
                    color: DT.c.brand,
                    icon: Icons.trending_up,
                    trend: _formatTrend(
                      statisticsState.data!.getTrendPercentage('active'),
                    ),
                    trendIndicator: statisticsState.data!.getTrendIndicator(
                      'active',
                    ),
                  ),
                ),
                SizedBox(width: DT.s.sm),
                Expanded(
                  child: _buildModernStatCard(
                    title: '${statisticsState.data!.resolved}',
                    subtitle: 'Resolved',
                    color: DT.c.accentGreen,
                    icon: Icons.task_alt,
                    trend: _formatTrend(
                      statisticsState.data!.getTrendPercentage('resolved'),
                    ),
                    trendIndicator: statisticsState.data!.getTrendIndicator(
                      'resolved',
                    ),
                  ),
                ),
                SizedBox(width: DT.s.sm),
                Expanded(
                  child: _buildModernStatCard(
                    title:
                        '${(statisticsState.data!.successRate * 100).toStringAsFixed(1)}%',
                    subtitle: 'Success Rate',
                    color: DT.c.accentRed,
                    icon: Icons.star,
                    trendIndicator: 'stable',
                  ),
                ),
              ],
            ),
          ] else if (statisticsState.isLoading) ...[
            // Loading state
            Row(
              children: [
                Expanded(child: _buildStatCardSkeleton()),
                SizedBox(width: DT.s.sm),
                Expanded(child: _buildStatCardSkeleton()),
                SizedBox(width: DT.s.sm),
                Expanded(child: _buildStatCardSkeleton()),
              ],
            ),
            SizedBox(height: DT.s.sm),
            Row(
              children: [
                Expanded(child: _buildStatCardSkeleton()),
                SizedBox(width: DT.s.sm),
                Expanded(child: _buildStatCardSkeleton()),
                SizedBox(width: DT.s.sm),
                Expanded(child: _buildStatCardSkeleton()),
              ],
            ),
          ] else if (statisticsState.error != null) ...[
            // Error state
            Container(
              padding: EdgeInsets.all(DT.s.md),
              decoration: BoxDecoration(
                color: DT.c.accentRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DT.r.md),
                border: Border.all(
                  color: DT.c.accentRed.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: DT.c.accentRed, size: 24),
                  SizedBox(height: DT.s.sm),
                  Text(
                    'Failed to load statistics',
                    style: DT.t.bodyMedium.copyWith(
                      color: DT.c.accentRed,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: DT.s.xs),
                  Text(
                    statisticsState.error!,
                    style: DT.t.bodySmall.copyWith(color: DT.c.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: DT.s.sm),
                  ElevatedButton(
                    onPressed: statisticsNotifier.refresh,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DT.c.accentRed,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: DT.s.md,
                        vertical: DT.s.sm,
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernStatCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    String? trend,
    String? trendIndicator,
  }) => Container(
    padding: EdgeInsets.all(DT.s.sm),
    decoration: BoxDecoration(
      color: DT.c.card,
      borderRadius: BorderRadius.circular(DT.r.lg),
      boxShadow: DT.e.md,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.all(DT.s.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DT.r.sm),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            if (trend != null) ...[
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DT.s.xs,
                  vertical: DT.s.xs / 2,
                ),
                decoration: BoxDecoration(
                  color: _getTrendColor(trendIndicator).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DT.r.xs),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getTrendIcon(trendIndicator),
                      size: 12,
                      color: _getTrendColor(trendIndicator),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      trend,
                      style: DT.t.labelSmall.copyWith(
                        color: _getTrendColor(trendIndicator),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: DT.s.md),
        Text(
          title,
          style: DT.t.displayMedium.copyWith(
            color: DT.c.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: DT.s.xs),
        Text(subtitle, style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted)),
      ],
    ),
  );

  Widget _buildStatCardSkeleton() => Container(
    padding: EdgeInsets.all(DT.s.sm),
    decoration: BoxDecoration(
      color: DT.c.card,
      borderRadius: BorderRadius.circular(DT.r.lg),
      boxShadow: DT.e.md,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: DT.c.surfaceContainer,
            borderRadius: BorderRadius.circular(DT.r.sm),
          ),
        ),
        SizedBox(height: DT.s.md),
        Container(
          width: 60,
          height: 24,
          decoration: BoxDecoration(
            color: DT.c.surfaceContainer,
            borderRadius: BorderRadius.circular(DT.r.xs),
          ),
        ),
        SizedBox(height: DT.s.xs),
        Container(
          width: 40,
          height: 16,
          decoration: BoxDecoration(
            color: DT.c.surfaceContainer,
            borderRadius: BorderRadius.circular(DT.r.xs),
          ),
        ),
      ],
    ),
  );

  Widget _buildReportsSectionHeader() => Padding(
    padding: EdgeInsets.symmetric(horizontal: DT.s.md),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Reports',
          style: DT.t.titleLarge.copyWith(
            color: DT.c.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        Consumer(
          builder: (context, ref, child) {
            final searchQuery = ref.watch(searchQueryProvider);
            final filters = ref.watch(filterProvider);
            final hasActiveFilters = searchQuery.isNotEmpty || filters != null;

            if (hasActiveFilters) {
              return TextButton(
                onPressed: () {
                  ref.read(searchQueryProvider.notifier).state = '';
                  ref.read(filterProvider.notifier).state = null;
                },
                child: Text(
                  'Clear Filters',
                  style: DT.t.labelMedium.copyWith(color: DT.c.brand),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    ),
  );

  Widget _buildLoadingState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Loading animation
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: DT.c.brand.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DT.r.xl),
          ),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(DT.c.brand),
            strokeWidth: 3,
          ),
        ),

        SizedBox(height: DT.s.lg),

        Text(
          'Loading items...',
          style: DT.t.bodyLarge.copyWith(color: DT.c.textMuted),
        ),

        SizedBox(height: DT.s.sm),

        Text(
          'Please wait while we fetch the latest reports',
          style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _buildEmptyState() => SingleChildScrollView(
    child: Center(
      child: Padding(
        padding: EdgeInsets.all(DT.s.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty state illustration
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: DT.c.surfaceVariant,
                borderRadius: BorderRadius.circular(DT.r.xl),
              ),
              child: Icon(Icons.search_off, size: 48, color: DT.c.textMuted),
            ),

            SizedBox(height: DT.s.lg),

            Text(
              'No items found',
              style: DT.t.headlineSmall.copyWith(
                color: DT.c.text,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: DT.s.sm),

            Text(
              "Try adjusting your search terms or filters to find what you're looking for",
              style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: DT.s.lg),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    ref.read(searchQueryProvider.notifier).state = '';
                    ref.read(filterProvider.notifier).state = null;
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: DT.c.brand),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DT.r.md),
                    ),
                  ),
                  child: Text(
                    'Clear Filters',
                    style: DT.t.labelLarge.copyWith(color: DT.c.brand),
                  ),
                ),
                SizedBox(width: DT.s.md),
                ElevatedButton(
                  onPressed: () {
                    context.go('/report');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DT.c.brand,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DT.r.md),
                    ),
                  ),
                  child: Text(
                    'Report Item',
                    style: DT.t.labelLarge.copyWith(color: DT.c.textOnBrand),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildErrorState(Object error) => SingleChildScrollView(
    child: Center(
      child: Padding(
        padding: EdgeInsets.all(DT.s.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error state illustration
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: DT.c.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DT.r.xl),
              ),
              child: Icon(Icons.error_outline, size: 48, color: DT.c.error),
            ),

            SizedBox(height: DT.s.lg),

            Text(
              'Failed to load reports',
              style: DT.t.headlineSmall.copyWith(
                color: DT.c.text,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: DT.s.sm),

            Text(
              'Unable to connect to the server. Please check your internet connection and try again.',
              style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: DT.s.lg),

            // Retry button
            ElevatedButton(
              onPressed: () {
                ref.invalidate(reportsProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DT.c.brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DT.r.md),
                ),
              ),
              child: Text(
                'Retry',
                style: DT.t.labelLarge.copyWith(color: DT.c.textOnBrand),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterSheet(
        initialFilters: ref.read(filterProvider),
        onApply: (filters) {
          ref.read(filterProvider.notifier).state = filters;
        },
        onClear: () {
          ref.read(filterProvider.notifier).state = null;
        },
      ),
    );
  }

  void _showContactDialog(ReportItem report) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item: ${report.name}'),
            SizedBox(height: DT.s.sm),
            Text('Contact: ${report.contactInfo}'),
            SizedBox(height: DT.s.sm),
            Text('Location: ${report.location}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await Clipboard.setData(ClipboardData(text: report.contactInfo));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Contact info copied to clipboard'),
                    backgroundColor: DT.c.brand,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DT.r.sm),
                    ),
                  ),
                );
              }
            },
            child: const Text('Contact'),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(ReportItem report) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (report.imageUrl != null) ...[
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DT.r.md),
                    color: DT.c.surfaceVariant,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(DT.r.md),
                    child: Image.network(
                      report.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.image_not_supported,
                        size: 64,
                        color: DT.c.textMuted,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: DT.s.md),
              ],
              Text(
                'Description:',
                style: DT.t.titleMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: DT.s.xs),
              Text(report.description),
              SizedBox(height: DT.s.md),
              Text(
                'Details:',
                style: DT.t.titleMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: DT.s.xs),
              Text('Category: ${report.category}'),
              Text('Location: ${report.location}'),
              Text('Distance: ${report.distance}'),
              Text('Time: ${report.timeAgo}'),
              Text('Contact: ${report.contactInfo}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showContactDialog(report);
            },
            child: const Text('Contact'),
          ),
        ],
      ),
    );
  }

  /// Format trend percentage for display
  String? _formatTrend(double? trend) {
    if (trend == null) {
      return null;
    }
    if (trend == 0) {
      return '0%';
    }
    return '${trend > 0 ? '+' : ''}${trend.toStringAsFixed(1)}%';
  }

  /// Get trend color based on indicator
  Color _getTrendColor(String? indicator) {
    switch (indicator) {
      case 'up':
        return DT.c.accentGreen;
      case 'down':
        return DT.c.accentRed;
      case 'stable':
      default:
        return DT.c.textMuted;
    }
  }

  /// Get trend icon based on indicator
  IconData _getTrendIcon(String? indicator) {
    switch (indicator) {
      case 'up':
        return Icons.trending_up;
      case 'down':
        return Icons.trending_down;
      case 'stable':
      default:
        return Icons.trending_flat;
    }
  }

  /// Format last updated time
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
}
