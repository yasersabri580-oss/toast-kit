# Core Concepts

This page explains the fundamental architecture and concepts in ToastKit.

---

## 1. ToastEvent — The Fundamental Unit

Everything in ToastKit is event-driven. A `ToastEvent` represents a single notification request.

```dart
final event = ToastEvent.error(
  message: 'Upload failed',
  title: 'Error',
  channel: 'network',
  priority: ToastPriority.high,
  deduplicationKey: 'upload-error',
  duration: const Duration(seconds: 5),
);

ToastKit.show(event);
```

### Key Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | `String` | Auto-generated | Unique identifier |
| `type` | `ToastType` | Required | `success`, `error`, `warning`, `info`, `loading`, `custom` |
| `message` | `String?` | `null` | Primary text content |
| `title` | `String?` | `null` | Optional title above message |
| `channel` | `String?` | `null` | Category for channel-based policies |
| `priority` | `ToastPriority` | `normal` | Queue ordering: `low`, `normal`, `high`, `urgent` |
| `deduplicationKey` | `String?` | `null` | Key for dedup (same key = coalesced) |
| `duration` | `Duration?` | Config default (3s) | Auto-dismiss duration |
| `position` | `ToastPosition?` | Config default (top) | Screen position |
| `animation` | `ToastAnimationType?` | Config default | Entry/exit animation |
| `variant` | `ToastVariant?` | Type-based default | Visual style preset |
| `persistent` | `bool` | `false` | If `true`, won't auto-dismiss |
| `dismissible` | `bool` | `true` | If `true`, user can swipe/tap to dismiss |
| `actions` | `List<ToastAction>?` | `null` | Action buttons |
| `customBuilder` | `Widget Function(BuildContext, ToastController)?` | `null` | Full custom UI |

### Convenience Factories

```dart
ToastEvent.success(message: 'Done!')
ToastEvent.error(message: 'Failed')
ToastEvent.warning(message: 'Careful')
ToastEvent.info(message: 'FYI')
ToastEvent.loading(message: 'Working…')  // persistent: true by default
ToastEvent.custom(builder: (ctx, ctrl) => MyWidget())
```

---

## 2. ToastController — Stateful Toast Lifecycle

A `ToastController` lets you update a toast after it's shown. This is the backbone of the loading → result pattern.

```dart
final ctrl = ToastKit.showLoading('Uploading…');

// Update progress
ctrl.update(progressValue: 0.5, message: 'Uploading… 50%');

// Transition to result
ctrl.success('Upload complete!');
// or
ctrl.error('Upload failed');
// or
ctrl.warning('Upload completed with warnings');
```

### Controller API

| Method | Description |
|--------|-------------|
| `dismiss()` | Dismiss the toast immediately |
| `pause()` | Pause auto-dismiss timer |
| `resume()` | Resume auto-dismiss timer |
| `update({message, progressValue, state, icon})` | Update any combination of fields |
| `success(message)` | Transition to success state |
| `error(message)` | Transition to error state |
| `warning(message)` | Transition to warning state |
| `info(message)` | Transition to info state |

### ValueNotifiers

The controller exposes `ValueNotifier`s that toast widgets listen to:

- `messageNotifier` — Current message text
- `stateNotifier` — Current `ToastState` (loading, success, error, etc.)
- `iconNotifier` — Current icon
- `progress` — Progress value (0.0–1.0)

---

## 3. Event Pipeline

When you call `ToastKit.show(event)`, the event flows through this pipeline:

```
ToastKit.show(event)
    │
    ▼
EventBus.emit(event)
    │
    ▼
_onEvent(event)
    ├── Channel policy check     → Is channel enabled? Is it full?
    ├── Loading exclusivity      → Dismiss old loading toast if new one requested
    ├── Router decision          → Dedup? Throttle? Show? Queue? Replace? Drop?
    ├── Record stats             → Update channel error/warning/success counts
    ├── Queue enqueue            → Add to queue or show immediately
    ├── Rule engine evaluate     → Fire matching rules
    └── Persistence              → Save if persistent flag is set
```

### Router Decisions

The `NotificationRouter` evaluates each event and returns one of:

