import 'package:flutter/material.dart';
import '../core/toast_config.dart';

/// Static utilities for layout and positioning of toast overlays.
class ToastPositionCalculator {
  ToastPositionCalculator._();

  /// Convert [ToastPosition] to an [Alignment].
  static Alignment toAlignment(ToastPosition position) {
    switch (position) {
      case ToastPosition.top:
        return Alignment.topCenter;
      case ToastPosition.topLeft:
        return Alignment.topLeft;
      case ToastPosition.topRight:
        return Alignment.topRight;
      case ToastPosition.center:
        return Alignment.center;
      case ToastPosition.centerLeft:
        return Alignment.centerLeft;
      case ToastPosition.centerRight:
        return Alignment.centerRight;
      case ToastPosition.bottom:
        return Alignment.bottomCenter;
      case ToastPosition.bottomLeft:
        return Alignment.bottomLeft;
      case ToastPosition.bottomRight:
        return Alignment.bottomRight;
    }
  }

  /// Calculate safe-area padding for the given position.
  static EdgeInsets calculateSafeAreaPadding(
    MediaQueryData mq,
    ToastPosition position,
  ) {
    switch (position) {
      case ToastPosition.top:
      case ToastPosition.topLeft:
      case ToastPosition.topRight:
        return EdgeInsets.only(top: mq.padding.top + 8);
      case ToastPosition.bottom:
      case ToastPosition.bottomLeft:
      case ToastPosition.bottomRight:
        return EdgeInsets.only(bottom: mq.padding.bottom + 8);
      default:
        return EdgeInsets.zero;
    }
  }

  /// Additional offset to avoid the on-screen keyboard.
  static double calculateKeyboardOffset(
    MediaQueryData mq,
    ToastPosition position,
  ) {
    if (mq.viewInsets.bottom <= 0) return 0;
    switch (position) {
      case ToastPosition.bottom:
      case ToastPosition.bottomLeft:
      case ToastPosition.bottomRight:
        return mq.viewInsets.bottom;
      default:
        return 0;
    }
  }

  /// Responsive max width: constrained by device width or custom override.
  static double calculateMaxWidth(
    BoxConstraints constraints, {
    double? customMaxWidth,
  }) {
    final max = customMaxWidth ?? 400.0;
    return max.clamp(0, constraints.maxWidth - 32);
  }

  /// Vertical stack offset for the n-th toast.
  static double calculateStackOffset(int index, double spacing,
      {double toastHeight = 0}) {
    return index * (spacing + toastHeight);
  }

  /// Check text direction for RTL support.
  static bool isRtl(BuildContext context) {
    return Directionality.of(context) == TextDirection.rtl;
  }

  /// Flip horizontal positions for RTL layouts.
  static ToastPosition flipForRtl(ToastPosition position, bool rtl) {
    if (!rtl) return position;
    switch (position) {
      case ToastPosition.topLeft:
        return ToastPosition.topRight;
      case ToastPosition.topRight:
        return ToastPosition.topLeft;
      case ToastPosition.centerLeft:
        return ToastPosition.centerRight;
      case ToastPosition.centerRight:
        return ToastPosition.centerLeft;
      case ToastPosition.bottomLeft:
        return ToastPosition.bottomRight;
      case ToastPosition.bottomRight:
        return ToastPosition.bottomLeft;
      default:
        return position;
    }
  }
}
