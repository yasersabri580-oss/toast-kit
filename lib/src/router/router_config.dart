import 'package:flutter/material.dart';

import '../core/toast_config.dart';

/// Configuration for the [NotificationRouter] decision engine.
@immutable
class RouterConfig {
  /// Whether to coalesce events with the same deduplication key.
  final bool enableDeduplication;

  /// Time window within which duplicate keys are coalesced.
  final Duration deduplicationWindow;

  /// Whether to enforce a minimum interval between same-type toasts.
  final bool enableThrottling;

  /// Minimum interval between same-type emissions.
  final Duration throttleInterval;

  /// What to do when visible slots are full.
  final ReplacementStrategy replacementStrategy;

  /// Whether urgent events can interrupt lower-priority visible toasts.
  final bool urgentInterruptsLower;

  const RouterConfig({
    this.enableDeduplication = true,
    this.deduplicationWindow = const Duration(seconds: 2),
    this.enableThrottling = false,
    this.throttleInterval = const Duration(milliseconds: 500),
    this.replacementStrategy = ReplacementStrategy.dropNew,
    this.urgentInterruptsLower = true,
  });

  RouterConfig copyWith({
    bool? enableDeduplication,
    Duration? deduplicationWindow,
    bool? enableThrottling,
    Duration? throttleInterval,
    ReplacementStrategy? replacementStrategy,
    bool? urgentInterruptsLower,
  }) {
    return RouterConfig(
      enableDeduplication: enableDeduplication ?? this.enableDeduplication,
      deduplicationWindow: deduplicationWindow ?? this.deduplicationWindow,
      enableThrottling: enableThrottling ?? this.enableThrottling,
      throttleInterval: throttleInterval ?? this.throttleInterval,
      replacementStrategy: replacementStrategy ?? this.replacementStrategy,
      urgentInterruptsLower:
          urgentInterruptsLower ?? this.urgentInterruptsLower,
    );
  }
}