| Decision | Meaning |
|----------|---------|
| `ShowDecision` | Display immediately (or enqueue normally) |
| `QueueDecision` | Place in waiting queue |
| `ReplaceDecision(targetId)` | Replace an existing visible toast |
| `DropDecision(reason)` | Silently drop the event |
| `DeduplicateDecision(existingId)` | Event is a duplicate, skip it |

---

## 4. Channels — Category-Based Policies

Channels group toasts by category and apply independent policies to each group.

### Built-in Channels

```dart
ToastChannel.auth      // maxVisible: 1, priority: high
ToastChannel.network   // priority: normal
ToastChannel.sync      // priority: normal
ToastChannel.payment   // maxVisible: 1, priority: urgent
ToastChannel.debug     // priority: low, variant: debug
```

### Register a Channel

```dart
ToastKit.registerChannel(ToastChannel.auth);
```

### Custom Channel

```dart
const myChannel = ToastChannel(
  id: 'sync',
  label: 'Sync Operations',
  maxVisible: 2,
  defaultPriority: ToastPriority.normal,
  defaultDuration: Duration(seconds: 5),
);

ToastKit.registerChannel(myChannel);
```

### Use a Channel

```dart
// Pass channel name to any toast
ToastKit.error('Sync failed', channel: 'sync');

// Or use the fluent API
ToastKit.channel('sync').error('Sync failed');
```

### Channel Capacity

When `maxVisible` is set, the channel rejects new toasts once it's full:

```dart
const authChannel = ToastChannel(
  id: 'auth',
  label: 'Auth',
  maxVisible: 1,  // Only 1 auth toast at a time
);
```

> **Note**: Channel capacity is checked before the event enters the router. A full channel means the event is silently dropped — it won't be recorded in stats or evaluated by rules.

---

## 5. Queue Management

The `QueueManager` controls how many toasts are visible and what happens to excess events.

### Configuration

```dart
ToastKit.init(
  navigatorKey: navigatorKey,
  config: const ToastConfig(
    maxVisibleToasts: 3,    // Up to 3 on screen at once
    enableQueue: true,       // Queue excess events
    queueMode: QueueMode.fifo,  // First-in, first-out
    maxQueueSize: 50,        // Max 50 waiting events
  ),
);
```

### Queue Modes

| Mode | Behavior |
|------|----------|
| `QueueMode.fifo` | First event queued is first to show |
| `QueueMode.lifo` | Last event queued shows first |
| `QueueMode.priority` | Highest priority shows first |

### Auto-Promotion

When a visible toast is dismissed, the next queued event is automatically promoted and shown.

---

## 6. Rule Engine — Smart Automation

The rule engine watches toast activity and triggers actions when conditions are met.

### Config-Based Rules (Simple)

```dart
ToastKit.configureRule(
  'auth',
  const RuleConfig(
    errorThreshold: 3,              // Fire after 3 errors
    deduplicateWindow: Duration(seconds: 60),  // Don't re-fire within 60s
    maxTriggers: 1,                 // Only fire once
  ),
);
```

### Custom Rules (Advanced)

```dart
ToastKit.addRule(ToastRule(
  id: 'login-lockout',
  channel: 'auth',
  maxTriggers: 1,  // Prevent repeated firing
  condition: (stats, event) => stats.errorCount >= 5,
  action: (context) {
    // Show lockout warning, redirect to help, etc.
    ToastKit.show(ToastEvent.error(
      message: 'Too many failures. Please try again later.',
      persistent: true,
      channel: 'auth',
    ));
  },
));
```

### Rule Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | `String` | Required | Unique rule identifier |
| `channel` | `String` | Required | Channel to watch |
| `condition` | `bool Function(ToastStats, ToastEvent)` | Required | When to trigger |
| `action` | `void Function(ToastRuleContext)` | Required | What to do |
| `maxTriggers` | `int` | `0` (unlimited) | Max times this rule can fire |
| `deduplicateWindow` | `Duration?` | `null` | Min interval between triggers |

### ToastStats

The `condition` function receives `ToastStats` with:

