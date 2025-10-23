import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

/// Enhanced card component with design science principles
class EnhancedCard extends StatefulWidget {
  /// Creates a new [EnhancedCard] instance
  const EnhancedCard({
    required this.child,
    super.key,
    this.onTap,
    this.elevation = CardElevation.medium,
    this.padding,
    this.margin,
    this.borderRadius,
    this.borderColor,
    this.backgroundColor,
    this.semanticLabel,
    this.isLoading = false,
  });

  /// Child widget to display inside the card
  final Widget child;

  /// Callback when the card is tapped
  final VoidCallback? onTap;

  /// Elevation level of the card
  final CardElevation elevation;

  /// Padding inside the card
  final EdgeInsetsGeometry? padding;

  /// Margin around the card
  final EdgeInsetsGeometry? margin;

  /// Border radius of the card
  final BorderRadius? borderRadius;

  /// Border color of the card
  final Color? borderColor;

  /// Background color of the card
  final Color? backgroundColor;

  /// Semantic label for accessibility
  final String? semanticLabel;

  /// Whether the card is in loading state
  final bool isLoading;

  @override
  State<EnhancedCard> createState() => _EnhancedCardState();
}

class _EnhancedCardState extends State<EnhancedCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;

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

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _shimmerAnimation = Tween<double>(begin: -1, end: 1).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    if (widget.isLoading) {
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EnhancedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _shimmerController.repeat();
      } else {
        _shimmerController.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.semanticLabel,
    button: widget.onTap != null,
    child: AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: Container(
          margin: widget.margin ?? EdgeInsets.all(DT.s.sm),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? DT.c.card,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(DT.r.md),
            border: widget.borderColor != null
                ? Border.all(color: widget.borderColor!)
                : null,
            boxShadow: _getBoxShadow(),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius:
                  widget.borderRadius ?? BorderRadius.circular(DT.r.md),
              child: Container(
                padding: widget.padding ?? EdgeInsets.all(DT.s.md),
                child: widget.isLoading ? _buildShimmerContent() : widget.child,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildShimmerContent() => AnimatedBuilder(
    animation: _shimmerAnimation,
    builder: (context, child) => ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [DT.c.surfaceVariant, DT.c.surface, DT.c.surfaceVariant],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(_shimmerAnimation.value * 3.14159),
      ).createShader(bounds),
      child: widget.child,
    ),
  );

  List<BoxShadow> _getBoxShadow() {
    switch (widget.elevation) {
      case CardElevation.none:
        return [];
      case CardElevation.small:
        return DT.e.xs;
      case CardElevation.medium:
        return DT.e.sm;
      case CardElevation.large:
        return DT.e.md;
    }
  }
}

/// Available card elevation levels
enum CardElevation {
  /// No elevation
  none,

  /// Small elevation
  small,

  /// Medium elevation
  medium,

  /// Large elevation
  large,
}

/// Specialized card for lost/found items
class ItemCard extends StatelessWidget {
  /// Creates a new [ItemCard] instance
  const ItemCard({
    required this.title,
    required this.description,
    required this.itemType,
    required this.location,
    required this.date,
    super.key,
    this.imageUrl,
    this.onTap,
    this.isLoading = false,
  });

  /// Title of the item
  final String title;

  /// Description of the item
  final String description;

  /// Type of the item (lost or found)
  final ItemType itemType;

  /// Location where the item was lost/found
  final String location;

  /// Date when the item was reported
  final DateTime date;

  /// URL of the item's image
  final String? imageUrl;

  /// Callback when the card is tapped
  final VoidCallback? onTap;

  /// Whether the card is in loading state
  final bool isLoading;

  @override
  Widget build(BuildContext context) => EnhancedCard(
    onTap: onTap,
    isLoading: isLoading,
    semanticLabel: '$itemType item: $title',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with type indicator
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: DT.s.sm,
                vertical: DT.s.xs,
              ),
              decoration: BoxDecoration(
                color: _getTypeColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DT.r.sm),
                border: Border.all(
                  color: _getTypeColor().withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                itemType.name.toUpperCase(),
                style: DT.t.labelSmall.copyWith(
                  color: _getTypeColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            Text(
              _formatDate(date),
              style: DT.t.caption.copyWith(color: DT.c.textMuted),
            ),
          ],
        ),

        SizedBox(height: DT.s.sm),

        // Image placeholder
        if (imageUrl != null)
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: DT.c.surfaceVariant,
              borderRadius: BorderRadius.circular(DT.r.sm),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DT.r.sm),
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: DT.c.surfaceVariant,
                  child: Icon(
                    Icons.image_not_supported,
                    color: DT.c.textMuted,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),

        SizedBox(height: DT.s.sm),

        // Title
        Text(
          title,
          style: DT.t.titleMedium.copyWith(
            color: DT.c.text,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        SizedBox(height: DT.s.xs),

        // Description
        Text(
          description,
          style: DT.t.bodySmall.copyWith(color: DT.c.textSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        SizedBox(height: DT.s.sm),

        // Location
        Row(
          children: [
            Icon(Icons.location_on_outlined, size: 16, color: DT.c.textMuted),
            SizedBox(width: DT.s.xs),
            Expanded(
              child: Text(
                location,
                style: DT.t.caption.copyWith(color: DT.c.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Color _getTypeColor() {
    switch (itemType) {
      case ItemType.lost:
        return DT.c.accentRed;
      case ItemType.found:
        return DT.c.accentGreen;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Type of item in the report
enum ItemType {
  /// Lost item
  lost,

  /// Found item
  found,
}
