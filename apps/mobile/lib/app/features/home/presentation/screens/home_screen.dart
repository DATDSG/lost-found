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
        ..invalidate(colorsProvider)
        ..invalidate(statisticsProvider);

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

  Widget _buildQuickActionsSection() => Padding(
    padding: EdgeInsets.all(DT.s.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: DT.t.titleLarge.copyWith(
            color: DT.c.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: DT.s.md),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Report Lost Item',
                subtitle: 'Lost something?',
                icon: Icons.search_off,
                color: DT.c.accentRed,
                onTap: () => context.go('/report'),
              ),
            ),
            SizedBox(width: DT.s.md),
            Expanded(
              child: _buildActionCard(
                title: 'Report Found Item',
                subtitle: 'Found something?',
                icon: Icons.check_circle,
                color: DT.c.accentGreen,
                onTap: () => context.go('/report'),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.all(DT.s.lg),
      decoration: BoxDecoration(
        color: DT.c.card,
        borderRadius: BorderRadius.circular(DT.r.lg),
        boxShadow: DT.e.md,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(DT.s.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DT.r.sm),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: DT.s.md),
          Text(
            title,
            style: DT.t.titleMedium.copyWith(
              color: DT.c.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: DT.s.xs),
          Text(subtitle, style: DT.t.bodySmall.copyWith(color: DT.c.textMuted)),
        ],
      ),
    ),
  );

  Widget _buildModernStatisticsSection() {
    final statisticsAsync = ref.watch(statisticsProvider);

    return statisticsAsync.when(
      data: (stats) {
        final foundCount = stats['found'] ?? 0;
        final lostCount = stats['lost'] ?? 0;
        final totalCount = stats['total'] ?? 0;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: DT.s.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Statistics',
                    style: DT.t.titleLarge.copyWith(
                      color: DT.c.text,
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
                          DT.c.brand.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: DT.s.md),
              Row(
                children: [
                  Expanded(
                    child: _buildModernStatCard(
                      title: '$foundCount',
                      subtitle: 'Found',
                      color: DT.c.accentGreen,
                      icon: Icons.check_circle_outline,
                      trend: '+12%',
                    ),
                  ),
                  SizedBox(width: DT.s.sm),
                  Expanded(
                    child: _buildModernStatCard(
                      title: '$lostCount',
                      subtitle: 'Lost',
                      color: DT.c.accentRed,
                      icon: Icons.search_off,
                      trend: '+8%',
                    ),
                  ),
                  SizedBox(width: DT.s.sm),
                  Expanded(
                    child: _buildModernStatCard(
                      title: '$totalCount',
                      subtitle: 'Total',
                      color: DT.c.brand,
                      icon: Icons.description_outlined,
                      trend: '+15%',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => Padding(
        padding: EdgeInsets.symmetric(horizontal: DT.s.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: DT.t.titleLarge.copyWith(
                color: DT.c.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: DT.s.md),
            Row(
              children: [
                Expanded(child: _buildStatCardSkeleton()),
                SizedBox(width: DT.s.sm),
                Expanded(child: _buildStatCardSkeleton()),
                SizedBox(width: DT.s.sm),
                Expanded(child: _buildStatCardSkeleton()),
              ],
            ),
          ],
        ),
      ),
      error: (error, stackTrace) => Padding(
        padding: EdgeInsets.symmetric(horizontal: DT.s.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: DT.t.titleLarge.copyWith(
                color: DT.c.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: DT.s.md),
            Row(
              children: [
                Expanded(
                  child: _buildModernStatCard(
                    title: '0',
                    subtitle: 'Found',
                    color: DT.c.accentGreen,
                    icon: Icons.check_circle_outline,
                    trend: '0%',
                  ),
                ),
                SizedBox(width: DT.s.sm),
                Expanded(
                  child: _buildModernStatCard(
                    title: '0',
                    subtitle: 'Lost',
                    color: DT.c.accentRed,
                    icon: Icons.search_off,
                    trend: '0%',
                  ),
                ),
                SizedBox(width: DT.s.sm),
                Expanded(
                  child: _buildModernStatCard(
                    title: '0',
                    subtitle: 'Total',
                    color: DT.c.brand,
                    icon: Icons.description_outlined,
                    trend: '0%',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStatCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required String trend,
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
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: DT.s.xs,
                vertical: DT.s.xs / 2,
              ),
              decoration: BoxDecoration(
                color: DT.c.successBg,
                borderRadius: BorderRadius.circular(DT.r.xs),
              ),
              child: Text(
                trend,
                style: DT.t.labelSmall.copyWith(
                  color: DT.c.successFg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
}