| Field | Type | Description |
|-------|------|-------------|
| `totalCount` | `int` | Total toasts on this channel |
| `errorCount` | `int` | Number of error toasts |
| `warningCount` | `int` | Number of warning toasts |
| `successCount` | `int` | Number of success toasts |
| `infoCount` | `int` | Number of info toasts |
| `dismissedCount` | `int` | Number of dismissed toasts |
| `droppedCount` | `int` | Number of dropped toasts |
| `errorsInWindow(Duration)` | `int` | Errors within a time window |

### Re-entrancy Protection

Rule actions can emit new toasts (e.g., `ToastKit.show(...)` inside an action). The rule engine has a re-entrant guard that prevents infinite recursion:

```dart
// This is SAFE — the nested show() won't re-trigger the same rule
ToastKit.addRule(ToastRule(
  id: 'help',
  channel: 'payment',
  condition: (stats, event) => stats.errorCount >= 10,
  action: (context) {
    ToastKit.show(ToastEvent.info(
      message: 'Need help?',
      channel: 'payment',
    ));
    // The info toast above won't cause 'help' to re-evaluate
  },
));
```

---

## 7. Plugin System

Plugins observe the toast lifecycle without modifying core behavior.

```dart
class MyAnalyticsPlugin extends ToastPlugin {
  @override
  String get name => 'my-analytics';

  @override
  void onToastShown(ToastEvent event) {
    analytics.track('toast_shown', {'type': event.type.name});
  }

  @override
  void onToastDismissed(ToastEvent event, DismissReason reason) {
    analytics.track('toast_dismissed', {'reason': reason.name});
  }
}

// Register the plugin
ToastKit.registerPlugin(MyAnalyticsPlugin());
```

### Plugin Lifecycle Hooks

| Hook | When |
|------|------|
| `onToastQueued(event)` | Event enters the queue |
| `onToastShown(event)` | Toast becomes visible |
| `onToastDismissed(event, reason)` | Toast is dismissed |
| `onToastDropped(event, reason)` | Event is dropped (dedup, channel full, etc.) |
| `onToastReplaced(event, replacedId)` | Toast replaces another |
| `onRuleTriggered(ruleId, channel)` | A rule fires |
| `onChannelRegistered(channelId)` | A channel is registered |

---

## 8. Toast Variants

Visual presets that control how a toast looks.

| Variant | Description |
|---------|-------------|
| `minimal` | Clean, minimal design |
| `material` | Material Design 3 style |
| `ios` | iOS Human Interface style |
| `glassmorphism` | Frosted-glass appearance |
| `gradient` | Gradient background |
| `floatingCard` | Floating elevated card |
| `compact` | Small pill-shaped |
| `fullWidth` | Spans entire width |
| `loading` | Spinner / loading indicator |
| `progress` | Determinate/indeterminate progress bar |
| `action` | Contains action buttons |
| `debug` | Developer/debug info |
| `customBuilder` | Fully user-built UI via builder |

```dart
ToastKit.show(ToastEvent.success(
  message: 'Saved!',
  variant: ToastVariant.glassmorphism,
));
```

---

## 9. Animations

Built-in animation types for toast enter/exit:

| Animation | Description |
|-----------|-------------|
| `fade` | Simple opacity transition |
| `slideFromTop` | Slides in from top |
| `slideFromBottom` | Slides in from bottom |
| `slideFromLeft` | Slides in from left |
| `slideFromRight` | Slides in from right |
| `scale` | Scales up from small |
| `bounce` | Bouncy overshoot |
| `elastic` | Elastic spring |
| `spring` | Physics-based spring |
| `shake` | Horizontal shake |
| `blur` | Blur transition |
| `glow` | Pulsing glow |
| `custom` | User-provided animation builder |

```dart
ToastKit.success(
  'Done!',
  animation: ToastAnimationType.bounce,
);
```

---

## 10. Positions

9 screen positions available:

```
topLeft       top       topRight
centerLeft    center    centerRight
bottomLeft    bottom    bottomRight
```

```dart
ToastKit.info('Bottom right!', position: ToastPosition.bottomRight);
```

---

[← Quick Start](quick_start.md) | [Next: API Reference →](api_reference.md)
