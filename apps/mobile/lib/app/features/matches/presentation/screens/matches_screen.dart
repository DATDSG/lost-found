import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/models/matching_models.dart';
import '../../../../shared/providers/matching_providers.dart';
import '../../../../shared/widgets/main_layout.dart';
import '../../../../shared/widgets/matching_report_card.dart';

/// Enhanced matches screen with modern design matching UI assets
class MatchesScreen extends ConsumerStatefulWidget {
  /// Creates a new matches screen widget
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MainLayout(
    currentIndex: 2, // Matches is index 2
    child: SingleChildScrollView(
      child: Column(
        children: [
          // Header with stats
          _buildHeader(),

          // Tab Bar
          _buildTabBar(),

          // Tab Content
          SizedBox(
            height: MediaQuery.of(context).size.height - 200, // Adjust height
            child: _tabController == null
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [_buildLostReportsTab(), _buildFoundReportsTab()],
                  ),
          ),
        ],
      ),
    ),
  );

  Widget _buildHeader() => Container(
    margin: EdgeInsets.all(DT.s.md),
    padding: EdgeInsets.all(DT.s.lg),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          DT.c.brand.withValues(alpha: 0.1),
          DT.c.brand.withValues(alpha: 0.05),
        ],
      ),
      borderRadius: BorderRadius.circular(DT.r.lg),
      boxShadow: DT.e.card,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.favorite, color: DT.c.brand, size: 24),
            SizedBox(width: DT.s.sm),
            Text(
              'My Reports & Matches',
              style: DT.t.titleLarge.copyWith(
                color: DT.c.brand,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: DT.s.md),
        Consumer(
          builder: (context, ref, child) {
            final unwatchedCountAsync = ref.watch(
              unwatchedMatchesCountProvider,
            );
            final acceptedCountAsync = ref.watch(acceptedMatchesCountProvider);
            final totalCountAsync = ref.watch(totalMatchesCountProvider);

            return Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'New',
                    unwatchedCountAsync.when(
                      data: (count) => count.toString(),
                      loading: () => '-',
                      error: (_, _) => '-',
                    ),
                    DT.c.accentOrange,
                    Icons.fiber_new,
                    hasUnwatched: unwatchedCountAsync.when(
                      data: (count) => count > 0,
                      loading: () => false,
                      error: (_, _) => false,
                    ),
                  ),
                ),
                SizedBox(width: DT.s.sm),
                Expanded(
                  child: _buildStatCard(
                    'Accepted',
                    acceptedCountAsync.when(
                      data: (count) => count.toString(),
                      loading: () => '-',
                      error: (_, _) => '-',
                    ),
                    DT.c.accentGreen,
                    Icons.check_circle,
                  ),
                ),
                SizedBox(width: DT.s.sm),
                Expanded(
                  child: _buildStatCard(
                    'Total',
                    totalCountAsync.when(
                      data: (count) => count.toString(),
                      loading: () => '-',
                      error: (_, _) => '-',
                    ),
                    DT.c.brand,
                    Icons.favorite,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    ),
  );

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon, {
    bool hasUnwatched = false,
  }) => Container(
    padding: EdgeInsets.all(DT.s.sm),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(DT.r.md),
      border: Border.all(
        color: hasUnwatched
            ? DT.c.accentOrange.withValues(alpha: 0.8)
            : color.withValues(alpha: 0.3),
        width: hasUnwatched ? 2 : 1,
      ),
      boxShadow: hasUnwatched
          ? [
              BoxShadow(
                color: DT.c.accentOrange.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ]
          : null,
    ),
    child: Column(
      children: [
        Stack(
          children: [
            Icon(icon, color: color, size: 20),
            if (hasUnwatched)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: DT.c.accentOrange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: DT.c.accentOrange.withValues(alpha: 0.6),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: DT.s.xs),
        Text(
          value,
          style: DT.t.titleSmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: DT.t.bodySmall.copyWith(
            color: DT.c.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  Widget _buildTabBar() {
    if (_tabController == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: DT.s.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DT.r.xl),
        boxShadow: DT.e.card,
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: DT.c.brand,
          borderRadius: BorderRadius.circular(DT.r.xl),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: DT.c.textMuted,
        labelStyle: DT.t.body.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: DT.t.body,
        onTap: (index) {
          // Tab selection handled by TabController
        },
        tabs: const [
          Tab(text: 'Lost Items'),
          Tab(text: 'Found Items'),
        ],
      ),
    );
  }

  Widget _buildLostReportsTab() => Consumer(
    builder: (context, ref, child) {
      final lostReportsAsync = ref.watch(lostReportsWithMatchesProvider);

      return lostReportsAsync.when(
        data: _buildReportsList,
        loading: _buildLoadingState,
        error: (error, _) =>
            _buildErrorState('Error loading lost reports: $error'),
      );
    },
  );

  Widget _buildFoundReportsTab() => Consumer(
    builder: (context, ref, child) {
      final foundReportsAsync = ref.watch(foundReportsWithMatchesProvider);

      return foundReportsAsync.when(
        data: _buildReportsList,
        loading: _buildLoadingState,
        error: (error, _) =>
            _buildErrorState('Error loading found reports: $error'),
      );
    },
  );

  Widget _buildReportsList(List<ReportWithMatches> reports) => RefreshIndicator(
    onRefresh: () async {
      ref.invalidate(userReportsWithMatchesProvider);
    },
    child: ListView.builder(
      padding: EdgeInsets.symmetric(vertical: DT.s.sm),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final reportWithMatches = reports[index];
        return MatchingReportCard(
          reportWithMatches: reportWithMatches,
          onTap: () =>
              context.push('/report-detail/${reportWithMatches.report.id}'),
          onViewMatches: () =>
              context.push('/matching-details/${reportWithMatches.report.id}'),
        );
      },
    ),
  );

  Widget _buildLoadingState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: DT.c.brand),
        SizedBox(height: DT.s.md),
        Text(
          'Loading your reports...',
          style: DT.t.body.copyWith(color: DT.c.textMuted),
        ),
      ],
    ),
  );

  Widget _buildErrorState(String message) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: DT.c.accentRed),
        SizedBox(height: DT.s.md),
        Text('Error', style: DT.t.title.copyWith(color: DT.c.accentRed)),
        SizedBox(height: DT.s.sm),
        Text(
          message,
          style: DT.t.body.copyWith(color: DT.c.textMuted),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: DT.s.lg),
        ElevatedButton(
          onPressed: () {
            ref.invalidate(userReportsWithMatchesProvider);
          },
          child: const Text('Retry'),
        ),
      ],
    ),
  );
}
