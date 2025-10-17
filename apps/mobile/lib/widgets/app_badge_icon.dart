import 'package:flutter/material.dart';
import '../core/theme/design_tokens.dart';

/// Icon wrapped in a square outline with optional red badge dot.
/// Sizes: 40x40, radius 12, 1dp border; badge 10dp.
class AppBadgeIcon extends StatelessWidget {
  final IconData icon;
  final int? badgeCount;
  final VoidCallback? onTap;

  const AppBadgeIcon({
    super.key,
    required this.icon,
    this.badgeCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'icon',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DT.c.brand, width: 1),
              ),
              child: Icon(icon, color: DT.c.brand, size: 22),
            ),
            if ((badgeCount ?? 0) > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  height: 10,
                  width: 10,
                  decoration: BoxDecoration(
                    color: DT.c.badge,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
