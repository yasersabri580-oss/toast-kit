import 'package:flutter/material.dart';

/// Position where a toast is displayed on screen.
enum ToastPosition {
  /// Top center of the screen.
  top,

  /// Top-left corner.
  topLeft,

  /// Top-right corner.
  topRight,

  /// Center of the screen.
  center,

  /// Center-left.
  centerLeft,

  /// Center-right.
  centerRight,

  /// Bottom center.
  bottom,

  /// Bottom-left corner.
  bottomLeft,

  /// Bottom-right corner.
  bottomRight,
}

/// Queue ordering mode.
enum QueueMode {
  /// First-in, first-out.
  fifo,

  /// Last-in, first-out.
  lifo,

  /// Ordered by [ToastPriority].
  priority,
}

/// Visual density of toast content.
enum ToastDensity {
  /// Less padding, smaller text.
  compact,

  /// Default balanced layout.
  comfortable,

  /// More padding, larger touch targets.
  spacious,
}

/// Built-in animation types.
enum ToastAnimationType {
  /// Simple opacity transition.
  fade,

  /// Slides in from the top.
  slideFromTop,

  /// Slides in from the bottom.
  slideFromBottom,

  /// Slides in from the left.
  slideFromLeft,

  /// Slides in from the right.
  slideFromRight,

  /// Scales up from a small size.
  scale,

  /// Bouncy overshoot entrance.
  bounce,

  /// Elastic spring effect.
  elastic,

  /// Physics-based spring animation.
  spring,

  /// Horizontal shake effect.
  shake,

  /// Blur transition.
  blur,

  /// Pulsing glow effect.
  glow,

  /// User-provided animation builder.
  custom,
}

/// Semantic type of a toast notification.
enum ToastType {
  /// Positive outcome.
  success,

  /// Failure or error.
  error,

  /// Cautionary alert.
  warning,

  /// Neutral information.
  info,

  /// In-progress indicator.
  loading,

  /// Completely user-defined.
  custom,
}

/// Lifecycle state of a toast notification.
///
/// Toasts can transition between states using [ToastController.updateState].
/// For example, a loading toast can transition to success or error.
enum ToastState {
  /// Initial idle state before display.
  idle,

  /// In-progress / loading indicator.
  loading,

  /// Positive outcome.
  success,

  /// Failure or error.
  error,

  /// Cautionary alert.
  warning,

  /// Neutral information.
  info,

  /// Completely user-defined state.
  custom,
}

/// Priority for queue ordering and interruption rules.
enum ToastPriority {
  /// Lowest priority – deferred when the queue is full.
  low,

  /// Default priority.
  normal,

  /// Elevated – displayed before normal and low.
  high,

  /// Highest – displayed immediately, may interrupt others.
  urgent,
}

/// Visual variant presets.
enum ToastVariant {
  /// Clean, minimal design.
  minimal,

  /// Material Design 3 style.
  material,

  /// iOS Human Interface style.
  ios,

  /// Frosted-glass appearance.
  glassmorphism,

  /// Soft raised / inset style.
  neumorphism,

  /// Gradient background.
  gradient,

  /// Background blur effect.
  blurredBackground,

  /// Floating elevated card.
  floatingCard,

  /// Full-width top banner.
  topBanner,

  /// Bottom sheet style.
  bottomSheet,

  /// Inline within content flow.
  inline,

  /// Small pill-shaped toast.
  compact,

  /// Spans entire width.
  fullWidth,

  /// Icon-centric layout.
  iconBased,

  /// Text only – no icons.
  textOnly,

  /// Embeds arbitrary widgets.
  richContent,

  /// Spinner / loading indicator.
  loading,

  /// Determinate / indeterminate progress bar.
  progress,

  /// Contains action buttons.
  action,

  /// Retry button included.
  retry,

  /// Undo action included.
  undo,

  /// Must be manually dismissed.
  persistent,

  /// Expandable / collapsible.
  expandable,

  /// Chat-bubble appearance.
  chatBubble,

  /// Developer / debug info.
  debug,

  /// Fully user-built UI via builder.
  customBuilder,
}

/// Swipe directions for gesture dismissal.
enum SwipeDismissDirection {
  /// Swipe left to dismiss.
  left,

  /// Swipe right to dismiss.
  right,

