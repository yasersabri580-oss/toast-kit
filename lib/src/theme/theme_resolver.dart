import 'package:flutter/material.dart';

import '../core/toast_config.dart';
import 'toast_theme.dart';

/// Hierarchical theme resolution: global → channel → variant → per-toast.
///
/// Each layer merges on top of the previous one using [ToastThemeData.copyWith],
/// so only the fields explicitly set at a given level will override the parent.
@immutable
class ThemeResolver {
  /// Optional application-wide theme override applied on top of the
  /// [ToastThemeProvider] base.
  final ToastThemeData? globalTheme;

  /// Per-channel theme overrides keyed by channel ID.
  final Map<String, ToastThemeData> channelThemes;

  /// Per-variant theme overrides keyed by [ToastVariant].
  final Map<ToastVariant, ToastThemeData> variantThemes;

  const ThemeResolver({
    this.globalTheme,
    this.channelThemes = const {},
    this.variantThemes = const {},
  });

  /// Resolves a [ToastThemeData] by walking the hierarchy:
  ///
  /// 1. [ToastThemeProvider.of] (context-based base)
  /// 2. [globalTheme]
  /// 3. [channelThemes] entry for [channelId]
  /// 4. [variantThemes] entry for [variant]
  /// 5. [perToastOverride]
  ToastThemeData resolve(
    BuildContext context, {
    String? channelId,
    ToastVariant? variant,
    ToastThemeData? perToastOverride,
  }) {
    ToastThemeData resolved = ToastThemeProvider.of(context);

    if (globalTheme != null) {
      resolved = merge(resolved, globalTheme!);
    }

    if (channelId != null && channelThemes.containsKey(channelId)) {
      resolved = merge(resolved, channelThemes[channelId]!);
    }

    if (variant != null && variantThemes.containsKey(variant)) {
      resolved = merge(resolved, variantThemes[variant]!);
    }

    if (perToastOverride != null) {
      resolved = merge(resolved, perToastOverride);
    }

    return resolved;
  }

  /// Merges [override] on top of [base].
  ///
  /// Every non-null field in [override] replaces the corresponding field in
  /// [base]. Because [ToastThemeData] fields are all required (except
  /// [borderColor]), the merge is implemented via [copyWith] so callers can
  /// build partial overrides using [ToastThemeData.copyWith] themselves.
  static ToastThemeData merge(ToastThemeData base, ToastThemeData override) {
    return base.copyWith(
      backgroundColor: override.backgroundColor,
      foregroundColor: override.foregroundColor,
      iconColor: override.iconColor,
      successColor: override.successColor,
      errorColor: override.errorColor,
      warningColor: override.warningColor,
      infoColor: override.infoColor,
      borderRadius: override.borderRadius,
      elevation: override.elevation,
      shadowColor: override.shadowColor,
      blurIntensity: override.blurIntensity,
      padding: override.padding,
      margin: override.margin,
      textStyle: override.textStyle,
      titleStyle: override.titleStyle,
      iconSize: override.iconSize,
      maxWidth: override.maxWidth,
      minHeight: override.minHeight,
      borderColor: override.borderColor,
      borderWidth: override.borderWidth,
      density: override.density,
    );
  }

  /// Returns a high-contrast variant of [theme].
  ///
  /// Text and icon colours are pushed toward full black or white depending on
  /// the perceived luminance of the background, and the border is set to a
  /// clearly visible contrasting colour.
  static ToastThemeData highContrast(ToastThemeData theme) {
    final bool isDark =
        theme.backgroundColor.computeLuminance() < 0.5;
    final Color contrastForeground =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final Color contrastBorder =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);

    return theme.copyWith(
      foregroundColor: contrastForeground,
      iconColor: contrastForeground,
      borderColor: contrastBorder,
      borderWidth: theme.borderWidth < 1.0 ? 1.5 : theme.borderWidth,
      textStyle: theme.textStyle.copyWith(
        fontWeight: FontWeight.w700,
        color: contrastForeground,
      ),
      titleStyle: theme.titleStyle.copyWith(
        fontWeight: FontWeight.w800,
        color: contrastForeground,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeResolver &&
        other.globalTheme == globalTheme &&
        _mapsEqual(other.channelThemes, channelThemes) &&
        _mapsEqual(other.variantThemes, variantThemes);
  }

  @override
  int get hashCode =>
      Object.hash(globalTheme, channelThemes.length, variantThemes.length);

  static bool _mapsEqual<K>(Map<K, dynamic> a, Map<K, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}

/// InheritedWidget that provides a [ThemeResolver] to the widget tree.
class ThemeResolverProvider extends InheritedWidget {
  final ThemeResolver resolver;

  const ThemeResolverProvider({
    super.key,
    required this.resolver,
    required super.child,
  });

  /// Retrieve the closest [ThemeResolver] or fall back to a default instance.
  static ThemeResolver of(BuildContext context) {
    return maybeOf(context) ?? const ThemeResolver();
  }

  /// Retrieve the closest [ThemeResolver] or `null`.
  static ThemeResolver? maybeOf(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<ThemeResolverProvider>();
    return provider?.resolver;
  }

  @override
  bool updateShouldNotify(ThemeResolverProvider oldWidget) =>
      resolver != oldWidget.resolver;
}
