import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/routing/app_routes.dart';
import '../../../providers/reports_provider.dart';
import '../../../models/report.dart';
import 'package:intl/intl.dart';

class MyItemsPage extends StatefulWidget {
  final String itemType; // 'active', 'resolved', 'pending', 'drafts'

  const MyItemsPage({super.key, required this.itemType});

  @override
  State<MyItemsPage> createState() => _MyItemsPageState();
}

class _MyItemsPageState extends State<MyItemsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserReports();
    });
  }

  Future<void> _loadUserReports() async {
    final reportsProvider = Provider.of<ReportsProvider>(
      context,
      listen: false,
    );
    await reportsProvider.loadMyReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getPageTitle()),
        backgroundColor: DT.c.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: DT.c.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<ReportsProvider>(
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
                      onPressed: _loadUserReports,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final filteredReports = _getFilteredReports(
            reportsProvider.myReports,
          );

          if (filteredReports.isEmpty) {
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
                      _getEmptyStateIcon(),
                      size: 120,
                      color: DT.c.textMuted.withValues(alpha: 0.3),
                    ),
                    SizedBox(height: DT.s.md),
                    Text(
                      _getEmptyStateTitle(),
                      style: DT.t.title.copyWith(color: DT.c.textMuted),
                    ),
                    SizedBox(height: DT.s.sm),
                    Text(
                      _getEmptyStateSubtitle(),
                      style: DT.t.body.copyWith(color: DT.c.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.itemType == 'active') ...[
                      SizedBox(height: DT.s.lg),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(AppRoutes.reportLost);
                        },
                        child: const Text('Create Report'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: EdgeInsets.fromLTRB(DT.s.lg, 0, DT.s.lg, DT.s.xxl + 80),
            children: filteredReports.asMap().entries.map((entry) {
              final index = entry.key;
              final report = entry.value;
              return Column(
                children: [
                  AnimatedListItem(
                    index: index,
                    child: _ReportItemCard(
                      report: report,
                      itemType: widget.itemType,
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.reportDetail,
                          arguments: report.id,
                        );
                      },
                      onEdit: widget.itemType == 'drafts'
                          ? () {
                              // Navigate to edit draft
                              Navigator.of(context).pushNamed(
                                AppRoutes.reportEdit,
                                arguments: report.id,
                              );
                            }
                          : null,
                      onResolve: widget.itemType == 'active'
                          ? () {
                              _showResolveDialog(report);
                            }
                          : null,
                    ),
                  ),
                  if (index < filteredReports.length - 1)
                    SizedBox(height: DT.s.md),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  String _getPageTitle() {
    switch (widget.itemType) {
      case 'active':
        return 'Active Reports';
      case 'resolved':
        return 'Resolved Items';
      case 'pending':
        return 'Pending Reports';
      case 'drafts':
        return 'Draft Reports';
      default:
        return 'My Items';
    }
  }

  IconData _getEmptyStateIcon() {
    switch (widget.itemType) {
      case 'active':
        return Icons.assignment_turned_in_rounded;
      case 'resolved':
        return Icons.check_circle_outline_rounded;
      case 'pending':
        return Icons.edit_note_rounded;
      case 'drafts':
        return Icons.edit_note_rounded;
      default:
        return Icons.assignment_turned_in_rounded;
    }
  }

  String _getEmptyStateTitle() {
    switch (widget.itemType) {
      case 'active':
        return 'No active reports';
      case 'resolved':
        return 'No resolved items';
      case 'pending':
        return 'No pending reports';
      case 'drafts':
        return 'No draft reports';
      default:
        return 'No items found';
    }
  }

  String _getEmptyStateSubtitle() {
    switch (widget.itemType) {
      case 'active':
        return 'Create your first report to get started';
      case 'resolved':
        return 'Your resolved items will appear here';
      case 'pending':
        return 'Reports awaiting approval will appear here';
      case 'drafts':
        return 'Your saved drafts will appear here';
      default:
        return 'Items will appear here';
    }
  }

  List<Report> _getFilteredReports(List<Report> reports) {
    switch (widget.itemType) {
      case 'active':
        return reports
            .where((r) => r.status == 'approved' && !r.isResolved)
            .toList();
      case 'resolved':
        return reports.where((r) => r.isResolved).toList();
      case 'pending':
        return reports.where((r) => r.status == 'pending').toList();
      case 'drafts':
        return reports.where((r) => r.status == 'draft').toList();
      default:
        return reports;
    }
  }

  void _showResolveDialog(Report report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Resolved'),
        content: Text(
          'Are you sure you want to mark "${report.title}" as resolved?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resolveReport(report);
            },
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }

  Future<void> _resolveReport(Report report) async {
    try {
      final reportsProvider =
          Provider.of<ReportsProvider>(context, listen: false);

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await reportsProvider.resolveReport(report.id);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Report marked as resolved'),
            backgroundColor: DT.c.successFg,
          ),
        );

        // Reload reports to reflect the change
        await _loadUserReports();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resolve report: $e'),
            backgroundColor: DT.c.dangerFg,
          ),
        );
      }
    }
  }
}

class _ReportItemCard extends StatelessWidget {
  final Report report;
  final String itemType;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onResolve;

  const _ReportItemCard({
    required this.report,
    required this.itemType,
    required this.onTap,
    this.onEdit,
    this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final statusColor = report.isLost ? DT.c.dangerFg : DT.c.successFg;
    final statusBg = report.isLost ? DT.c.dangerBg : DT.c.successBg;

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
          Padding(
            padding: EdgeInsets.all(DT.s.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Report image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 80,
                    width: 80,
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
                                    : Icons.check_circle_outline_rounded,
                                size: 36,
                                color: statusColor.withValues(alpha: 0.4),
                              );
                            },
                          )
                        : Icon(
                            report.isLost
                                ? Icons.search_off_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 36,
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
                              maxLines: 2,
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
                      SizedBox(height: DT.s.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.category_rounded,
                            size: 12,
                            color: DT.c.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            report.category,
                            style: DT.t.body.copyWith(
                              fontSize: 12,
                              color: DT.c.textMuted,
                            ),
                          ),
                        ],
                      ),
                      if (itemType == 'pending') ...[
                        SizedBox(height: DT.s.xs),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 12,
                              color: DT.c.brand,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Awaiting approval',
                              style: DT.t.body.copyWith(
                                fontSize: 12,
                                color: DT.c.brand,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: DT.c.divider, width: 1)),
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
                            'View',
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
                if (onEdit != null || onResolve != null) ...[
                  Container(width: 1, height: 40, color: DT.c.divider),
                  Expanded(
                    child: InkWell(
                      onTap: onEdit ?? onResolve,
                      child: Padding(
                        padding: EdgeInsets.all(DT.s.md),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              onEdit != null
                                  ? Icons.edit_rounded
                                  : Icons.check_rounded,
                              size: 16,
                              color:
                                  onEdit != null ? DT.c.brand : DT.c.successFg,
                            ),
                            SizedBox(width: DT.s.xs),
                            Text(
                              onEdit != null ? 'Edit' : 'Resolve',
                              style: DT.t.body.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: onEdit != null
                                    ? DT.c.brand
                                    : DT.c.successFg,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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
