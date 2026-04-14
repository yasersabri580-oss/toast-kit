# Advanced: Rule Engine Deep Dive

The rule engine is one of ToastKit's most powerful features. This guide covers complex scenarios, edge cases, and best practices.

---

## How Rules Work

Rules evaluate **after** every toast event that passes through the pipeline. The evaluation flow:

```
Event enters _onEvent()
    │
    ├── Channel check         → Rejected events don't trigger rules
    ├── Router decision       → Deduplicated events don't trigger rules
    ├── Record stats          → Stats updated BEFORE rule evaluation
    ├── Queue enqueue         → Toast is shown/queued
    │
    └── Rule evaluation       → All matching rules fire
```

> **Key insight**: Only events that pass the channel check AND the router get recorded in stats. Dropped/deduplicated events do NOT affect rule conditions.

---

## Config-Based Rules

Simple threshold rules without writing code:

```dart
ToastKit.configureRule(
  'channelName',
  const RuleConfig(
    errorThreshold: 5,              // Fire when errorCount >= 5
    deduplicateWindow: Duration(seconds: 30),  // Don't re-fire within 30s
    maxTriggers: 0,                 // 0 = unlimited (will re-fire after dedup window)
  ),
);
```

Config rules fire the `onRuleTriggered` callback (used by plugins for analytics) but don't execute custom actions. Use custom rules for actions.

---

## Custom Rules

Full condition → action control:

```dart
ToastKit.addRule(ToastRule(
  id: 'unique-rule-id',
  channel: 'auth',
  maxTriggers: 1,                    // Fire at most once
  deduplicateWindow: Duration(seconds: 60),  // Or use a dedup window
  condition: (stats, event) {
    // Return true to fire the action
    return stats.errorCount >= 3;
  },
  action: (context) {
    // context.channel — the channel name
    // context.stats — current stats
    // context.event — the triggering event
    // context.ruleId — this rule's ID
    print('Rule ${context.ruleId} fired on ${context.channel}');
  },
));
```

### Rule Properties

| Property | Default | Description |
|----------|---------|-------------|
| `maxTriggers` | `0` (unlimited) | Max times this rule can fire. Use `1` for "fire once" rules. |
| `deduplicateWindow` | `null` | Min time between triggers. Independent of `maxTriggers`. |

### Trigger Control Comparison

| Goal | Use |
|------|-----|
| Fire exactly once | `maxTriggers: 1` |
| Fire at most once per minute | `deduplicateWindow: Duration(minutes: 1)` |
| Fire once per minute, max 3 times total | Both: `maxTriggers: 3, deduplicateWindow: Duration(minutes: 1)` |
| Fire every time condition is true | `maxTriggers: 0` (default, no dedup window) |

---

## Common Patterns

### Pattern: Escalating Severity

```dart
// Warning after 3 errors
ToastKit.addRule(ToastRule(
  id: 'warn-3',
  channel: 'payment',
  maxTriggers: 1,
  condition: (stats, event) => stats.errorCount >= 3 && stats.errorCount < 5,
  action: (ctx) => ToastKit.warning('Multiple payment failures detected'),
));

// Critical after 5 errors
ToastKit.addRule(ToastRule(
  id: 'critical-5',
  channel: 'payment',
  maxTriggers: 1,
  condition: (stats, event) => stats.errorCount >= 5,
  action: (ctx) => ToastKit.show(ToastEvent.error(
    message: 'Please contact support',
    persistent: true,
    channel: 'payment',
  )),
));
```

### Pattern: Windowed Rate Detection

```dart
// Detect error bursts: 5+ errors in 30 seconds
ToastKit.addRule(ToastRule(
  id: 'error-burst',
  channel: 'network',
  deduplicateWindow: Duration(seconds: 60),
  condition: (stats, event) {
    return stats.errorsInWindow(const Duration(seconds: 30)) >= 5;
  },
  action: (ctx) {
    ToastKit.show(ToastEvent.warning(
      message: 'Unstable connection detected',
      channel: 'network',
    ));
  },
));
```

### Pattern: Combined Condition

```dart
// Fire when errors AND warnings are both high
ToastKit.addRule(ToastRule(
  id: 'combined-issues',
  channel: 'sync',
  maxTriggers: 1,
  condition: (stats, event) =>
      stats.errorCount >= 3 && stats.warningCount >= 5,
  action: (ctx) {
    ToastKit.info('Multiple sync issues detected. Check your connection.');
  },
));
```

---

## Edge Cases and Gotchas

### 1. Re-entrant Rule Actions

Rule actions can call `ToastKit.show()`, which re-enters the event pipeline. The rule engine has a re-entrant guard:

```dart
// SAFE: The nested show() won't cause infinite recursion
ToastKit.addRule(ToastRule(
  id: 'help',
  channel: 'auth',
  condition: (stats, event) => stats.errorCount >= 5,
  action: (ctx) {
    // This toast triggers _onEvent → evaluate() → but _isEvaluating is true → skipped
    ToastKit.show(ToastEvent.info(message: 'Need help?', channel: 'auth'));
  },
));
```

> **Consequence**: The toast emitted inside a rule action will be shown, but it won't be evaluated by rules (because evaluation is already in progress).

### 2. Channel Full During Rule Action

If a rule action emits a toast to a channel that's already full, the toast is silently dropped:

```dart
// auth channel has maxVisible: 1
// When the error that triggered the rule is already showing, the action's toast may be dropped
ToastKit.addRule(ToastRule(
  id: 'suggest',
  channel: 'auth',
  condition: (stats, event) => stats.errorCount >= 3,
  action: (ctx) {
    // This toast might be dropped if auth channel is already full
    ToastKit.show(ToastEvent.info(message: 'Help?', channel: 'auth'));
  },
));
```

**Mitigation**: Use `deduplicationKey` on the action's toast so it can be shown later, or emit the toast without a channel to bypass channel limits.

### 3. Condition Uses `==` Instead of `>=`

```dart
// FRAGILE: Fires ONLY when errorCount is exactly 3
condition: (stats, event) => stats.errorCount == 3,

// BETTER: Fires on 3+, use maxTriggers to prevent repeated firing
condition: (stats, event) => stats.errorCount >= 3,
```

If an error event is dropped (dedup, channel full), the stats won't increment, and the `== 3` condition might never be true if count jumps from 2 to 4.

### 4. Condition Uses `>=` Without maxTriggers

```dart
// DANGEROUS: Fires on EVERY event after errorCount reaches 5
condition: (stats, event) => stats.errorCount >= 5,
// Add maxTriggers: 1 to fire only once
```

### 5. Stats Reflect Only Shown Events

Events dropped by channel capacity or deduplication are NOT recorded in stats. This means:

- Rapid-fire errors with dedup enabled: errorCount increments slower than the call rate
- Channel-full drops: errorCount doesn't increment for dropped events

---

## Rule Evaluation Order

1. Config-based rules evaluate first (one per channel)
2. Custom rules evaluate in insertion order (order of `addRule()` calls)
3. All matching rules fire in the same evaluation pass
4. Rule actions execute synchronously within a `_safeCallback` wrapper

---

## Cleaning Up

```dart
// Remove a specific rule
ToastKit.removeRule('login-lockout');

// Reset all stats but keep rules
ToastKit.ruleEngine.resetStats();

// Remove everything (rules + stats + trigger counts)
ToastKit.ruleEngine.clear();
```

---

[← Customization](customization.md) | [Next: Performance →](performance.md)
