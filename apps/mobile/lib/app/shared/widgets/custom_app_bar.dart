import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/design_tokens.dart';

/// Custom app bar with modern design and animations
class CustomAppBar extends ConsumerStatefulWidget {
  /// Creates a new [CustomAppBar] instance
  const CustomAppBar({
    super.key,
    this.title,
    this.showBackButton = false,
    this.actions,
    this.onBackPressed,
    this.showLogo = true,
    this.elevated = false,
  });

  /// Title to display in the app bar
  final String? title;

  /// Whether to show the back button
  final bool showBackButton;

  /// Action widgets to display on the right side
  final List<Widget>? actions;

  /// Callback when back button is pressed
  final VoidCallback? onBackPressed;

  /// Whether to show the app logo
  final bool showLogo;

  /// Whether the app bar should have elevation
  final bool elevated;

  @override
  ConsumerState<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends ConsumerState<CustomAppBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _elevationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _elevationAnimation,
    builder: (context, child) => Container(
      height: 72, // Increased for better touch targets
      padding: EdgeInsets.symmetric(horizontal: DT.s.lg, vertical: DT.s.md),
      decoration: BoxDecoration(
        color: DT.c.card,
        boxShadow: widget.elevated
            ? DT.e.md
                  .map(
                    (shadow) => BoxShadow(
                      color: shadow.color.withValues(
                        alpha: _elevationAnimation.value,
                      ),
                      blurRadius: shadow.blurRadius,
                      offset: shadow.offset,
                    ),
                  )
                  .toList()
            : DT.e.xs,
        border: Border(
          bottom: BorderSide(
            color: DT.c.border.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button or spacer
          if (widget.showBackButton)
            _buildBackButton()
          else
            const SizedBox(width: 48), // Consistent spacing
          // Spacer
          const Spacer(),

          // Centered logo or title
          if (widget.showLogo)
            _buildAppLogo()
          else if (widget.title != null)
            _buildTitle(),

          // Spacer
          const Spacer(),

          // Actions or spacer
          if (widget.actions != null) ...[
            ...widget.actions!,
            SizedBox(width: DT.s.sm),
          ] else
            const SizedBox(width: 48), // Consistent spacing
        ],
      ),
    ),
  );

  Widget _buildBackButton() => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: DT.c.surfaceVariant,
      borderRadius: BorderRadius.circular(DT.r.md),
      border: Border.all(color: DT.c.border.withValues(alpha: 0.5)),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onBackPressed ?? () => Navigator.of(context).pop(),
        borderRadius: BorderRadius.circular(DT.r.md),
        child: Icon(Icons.arrow_back_ios_new, color: DT.c.text, size: 20),
      ),
    ),
  );

  Widget _buildAppLogo() => SizedBox(
    height: 44,
    child: Image.asset(
      'assets/images/App Logo.png',
      fit: BoxFit.contain,
      semanticLabel: 'Lost Finder app logo',
    ),
  );

  Widget _buildTitle() => Text(
    widget.title!,
    style: DT.t.titleLarge.copyWith(
      color: DT.c.text,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    textAlign: TextAlign.center,
  );
}
