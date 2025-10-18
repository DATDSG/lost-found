import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/routing/app_routes.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/reports_provider.dart';
import '../../../providers/matches_provider.dart';
import '../../../models/report.dart';
import '../../../models/match_model.dart';
import 'package:intl/intl.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});
  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final reportsProvider = Provider.of<ReportsProvider>(
      context,
      listen: false,
    );
    final matchesProvider = Provider.of<MatchesProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Only load data if user is authenticated
    if (authProvider.isAuthenticated) {
      await Future.wait([
        reportsProvider.loadMyReports(),
        matchesProvider.loadAllMatches(),
        matchesProvider.loadAnalytics(),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Padding(
            padding: EdgeInsets.fromLTRB(DT.s.lg, DT.s.lg, DT.s.lg, DT.s.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics_rounded, size: 32, color: DT.c.brand),
                    SizedBox(width: DT.s.sm),
                    Text('My Matches', style: DT.t.h1),
                  ],
                ),
                SizedBox(height: DT.s.sm),
                Text(
                  'Track matching progress for your reports',
                  style: DT.t.bodyMuted.copyWith(fontSize: 15),
                ),
              ],
            ),
          ),

          // Stats Cards
          Consumer<MatchesProvider>(
            builder: (context, matchesProvider, _) {
              return FutureBuilder<MatchStats?>(
                future: matchesProvider.getMatchStats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: DT.s.lg),
                      child: Row(
                        children: [
                          Expanded(
                              child: _buildStatCard(
                                  'Active Reports', '...', DT.c.brand)),
                          SizedBox(width: DT.s.md),
                          Expanded(
                              child: _buildStatCard(
                                  'Potential Matches', '...', DT.c.successFg)),
                          SizedBox(width: DT.s.md),
                          Expanded(
                              child: _buildStatCard(
                                  'Confirmed Matches', '...', DT.c.brand)),
                        ],
                      ),
                    );
                  }

                  final stats = snapshot.data;
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: DT.s.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Active Reports',
                            '${stats?.totalMatches ?? 0}',
                            DT.c.brand,
                          ),
                        ),
                        SizedBox(width: DT.s.md),
                        Expanded(
                          child: _buildStatCard(
                            'Potential Matches',
                            '${stats?.pendingMatches ?? 0}',
                            DT.c.successFg,
                          ),
                        ),
                        SizedBox(width: DT.s.md),
                        Expanded(
                          child: _buildStatCard(
                            'Confirmed Matches',
                            '${stats?.confirmedMatches ?? 0}',
                            DT.c.brand,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),

          SizedBox(height: DT.s.lg),

          // Reports List
          Expanded(
            child: Consumer<ReportsProvider>(
              builder: (context, reportsProvider, _) {
                if (reportsProvider.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (reportsProvider.error != null) {
                  return Center(
                    child: Container(
                      margin: EdgeInsets.all(DT.s.lg),
                      padding: EdgeInsets.all(DT.s.lg),
                      decoration: BoxDecoration(
                        color: DT.c.dangerBg,
                        borderRadius: BorderRadius.circular(DT.r.md),
                        border: Border.all(
                          color: DT.c.dangerFg.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, color: DT.c.dangerFg),
                          SizedBox(height: DT.s.sm),
                          Text(
                            reportsProvider.error!,
                            style: DT.t.body.copyWith(color: DT.c.dangerFg),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: DT.s.md),
                          ElevatedButton(
                            onPressed: _loadData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final myReports = reportsProvider.myReports;

                if (myReports.isEmpty) {
                  return Center(
                    child: Container(
                      margin: EdgeInsets.all(DT.s.lg),
                      padding: EdgeInsets.all(DT.s.xl),
                      decoration: BoxDecoration(
                        color: DT.c.surface,
                        borderRadius: BorderRadius.circular(DT.r.lg),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.analytics_rounded,
                            size: 120,
                            color: DT.c.textMuted.withValues(alpha: 0.3),
                          ),
                          SizedBox(height: DT.s.md),
                          Text(
                            'No reports yet',
                            style: DT.t.title.copyWith(color: DT.c.textMuted),
                          ),
                          SizedBox(height: DT.s.sm),
                          Text(
                            'Create your first report to start matching',
                            style: DT.t.body.copyWith(color: DT.c.textMuted),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: DT.s.lg),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.reportLost);
                            },
                            child: const Text('Create Report'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    DT.s.lg,
                    0,
                    DT.s.lg,
                    DT.s.xxl + 80,
                  ),
                  children: myReports.asMap().entries.map((entry) {
                    final index = entry.key;
                    final report = entry.value;
                    return Column(
                      children: [
                        AnimatedListItem(
                          index: index,
                          child: _ReportMatchCard(
                            report: report,
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.viewDetails,
                                arguments: {
                                  'reportId': report.id,
                                  'reportType':
                                      report.isLost ? 'lost' : 'found',
                                  'reportData': {
                                    'title': report.title,
                                    'description': report.description,
                                    'category': report.category,
                                    'brand': 'Unknown',
                                    'color': report.colors?.isNotEmpty == true
                                        ? report.colors!.first
                                        : 'Unknown',
                                    'condition': 'Unknown',
                                    'value': 'Unknown',
                                    'reporterName': 'Anonymous',
                                    'phone': 'Not provided',
                                    'email': 'Not provided',
                                    'preferredContact': 'Any',
                                    'address': report.locationAddress ??
                                        'Not specified',
                                    'city': report.city,
                                    'state': 'Unknown',
                                    'landmark': 'None',
                                    'status': 'Active',
                                    'lastUpdated': DateFormat(
                                      'MMM d, yyyy',
                                    ).format(report.createdAt),
                                    'views': 0,
                                    'date': DateFormat(
                                      'MMM d, yyyy',
                                    ).format(report.createdAt),
                                    'images':
                                        report.media.map((m) => m.url).toList(),
                                  },
                                },
                              );
                            },
                            onViewMatches: () async {
                              // Check if user is authenticated
                              final authProvider = Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              );

                              if (!authProvider.isAuthenticated) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Please log in to view matches',
                                    ),
                                    backgroundColor: DT.c.dangerFg,
                                  ),
                                );
                                return;
                              }

                              // Load matches for this specific report
                              final matchesProvider =
                                  Provider.of<MatchesProvider>(
                                context,
                                listen: false,
                              );
                              await matchesProvider.loadMatchesForReport(
                                report.id,
                              );

                              Navigator.of(context).pushNamed(
                                AppRoutes.matchesDetail,
                                arguments: report.id,
                              );
                            },
                          ),
                        ),
                        if (index < myReports.length - 1)
                          SizedBox(height: DT.s.md),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(DT.s.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DT.r.md),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: DT.t.title.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: DT.s.xs),
          Text(
            title,
            style: DT.t.label.copyWith(color: color, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ReportMatchCard extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;
  final VoidCallback onViewMatches;

  const _ReportMatchCard({
    required this.report,
    required this.onTap,
    required this.onViewMatches,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final statusColor = report.isLost ? DT.c.dangerFg : DT.c.successFg;
    final statusBg = report.isLost ? DT.c.dangerBg : DT.c.successBg;

    // Get real match data for this report
    return Consumer<MatchesProvider>(
      builder: (context, matchesProvider, _) {
        return FutureBuilder<List<Match>>(
          future: matchesProvider.getMatchesForReport(report.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingCard();
            }

            final matches = snapshot.data ?? [];
            final pendingMatches = matches.where((m) => m.isPending).toList();

            // Calculate average score
            final averageScore = matches.isNotEmpty
                ? matches.fold<double>(
                      0.0,
                      (sum, match) => sum + match.overallScore,
                    ) /
                    matches.length
                : 0.0;

            // Get last match date
            final lastMatchDate =
                matches.isNotEmpty ? matches.first.timeAgo : 'No matches yet';

            final matchScore = averageScore;
            final potentialMatchesCount = pendingMatches.length;
            final lastMatch = lastMatchDate;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(DT.r.lg),
                boxShadow: [
                  BoxShadow(
                    color: DT.c.shadow.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header with report info
                  Padding(
                    padding: EdgeInsets.all(DT.s.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Report image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  statusColor.withValues(alpha: 0.15),
                                  statusColor.withValues(alpha: 0.05),
                                ],
                              ),
                            ),
                            child: report.media.isNotEmpty
                                ? Image.network(
                                    report.media.first.url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        report.isLost
                                            ? Icons.search_off_rounded
                                            : Icons
                                                .check_circle_outline_rounded,
                                        size: 24,
                                        color:
                                            statusColor.withValues(alpha: 0.4),
                                      );
                                    },
                                  )
                                : Icon(
                                    report.isLost
                                        ? Icons.search_off_rounded
                                        : Icons.check_circle_outline_rounded,
                                    size: 24,
                                    color: statusColor.withValues(alpha: 0.4),
                                  ),
                          ),
                        ),
                        SizedBox(width: DT.s.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      report.title,
                                      style: DT.t.title.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: DT.s.sm,
                                      vertical: DT.s.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      report.isLost ? 'Lost' : 'Found',
                                      style: DT.t.label.copyWith(
                                        color: statusColor,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: DT.s.xs),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 12,
                                    color: DT.c.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${report.city} • ${dateFormat.format(report.occurredAt)}',
                                    style: DT.t.body.copyWith(
                                      fontSize: 12,
                                      color: DT.c.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Matching Stats Section
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DT.s.md,
                      vertical: DT.s.sm,
                    ),
                    decoration: BoxDecoration(
                      color: DT.c.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(DT.r.lg),
                        bottomRight: Radius.circular(DT.r.lg),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Match Score
                        Expanded(
                          child: _buildMatchStat(
                            'Match Score',
                            '${(matchScore * 100).toInt()}%',
                            _getScoreColor(matchScore),
                            Icons.auto_awesome_rounded,
                          ),
                        ),
                        Container(width: 1, height: 30, color: DT.c.divider),

                        // Potential Matches
                        Expanded(
                          child: _buildMatchStat(
                            'Potential',
                            '$potentialMatchesCount',
                            DT.c.brand,
                            Icons.search_rounded,
                          ),
                        ),
                        Container(width: 1, height: 30, color: DT.c.divider),

                        // Last Match
                        Expanded(
                          child: _buildMatchStat(
                            'Last Match',
                            lastMatch,
                            DT.c.textMuted,
                            Icons.schedule_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: DT.c.divider, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: onTap,
                            child: Padding(
                              padding: EdgeInsets.all(DT.s.md),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.visibility_outlined,
                                    size: 16,
                                    color: DT.c.brand,
                                  ),
                                  SizedBox(width: DT.s.xs),
                                  Text(
                                    'View Report',
                                    style: DT.t.body.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: DT.c.brand,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(width: 1, height: 40, color: DT.c.divider),
                        Expanded(
                          child: InkWell(
                            onTap: onViewMatches,
                            child: Padding(
                              padding: EdgeInsets.all(DT.s.md),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 16,
                                    color: DT.c.successFg,
                                  ),
                                  SizedBox(width: DT.s.xs),
                                  Text(
                                    'View Matches',
                                    style: DT.t.body.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: DT.c.successFg,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DT.r.lg),
        boxShadow: [
          BoxShadow(
            color: DT.c.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(DT.s.lg),
        child: Center(
          child: CircularProgressIndicator(color: DT.c.brand),
        ),
      ),
    );
  }

  Widget _buildMatchStat(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                value,
                style: DT.t.body.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: DT.t.label.copyWith(fontSize: 9, color: DT.c.textMuted),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return DT.c.successFg;
    if (score >= 0.6) return DT.c.brand;
    return DT.c.dangerFg;
  }
}

class AnimatedListItem extends StatefulWidget {
  final int index;
  final Widget child;

  const AnimatedListItem({super.key, required this.index, required this.child});

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300 + (widget.index * 100)),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Start animation after a short delay
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _animation.value)),
          child: Opacity(opacity: _animation.value, child: widget.child),
        );
      },
    );
  }
}
