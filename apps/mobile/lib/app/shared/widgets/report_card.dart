import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/design_tokens.dart';
import '../models/home_models.dart';

/// Report card widget for displaying lost/found items
class ReportCard extends StatefulWidget {
  /// Creates a new [ReportCard] instance
  const ReportCard({
    required this.report,
    super.key,
    this.onContact,
    this.onViewDetails,
  });

  /// Report item to display
  final ReportItem report;

  /// Callback when contact button is pressed
  final VoidCallback? onContact;

  /// Callback when view details is requested
  final VoidCallback? onViewDetails;

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _scaleAnimation,
    builder: (context, child) => Transform.scale(
      scale: _scaleAnimation.value,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: DT.s.md, vertical: DT.s.sm),
        decoration: BoxDecoration(
          color: DT.c.card,
          borderRadius: BorderRadius.circular(DT.r.lg),
          boxShadow: DT.e.sm,
          border: Border.all(color: DT.c.border, width: 0.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTapDown: (_) {
              HapticFeedback.lightImpact();
              _scaleController.forward();
            },
            onTapUp: (_) {
              _scaleController.reverse();
            },
            onTapCancel: () {
              _scaleController.reverse();
            },
            borderRadius: BorderRadius.circular(DT.r.lg),
            child: Padding(
              padding: EdgeInsets.all(DT.s.md),
              child: Row(
                children: [
                  // Item image
                  _buildItemImage(),
                  SizedBox(width: DT.s.md),

                  // Item details
                  Expanded(child: _buildItemDetails()),

                  // Status badge
                  _buildStatusBadge(),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildItemImage() => Container(
    width: 80,
    height: 80,
    decoration: BoxDecoration(
      color: DT.c.surfaceVariant,
      borderRadius: BorderRadius.circular(DT.r.md),
      border: Border.all(color: DT.c.border, width: 0.5),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(DT.r.md),
      child: widget.report.imageUrl != null
          ? Image.network(
              widget.report.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildPlaceholderImage(),
            )
          : _buildPlaceholderImage(),
    ),
  );

  Widget _buildPlaceholderImage() => Container(
    color: DT.c.surfaceVariant,
    child: Icon(_getCategoryIcon(), color: DT.c.textMuted, size: 32),
  );

  IconData _getCategoryIcon() {
    switch (widget.report.category.toLowerCase()) {
      case 'electronics':
        return Icons.phone_android;
      case 'clothing':
        return Icons.checkroom;
      case 'accessories':
        return Icons.watch;
      case 'books':
        return Icons.menu_book;
      default:
        return Icons.category;
    }
  }

  Widget _buildItemDetails() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Item name
      Text(
        widget.report.name,
        style: DT.t.titleMedium.copyWith(
          color: DT.c.text,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),

      SizedBox(height: DT.s.xs),

      // Location, distance, and time
      Row(
        children: [
          Icon(Icons.location_on_outlined, size: 14, color: DT.c.textMuted),
          SizedBox(width: DT.s.xs),
          Expanded(
            child: Text(
              '${widget.report.location} | ${widget.report.distance} | ${widget.report.timeAgo}',
              style: DT.t.caption.copyWith(color: DT.c.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),

      SizedBox(height: DT.s.sm),

      // Action buttons
      Row(
        children: [
          Expanded(
            child: _buildActionButton(
              label: 'Contact',
              isPrimary: false,
              onTap: widget.onContact,
            ),
          ),
          SizedBox(width: DT.s.sm),
          Expanded(
            child: _buildActionButton(
              label: 'View Details',
              isPrimary: true,
              onTap: widget.onViewDetails,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _buildActionButton({
    required String label,
    required bool isPrimary,
    required VoidCallback? onTap,
  }) => GestureDetector(
    onTap: () {
      HapticFeedback.lightImpact();
      onTap?.call();
    },
    child: Container(
      padding: EdgeInsets.symmetric(vertical: DT.s.sm, horizontal: DT.s.sm),
      decoration: BoxDecoration(
        color: isPrimary
            ? DT.c.brand.withValues(alpha: 0.1)
            : DT.c.surfaceVariant,
        borderRadius: BorderRadius.circular(DT.r.sm),
        border: isPrimary
            ? Border.all(color: DT.c.brand.withValues(alpha: 0.3))
            : null,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: DT.t.labelSmall.copyWith(
          color: isPrimary ? DT.c.brand : DT.c.text,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  Widget _buildStatusBadge() {
    final isFound = widget.report.itemType == ItemType.found;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: DT.s.sm, vertical: DT.s.xs),
      decoration: BoxDecoration(
        color: isFound
            ? DT.c.accentGreen.withValues(alpha: 0.1)
            : DT.c.accentRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DT.r.sm),
        border: Border.all(
          color: isFound
              ? DT.c.accentGreen.withValues(alpha: 0.3)
              : DT.c.accentRed.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        widget.report.itemType.name.toUpperCase(),
        style: DT.t.labelSmall.copyWith(
          color: isFound ? DT.c.accentGreen : DT.c.accentRed,
          fontWeight: FontWeight.w600,
          fontSize: 9,
        ),
      ),
    );
  }
}
