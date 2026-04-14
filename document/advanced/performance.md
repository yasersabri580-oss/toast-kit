# Advanced: Performance

ToastKit is designed for production use. This page covers built-in safeguards and optimization tips.

---

## Built-in Safety Limits

| Component | Limit | Default | Purpose |
|-----------|-------|---------|---------|
| Queue size | `maxQueueSize` | 50 | Prevents unbounded memory from rapid-fire events |
| Recent errors | `_maxRecentErrors` | 500 | Bounds the time-windowed error list in `ToastStats` |
| Dedup log | `_maxDeduplicationEntries` | 200 | Prunes expired dedup entries |
| Visible toasts | `maxVisibleToasts` | 3 | Limits overlay rendering |
| Channel capacity | `ToastChannel.maxVisible` | Per-channel | Independent per-channel limits |

---

## Zero Overhead When Unused

ToastKit features are designed to have zero cost when not configured:

```dart
// No rules configured? evaluate() is a no-op
if (!hasRules) return const [];

// No plugins? notify calls return immediately
// No channels? Channel checks skip
```

---

## Rapid-Fire Protection

### Deduplication

Prevents identical toasts from spamming:

```dart
ToastKit.init(
  navigatorKey: navigatorKey,
  routerConfig: const RouterConfig(
    enableDeduplication: true,
    deduplicationWindow: Duration(seconds: 2),
  ),
);

// Rapid-fire same message — only first shows
for (var i = 0; i < 100; i++) {
  ToastKit.error('Network failed');  // Only first shows, rest deduplicated
}
```

### Throttling

Enforces minimum interval between same-type toasts:

```dart
ToastKit.init(
  navigatorKey: navigatorKey,
  routerConfig: const RouterConfig(
    enableThrottling: true,
    throttleInterval: Duration(seconds: 1),
  ),
);
```

### Queue Bounds

When the queue exceeds `maxQueueSize`, oldest events are dropped:

```dart
const ToastConfig(maxQueueSize: 50)  // Default

// If 50 events are queued and a 51st arrives, the oldest is dropped
```

---

## Memory Management

### Bounded Stats

`ToastStats._recentErrors` is bounded to 500 entries. Oldest entries are pruned when the limit is exceeded.

### Bounded Dedup Log

The router's deduplication log is bounded to 200 entries. Expired entries are pruned periodically.

### Controller Disposal

Toast controllers are disposed when their toast is dismissed. Calling methods on a disposed controller is a safe no-op.

---

## Concurrency Safety

### Re-entrant Guards

- **Rule engine**: `_isEvaluating` flag prevents recursive evaluation
- **Queue promotion**: `_isProcessing` flag prevents re-entrant promotion
- **Dismiss all**: `_isDismissingAll` flag suppresses queue promotion during bulk dismiss

### Loading Toast Exclusivity

Only one loading toast exists at a time. Creating a new one dismisses the previous, preventing loading toast accumulation.

### Duplicate ID Guard

The queue manager rejects events with IDs that are already visible or queued, preventing double-tracking.

---

## Optimization Tips

### 1. Use Channels for High-Frequency Categories

```dart
// Auth errors happen infrequently — simple channel
ToastKit.registerChannel(ToastChannel.auth);

// Network errors can be rapid — add dedup and throttling
ToastKit.registerChannel(
  const ToastChannel(id: 'network', label: 'Network'),
  config: const ChannelConfig(
    enableDeduplication: true,
    deduplicationWindow: Duration(seconds: 5),
    enableThrottling: true,
    throttleInterval: Duration(seconds: 2),
  ),
);
```

### 2. Set maxTriggers on Rules

```dart
// Without maxTriggers, this fires on EVERY event after errorCount >= 5
// With maxTriggers: 1, it fires exactly once
ToastKit.addRule(ToastRule(
  id: 'lockout',
  channel: 'auth',
  maxTriggers: 1,  // Critical for >= conditions
  condition: (stats, event) => stats.errorCount >= 5,
  action: (ctx) { /* ... */ },
));
```

### 3. Prefer Deduplication Keys

```dart
// Without key: dedup uses type:message combo
ToastKit.error('Network failed');

// With key: more reliable dedup across message variants
ToastKit.show(ToastEvent.error(
  message: 'Network failed: $errorDetails',
  deduplicationKey: 'network-error',
));
```

### 4. Clean Up on Dispose

```dart
@override
void dispose() {
  // Remove rules that reference widget state
  ToastKit.removeRule('my-rule');

  // Or reset everything
  ToastKit.ruleEngine.resetStats();

  super.dispose();
}
```

---

[← Rule Engine](rule_engine.md) | [Next: Troubleshooting →](../troubleshooting.md)
