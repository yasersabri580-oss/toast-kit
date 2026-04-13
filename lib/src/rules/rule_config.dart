import 'package:flutter/foundation.dart';

/// Simple config-based rule definition.
///
/// ```dart
/// ToastKit.configureRule(
///   "payment",
///   RuleConfig(
///     errorThreshold: 10,
///     deduplicateWindow: Duration(seconds: 30),
///     maxTriggers: 1,
///   ),
/// );
/// ```
@immutable
class RuleConfig {

  /// Creates a [RuleConfig].
  const RuleConfig({
    this.errorThreshold = 5,
    this.deduplicateWindow = const Duration(seconds: 30),
    this.maxTriggers = 0,
  });
  /// Number of errors on a channel before the rule triggers.
  final int errorThreshold;

  /// Time window for deduplication of rule triggers.
  final Duration deduplicateWindow;

  /// Maximum number of times this rule can trigger (0 = unlimited).
  final int maxTriggers;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RuleConfig &&
        other.errorThreshold == errorThreshold &&
        other.deduplicateWindow == deduplicateWindow &&
        other.maxTriggers == maxTriggers;
  }

  @override
  int get hashCode =>
      Object.hash(errorThreshold, deduplicateWindow, maxTriggers);
}
