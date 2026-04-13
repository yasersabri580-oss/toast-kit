import 'package:flutter/material.dart';
import '../core/toast_config.dart';

/// Design token system for ToastKit.
@immutable
class ToastThemeData {
  final Color backgroundColor;
  final Color foregroundColor;
  final Color iconColor;
  final Color successColor;
  final Color errorColor;
  final Color warningColor;
  final Color infoColor;
  final BorderRadius borderRadius;
  final double elevation;
  final Color shadowColor;
  final double blurIntensity;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final TextStyle textStyle;
  final TextStyle titleStyle;
  final double iconSize;
  final double maxWidth;
  final double minHeight;
  final Color? borderColor;
  final double borderWidth;
  final ToastDensity density;

  const ToastThemeData({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.iconColor,
    required this.successColor,
    required this.errorColor,
    required this.warningColor,
    required this.infoColor,
    required this.borderRadius,
    required this.elevation,
    required this.shadowColor,
    required this.blurIntensity,
    required this.padding,
    required this.margin,
    required this.textStyle,
    required this.titleStyle,
    required this.iconSize,
    required this.maxWidth,
    required this.minHeight,
    this.borderColor,
    required this.borderWidth,
    required this.density,
  });

  /// Light theme preset.
  factory ToastThemeData.light() {
    return ToastThemeData(
      backgroundColor: const Color(0xFFFFFFFF),
      foregroundColor: const Color(0xFF1E1E1E),
      iconColor: const Color(0xFF424242),
      successColor: const Color(0xFF4CAF50),
      errorColor: const Color(0xFFE53935),
      warningColor: const Color(0xFFFFA726),
      infoColor: const Color(0xFF42A5F5),
      borderRadius: BorderRadius.circular(12),
      elevation: 6.0,
      shadowColor: const Color(0x40000000),
      blurIntensity: 0.0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      titleStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      iconSize: 24,
      maxWidth: 400,
      minHeight: 48,
      borderColor: null,
      borderWidth: 0,
      density: ToastDensity.comfortable,
    );
  }

  /// Dark theme preset.
  factory ToastThemeData.dark() {
    return ToastThemeData(
      backgroundColor: const Color(0xFF2C2C2E),
      foregroundColor: const Color(0xFFF5F5F5),
      iconColor: const Color(0xFFE0E0E0),
      successColor: const Color(0xFF66BB6A),
      errorColor: const Color(0xFFEF5350),
      warningColor: const Color(0xFFFFCA28),
      infoColor: const Color(0xFF64B5F6),
      borderRadius: BorderRadius.circular(12),
      elevation: 8.0,
      shadowColor: const Color(0x60000000),
      blurIntensity: 0.0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      titleStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      iconSize: 24,
      maxWidth: 400,
      minHeight: 48,
      borderColor: null,
      borderWidth: 0,
      density: ToastDensity.comfortable,
    );
  }

  /// Adaptive theme based on system brightness.
  factory ToastThemeData.adaptive(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    return brightness == Brightness.dark
        ? ToastThemeData.dark()
        : ToastThemeData.light();
  }

  ToastThemeData copyWith({
    Color? backgroundColor,
    Color? foregroundColor,
    Color? iconColor,
    Color? successColor,
    Color? errorColor,
    Color? warningColor,
    Color? infoColor,
    BorderRadius? borderRadius,
    double? elevation,
    Color? shadowColor,
    double? blurIntensity,
    EdgeInsets? padding,
    EdgeInsets? margin,
    TextStyle? textStyle,
    TextStyle? titleStyle,
    double? iconSize,
    double? maxWidth,
    double? minHeight,
    Color? borderColor,
    double? borderWidth,
    ToastDensity? density,
  }) {
    return ToastThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      iconColor: iconColor ?? this.iconColor,
      successColor: successColor ?? this.successColor,
      errorColor: errorColor ?? this.errorColor,
      warningColor: warningColor ?? this.warningColor,
      infoColor: infoColor ?? this.infoColor,
      borderRadius: borderRadius ?? this.borderRadius,
      elevation: elevation ?? this.elevation,
      shadowColor: shadowColor ?? this.shadowColor,
      blurIntensity: blurIntensity ?? this.blurIntensity,
      padding: padding ?? this.padding,
      margin: margin ?? this.margin,
      textStyle: textStyle ?? this.textStyle,
      titleStyle: titleStyle ?? this.titleStyle,
      iconSize: iconSize ?? this.iconSize,
      maxWidth: maxWidth ?? this.maxWidth,
      minHeight: minHeight ?? this.minHeight,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      density: density ?? this.density,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToastThemeData &&
        other.backgroundColor == backgroundColor &&
        other.foregroundColor == foregroundColor &&
        other.elevation == elevation &&
        other.density == density;
  }

  @override
  int get hashCode =>
      Object.hash(backgroundColor, foregroundColor, elevation, density);
}

/// InheritedWidget that provides [ToastThemeData] to the widget tree.
class ToastThemeProvider extends InheritedWidget {
  final ToastThemeData theme;

  const ToastThemeProvider({
    super.key,
    required this.theme,
    required super.child,
  });

  /// Retrieve the closest [ToastThemeData] or fall back to the light theme.
  static ToastThemeData of(BuildContext context) {
    return maybeOf(context) ?? ToastThemeData.light();
  }

  /// Retrieve the closest [ToastThemeData] or `null`.
  static ToastThemeData? maybeOf(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<ToastThemeProvider>();
    return provider?.theme;
  }

  @override
  bool updateShouldNotify(ToastThemeProvider oldWidget) =>
      theme != oldWidget.theme;
}
