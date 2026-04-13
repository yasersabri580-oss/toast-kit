import '../events/toast_event.dart';
import 'toast_stats.dart';

/// Context passed to rule actions when they trigger.
class ToastRuleContext {
  /// The channel this rule is associated with.
  final String channel;

  /// Current stats for the channel.
  final ToastStats stats;

  /// The toast event that caused the rule to trigger.
  final ToastEvent event;

  /// The rule that was triggered.
  final String ruleId;

  const ToastRuleContext({
    required this.channel,
    required this.stats,
    required this.event,
    required this.ruleId,
  });
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
///   ),
/// );
/// ```
class ToastRule {
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

  /// Creates a [ToastRule].
  const ToastRule({
    required this.id,
    required this.channel,
    required this.condition,
    required this.action,
  });
}
