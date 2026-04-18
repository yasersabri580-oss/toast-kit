import 'package:flutter/material.dart';

/// Breakpoint definitions for responsive layouts.
enum ScreenSize { mobile, tablet, desktop }

/// Utility class for responsive layout decisions.
class ResponsiveHelper {
  ResponsiveHelper._();

  /// Mobile breakpoint: < 600px
  static const double mobileBreakpoint = 600;

  /// Tablet breakpoint: 600px – 1024px
  static const double tabletBreakpoint = 1024;

  /// Maximum content width for centered layouts on large screens.
  static const double maxContentWidth = 1200;

  /// Returns the current [ScreenSize] based on screen width.
  static ScreenSize screenSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileBreakpoint) return ScreenSize.mobile;
    if (width < tabletBreakpoint) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  /// Returns true if the current screen is mobile-sized.
  static bool isMobile(BuildContext context) =>
      screenSize(context) == ScreenSize.mobile;

  /// Returns true if the current screen is tablet-sized.
  static bool isTablet(BuildContext context) =>
      screenSize(context) == ScreenSize.tablet;

  /// Returns true if the current screen is desktop-sized.
  static bool isDesktop(BuildContext context) =>
      screenSize(context) == ScreenSize.desktop;

  /// Returns the number of grid columns for the current screen size.
  static int gridColumns(BuildContext context) {
    return switch (screenSize(context)) {
      ScreenSize.mobile => 1,
      ScreenSize.tablet => 2,
      ScreenSize.desktop => 3,
    };
  }

  /// Returns adaptive horizontal padding based on screen size.
  static double horizontalPadding(BuildContext context) {
    return switch (screenSize(context)) {
      ScreenSize.mobile => 16,
      ScreenSize.tablet => 24,
      ScreenSize.desktop => 32,
    };
  }

  /// Returns adaptive vertical padding based on screen size.
  static double verticalPadding(BuildContext context) {
    return switch (screenSize(context)) {
      ScreenSize.mobile => 12,
      ScreenSize.tablet => 16,
      ScreenSize.desktop => 24,
    };
  }

  /// Returns spacing between sections based on screen size.
  static double sectionSpacing(BuildContext context) {
    return switch (screenSize(context)) {
      ScreenSize.mobile => 16,
      ScreenSize.tablet => 20,
      ScreenSize.desktop => 24,
    };
  }
}
