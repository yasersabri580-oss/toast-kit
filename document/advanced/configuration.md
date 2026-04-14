# Advanced: Configuration

Complete guide to configuring every aspect of ToastKit.

---

## Global Configuration

Pass `ToastConfig` at initialization:

```dart
ToastKit.init(
  navigatorKey: navigatorKey,
  config: const ToastConfig(
    defaultPosition: ToastPosition.bottom,
    defaultDuration: Duration(seconds: 4),
    maxVisibleToasts: 5,
    enableQueue: true,
    queueMode: QueueMode.priority,
    defaultAnimationDuration: Duration(milliseconds: 400),
    defaultAnimation: ToastAnimationType.scale,
    safeAreaEnabled: true,
    keyboardAvoidance: true,
    density: ToastDensity.compact,
    toastSpacing: 12.0,
    maxQueueSize: 100,
  ),
);
```

### Configuration Reference

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `defaultPosition` | `ToastPosition` | `top` | Where toasts appear on screen |
| `defaultDuration` | `Duration` | `3s` | How long toasts stay visible |
| `maxVisibleToasts` | `int` | `3` | Max simultaneous toasts on screen |
| `enableQueue` | `bool` | `true` | Queue excess events or drop them |
| `queueMode` | `QueueMode` | `fifo` | Queue ordering strategy |
| `defaultAnimationDuration` | `Duration` | `300ms` | Enter/exit animation duration |
| `defaultAnimation` | `ToastAnimationType` | `slideFromTop` | Default animation |
| `safeAreaEnabled` | `bool` | `true` | Respect device safe-area insets |
| `keyboardAvoidance` | `bool` | `true` | Move toasts above keyboard |
| `density` | `ToastDensity` | `comfortable` | Content padding density |
| `toastSpacing` | `double` | `8.0` | Gap between stacked toasts |
| `maxQueueSize` | `int` | `50` | Max queued events (0 = unlimited) |

---

## Router Configuration

Control deduplication, throttling, and replacement:

```dart
ToastKit.init(
  navigatorKey: navigatorKey,
  routerConfig: const RouterConfig(
    enableDeduplication: true,
    deduplicationWindow: Duration(seconds: 3),
    enableThrottling: true,
    throttleInterval: Duration(seconds: 1),
    replacementStrategy: ReplacementStrategy.replaceOldest,
    urgentInterruptsLower: true,
  ),
);
```

### Deduplication

When enabled, events with the same `deduplicationKey` (or same `type:message` combo) within the dedup window are silently coalesced.

```dart
// These two calls within 3 seconds: only the first shows
ToastKit.error('Network failed');
ToastKit.error('Network failed');  // Deduplicated — not shown
```

### Throttling

When enabled, enforces a minimum interval between same-type toasts:

```dart
// With throttleInterval: 1s
ToastKit.success('A');  // Shown
ToastKit.success('B');  // Dropped (same type, within 1s)
// After 1 second:
ToastKit.success('C');  // Shown
```

### Replacement Strategies

When visible slots are full:

| Strategy | Behavior |
|----------|----------|
| `dropNew` | New events go to queue (default) |
| `replaceOldest` | Dismiss the oldest visible toast, show new one |
| `replaceSamePriority` | Replace a toast with same or lower priority |

---

## Channel Configuration

Channels support independent configuration:

```dart
ToastKit.registerChannel(
  const ToastChannel(
    id: 'critical',
    label: 'Critical Alerts',
    maxVisible: 1,
    defaultPriority: ToastPriority.urgent,
    defaultDuration: Duration(seconds: 10),
    defaultAnimation: ToastAnimationType.shake,
  ),
  config: const ChannelConfig(
    maxVisible: 1,
    interruptCurrent: true,
    enableDeduplication: true,
    deduplicationWindow: Duration(seconds: 10),
    enableThrottling: false,
  ),
);
```

### Channel Config Options

| Option | Default | Description |
|--------|---------|-------------|
| `maxVisible` | `null` (global limit) | Max visible toasts for this channel |
| `duration` | `null` (global default) | Auto-dismiss duration |
| `interruptCurrent` | `false` | New toasts replace the current one |
| `enableDeduplication` | `false` | Channel-level deduplication |
| `deduplicationWindow` | `2s` | Dedup window |
| `enableThrottling` | `false` | Channel-level throttling |
| `throttleInterval` | `500ms` | Throttle interval |

---

## Pre-registering at Init

Register channels and plugins at initialization for cleaner code:

```dart
ToastKit.init(
  navigatorKey: navigatorKey,
  channels: [
    ToastChannel.auth,
    ToastChannel.network,
    ToastChannel.payment,
    const ToastChannel(
      id: 'custom',
      label: 'Custom',
      maxVisible: 2,
    ),
  ],
  plugins: [
    MyAnalyticsPlugin(),
    MyLoggerPlugin(),
  ],
);
```

---

## Configuration Comparison

### Minimal Setup

```dart
// Just the navigator key — all defaults
ToastKit.init(navigatorKey: navigatorKey);
```

### Production Setup

```dart
ToastKit.init(
  navigatorKey: navigatorKey,
  config: const ToastConfig(
    maxVisibleToasts: 3,
    maxQueueSize: 50,
    defaultDuration: Duration(seconds: 3),
    density: ToastDensity.comfortable,
  ),
  routerConfig: const RouterConfig(
    enableDeduplication: true,
    deduplicationWindow: Duration(seconds: 2),
    replacementStrategy: ReplacementStrategy.replaceOldest,
  ),
  channels: [
    ToastChannel.auth,
    ToastChannel.network,
    ToastChannel.payment,
  ],
  plugins: [
    AnalyticsPlugin(),
  ],
);
```

---

[← Advanced Index](index.md) | [Next: Customization →](customization.md)
