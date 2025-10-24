import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/models/home_models.dart';
import '../../../../shared/providers/api_providers.dart';
import '../../../../shared/widgets/enhanced_statistics_widget.dart';
import '../../../../shared/widgets/main_layout.dart';

/// Enhanced report section with design science principles
/// Focuses on navigation to report forms with modern UX
class ReportsScreen extends ConsumerStatefulWidget {
  /// Creates a new reports screen widget
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    // Invalidate and refresh all data providers
    ref
      ..invalidate(userReportsProvider)
      ..invalidate(userActiveReportsProvider)
      ..invalidate(userDraftReportsProvider)
      ..invalidate(userResolvedReportsProvider)
      ..invalidate(statisticsProvider);

    // Wait a bit for the refresh to complete
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: MainLayout(
      currentIndex: 1, // Reports is index 1
      child: RefreshIndicator(
        onRefresh: _refreshData,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) => FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: CustomScrollView(
                slivers: [
                  // Hero Header
                  SliverToBoxAdapter(child: _buildHeroHeader()),

                  // Quick Actions Grid
                  SliverToBoxAdapter(child: _buildQuickActionsGrid()),

                  // Statistics Overview
                  SliverToBoxAdapter(child: _buildStatisticsOverview()),

                  // Recent Activity
                  SliverToBoxAdapter(child: _buildRecentActivity()),

                  // Bottom spacing
                  SliverToBoxAdapter(child: SizedBox(height: DT.s.xl)),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildHeroHeader() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          DT.c.brand,
          DT.c.brand.withValues(alpha: 0.8),
          DT.c.accentGreen.withValues(alpha: 0.6),
        ],
        stops: const [0.0, 0.6, 1.0],
      ),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(DT.r.xl)),
      boxShadow: [
        BoxShadow(
          color: DT.c.brand.withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: SafeArea(
      child: Padding(
        padding: EdgeInsets.all(DT.s.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Header with Better Typography
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 32,
                            decoration: BoxDecoration(
                              color: DT.c.textOnBrand,
                              borderRadius: BorderRadius.circular(DT.r.sm),
                            ),
                          ),
                          SizedBox(width: DT.s.sm),
                          Text(
                            'Reports Dashboard',
                            style: DT.t.headlineSmall.copyWith(
                              color: DT.c.textOnBrand,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: DT.s.sm),
                      Text(
                        "Help others find what they're looking for",
                        style: DT.t.bodyLarge.copyWith(
                          color: DT.c.textOnBrand.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: DT.s.xs),
                      Text(
                        'Create reports and track your submissions',
                        style: DT.t.bodyMedium.copyWith(
                          color: DT.c.textOnBrand.withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                // Enhanced Icon Container
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: DT.c.textOnBrand.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(DT.r.xl),
                    border: Border.all(
                      color: DT.c.textOnBrand.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: DT.c.textOnBrand,
                    size: 40,
                  ),
                ),
              ],
            ),

            SizedBox(height: DT.s.xl),

            // Enhanced Search and Filter Section
            Container(
              decoration: BoxDecoration(
                color: DT.c.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(DT.r.lg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search reports...',
                        hintStyle: DT.t.bodyMedium.copyWith(
                          color: DT.c.textMuted,
                        ),
                        prefixIcon: Container(
                          margin: EdgeInsets.all(DT.s.sm),
                          decoration: BoxDecoration(
                            color: DT.c.brand.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(DT.r.sm),
                          ),
                          child: Icon(
                            Icons.search_rounded,
                            color: DT.c.brand,
                            size: 20,
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: DT.s.md,
                          vertical: DT.s.lg,
                        ),
                      ),
                      onChanged: (value) {
                        // Implement search logic
                      },
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.all(DT.s.sm),
                    decoration: BoxDecoration(
                      color: DT.c.accentGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DT.r.sm),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.filter_list_rounded,
                        color: DT.c.accentGreen,
                        size: 20,
                      ),
                      onPressed: () {
                        // Implement filter logic
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildQuickActionsGrid() => Padding(
    padding: EdgeInsets.all(DT.s.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: DT.t.titleLarge.copyWith(
            color: DT.c.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: DT.s.lg),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Report Lost Item',
                subtitle: 'Something you lost?',
                description: 'Help others find your lost item',
                icon: Icons.search_off_rounded,
                color: DT.c.accentRed,
                onTap: () => context.push('/lost-report'),
              ),
            ),
            SizedBox(width: DT.s.md),
            Expanded(
              child: _buildActionCard(
                title: 'Report Found Item',
                subtitle: 'Found something?',
                description: 'Help reunite someone with their item',
                icon: Icons.check_circle_rounded,
                color: DT.c.accentGreen,
                onTap: () => context.push('/found-report'),
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
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: () {
      HapticFeedback.lightImpact();
      onTap();
    },
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DT.r.lg),
            ),
            child: Icon(icon, color: color, size: 32),
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
            style: DT.t.bodyLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: DT.s.sm),
          Text(
            description,
            style: DT.t.bodySmall.copyWith(color: DT.c.textMuted),
          ),
          SizedBox(height: DT.s.md),
          Row(
            children: [
              Text(
                'Get Started',
                style: DT.t.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: DT.s.xs),
              Icon(Icons.arrow_forward_ios, color: color, size: 14),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildStatisticsOverview() => Padding(
    padding: EdgeInsets.symmetric(horizontal: DT.s.lg),
    child: const EnhancedStatisticsWidget(),
  );

  Widget _buildRecentActivity() => Padding(
    padding: EdgeInsets.all(DT.s.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Activity',
              style: DT.t.titleLarge.copyWith(
                color: DT.c.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // Navigate to profile screen to see all reports
                context.go('/profile');
              },
              child: Text(
                'View All',
                style: DT.t.labelMedium.copyWith(
                  color: DT.c.brand,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: DT.s.lg),
        Consumer(
          builder: (context, ref, child) {
            final userReportsAsync = ref.watch(userReportsProvider);

            return userReportsAsync.when(
              data: (reports) {
                if (reports.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(DT.s.lg),
                    decoration: BoxDecoration(
                      color: DT.c.surfaceVariant,
                      borderRadius: BorderRadius.circular(DT.r.md),
                      border: Border.all(color: DT.c.border),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          color: DT.c.textMuted,
                          size: 48,
                        ),
                        SizedBox(height: DT.s.md),
                        Text(
                          'No reports yet',
                          style: DT.t.titleMedium.copyWith(
                            color: DT.c.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: DT.s.sm),
                        Text(
                          'Create your first report to get started',
                          style: DT.t.bodySmall.copyWith(color: DT.c.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Show recent reports (limit to 3)
                final recentReports = reports.take(3).toList();

                return Column(
                  children: recentReports.asMap().entries.map((entry) {
                    final index = entry.key;
                    final report = entry.value;

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < recentReports.length - 1 ? DT.s.md : 0,
                      ),
                      child: _buildActivityItem(
                        icon: report.itemType == ItemType.lost
                            ? Icons.search_off
                            : Icons.check_circle,
                        title: report.itemType == ItemType.lost
                            ? 'Lost Item Reported'
                            : 'Found Item Reported',
                        subtitle: '${report.name} - ${report.category}',
                        time: report.timeAgo,
                        color: report.itemType == ItemType.lost
                            ? DT.c.accentRed
                            : DT.c.accentGreen,
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => Column(
                children: [
                  _buildActivityItem(
                    icon: Icons.hourglass_empty,
                    title: 'Loading...',
                    subtitle: 'Fetching your recent reports',
                    time: 'Please wait',
                    color: DT.c.textMuted,
                  ),
                ],
              ),
              error: (error, stackTrace) => Container(
                padding: EdgeInsets.all(DT.s.lg),
                decoration: BoxDecoration(
                  color: DT.c.surfaceVariant,
                  borderRadius: BorderRadius.circular(DT.r.md),
                  border: Border.all(color: DT.c.border),
                ),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, color: DT.c.accentRed, size: 48),
                    SizedBox(height: DT.s.md),
                    Text(
                      'Error loading reports',
                      style: DT.t.titleMedium.copyWith(
                        color: DT.c.accentRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: DT.s.sm),
                    Text(
                      'Pull down to refresh',
                      style: DT.t.bodySmall.copyWith(color: DT.c.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ),
  );

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) => Container(
    padding: EdgeInsets.all(DT.s.md),
    decoration: BoxDecoration(
      color: DT.c.surfaceVariant,
      borderRadius: BorderRadius.circular(DT.r.md),
      border: Border.all(color: DT.c.border),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DT.r.md),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: DT.s.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: DT.t.titleMedium.copyWith(
                  color: DT.c.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: DT.s.xs),
              Text(
                subtitle,
                style: DT.t.bodySmall.copyWith(color: DT.c.textMuted),
              ),
            ],
          ),
        ),
        Text(time, style: DT.t.labelSmall.copyWith(color: DT.c.textMuted)),
      ],
    ),
  );
}
