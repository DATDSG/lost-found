// Enhanced matching card widget with modern design

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/time_utils.dart';
import '../models/matching_models.dart';

/// Enhanced card widget for displaying user reports with matches
class MatchingReportCard extends StatefulWidget {
  /// Creates a new [MatchingReportCard] instance
  const MatchingReportCard({
    required this.reportWithMatches,
    super.key,
    this.onTap,
    this.onViewMatches,
  });

  /// Report with matches data
  final ReportWithMatches reportWithMatches;

  /// Callback when the card is tapped
  final VoidCallback? onTap;

  /// Callback when view matches is requested
  final VoidCallback? onViewMatches;

  @override
  State<MatchingReportCard> createState() => _MatchingReportCardState();
}

class _MatchingReportCardState extends State<MatchingReportCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start pulse animation if there are pending matches
    if (widget.reportWithMatches.matches.any(
      (match) => match.status == MatchStatus.pending,
    )) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.reportWithMatches.report;
    final matches = widget.reportWithMatches.matches;
    final pendingMatches = matches
        .where((m) => m.status == MatchStatus.pending)
        .length;
    final acceptedMatches = matches
        .where((m) => m.status == MatchStatus.accepted)
        .length;
    final unwatchedMatches = matches
        .where((m) => !m.isViewed && m.status == MatchStatus.pending)
        .length;
    final hasUnwatchedMatches = unwatchedMatches > 0;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: GestureDetector(
          onTapDown: (_) {
            HapticFeedback.lightImpact();
            _scaleController.forward();
          },
          onTapUp: (_) {
            _scaleController.reverse();
            widget.onTap?.call();
          },
          onTapCancel: () {
            _scaleController.reverse();
          },
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: DT.s.md,
              vertical: DT.s.sm,
            ),
            decoration: BoxDecoration(
              color: DT.c.card,
              borderRadius: BorderRadius.circular(DT.r.lg),
              boxShadow: hasUnwatchedMatches
                  ? [
                      BoxShadow(
                        color: DT.c.accentOrange.withValues(alpha: 0.2),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                      ...DT.e.card,
                    ]
                  : DT.e.card,
              border: Border.all(
                color: hasUnwatchedMatches
                    ? DT.c.accentOrange.withValues(alpha: 0.6)
                    : DT.c.border.withValues(alpha: 0.3),
                width: hasUnwatchedMatches ? 2 : 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with image and status
                _buildHeader(report, pendingMatches, unwatchedMatches),

                // Content section
                _buildContent(report, matches),

                // Matches summary
                if (matches.isNotEmpty)
                  _buildMatchesSummary(
                    matches,
                    pendingMatches,
                    acceptedMatches,
                  ),

                // Action buttons
                _buildActionButtons(report, matches.isNotEmpty),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    UserReport report,
    int pendingMatches,
    int unwatchedMatches,
  ) => Container(
    height: 120,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(DT.r.lg),
        topRight: Radius.circular(DT.r.lg),
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          DT.c.brand.withValues(alpha: 0.1),
          DT.c.brand.withValues(alpha: 0.05),
        ],
      ),
    ),
    child: Stack(
      children: [
        // Background image
        if (report.imageUrl != null)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(DT.r.lg),
                topRight: Radius.circular(DT.r.lg),
              ),
              child: Image.network(
                report.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholderImage(),
              ),
            ),
          )
        else
          _buildPlaceholderImage(),

        // Gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(DT.r.lg),
                topRight: Radius.circular(DT.r.lg),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Status badges
        Positioned(
          top: DT.s.sm,
          left: DT.s.sm,
          child: Row(
            children: [
              _buildStatusBadge(report.type),
              if (report.isUrgent) ...[
                SizedBox(width: DT.s.xs),
                _buildUrgentBadge(),
              ],
              if (report.rewardOffered) ...[
                SizedBox(width: DT.s.xs),
                _buildRewardBadge(),
              ],
            ],
          ),
        ),

        // Pending matches indicator
        if (pendingMatches > 0)
          Positioned(
            top: DT.s.sm,
            right: DT.s.sm,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: DT.s.sm,
                    vertical: DT.s.xs,
                  ),
                  decoration: BoxDecoration(
                    color: unwatchedMatches > 0
                        ? DT.c.accentOrange
                        : DT.c.brand,
                    borderRadius: BorderRadius.circular(DT.r.full),
                    boxShadow: DT.e.sm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        unwatchedMatches > 0 ? Icons.fiber_new : Icons.pending,
                        color: Colors.white,
                        size: 12,
                      ),
                      SizedBox(width: DT.s.xs),
                      Text(
                        unwatchedMatches > 0
                            ? '$unwatchedMatches'
                            : '$pendingMatches',
                        style: DT.t.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Title overlay
        Positioned(
          bottom: DT.s.sm,
          left: DT.s.sm,
          right: DT.s.sm,
          child: Text(
            report.title,
            style: DT.t.title.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );

  Widget _buildPlaceholderImage() => Container(
    decoration: BoxDecoration(
      color: DT.c.surfaceVariant,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(DT.r.lg),
        topRight: Radius.circular(DT.r.lg),
      ),
    ),
    child: Center(
      child: Icon(Icons.image_outlined, size: 40, color: DT.c.textMuted),
    ),
  );

  Widget _buildStatusBadge(ReportType type) {
    final isLost = type == ReportType.lost;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: DT.s.sm, vertical: DT.s.xs),
      decoration: BoxDecoration(
        color: isLost
            ? DT.c.accentRed.withValues(alpha: 0.9)
            : DT.c.accentGreen.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(DT.r.xs),
        boxShadow: DT.e.xs,
      ),
      child: Text(
        isLost ? 'Lost' : 'Found',
        style: DT.t.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUrgentBadge() => Container(
    padding: EdgeInsets.symmetric(horizontal: DT.s.sm, vertical: DT.s.xs),
    decoration: BoxDecoration(
      color: DT.c.warning.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(DT.r.xs),
      boxShadow: DT.e.xs,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.priority_high, color: Colors.white, size: 10),
        SizedBox(width: DT.s.xs),
        Text(
          'Urgent',
          style: DT.t.labelSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Widget _buildRewardBadge() => Container(
    padding: EdgeInsets.symmetric(horizontal: DT.s.sm, vertical: DT.s.xs),
    decoration: BoxDecoration(
      color: DT.c.accentPurple.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(DT.r.xs),
      boxShadow: DT.e.xs,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.monetization_on, color: Colors.white, size: 10),
        SizedBox(width: DT.s.xs),
        Text(
          'Reward',
          style: DT.t.labelSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Widget _buildContent(UserReport report, List<Match> matches) => Padding(
    padding: EdgeInsets.all(DT.s.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        Text(
          report.description,
          style: DT.t.bodyMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        SizedBox(height: DT.s.sm),

        // Location and date
        Row(
          children: [
            Icon(Icons.location_on_outlined, color: DT.c.textMuted, size: 16),
            SizedBox(width: DT.s.xs),
            Expanded(
              child: Text(
                report.location,
                style: DT.t.bodySmall.copyWith(color: DT.c.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: DT.s.sm),
            Icon(Icons.access_time, color: DT.c.textMuted, size: 16),
            SizedBox(width: DT.s.xs),
            Text(
              formatTimeAgo(report.createdAt),
              style: DT.t.bodySmall.copyWith(color: DT.c.textMuted),
            ),
          ],
        ),

        // Colors
        if (report.colors.isNotEmpty) ...[
          SizedBox(height: DT.s.sm),
          Wrap(
            spacing: DT.s.xs,
            children: report.colors.map(_buildColorChip).toList(),
          ),
        ],
      ],
    ),
  );

  Widget _buildColorChip(String color) => Container(
    padding: EdgeInsets.symmetric(horizontal: DT.s.sm, vertical: DT.s.xs),
    decoration: BoxDecoration(
      color: DT.c.surfaceVariant,
      borderRadius: BorderRadius.circular(DT.r.xs),
      border: Border.all(color: DT.c.border),
    ),
    child: Text(
      color,
      style: DT.t.bodySmall.copyWith(
        color: DT.c.textMuted,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  Widget _buildMatchesSummary(
    List<Match> matches,
    int pendingMatches,
    int acceptedMatches,
  ) => Container(
    margin: EdgeInsets.symmetric(horizontal: DT.s.md),
    padding: EdgeInsets.all(DT.s.md),
    decoration: BoxDecoration(
      color: DT.c.surfaceVariant,
      borderRadius: BorderRadius.circular(DT.r.md),
      border: Border.all(color: DT.c.border.withValues(alpha: 0.5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.favorite, color: DT.c.brand, size: 18),
            SizedBox(width: DT.s.xs),
            Text(
              'Matches Found',
              style: DT.t.titleSmall.copyWith(
                color: DT.c.brand,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${matches.length} total',
              style: DT.t.bodySmall.copyWith(
                color: DT.c.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        SizedBox(height: DT.s.sm),

        // Match status indicators
        Row(
          children: [
            if (pendingMatches > 0) ...[
              _buildMatchStatusIndicator(
                'Pending',
                pendingMatches,
                DT.c.accentOrange,
                Icons.pending,
              ),
              SizedBox(width: DT.s.md),
            ],
            if (acceptedMatches > 0) ...[
              _buildMatchStatusIndicator(
                'Accepted',
                acceptedMatches,
                DT.c.accentGreen,
                Icons.check_circle,
              ),
              SizedBox(width: DT.s.md),
            ],
            _buildMatchStatusIndicator(
              'Rejected',
              matches.where((m) => m.status == MatchStatus.rejected).length,
              DT.c.accentRed,
              Icons.cancel,
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildMatchStatusIndicator(
    String label,
    int count,
    Color color,
    IconData icon,
  ) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color, size: 14),
      SizedBox(width: DT.s.xs),
      Text(
        '$count $label',
        style: DT.t.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  Widget _buildActionButtons(UserReport report, bool hasMatches) => Padding(
    padding: EdgeInsets.all(DT.s.md),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onTap,
            icon: const Icon(Icons.visibility_outlined, size: 16),
            label: const Text('View Details'),
            style: OutlinedButton.styleFrom(
              foregroundColor: DT.c.brand,
              side: BorderSide(color: DT.c.brand),
              padding: EdgeInsets.symmetric(vertical: DT.s.sm),
            ),
          ),
        ),
        if (hasMatches) ...[
          SizedBox(width: DT.s.sm),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: widget.onViewMatches,
              icon: const Icon(Icons.favorite, size: 16),
              label: const Text('View Matches'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DT.c.brand,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: DT.s.sm),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
