import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/models/matching_models.dart';
import '../../../../shared/providers/matching_providers.dart';
import '../../../../shared/widgets/enhanced_card.dart';

/// Screen for viewing detailed report information
class ReportDetailScreen extends ConsumerWidget {
  /// Creates a new [ReportDetailScreen] instance
  const ReportDetailScreen({required this.reportId, super.key});

  /// ID of the report to show details for
  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(userReportsWithMatchesProvider);

    return Scaffold(
      backgroundColor: DT.c.background,
      appBar: AppBar(
        title: Text(
          'Report Details',
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
              .where((r) => r.report.id == reportId)
              .firstOrNull;

          if (reportWithMatches == null) {
            return _buildErrorState(context, 'Report not found');
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(DT.s.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageSection(reportWithMatches.report),
                SizedBox(height: DT.s.lg),
                _buildBasicInfoCard(reportWithMatches.report),
                SizedBox(height: DT.s.md),
                _buildDescriptionCard(reportWithMatches.report),
                SizedBox(height: DT.s.md),
                _buildLocationCard(reportWithMatches.report),
                SizedBox(height: DT.s.md),
                _buildAdditionalInfoCard(reportWithMatches.report),
                SizedBox(height: DT.s.md),
                _buildActionButtons(context, reportWithMatches),
              ],
            ),
          );
        },
        loading: _buildLoadingState,
        error: (error, stackTrace) =>
            _buildErrorState(context, 'Error loading report: $error'),
      ),
    );
  }

  Widget _buildImageSection(UserReport report) => Container(
    width: double.infinity,
    height: 250,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(DT.r.lg),
      color: DT.c.surfaceVariant,
    ),
    child: report.imageUrl != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(DT.r.lg),
            child: Image.network(
              report.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildPlaceholderImage(),
            ),
          )
        : _buildPlaceholderImage(),
  );

  Widget _buildPlaceholderImage() => Container(
    decoration: BoxDecoration(
      color: DT.c.surfaceVariant,
      borderRadius: BorderRadius.circular(DT.r.lg),
    ),
    child: Center(
      child: Icon(Icons.image_outlined, size: 64, color: DT.c.textMuted),
    ),
  );

  Widget _buildBasicInfoCard(UserReport report) => EnhancedCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: DT.t.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: DT.s.md),
        _buildInfoRow('Title', report.title),
        _buildInfoRow('Type', report.type.name),
        _buildInfoRow('Status', report.status),
        _buildInfoRow('Created', _formatDate(report.createdAt)),
        if (report.isUrgent) ...[
          SizedBox(height: DT.s.sm),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DT.s.sm,
              vertical: DT.s.xs,
            ),
            decoration: BoxDecoration(
              color: DT.c.accentRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DT.r.xs),
              border: Border.all(color: DT.c.accentRed),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.priority_high, color: DT.c.accentRed, size: 16),
                SizedBox(width: DT.s.xs),
                Text(
                  'URGENT',
                  style: DT.t.labelSmall.copyWith(
                    color: DT.c.accentRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (report.rewardOffered && report.rewardAmount != null) ...[
          SizedBox(height: DT.s.sm),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DT.s.sm,
              vertical: DT.s.xs,
            ),
            decoration: BoxDecoration(
              color: DT.c.accentGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DT.r.xs),
              border: Border.all(color: DT.c.accentGreen),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.monetization_on, color: DT.c.accentGreen, size: 16),
                SizedBox(width: DT.s.xs),
                Text(
                  'Reward: ${report.rewardAmount}',
                  style: DT.t.labelSmall.copyWith(
                    color: DT.c.accentGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );

  Widget _buildDescriptionCard(UserReport report) => EnhancedCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: DT.t.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: DT.s.md),
        Text(report.description, style: DT.t.bodyMedium),
      ],
    ),
  );

  Widget _buildLocationCard(UserReport report) => EnhancedCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: DT.t.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: DT.s.md),
        Row(
          children: [
            Icon(Icons.location_on_outlined, color: DT.c.textMuted, size: 20),
            SizedBox(width: DT.s.sm),
            Expanded(child: Text(report.location, style: DT.t.bodyMedium)),
          ],
        ),
      ],
    ),
  );

  Widget _buildAdditionalInfoCard(UserReport report) => EnhancedCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Information',
          style: DT.t.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: DT.s.md),
        if (report.colors.isNotEmpty) ...[
          Text(
            'Colors:',
            style: DT.t.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: DT.s.sm),
          Wrap(
            spacing: DT.s.xs,
            children: report.colors
                .map(
                  (color) => Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DT.s.sm,
                      vertical: DT.s.xs,
                    ),
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
                  ),
                )
                .toList(),
          ),
          SizedBox(height: DT.s.md),
        ],
        _buildInfoRow('Report ID', report.id),
      ],
    ),
  );

  Widget _buildInfoRow(String label, String value) => Padding(
    padding: EdgeInsets.only(bottom: DT.s.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: DT.t.bodyMedium.copyWith(
              color: DT.c.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Text(value, style: DT.t.bodyMedium)),
      ],
    ),
  );

  Widget _buildActionButtons(
    BuildContext context,
    ReportWithMatches reportWithMatches,
  ) => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () {
            context.push('/matching-details/${reportWithMatches.report.id}');
          },
          icon: const Icon(Icons.favorite, size: 16),
          label: Text('View Matches (${reportWithMatches.matches.length})'),
          style: OutlinedButton.styleFrom(
            foregroundColor: DT.c.brand,
            side: BorderSide(color: DT.c.brand),
            padding: EdgeInsets.symmetric(vertical: DT.s.md),
          ),
        ),
      ),
    ],
  );

  Widget _buildLoadingState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: DT.c.brand),
        SizedBox(height: DT.s.md),
        Text(
          'Loading report details...',
          style: DT.t.body.copyWith(color: DT.c.textMuted),
        ),
      ],
    ),
  );

  Widget _buildErrorState(BuildContext context, String message) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: DT.c.textMuted),
        SizedBox(height: DT.s.md),
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

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