  /// Swipe up to dismiss.
  up,

  /// Swipe down to dismiss.
  down,

  /// Either left or right.
  horizontal,

  /// Either up or down.
  vertical,

  /// Any direction.
  any,
}

/// Replacement strategy when the visible slot limit is reached.
enum ReplacementStrategy {
  /// New events are silently dropped.
  dropNew,

  /// The oldest visible toast is replaced.
  replaceOldest,

  /// The visible toast with the same or lower priority is replaced.
  replaceSamePriority,
}

/// Global configuration for ToastKit SDK.
@immutable
class ToastConfig {
  /// Default screen position for toasts.
  final ToastPosition defaultPosition;

  /// Default auto-dismiss duration.
  final Duration defaultDuration;

  /// Maximum number of toasts visible at the same time.
  final int maxVisibleToasts;

  /// Whether the internal queue is enabled.
  final bool enableQueue;

  /// Queue ordering mode.
  final QueueMode queueMode;

  /// Default enter / exit animation duration.
  final Duration defaultAnimationDuration;

  /// Default animation type.
  final ToastAnimationType defaultAnimation;

  /// Whether to respect device safe-area insets.
  final bool safeAreaEnabled;

  /// Whether toasts should move above the on-screen keyboard.
  final bool keyboardAvoidance;

  /// Visual density of toast content.
  final ToastDensity density;

  /// Vertical spacing between stacked toasts.
  final double toastSpacing;

  /// Creates a [ToastConfig] with sensible defaults.
  const ToastConfig({
    this.defaultPosition = ToastPosition.top,
    this.defaultDuration = const Duration(seconds: 3),
    this.maxVisibleToasts = 3,
    this.enableQueue = true,
    this.queueMode = QueueMode.fifo,
    this.defaultAnimationDuration = const Duration(milliseconds: 300),
    this.defaultAnimation = ToastAnimationType.slideFromTop,
    this.safeAreaEnabled = true,
    this.keyboardAvoidance = true,
    this.density = ToastDensity.comfortable,
    this.toastSpacing = 8.0,
  });

  /// Returns a copy with the given fields replaced.
  ToastConfig copyWith({
    ToastPosition? defaultPosition,
    Duration? defaultDuration,
    int? maxVisibleToasts,
    bool? enableQueue,
    QueueMode? queueMode,
    Duration? defaultAnimationDuration,
    ToastAnimationType? defaultAnimation,
    bool? safeAreaEnabled,
    bool? keyboardAvoidance,
    ToastDensity? density,
    double? toastSpacing,
  }) {
    return ToastConfig(
      defaultPosition: defaultPosition ?? this.defaultPosition,
      defaultDuration: defaultDuration ?? this.defaultDuration,
      maxVisibleToasts: maxVisibleToasts ?? this.maxVisibleToasts,
      enableQueue: enableQueue ?? this.enableQueue,
      queueMode: queueMode ?? this.queueMode,
      defaultAnimationDuration:
          defaultAnimationDuration ?? this.defaultAnimationDuration,
      defaultAnimation: defaultAnimation ?? this.defaultAnimation,
      safeAreaEnabled: safeAreaEnabled ?? this.safeAreaEnabled,
      keyboardAvoidance: keyboardAvoidance ?? this.keyboardAvoidance,
      density: density ?? this.density,
      toastSpacing: toastSpacing ?? this.toastSpacing,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToastConfig &&
        other.defaultPosition == defaultPosition &&
        other.defaultDuration == defaultDuration &&
        other.maxVisibleToasts == maxVisibleToasts &&
        other.enableQueue == enableQueue &&
        other.queueMode == queueMode &&
        other.defaultAnimationDuration == defaultAnimationDuration &&
        other.defaultAnimation == defaultAnimation &&
        other.safeAreaEnabled == safeAreaEnabled &&
        other.keyboardAvoidance == keyboardAvoidance &&
        other.density == density &&
        other.toastSpacing == toastSpacing;
  }

  @override
  int get hashCode => Object.hash(
        defaultPosition,
        defaultDuration,
        maxVisibleToasts,
        enableQueue,
        queueMode,
        defaultAnimationDuration,
        defaultAnimation,
        safeAreaEnabled,
        keyboardAvoidance,
        density,
        toastSpacing,
      );
}
