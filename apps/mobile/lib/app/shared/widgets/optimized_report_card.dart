import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/design_tokens.dart';
import '../models/home_models.dart';

/// Optimized ReportCard widget with reduced animation overhead
class OptimizedReportCard extends StatefulWidget {
  /// Creates a new [OptimizedReportCard] instance
  const OptimizedReportCard({
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
  State<OptimizedReportCard> createState() => _OptimizedReportCardState();
}

class _OptimizedReportCardState extends State<OptimizedReportCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) {
      if (mounted) {
        setState(() {
          _isPressed = true;
        });
      }
    },
    onTapUp: (_) {
      if (mounted) {
        setState(() {
          _isPressed = false;
        });
      }
      widget.onViewDetails?.call();
    },
    onTapCancel: () {
      if (mounted) {
        setState(() {
          _isPressed = false;
        });
      }
    },
    child: Transform.scale(
      scale: _isPressed ? 0.98 : 1.0,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: DT.s.md, vertical: DT.s.sm),
        decoration: BoxDecoration(
          color: DT.c.card,
          borderRadius: BorderRadius.circular(DT.r.lg),
          boxShadow: DT.e.sm,
          border: Border.all(color: DT.c.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image and status
            _buildImageSection(),

            // Content
            Padding(
              padding: EdgeInsets.all(DT.s.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  SizedBox(height: DT.s.sm),
                  _buildDescription(),
                  SizedBox(height: DT.s.md),
                  _buildFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildImageSection() => Stack(
    children: [
      // Image
      Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(DT.r.lg),
            topRight: Radius.circular(DT.r.lg),
          ),
          color: DT.c.surfaceVariant,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(DT.r.lg),
            topRight: Radius.circular(DT.r.lg),
          ),
          child: widget.report.imageUrl != null
              ? Image.network(
                  widget.report.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.image_not_supported,
                    size: 64,
                    color: DT.c.textMuted,
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(DT.c.brand),
                        strokeWidth: 2,
                      ),
                    );
                  },
                )
              : Icon(
                  Icons.image_not_supported,
                  size: 64,
                  color: DT.c.textMuted,
                ),
        ),
      ),

      // Status badge
      Positioned(
        top: DT.s.sm,
        right: DT.s.sm,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: DT.s.sm, vertical: DT.s.xs),
          decoration: BoxDecoration(
            color: widget.report.itemType == ItemType.lost
                ? DT.c.accentRed
                : DT.c.accentGreen,
            borderRadius: BorderRadius.circular(DT.r.sm),
          ),
          child: Text(
            widget.report.itemType == ItemType.lost ? 'Lost' : 'Found',
            style: DT.t.labelSmall.copyWith(
              color: DT.c.textOnBrand,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ],
  );

  Widget _buildHeader() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              widget.report.name,
              style: DT.t.titleMedium.copyWith(
                color: DT.c.text,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: DT.s.sm),
          Text(
            widget.report.timeAgo,
            style: DT.t.caption.copyWith(color: DT.c.textMuted),
          ),
        ],
      ),
      SizedBox(height: DT.s.xs),
      Row(
        children: [
          // Category badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DT.s.sm,
              vertical: DT.s.xs,
            ),
            decoration: BoxDecoration(
              color: DT.c.brand.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DT.r.sm),
              border: Border.all(color: DT.c.brand.withValues(alpha: 0.3)),
            ),
            child: Text(
              widget.report.category,
              style: DT.t.labelSmall.copyWith(
                color: DT.c.brand,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: DT.s.sm),
          // Colors display
          if (widget.report.colors.isNotEmpty) ...[
            Expanded(
              child: Wrap(
                spacing: DT.s.xs,
                children: widget.report.colors
                    .take(3)
                    .map(
                      (color) => Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getColorFromName(color),
                          borderRadius: BorderRadius.circular(DT.r.xs),
                          border: Border.all(color: DT.c.border),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    ],
  );

  Widget _buildDescription() => Text(
    widget.report.description,
    style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  );

  Widget _buildFooter() => Row(
    children: [
      // Location
      Expanded(
        child: Row(
          children: [
            Icon(Icons.location_on_outlined, size: 16, color: DT.c.textMuted),
            SizedBox(width: DT.s.xs),
            Expanded(
              child: Text(
                widget.report.location,
                style: DT.t.bodySmall.copyWith(color: DT.c.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),

      SizedBox(width: DT.s.sm),

      // Distance
      Row(
        children: [
          Icon(Icons.near_me_outlined, size: 16, color: DT.c.textMuted),
          SizedBox(width: DT.s.xs),
          Text(
            widget.report.distance,
            style: DT.t.bodySmall.copyWith(color: DT.c.textMuted),
          ),
        ],
      ),

      SizedBox(width: DT.s.md),

      // Contact button
      GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onContact?.call();
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: DT.s.sm, vertical: DT.s.xs),
          decoration: BoxDecoration(
            color: DT.c.brand.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DT.r.sm),
            border: Border.all(color: DT.c.brand.withValues(alpha: 0.3)),
          ),
          child: Text(
            'Contact',
            style: DT.t.labelSmall.copyWith(
              color: DT.c.brand,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ],
  );

  /// Convert color name to actual Color object
  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'gray':
      case 'grey':
        return Colors.grey;
      case 'brown':
        return Colors.brown;
      case 'pink':
        return Colors.pink;
      case 'cyan':
        return Colors.cyan;
      case 'magenta':
        return Colors.pink.shade400;
      case 'lime':
        return Colors.lime;
      case 'navy':
        return Colors.indigo.shade900;
      case 'maroon':
        return Colors.red.shade900;
      case 'silver':
        return Colors.grey.shade400;
      case 'gold':
        return Colors.amber;
      case 'bronze':
        return Colors.brown.shade600;
      case 'copper':
        return Colors.orange.shade700;
      case 'light_blue':
        return Colors.lightBlue;
      case 'light_green':
        return Colors.lightGreen;
      case 'light_pink':
        return Colors.pink.shade200;
      case 'lavender':
        return Colors.purple.shade200;
      case 'dark_blue':
        return Colors.indigo.shade800;
      case 'dark_green':
        return Colors.green.shade800;
      case 'dark_red':
        return Colors.red.shade800;
      case 'dark_gray':
        return Colors.grey.shade700;
      case 'beige':
        return Colors.brown.shade200;
      case 'tan':
        return Colors.brown.shade300;
      case 'transparent':
        return Colors.transparent;
      case 'multicolored':
        return Colors.purple;
      case 'patterned':
        return Colors.grey.shade600;
      default:
        return Colors.grey.shade400;
    }
  }
}
