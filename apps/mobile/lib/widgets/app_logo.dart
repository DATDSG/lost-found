import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

/// Simple logo component that only shows the App Logo.png image
class AppLogo extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;

  const AppLogo({super.key, this.size = 40, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(DT.r.sm),
          boxShadow: [
            BoxShadow(
              color: DT.c.shadow.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DT.r.sm),
          child: Image.asset(
            'assets/images/App Logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to icon if image fails to load
              return Container(
                decoration: BoxDecoration(
                  color: DT.c.brand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DT.r.sm),
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: DT.c.brand,
                  size: size * 0.5,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Predefined logo configurations for common use cases
class AppLogoPresets {
  static Widget appBarLogo() => const AppLogo(size: 40);

  static Widget splashLogo() => const AppLogo(size: 80);

  static Widget compactLogo() => const AppLogo(size: 32);

  static Widget iconOnly({double size = 40}) => AppLogo(size: size);
}
