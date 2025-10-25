// Matching details screen for viewing match information

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/models/matching_models.dart';
import '../../../../shared/providers/matching_providers.dart';
import '../../../../shared/widgets/enhanced_card.dart';

/// Screen for viewing detailed match information
class MatchingDetailsScreen extends ConsumerStatefulWidget {
  /// Creates a new [MatchingDetailsScreen] instance
  const MatchingDetailsScreen({required this.reportId, super.key});

  /// ID of the report to show matches for
  final String reportId;

  @override
  ConsumerState<MatchingDetailsScreen> createState() =>
      _MatchingDetailsScreenState();
}

class _MatchingDetailsScreenState extends ConsumerState<MatchingDetailsScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(userReportsWithMatchesProvider);
    final matchActions = ref.read(matchActionsProvider);

    return Scaffold(
      backgroundColor: DT.c.background,
      appBar: AppBar(
        title: Text(
          'Match Details',
          style: DT.t.titleLarge.copyWith(
            color: DT.c.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: DT.c.card,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: DT.c.text),
          onPressed: context.pop,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: DT.c.text),
            onPressed: () {
              ref.invalidate(userReportsWithMatchesProvider);
            },
          ),
        ],
      ),
      body: reportsAsync.when(
        data: (reports) {
          final reportWithMatches = reports
              .where((r) => r.report.id == widget.reportId)
              .firstOrNull;

          if (reportWithMatches == null) {
            return _buildErrorState('Report not found');
          }

          // Mark unwatched matches as viewed when screen opens
          _markUnwatchedMatchesAsViewed(
            reportWithMatches.matches,
            matchActions,
          );

          return Column(
            children: [
              // Report summary card
              _buildReportSummaryCard(reportWithMatches.report),

              // Tab bar
              _buildTabBar(),

              // Tab content
              Expanded(
                child: _tabController == null
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPendingMatchesTab(
                            reportWithMatches.matches,
                            matchActions,
                          ),
                          _buildAcceptedMatchesTab(reportWithMatches.matches),
                          _buildAllMatchesTab(
                            reportWithMatches.matches,
                            matchActions,
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
        loading: _buildLoadingState,
        error: (error, stackTrace) =>
            _buildErrorState('Error loading matches: $error'),
      ),
    );
  }

  /// Mark unwatched matches as viewed
  void _markUnwatchedMatchesAsViewed(
    List<Match> matches,
    MatchActions matchActions,
  ) {
    final unwatchedMatches = matches.where(
      (match) => !match.isViewed && match.status == MatchStatus.pending,
    );

    for (final match in unwatchedMatches) {
      matchActions.markAsViewed(match.id);
    }
  }

  Widget _buildReportSummaryCard(UserReport report) => Container(
    margin: EdgeInsets.all(DT.s.md),
    child: EnhancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Report image
              if (report.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(DT.r.md),
                  child: Image.network(
                    report.imageUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholderImage(),
                  ),
                )
              else
                _buildPlaceholderImage(),

              SizedBox(width: DT.s.md),

              // Report details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      style: DT.t.title.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: DT.s.xs),
                    Text(
                      report.description,
                      style: DT.t.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: DT.s.sm),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: DT.c.textMuted,
                          size: 16,
                        ),
                        SizedBox(width: DT.s.xs),
                        Expanded(
                          child: Text(
                            report.location,
                            style: DT.t.bodySmall.copyWith(
                              color: DT.c.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildPlaceholderImage() => Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      color: DT.c.surfaceVariant,
      borderRadius: BorderRadius.circular(DT.r.md),
    ),
    child: Icon(Icons.image_outlined, color: DT.c.textMuted, size: 24),
  );

  Widget _buildTabBar() {
    if (_tabController == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: DT.s.md),
      decoration: BoxDecoration(
        color: DT.c.card,
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
        tabs: const [
          Tab(text: 'Pending'),
          Tab(text: 'Accepted'),
          Tab(text: 'All'),
        ],
      ),
    );
  }

  Widget _buildPendingMatchesTab(
    List<Match> matches,
    MatchActions matchActions,
  ) {
    final pendingMatches = matches
        .where((m) => m.status == MatchStatus.pending)
        .toList();

    if (pendingMatches.isEmpty) {
      return _buildEmptyState(
        'No Pending Matches',
        'All matches have been reviewed',
        Icons.check_circle_outline,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(DT.s.md),
      itemCount: pendingMatches.length,
      itemBuilder: (context, index) {
        final match = pendingMatches[index];
        return _buildMatchCard(match, matchActions);
      },
    );
  }

  Widget _buildAcceptedMatchesTab(List<Match> matches) {
    final acceptedMatches = matches
        .where((m) => m.status == MatchStatus.accepted)
        .toList();

    if (acceptedMatches.isEmpty) {
      return _buildEmptyState(
        'No Accepted Matches',
        'No matches have been accepted yet',
        Icons.favorite_outline,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(DT.s.md),
      itemCount: acceptedMatches.length,
      itemBuilder: (context, index) {
        final match = acceptedMatches[index];
        return _buildAcceptedMatchCard(match);
      },
    );
  }

  Widget _buildAllMatchesTab(List<Match> matches, MatchActions matchActions) {
    if (matches.isEmpty) {
      return _buildEmptyState(
        'No Matches Found',
        'No potential matches have been found for this report',
        Icons.search_off,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(DT.s.md),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return _buildMatchCard(match, matchActions);
      },
    );
  }

  Widget _buildMatchCard(Match match, MatchActions matchActions) => Container(
    margin: EdgeInsets.only(bottom: DT.s.md),
    child: EnhancedCard(
      borderColor: !match.isViewed && match.status == MatchStatus.pending
          ? DT.c.accentOrange
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match score header
          _buildMatchScoreHeader(match),

          // Match details
          _buildMatchDetails(match),

          // Action buttons
          if (match.status == MatchStatus.pending)
            _buildMatchActionButtons(match, matchActions),
        ],
      ),
    ),
  );

  Widget _buildAcceptedMatchCard(Match match) => Container(
    margin: EdgeInsets.only(bottom: DT.s.md),
    child: EnhancedCard(
      borderColor: DT.c.accentGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accepted status header
          Container(
            padding: EdgeInsets.all(DT.s.md),
            decoration: BoxDecoration(
              color: DT.c.accentGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(DT.r.md),
                topRight: Radius.circular(DT.r.md),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: DT.c.accentGreen, size: 20),
                SizedBox(width: DT.s.xs),
                Text(
                  'Match Accepted',
                  style: DT.t.titleSmall.copyWith(
                    color: DT.c.accentGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(match.score.totalScore * 100).toStringAsFixed(0)}%',
                  style: DT.t.body.copyWith(
                    color: DT.c.accentGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Match details
          _buildMatchDetails(match),
        ],
      ),
    ),
  );

  Widget _buildMatchScoreHeader(Match match) => Container(
    padding: EdgeInsets.all(DT.s.md),
    decoration: BoxDecoration(
      color: !match.isViewed && match.status == MatchStatus.pending
          ? DT.c.accentOrange.withValues(alpha: 0.1)
          : DT.c.brand.withValues(alpha: 0.1),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(DT.r.md),
        topRight: Radius.circular(DT.r.md),
      ),
    ),
    child: Row(
      children: [
        Icon(
          !match.isViewed && match.status == MatchStatus.pending
              ? Icons.fiber_new
              : Icons.star,
          color: !match.isViewed && match.status == MatchStatus.pending
              ? DT.c.accentOrange
              : DT.c.brand,
          size: 20,
        ),
        SizedBox(width: DT.s.xs),
        Text(
          'Match Score: ${(match.score.totalScore * 100).toStringAsFixed(0)}%',
          style: DT.t.titleSmall.copyWith(
            color: !match.isViewed && match.status == MatchStatus.pending
                ? DT.c.accentOrange
                : DT.c.brand,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (!match.isViewed && match.status == MatchStatus.pending)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DT.s.sm,
              vertical: DT.s.xs,
            ),
            decoration: BoxDecoration(
              color: DT.c.accentOrange.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(DT.r.xs),
            ),
            child: Text(
              'NEW',
              style: DT.t.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DT.s.sm,
              vertical: DT.s.xs,
            ),
            decoration: BoxDecoration(
              color: DT.c.brand.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(DT.r.xs),
            ),
            child: Text(
              match.status.name.toUpperCase(),
              style: DT.t.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    ),
  );

  Widget _buildMatchDetails(Match match) => Padding(
    padding: EdgeInsets.all(DT.s.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Target report details
        Text(
          'Matched Report',
          style: DT.t.titleSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: DT.s.sm),

        Row(
          children: [
            // Target report image
            if (match.targetReport.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(DT.r.sm),
                child: Image.network(
                  match.targetReport.imageUrl!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildSmallPlaceholderImage(),
                ),
              )
            else
              _buildSmallPlaceholderImage(),

            SizedBox(width: DT.s.sm),

            // Target report info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.targetReport.title,
                    style: DT.t.body.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: DT.s.xs),
                  Text(
                    match.targetReport.description,
                    style: DT.t.bodySmall.copyWith(color: DT.c.textMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: DT.s.xs),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: DT.c.textMuted,
                        size: 12,
                      ),
                      SizedBox(width: DT.s.xs),
                      Expanded(
                        child: Text(
                          match.targetReport.location,
                          style: DT.t.bodySmall.copyWith(color: DT.c.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: DT.s.md),

        // Score breakdown
        Text(
          'Score Breakdown',
          style: DT.t.titleSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: DT.s.sm),

        _buildScoreRow('Text Similarity', match.score.textSimilarity),
        _buildScoreRow('Image Similarity', match.score.imageSimilarity),
        _buildScoreRow('Location Proximity', match.score.locationProximity),

        if (match.notes != null) ...[
          SizedBox(height: DT.s.md),
          Text(
            'Notes',
            style: DT.t.titleSmall.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: DT.s.sm),
          Container(
            padding: EdgeInsets.all(DT.s.sm),
            decoration: BoxDecoration(
              color: DT.c.surfaceVariant,
              borderRadius: BorderRadius.circular(DT.r.sm),
            ),
            child: Text(match.notes!, style: DT.t.bodySmall),
          ),
        ],
      ],
    ),
  );

  Widget _buildSmallPlaceholderImage() => Container(
    width: 50,
    height: 50,
    decoration: BoxDecoration(
      color: DT.c.surfaceVariant,
      borderRadius: BorderRadius.circular(DT.r.sm),
    ),
    child: Icon(Icons.image_outlined, color: DT.c.textMuted, size: 20),
  );

  Widget _buildScoreRow(String label, double score) => Padding(
    padding: EdgeInsets.only(bottom: DT.s.xs),
    child: Row(
      children: [
        Text('$label:', style: DT.t.bodySmall.copyWith(color: DT.c.textMuted)),
        SizedBox(width: DT.s.sm),
        Expanded(
          child: LinearProgressIndicator(
            value: score,
            backgroundColor: DT.c.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(DT.c.brand),
          ),
        ),
        SizedBox(width: DT.s.sm),
        Text(
          '${(score * 100).toStringAsFixed(0)}%',
          style: DT.t.bodySmall.copyWith(
            color: DT.c.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _buildMatchActionButtons(Match match, MatchActions matchActions) =>
      Padding(
        padding: EdgeInsets.all(DT.s.md),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final success = await matchActions.rejectMatch(match.id);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Match rejected'),
                        backgroundColor: DT.c.accentRed,
                      ),
                    );
                    ref.invalidate(userReportsWithMatchesProvider);
                  }
                },
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DT.c.accentRed,
                  side: BorderSide(color: DT.c.accentRed),
                  padding: EdgeInsets.symmetric(vertical: DT.s.sm),
                ),
              ),
            ),
            SizedBox(width: DT.s.sm),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final success = await matchActions.acceptMatch(match.id);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Match accepted!'),
                        backgroundColor: DT.c.accentGreen,
                      ),
                    );
                    ref.invalidate(userReportsWithMatchesProvider);
                  }
                },
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Accept'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DT.c.accentGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: DT.s.sm),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildEmptyState(String title, String subtitle, IconData icon) =>
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: DT.c.textMuted),
            SizedBox(height: DT.s.md),
            Text(title, style: DT.t.title.copyWith(color: DT.c.textMuted)),
            SizedBox(height: DT.s.sm),
            Text(
              subtitle,
              style: DT.t.body.copyWith(color: DT.c.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildLoadingState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: DT.c.brand),
        SizedBox(height: DT.s.md),
        Text(
          'Loading matches...',
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
          onPressed: () => context.pop(),
          child: const Text('Go Back'),
        ),
      ],
    ),
  );
}
