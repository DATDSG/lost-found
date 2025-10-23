import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

/// Responsive design utilities based on design science principles

/// Mobile breakpoint width
const double mobileBreakpoint = 600;

/// Tablet breakpoint width
const double tabletBreakpoint = 900;

/// Desktop breakpoint width
const double desktopBreakpoint = 1200;

/// Get responsive padding based on screen width
EdgeInsets getResponsivePadding(BuildContext context) {
  final width = MediaQuery.of(context).size.width;

  if (width < mobileBreakpoint) {
    return EdgeInsets.all(DT.s.md);
  } else if (width < tabletBreakpoint) {
    return EdgeInsets.all(DT.s.lg);
  } else {
    return EdgeInsets.all(DT.s.xl);
  }
}

/// Get responsive font size based on screen width
double getResponsiveFontSize(BuildContext context, double baseSize) {
  final width = MediaQuery.of(context).size.width;
  final scaleFactor = width / mobileBreakpoint;

  return (baseSize * scaleFactor).clamp(baseSize * 0.8, baseSize * 1.4);
}

/// Get responsive spacing based on screen width
double getResponsiveSpacing(BuildContext context, double baseSpacing) {
  final width = MediaQuery.of(context).size.width;
  final scaleFactor = width / mobileBreakpoint;

  return (baseSpacing * scaleFactor).clamp(
    baseSpacing * 0.8,
    baseSpacing * 1.6,
  );
}

/// Check if device is mobile
bool isMobile(BuildContext context) =>
    MediaQuery.of(context).size.width < mobileBreakpoint;

/// Check if device is tablet
bool isTablet(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return width >= mobileBreakpoint && width < tabletBreakpoint;
}

/// Check if device is desktop
bool isDesktop(BuildContext context) =>
    MediaQuery.of(context).size.width >= desktopBreakpoint;

/// Get responsive column count for grid layouts
int getResponsiveColumns(BuildContext context) {
  if (isMobile(context)) {
    return 1;
  }
  if (isTablet(context)) {
    return 2;
  }
  return 3;
}

/// Get responsive card width
double getResponsiveCardWidth(BuildContext context) {
  final width = MediaQuery.of(context).size.width;

  if (isMobile(context)) {
    return width - (DT.s.md * 2);
  } else if (isTablet(context)) {
    return (width - (DT.s.lg * 3)) / 2;
  } else {
    return (width - (DT.s.xl * 4)) / 3;
  }
}

/// Responsive container widget
class ResponsiveContainer extends StatelessWidget {
  /// Creates a new [ResponsiveContainer] instance
  const ResponsiveContainer({
    required this.child,
    super.key,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
    this.maxWidth,
  });

  /// Child widget to display
  final Widget child;

  /// Padding for mobile devices
  final EdgeInsets? mobilePadding;

  /// Padding for tablet devices
  final EdgeInsets? tabletPadding;

  /// Padding for desktop devices
  final EdgeInsets? desktopPadding;

  /// Maximum width constraint
  final double? maxWidth;

  @override
  Widget build(BuildContext context) => Container(
    constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth!) : null,
    padding: _getResponsivePadding(context),
    child: child,
  );

  EdgeInsets _getResponsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return mobilePadding ?? EdgeInsets.all(DT.s.md);
    } else if (isTablet(context)) {
      return tabletPadding ?? EdgeInsets.all(DT.s.lg);
    } else {
      return desktopPadding ?? EdgeInsets.all(DT.s.xl);
    }
  }
}

/// Responsive text widget
class ResponsiveText extends StatelessWidget {
  /// Creates a new [ResponsiveText] instance
  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.baseFontSize,
  });

  /// Text to display
  final String text;

  /// Text style to apply
  final TextStyle? style;

  /// Text alignment
  final TextAlign? textAlign;

  /// Maximum number of lines
  final int? maxLines;

  /// Text overflow behavior
  final TextOverflow? overflow;

  /// Base font size for responsive scaling
  final double? baseFontSize;

  @override
  Widget build(BuildContext context) {
    final responsiveStyle = style?.copyWith(
      fontSize: baseFontSize != null
          ? getResponsiveFontSize(context, baseFontSize!)
          : style?.fontSize,
    );

    return Text(
      text,
      style: responsiveStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Responsive spacing widget
class ResponsiveSpacing extends StatelessWidget {
  /// Creates a new [ResponsiveSpacing] instance
  const ResponsiveSpacing({
    super.key,
    this.height,
    this.width,
    this.baseSpacing,
  });

  /// Height of the spacing
  final double? height;

  /// Width of the spacing
  final double? width;

  /// Base spacing for responsive scaling
  final double? baseSpacing;

  @override
  Widget build(BuildContext context) {
    final responsiveHeight = height != null && baseSpacing != null
        ? getResponsiveSpacing(context, baseSpacing!)
        : height;

    final responsiveWidth = width != null && baseSpacing != null
        ? getResponsiveSpacing(context, baseSpacing!)
        : width;

    return SizedBox(height: responsiveHeight, width: responsiveWidth);
  }
}
