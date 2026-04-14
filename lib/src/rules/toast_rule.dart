import '../events/toast_event.dart';
import 'toast_stats.dart';

/// Context passed to rule actions when they trigger.
class ToastRuleContext {

  const ToastRuleContext({
    required this.channel,
    required this.stats,
    required this.event,
    required this.ruleId,
  });
  /// The channel this rule is associated with.
  final String channel;

  /// Current stats for the channel.
  final ToastStats stats;

  /// The toast event that caused the rule to trigger.
  final ToastEvent event;

  /// The rule that was triggered.
  final String ruleId;
}

/// A custom smart rule that triggers based on toast activity.
///
/// ```dart
/// ToastKit.addRule(
///   ToastRule(
///     id: "payment-help-after-10-errors",
///     channel: "payment",
///     condition: (stats, event) => stats.errorCount >= 10,
///     action: (context) {
///       // developer decides what to do
///     },
///     maxTriggers: 1,
///   ),
/// );
/// ```
class ToastRule {

  /// Creates a [ToastRule].
  const ToastRule({
    required this.id,
    required this.channel,
    required this.condition,
    required this.action,
    this.maxTriggers = 0,
    this.deduplicateWindow,
  });
  /// Unique identifier for this rule.
  final String id;

  /// Channel this rule applies to.
  final String channel;

  /// Condition that determines whether the rule should trigger.
  /// Returns `true` to trigger the action.
  final bool Function(ToastStats stats, ToastEvent event) condition;

  /// Action to execute when the rule triggers. The app decides how
  /// to present UI — ToastKit does not show dialogs or navigate.
  final void Function(ToastRuleContext context) action;

  /// Maximum number of times this rule can trigger (0 = unlimited).
  final int maxTriggers;

  /// Optional deduplication window. If set, the rule will not fire again
  /// within this duration after the last trigger.
  final Duration? deduplicateWindow;
}
