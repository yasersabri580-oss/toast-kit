import 'package:flutter/foundation.dart';

import '../events/toast_event.dart';
import 'rule_config.dart';
import 'toast_rule.dart';
import 'toast_stats.dart';

/// Evaluates smart rules against channel statistics and toast events.
///
/// The rule engine is optional. When no rules are configured, it has zero
/// overhead — evaluating an event is a no-op.
class RuleEngine {
  /// Stats tracked per channel.
  final Map<String, ToastStats> _channelStats = {};

  /// Custom rules, keyed by rule ID.
  final Map<String, ToastRule> _customRules = {};

  /// Config-based rules, keyed by channel name.
  final Map<String, RuleConfig> _configRules = {};

  /// Tracks how many times each rule has triggered.
  final Map<String, int> _triggerCounts = {};

  /// Tracks the last trigger time for deduplication windows.
  final Map<String, DateTime> _lastTriggerTimes = {};

  /// Callback invoked when a rule triggers (for plugin/analytics integration).
  void Function(String ruleId, String channel)? onRuleTriggered;

  /// Whether any rules are configured.
  bool get hasRules => _customRules.isNotEmpty || _configRules.isNotEmpty;

  // -----------------------------------------------------------------------
  // Config-based rules
  // -----------------------------------------------------------------------

  /// Register a config-based rule for a channel.
  /// Replaces any existing config rule for the same channel.
  void configureRule(String channel, RuleConfig config) {
    _configRules[channel] = config;
  }

  /// Remove a config-based rule for a channel.
  void removeConfigRule(String channel) {
    _configRules.remove(channel);
  }

  // -----------------------------------------------------------------------
  // Custom rules
  // -----------------------------------------------------------------------

  /// Add a custom rule. Replaces any existing rule with the same ID.
  void addRule(ToastRule rule) {
    _customRules[rule.id] = rule;
  }

  /// Remove a custom rule by ID.
  void removeRule(String ruleId) {
    _customRules.remove(ruleId);
  }

  // -----------------------------------------------------------------------
  // Stats
  // -----------------------------------------------------------------------

  /// Get or create stats for a channel.
  ToastStats statsFor(String channel) {
    return _channelStats.putIfAbsent(channel, () => ToastStats());
  }

  /// Record a toast event in the stats for its channel.
  void recordEvent(ToastEvent event) {
    final channel = event.channel ?? 'default';
    statsFor(channel).record(event.type);
  }

  /// Record a dismissal for a channel.
  void recordDismissed(String channel) {
    statsFor(channel).recordDismissed();
  }

  /// Record a drop for a channel.
  void recordDropped(String channel) {
    statsFor(channel).recordDropped();
  }

  // -----------------------------------------------------------------------
  // Evaluation
  // -----------------------------------------------------------------------

  /// Evaluate all rules against the current event.
  /// Returns the list of rule IDs that triggered.
  List<String> evaluate(ToastEvent event) {
    if (!hasRules) return const [];

    final triggered = <String>[];
    final channel = event.channel ?? 'default';
    final stats = statsFor(channel);

    // Evaluate config-based rules.
    final configRule = _configRules[channel];
    if (configRule != null) {
      final configRuleId = '_config_$channel';
      if (_shouldTriggerConfigRule(configRuleId, configRule, stats)) {
        _markTriggered(configRuleId);
        triggered.add(configRuleId);
        _safeCallback(() => onRuleTriggered?.call(configRuleId, channel));
      }
    }

    // Evaluate custom rules.
    for (final rule in _customRules.values) {
      if (rule.channel != channel) continue;
      if (!_shouldTriggerCustomRule(rule, stats, event)) continue;

      _markTriggered(rule.id);
      triggered.add(rule.id);

      // Execute the rule action safely.
      _safeCallback(() {
        rule.action(ToastRuleContext(
          channel: channel,
          stats: stats,
          event: event,
          ruleId: rule.id,
        ));
      });
      _safeCallback(() => onRuleTriggered?.call(rule.id, channel));
    }

    return triggered;
  }

  // -----------------------------------------------------------------------
  // Internal helpers
  // -----------------------------------------------------------------------

  bool _shouldTriggerConfigRule(
      String ruleId, RuleConfig config, ToastStats stats) {
    // Check error threshold.
    if (stats.errorCount < config.errorThreshold) return false;

    // Check deduplication window.
    final lastTrigger = _lastTriggerTimes[ruleId];
    if (lastTrigger != null) {
      final elapsed = DateTime.now().difference(lastTrigger);
      if (elapsed < config.deduplicateWindow) return false;
    }

    // Check max triggers.
    if (config.maxTriggers > 0) {
      final count = _triggerCounts[ruleId] ?? 0;
      if (count >= config.maxTriggers) return false;
    }

    return true;
  }

  bool _shouldTriggerCustomRule(
      ToastRule rule, ToastStats stats, ToastEvent event) {
    // Evaluate the condition safely.
    try {
      return rule.condition(stats, event);
    } catch (e, stack) {
      debugPrint(
          'ToastKit rule condition error [${rule.id}]: $e\n$stack');
      return false;
    }
  }

  void _markTriggered(String ruleId) {
    _triggerCounts[ruleId] = (_triggerCounts[ruleId] ?? 0) + 1;
    _lastTriggerTimes[ruleId] = DateTime.now();
  }

  void _safeCallback(VoidCallback fn) {
    try {
      fn();
    } catch (e, stack) {
      debugPrint('ToastKit rule engine error: $e\n$stack');
    }
  }

  /// Get trigger count for a rule.
  int triggerCount(String ruleId) => _triggerCounts[ruleId] ?? 0;

  /// Reset all stats, trigger counts, and rules.
  void clear() {
    _channelStats.clear();
    _customRules.clear();
    _configRules.clear();
    _triggerCounts.clear();
    _lastTriggerTimes.clear();
  }

  /// Reset only trigger counts and stats (keep rules).
  void resetStats() {
    _channelStats.clear();
    _triggerCounts.clear();
    _lastTriggerTimes.clear();
  }
}
