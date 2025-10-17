import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/design_tokens.dart';

/// Custom bottom navigation bar for the main app shell
class AppShellBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppShellBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: DT.s.lg, vertical: DT.s.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DT.r.xl),
        border: Border.all(
          color: DT.c.divider.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DT.c.shadow.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: DT.c.shadow.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 115, // Increased from 105 to fix remaining overflow
          padding: EdgeInsets.symmetric(
            horizontal: DT.s.sm,
            vertical: DT.s.md,
          ), // Increased padding
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DT.r.xl),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.white.withValues(alpha: 0.98)],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isActive = index == currentIndex;

              return Expanded(
                child: _EnhancedNavItem(
                  item: item,
                  isActive: isActive,
                  onTap: () {
                    // Haptic feedback
                    HapticFeedback.lightImpact();
                    onTap(index);
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  static const List<_NavItemData> _navItems = [
    _NavItemData(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
      route: 'home',
    ),
    _NavItemData(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Report',
      route: 'report',
    ),
    _NavItemData(
      icon: Icons.verified_user_outlined,
      activeIcon: Icons.verified_user_rounded,
      label: 'Matches',
      route: 'matches',
    ),
    _NavItemData(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
      route: 'profile',
    ),
  ];
}

/// Enhanced navigation item with better animations and user experience
class _EnhancedNavItem extends StatefulWidget {
  final _NavItemData item;
  final bool isActive;
  final VoidCallback onTap;

  const _EnhancedNavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_EnhancedNavItem> createState() => _EnhancedNavItemState();
}

class _EnhancedNavItemState extends State<_EnhancedNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive ? DT.c.brand : DT.c.textMuted;
    final icon = widget.isActive ? widget.item.activeIcon : widget.item.icon;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(DT.r.md),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DT.s.xs,
                  vertical: DT.s.xs,
                ),
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? DT.c.brand.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(DT.r.md),
                  border: widget.isActive
                      ? Border.all(
                          color: DT.c.brand.withValues(alpha: 0.15),
                          width: 1,
                        )
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon with enhanced animation
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.all(6), // Increased padding
                      decoration: BoxDecoration(
                        color: widget.isActive
                            ? DT.c.brand.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(DT.r.sm),
                        boxShadow: widget.isActive
                            ? [
                                BoxShadow(
                                  color: DT.c.brand.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Transform.scale(
                        scale: widget.isActive ? _bounceAnimation.value : 1.0,
                        child: Icon(
                          icon,
                          size: widget.isActive
                              ? 26
                              : 22, // Increased icon sizes
                          color: color,
                        ),
                      ),
                    ),

                    SizedBox(height: 3), // Reduced spacing to fit better
                    // Label with enhanced animation
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: DT.t.label.copyWith(
                        color: color,
                        fontWeight: widget.isActive
                            ? FontWeight.w700
                            : FontWeight.w600,
                        fontSize: widget.isActive
                            ? 12
                            : 10, // Increased text sizes
                      ),
                      child: Text(
                        widget.item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),

                    SizedBox(height: 3), // Reduced spacing to fit better
                    // Enhanced active indicator
                    if (widget.isActive)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        height: 2,
                        width: 20, // Increased width
                        decoration: BoxDecoration(
                          color: DT.c.brand,
                          borderRadius: BorderRadius.circular(1),
                          boxShadow: [
                            BoxShadow(
                              color: DT.c.brand.withValues(alpha: 0.3),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

/// Enhanced bottom navigation with floating action button variant
class AppShellBottomNavWithFAB extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onFABTap;
  final IconData? fabIcon;

  const AppShellBottomNavWithFAB({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onFABTap,
    this.fabIcon,
  });

  @override
  State<AppShellBottomNavWithFAB> createState() =>
      _AppShellBottomNavWithFABState();
}

class _AppShellBottomNavWithFABState extends State<AppShellBottomNavWithFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _fabRotationAnimation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _fabController, curve: Curves.easeInOut));

    _fabRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(parent: _fabController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _handleFABTap() {
    _fabController.forward().then((_) {
      _fabController.reverse();
    });
    HapticFeedback.mediumImpact();
    widget.onFABTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Enhanced Bottom Navigation
        AppShellBottomNav(
          currentIndex: widget.currentIndex,
          onTap: widget.onTap,
        ),

        // Enhanced Floating Action Button
        if (widget.onFABTap != null)
          Positioned(
            top: -20,
            child: AnimatedBuilder(
              animation: _fabController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _fabScaleAnimation.value,
                  child: Transform.rotate(
                    angle: _fabRotationAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: DT.c.brand.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: DT.c.brand.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: FloatingActionButton(
                        onPressed: _handleFABTap,
                        backgroundColor: DT.c.brand,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        mini: true,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Icon(
                            widget.fabIcon ?? Icons.add_rounded,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
