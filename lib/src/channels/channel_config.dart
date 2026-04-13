import 'package:flutter/foundation.dart';

/// Per-channel configuration for queue, display, and behavior policies.
///
/// ```dart
/// const config = ChannelConfig(
///   maxVisible: 3,
///   duration: Duration(seconds: 6),
///   interruptCurrent: true,
/// );
/// ```
@immutable
class ChannelConfig {

  /// Creates a [ChannelConfig] with sensible defaults.
  const ChannelConfig({
    this.maxVisible,
    this.duration,
    this.interruptCurrent = false,
    this.enableDeduplication = false,
    this.deduplicationWindow = const Duration(seconds: 2),
    this.enableThrottling = false,
    this.throttleInterval = const Duration(milliseconds: 500),
  });
  /// Maximum number of toasts visible at once for this channel.
  final int? maxVisible;

  /// Default auto-dismiss duration for toasts on this channel.
  final Duration? duration;

  /// Whether new toasts on this channel should interrupt (replace) the
  /// currently visible toast.
  final bool interruptCurrent;

  /// Whether deduplication is enabled for this channel.
  final bool enableDeduplication;

  /// Time window for deduplication within this channel.
  final Duration deduplicationWindow;

  /// Whether throttling is enabled for this channel.
  final bool enableThrottling;

  /// Minimum interval between toasts on this channel.
  final Duration throttleInterval;

  /// Returns a copy with the given fields replaced.
  ChannelConfig copyWith({
    int? maxVisible,
    Duration? duration,
    bool? interruptCurrent,
    bool? enableDeduplication,
    Duration? deduplicationWindow,
    bool? enableThrottling,
    Duration? throttleInterval,
  }) {
    return ChannelConfig(
      maxVisible: maxVisible ?? this.maxVisible,
      duration: duration ?? this.duration,
      interruptCurrent: interruptCurrent ?? this.interruptCurrent,
      enableDeduplication: enableDeduplication ?? this.enableDeduplication,
      deduplicationWindow: deduplicationWindow ?? this.deduplicationWindow,
      enableThrottling: enableThrottling ?? this.enableThrottling,
      throttleInterval: throttleInterval ?? this.throttleInterval,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChannelConfig &&
        other.maxVisible == maxVisible &&
        other.duration == duration &&
        other.interruptCurrent == interruptCurrent &&
        other.enableDeduplication == enableDeduplication &&
        other.deduplicationWindow == deduplicationWindow &&
        other.enableThrottling == enableThrottling &&
        other.throttleInterval == throttleInterval;
  }

  @override
  int get hashCode => Object.hash(
        maxVisible,
        duration,
        interruptCurrent,
        enableDeduplication,
        deduplicationWindow,
        enableThrottling,
        throttleInterval,
      );
}
