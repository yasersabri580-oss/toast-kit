import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../core/toast_config.dart';

/// Configuration for toast accessibility features.
///
/// Controls how toasts interact with assistive technologies such as
/// screen readers, reduced-motion preferences, and high-contrast mode.
///
/// ```dart
/// const config = ToastAccessibilityConfig(
///   announceToasts: true,
///   respectReducedMotion: true,
/// );
/// ```
@immutable
class ToastAccessibilityConfig {
  /// Creates a [ToastAccessibilityConfig] with sensible defaults.
  const ToastAccessibilityConfig({
    this.announceToasts = true,
    this.respectReducedMotion = true,
    this.semanticLabels = true,
    this.focusActionButtons = true,
    this.highContrastMode = false,
  });

  /// Whether to announce toasts to screen readers via
  /// [SemanticsService].
  final bool announceToasts;

  /// Whether to respect the platform's reduced-motion preference.
  ///
  /// When `true`, animations may be shortened or removed for users who
  /// have enabled reduced-motion in their system settings.
  final bool respectReducedMotion;

  /// Whether to add semantic labels to toast widgets so assistive
  /// technologies can describe them.
  final bool semanticLabels;

  /// Whether action buttons inside toasts should be keyboard-focusable.
  final bool focusActionButtons;

  /// Whether to force high-contrast visuals regardless of the platform
  /// setting.
  final bool highContrastMode;

  /// Returns a copy with the given fields replaced.
  ToastAccessibilityConfig copyWith({
    bool? announceToasts,
    bool? respectReducedMotion,
    bool? semanticLabels,
    bool? focusActionButtons,
    bool? highContrastMode,
  }) {
    return ToastAccessibilityConfig(
      announceToasts: announceToasts ?? this.announceToasts,
      respectReducedMotion: respectReducedMotion ?? this.respectReducedMotion,
      semanticLabels: semanticLabels ?? this.semanticLabels,
      focusActionButtons: focusActionButtons ?? this.focusActionButtons,
      highContrastMode: highContrastMode ?? this.highContrastMode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToastAccessibilityConfig &&
        other.announceToasts == announceToasts &&
        other.respectReducedMotion == respectReducedMotion &&
        other.semanticLabels == semanticLabels &&
        other.focusActionButtons == focusActionButtons &&
        other.highContrastMode == highContrastMode;
  }

  @override
  int get hashCode => Object.hash(
        announceToasts,
        respectReducedMotion,
        semanticLabels,
        focusActionButtons,
        highContrastMode,
      );
}

/// Utility helpers for querying platform accessibility state and
/// interacting with assistive technology services.
///
/// All methods are static and stateless.
///
/// ```dart
/// if (ToastAccessibility.shouldReduceMotion(context)) {
///   // use a simpler animation
/// }
/// ```
class ToastAccessibility {
  // Private constructor – this class is not meant to be instantiated.
  ToastAccessibility._();

  /// Returns `true` when the platform indicates that the user prefers
  /// reduced motion (e.g. "Reduce motion" on iOS / "Remove animations"
  /// on Android).
  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Returns the current text-scale factor reported by the platform.
  ///
  /// Uses [TextScaler.scale] with a base size of `1.0` to correctly
  /// support nonlinear text scaling. Toast layouts can use this value
  /// to adjust sizing so text remains legible at larger accessibility
  /// font sizes.
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaler.scale(1.0);
  }

  /// Returns `true` when the platform's high-contrast mode is active.
  static bool isHighContrast(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// Announces a toast message to screen readers using
  /// [SemanticsService].
  ///
  /// A [BuildContext] is required to resolve the current text direction.
  /// The [type] is prepended to the announcement so users understand the
  /// severity (e.g. "Error: Something went wrong").
  static Future<void> announceToast(
    String message,
    ToastType type, {
    required BuildContext context,
  }) async {
    final String prefix = _prefixForType(type);
    final String announcement =
        prefix.isEmpty ? message : '$prefix: $message';
    final textDirection = Directionality.of(context);

    // ignore: deprecated_member_use
    await SemanticsService.announce(announcement, textDirection);
  }

  /// Builds a human-readable semantic label for a toast.
  ///
  /// The label includes the toast [type], an optional [title], and the
  /// [message] body – for example:
  ///
  /// ```
  /// "Success: Upload complete – Your file has been saved."
  /// ```
  static String buildSemanticLabel(
    String message,
    String? title,
    ToastType type,
  ) {
    final String prefix = _prefixForType(type);
    final StringBuffer buffer = StringBuffer();

    if (prefix.isNotEmpty) {
      buffer.write(prefix);
    }

    if (title != null && title.isNotEmpty) {
      if (buffer.isNotEmpty) {
        buffer.write(': ');
      }
      buffer.write(title);
    }

    if (message.isNotEmpty) {
      if (buffer.isNotEmpty) {
        buffer.write(' – ');
      }
      buffer.write(message);
    }

    return buffer.toString();
  }

  /// Maps a [ToastType] to its human-readable prefix for announcements.
  static String _prefixForType(ToastType type) {
    switch (type) {
      case ToastType.success:
        return 'Success';
      case ToastType.error:
        return 'Error';
      case ToastType.warning:
        return 'Warning';
      case ToastType.info:
        return 'Info';
      case ToastType.loading:
        return 'Loading';
      // ignore: deprecated_member_use_from_same_package
      case ToastType.custom:
        return '';
    }
  }
}

/// A widget that wraps its [child] with [Semantics] metadata so
/// assistive technologies can correctly describe and announce toasts.
///
/// When [hasActions] is `true` the wrapper adds a container-role hint
/// so screen readers indicate the presence of interactive elements.
///
/// ```dart
/// SemanticToastWrapper(
///   message: 'File deleted',
///   type: ToastType.info,
///   hasActions: true,
///   child: MyToastContent(),
/// );
/// ```
class SemanticToastWrapper extends StatelessWidget {
  /// Creates a [SemanticToastWrapper].
  const SemanticToastWrapper({
    required this.message,
    required this.type,
    required this.child,
    this.title,
    this.hasActions = false,
    super.key,
  });

  /// The main body text of the toast.
  final String message;

  /// Optional title displayed above [message].
  final String? title;

  /// Semantic type of the toast (success, error, etc.).
  final ToastType type;

  /// Whether the toast contains interactive action buttons.
  final bool hasActions;

  /// The widget tree rendered inside the semantic wrapper.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final String label = ToastAccessibility.buildSemanticLabel(
      message,
      title,
      type,
    );

    return Semantics(
      label: label,
      liveRegion: true,
      button: false,
      container: hasActions,
      child: child,
    );
  }
}
