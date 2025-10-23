import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/design_tokens.dart';

/// Custom bottom navigation bar with animations and modern design
class BottomNavBar extends StatefulWidget {
  /// Creates a new [BottomNavBar] instance
  const BottomNavBar({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  /// Currently selected tab index
  final int currentIndex;

  /// Callback when a tab is tapped
  final void Function(int) onTap;

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar>
    with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _iconAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationControllers = List.generate(
      4,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 150),
        vsync: this,
      ),
    );

    _scaleAnimations = _animationControllers
        .map(
          (controller) => Tween<double>(begin: 1, end: 0.9).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut),
          ),
        )
        .toList();

    _iconAnimations = _animationControllers
        .map(
          (controller) => Tween<double>(
            begin: 0,
            end: 1,
          ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut)),
        )
        .toList();
  }

  @override
  void dispose() {
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: DT.c.card,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(28),
      ),
      boxShadow: DT.e.lg,
      border: Border(
        top: BorderSide(color: DT.c.border.withValues(alpha: 0.3), width: 0.5),
      ),
    ),
    child: SafeArea(
      child: Container(
        height: 80, // Optimized height to prevent overflow
        padding: EdgeInsets.symmetric(horizontal: DT.s.lg, vertical: DT.s.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              label: 'Home',
              semanticLabel: 'Navigate to Home screen',
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.add_circle_outline,
              selectedIcon: Icons.add_circle_rounded,
              label: 'Report',
              semanticLabel: 'Navigate to Report screen',
            ),
            _buildNavItem(
              index: 2,
              icon: Icons.favorite_outline,
              selectedIcon: Icons.favorite_rounded,
              label: 'Matches',
              semanticLabel: 'Navigate to Matches screen',
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.person_outline,
              selectedIcon: Icons.person_rounded,
              label: 'Profile',
              semanticLabel: 'Navigate to Profile screen',
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required String semanticLabel,
  }) {
    final isSelected = widget.currentIndex == index;
    final activeColor = DT.c.brand;
    final inactiveColor = DT.c.textMuted;

    return Expanded(
      child: Semantics(
        label: semanticLabel,
        selected: isSelected,
        button: true,
        child: GestureDetector(
          onTapDown: (_) {
            HapticFeedback.lightImpact();
            _animationControllers[index].forward();
          },
          onTapUp: (_) {
            _animationControllers[index].reverse();
            widget.onTap(index);
          },
          onTapCancel: () {
            _animationControllers[index].reverse();
          },
          child: AnimatedBuilder(
            animation: _scaleAnimations[index],
            builder: (context, child) => Transform.scale(
              scale: _scaleAnimations[index].value,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: DT.s.xs),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Enhanced icon container with modern design
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 48,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? DT.c.brand.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(DT.r.md),
                        border: isSelected
                            ? Border.all(
                                color: DT.c.brand.withValues(alpha: 0.2),
                              )
                            : null,
                      ),
                      child: AnimatedBuilder(
                        animation: _iconAnimations[index],
                        builder: (context, child) => Icon(
                          isSelected ? selectedIcon : icon,
                          size: 16,
                          color: isSelected ? activeColor : inactiveColor,
                          semanticLabel: isSelected ? 'Selected $label' : label,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Enhanced label with better typography
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
                      style: DT.t.labelSmall.copyWith(
                        color: isSelected ? activeColor : inactiveColor,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 9,
                        letterSpacing: 0.1,
                      ),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
