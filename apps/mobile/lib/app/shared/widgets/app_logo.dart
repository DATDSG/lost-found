import 'package:flutter/material.dart';

/// Application logo widget with customizable size and text display
class AppLogo extends StatelessWidget {
  /// Creates a new [AppLogo] instance
  const AppLogo({
    super.key,
    this.size = AppLogoSize.medium,
    this.showText = true,
    this.textColor,
  });

  /// Size of the logo
  final AppLogoSize size;

  /// Whether to show the text alongside the icon
  final bool showText;

  /// Color of the text, defaults to dark blue
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final dimensions = _getDimensions();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Location Pin Icon with Magnifying Glass
        Container(
          width: dimensions.iconSize,
          height: dimensions.iconSize,
          decoration: BoxDecoration(
            color: const Color(0xFF4464B4), // Primary blue
            borderRadius: BorderRadius.circular(dimensions.iconSize / 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4464B4).withValues(alpha: 0.3),
                blurRadius: dimensions.shadowBlur,
                offset: Offset(0, dimensions.shadowOffset),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Map pin shape
              Center(
                child: Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: dimensions.iconSize * 0.6,
                ),
              ),
              // Magnifying glass overlay
              Positioned(
                right: dimensions.iconSize * 0.1,
                bottom: dimensions.iconSize * 0.1,
                child: Container(
                  width: dimensions.iconSize * 0.4,
                  height: dimensions.iconSize * 0.4,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      dimensions.iconSize * 0.2,
                    ),
                    border: Border.all(
                      color: const Color(0xFF4464B4),
                      width: dimensions.borderWidth,
                    ),
                  ),
                  child: Icon(
                    Icons.search,
                    color: const Color(0xFF4464B4),
                    size: dimensions.iconSize * 0.25,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (showText) ...[
          SizedBox(width: dimensions.spacing),

          // Brand Text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'LOST',
                style: TextStyle(
                  fontSize: dimensions.fontSize,
                  fontWeight: FontWeight.bold,
                  color: textColor ?? const Color(0xFF1E3A8A), // Dark blue
                  fontFamily: 'SF Pro Display',
                  height: 1,
                  shadows: textColor == Colors.white
                      ? [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          Shadow(
                            color: const Color(
                              0xFF4464B4,
                            ).withValues(alpha: 0.3),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
              ),
              Text(
                'FINDER',
                style: TextStyle(
                  fontSize: dimensions.fontSize,
                  fontWeight: FontWeight.bold,
                  color: textColor ?? const Color(0xFF1E3A8A), // Dark blue
                  fontFamily: 'SF Pro Display',
                  height: 1,
                  shadows: textColor == Colors.white
                      ? [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          Shadow(
                            color: const Color(
                              0xFF4464B4,
                            ).withValues(alpha: 0.3),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  _LogoDimensions _getDimensions() {
    switch (size) {
      case AppLogoSize.small:
        return _LogoDimensions(
          iconSize: 24,
          fontSize: 12,
          spacing: 6,
          shadowBlur: 4,
          shadowOffset: 1,
          borderWidth: 0.5,
        );
      case AppLogoSize.medium:
        return _LogoDimensions(
          iconSize: 40,
          fontSize: 16,
          spacing: 12,
          shadowBlur: 8,
          shadowOffset: 2,
          borderWidth: 1,
        );
      case AppLogoSize.large:
        return _LogoDimensions(
          iconSize: 80,
          fontSize: 32,
          spacing: 24,
          shadowBlur: 20,
          shadowOffset: 8,
          borderWidth: 2,
        );
    }
  }
}

/// Available sizes for the app logo
enum AppLogoSize {
  /// Small size logo
  small,

  /// Medium size logo
  medium,

  /// Large size logo
  large,
}

/// Internal class for logo dimensions
class _LogoDimensions {
  /// Creates a new [_LogoDimensions] instance
  _LogoDimensions({
    required this.iconSize,
    required this.fontSize,
    required this.spacing,
    required this.shadowBlur,
    required this.shadowOffset,
    required this.borderWidth,
  });

  /// Size of the icon
  final double iconSize;

  /// Size of the font
  final double fontSize;

  /// Spacing between icon and text
  final double spacing;

  /// Blur radius for shadows
  final double shadowBlur;

  /// Offset for shadows
  final double shadowOffset;

  /// Width of borders
  final double borderWidth;
}
