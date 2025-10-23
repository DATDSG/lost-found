import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';

/// Skeleton loader widget for better loading states
class SkeletonLoader extends StatefulWidget {
  /// Creates a skeleton loader widget
  const SkeletonLoader({
    required this.child,
    super.key,
    this.isLoading = true,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  /// The child widget to show when not loading
  final Widget child;

  /// Whether the skeleton is currently loading
  final bool isLoading;

  /// Base color for the skeleton
  final Color? baseColor;

  /// Highlight color for the skeleton
  final Color? highlightColor;

  /// Duration of the shimmer animation
  final Duration duration;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.isLoading) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(SkeletonLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            widget.baseColor ?? DT.c.surfaceVariant,
            widget.highlightColor ?? DT.c.surface,
            widget.baseColor ?? DT.c.surfaceVariant,
          ],
          stops: [
            _animation.value - 0.3,
            _animation.value,
            _animation.value + 0.3,
          ],
        ).createShader(bounds),
        child: widget.child,
      ),
    );
  }
}

/// Skeleton text widget for loading text content
class SkeletonText extends StatelessWidget {
  /// Creates a skeleton text widget
  const SkeletonText({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  /// Width of the skeleton text
  final double? width;

  /// Height of the skeleton text
  final double height;

  /// Border radius of the skeleton text
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) => SkeletonLoader(
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: DT.c.surfaceVariant,
        borderRadius: borderRadius ?? BorderRadius.circular(DT.r.sm),
      ),
    ),
  );
}

/// Skeleton avatar widget for loading avatar content
class SkeletonAvatar extends StatelessWidget {
  /// Creates a skeleton avatar widget
  const SkeletonAvatar({super.key, this.size = 40, this.borderRadius});

  /// Size of the skeleton avatar
  final double size;

  /// Border radius of the skeleton avatar
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) => SkeletonLoader(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: DT.c.surfaceVariant,
        borderRadius: borderRadius ?? BorderRadius.circular(size / 2),
      ),
    ),
  );
}

/// Skeleton card widget for loading card content
class SkeletonCard extends StatelessWidget {
  /// Creates a skeleton card widget
  const SkeletonCard({
    super.key,
    this.width,
    this.height = 120,
    this.borderRadius,
    this.padding,
  });

  /// Width of the skeleton card
  final double? width;

  /// Height of the skeleton card
  final double height;

  /// Border radius of the skeleton card
  final BorderRadius? borderRadius;

  /// Padding of the skeleton card
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => SkeletonLoader(
    child: Container(
      width: width,
      height: height,
      padding: padding ?? EdgeInsets.all(DT.s.md),
      decoration: BoxDecoration(
        color: DT.c.surfaceVariant,
        borderRadius: borderRadius ?? BorderRadius.circular(DT.r.md),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonAvatar(size: 32),
                SizedBox(width: DT.s.sm),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonText(width: 120, height: 14),
                      SizedBox(height: DT.s.xs),
                      const SkeletonText(width: 80, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: DT.s.md),
            const SkeletonText(width: double.infinity),
            SizedBox(height: DT.s.sm),
            const SkeletonText(width: 200, height: 14),
            SizedBox(height: DT.s.sm),
            const SkeletonText(width: 150, height: 14),
          ],
        ),
      ),
    ),
  );
}

/// Skeleton list widget for loading list content
class SkeletonList extends StatelessWidget {
  /// Creates a skeleton list widget
  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.spacing = 8,
  });

  /// Number of skeleton items
  final int itemCount;

  /// Height of each skeleton item
  final double itemHeight;

  /// Spacing between skeleton items
  final double spacing;

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      itemCount,
      (index) => Padding(
        padding: EdgeInsets.only(bottom: index < itemCount - 1 ? spacing : 0),
        child: SkeletonCard(width: double.infinity, height: itemHeight),
      ),
    ),
  );
}
