# API Reference

Complete reference for every public class, method, enum, typedef, and configuration object.

---

## ToastKit (Main Class)

The main entry point for the SDK. All methods are static.

### Initialization

#### `ToastKit.init(...)`

Initialize the SDK. Must be called once before any other method.

```dart
static void init({
  required GlobalKey<NavigatorState> navigatorKey,
  ToastConfig? config,
  RouterConfig? routerConfig,
  ToastPersistence? persistence,
  List<ToastChannel>? channels,
  List<ToastPlugin>? plugins,
})
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `navigatorKey` | `GlobalKey<NavigatorState>` | **Required** | Must be the same key on `MaterialApp` |
| `config` | `ToastConfig?` | `ToastConfig()` | Global display/queue configuration |
| `routerConfig` | `RouterConfig?` | `RouterConfig()` | Deduplication, throttling, replacement |
| `persistence` | `ToastPersistence?` | `null` | Adapter for saving/restoring critical toasts |
| `channels` | `List<ToastChannel>?` | `null` | Pre-register channels at init time |
| `plugins` | `List<ToastPlugin>?` | `null` | Pre-register plugins at init time |

#### `ToastKit.isInitialized`

```dart
static bool get isInitialized
```

Returns `true` if `init()` has been called.

#### `ToastKit.dispose()`

```dart
static void dispose()
```

Release all resources. Cancels subscriptions, clears queues, removes overlays.

---

### Simple Toast API

All methods below are **static** and require no `BuildContext`.

#### `ToastKit.success(...)`

```dart
static void success(String message, {
  String? title,
  Duration? duration,
  ToastPosition? position,
  ToastVariant? variant,
  ToastAnimationType? animation,
  String? channel,
})
```

Show a success toast. Green check icon by default.

```dart
ToastKit.success('Profile updated');
ToastKit.success('Saved', channel: 'sync', variant: ToastVariant.compact);
```

#### `ToastKit.error(...)`

```dart
static void error(String message, {
  String? title,
  Duration? duration,
  ToastPosition? position,
  ToastVariant? variant,
  ToastAnimationType? animation,
  String? channel,
})
```

Show an error toast. Red error icon by default.

```dart
ToastKit.error('Connection lost');
```

#### `ToastKit.warning(...)`

```dart
static void warning(String message, {
  String? title,
  Duration? duration,
  ToastPosition? position,
  ToastVariant? variant,
  ToastAnimationType? animation,
  String? channel,
})
```

Show a warning toast. Orange warning icon by default.

```dart
ToastKit.warning('Low disk space');
```

#### `ToastKit.info(...)`

```dart
static void info(String message, {
  String? title,
  Duration? duration,
  ToastPosition? position,
  ToastVariant? variant,
  ToastAnimationType? animation,
  String? channel,
})
```

Show an info toast. Blue info icon by default.

```dart
ToastKit.info('Update available');
```

#### `ToastKit.showLoading(...)`

```dart
static ToastController showLoading(String message, {
  Duration? duration,
  ToastPosition? position,
  String? channel,
})
```

Show a loading toast and return its controller. Loading toasts are persistent (won't auto-dismiss) and non-dismissible by default.

```dart
final ctrl = ToastKit.showLoading('Processing…');
// Later:
ctrl.success('Done!');
// or:
ctrl.error('Failed');
```

> **Loading toast exclusivity**: Only one loading toast can exist at a time. Creating a new one dismisses the previous.

#### `ToastKit.show(...)`

```dart
static void show(ToastEvent event)
```

Show an arbitrary `ToastEvent`. Use this for full control.

```dart
ToastKit.show(ToastEvent.info(
  message: 'Undo available',
  variant: ToastVariant.action,
  actions: [ToastAction(label: 'Undo', onPressed: undoAction)],
  channel: 'sync',
  duration: const Duration(seconds: 8),
));
```

#### `ToastKit.showWithController(...)`

```dart
static ToastController showWithController(ToastEvent event)
```

Show a toast and return its `ToastController`. Use when you need to update the toast later.

#### `ToastKit.showOrReplace(...)`

```dart
static void showOrReplace(ToastEvent event)
```

Show a toast, replacing any existing toast with the same `deduplicationKey` or message. Useful for progress updates.

---

### Channel API

#### `ToastKit.registerChannel(...)`

```dart
static void registerChannel(ToastChannel channel, {ChannelConfig? config})
```

Register a channel. Re-registering the same ID replaces the previous.

```dart
ToastKit.registerChannel(
  ToastChannel.auth,
  config: const ChannelConfig(
    maxVisible: 1,
    enableDeduplication: true,
    deduplicationWindow: Duration(seconds: 5),
  ),
);
```

#### `ToastKit.unregisterChannel(...)`

```dart
static void unregisterChannel(String channelId)
```

#### `ToastKit.channel(...)`

```dart
static ChannelHandle channel(String channelName)
```

Get a fluent handle for emitting toasts on a specific channel.

```dart
ToastKit.channel('payment').error('Payment declined');
ToastKit.channel('network').warning('Slow connection');
```

---

### Rule API

#### `ToastKit.configureRule(...)`

```dart
static void configureRule(String channel, RuleConfig config)
```

Configure a simple threshold-based rule for a channel.

```dart
ToastKit.configureRule('payment', const RuleConfig(
  errorThreshold: 10,
  deduplicateWindow: Duration(seconds: 30),
  maxTriggers: 1,
));
```

#### `ToastKit.addRule(...)`

```dart
static void addRule(ToastRule rule)
```

Add a custom rule. Replaces any existing rule with the same ID.

```dart
ToastKit.addRule(ToastRule(
  id: 'help-suggestion',
  channel: 'payment',
  maxTriggers: 1,
  condition: (stats, event) => stats.errorCount >= 10,
  action: (context) {
    ToastKit.show(ToastEvent.info(
      message: 'Need help with payments?',
      variant: ToastVariant.action,
      actions: [
        ToastAction(label: 'Get Help', onPressed: openHelp),
      ],
    ));
  },
));
```

#### `ToastKit.removeRule(...)`

```dart
static void removeRule(String ruleId)
```

---

### Plugin API

#### `ToastKit.registerPlugin(...)`

```dart
static void registerPlugin(ToastPlugin plugin)
```

#### `ToastKit.unregisterPlugin(...)`

```dart
static void unregisterPlugin(String name)
```

#### `ToastKit.configure(...)`

```dart
static void configure({List<ToastPlugin>? plugins})
```

Batch-register plugins after initialization.

---

### Management

#### `ToastKit.dismiss(...)`

```dart
static void dismiss(String id)
```

Dismiss a specific toast by ID.

#### `ToastKit.dismissAll()`

```dart
static void dismissAll()
```

Dismiss all visible toasts and clear the waiting queue.

#### `ToastKit.clearQueue()`

```dart
static void clearQueue()
```

Clear waiting queue without affecting visible toasts.

#### `ToastKit.controllerFor(...)`

```dart
static ToastController? controllerFor(String id)
```

Look up the controller for an active toast.

#### `ToastKit.eventStream`

```dart
static Stream<ToastEvent> get eventStream
```

Broadcast stream of all events passing through the system.

---

## ToastEvent

An immutable notification event. This is the fundamental unit of communication.

### Factories

| Factory | Type | Persistent | Dismissible |
|---------|------|------------|-------------|
| `ToastEvent.success(...)` | `success` | `false` | `true` |
| `ToastEvent.error(...)` | `error` | `false` | `true` |
| `ToastEvent.warning(...)` | `warning` | `false` | `true` |
| `ToastEvent.info(...)` | `info` | `false` | `true` |
| `ToastEvent.loading(...)` | `loading` | **`true`** | **`false`** |
| `ToastEvent.custom(...)` | `custom` | `false` | `true` |

### All Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | Auto-generated unique ID |
| `type` | `ToastType` | Semantic type |
| `message` | `String?` | Primary text |
| `title` | `String?` | Title above message |
| `icon` | `IconData?` | Leading icon |
| `iconColor` | `Color?` | Icon color override |
| `duration` | `Duration?` | Auto-dismiss duration (null = use config default) |
| `position` | `ToastPosition?` | Screen position (null = use config default) |
| `animation` | `ToastAnimationType?` | Animation type (null = use config default) |
| `priority` | `ToastPriority` | Queue priority: `low`, `normal`, `high`, `urgent` |
| `deduplicationKey` | `String?` | Key for deduplication |
| `metadata` | `Map<String, dynamic>?` | Arbitrary data bag |
| `onTap` | `VoidCallback?` | Tap callback |
| `onDismiss` | `VoidCallback?` | Post-dismiss callback |
| `actions` | `List<ToastAction>?` | Action buttons |
| `customBuilder` | `Widget Function(BuildContext, ToastController)?` | Custom UI builder |
| `variant` | `ToastVariant?` | Visual preset |
| `persistent` | `bool` | Won't auto-dismiss if `true` |
| `dismissible` | `bool` | User can dismiss if `true` |
| `channel` | `String?` | Channel category |
| `createdAt` | `DateTime` | When the event was created |

---

## ToastController

Stateful controller for an individual toast's lifecycle.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | Toast identifier |
| `state` | `ToastState` | Current lifecycle state |
| `isDisposed` | `bool` | Whether controller is disposed |
| `progress` | `ValueNotifier<double>` | Progress (0.0–1.0) |
| `messageNotifier` | `ValueNotifier<String>` | Current message |
| `stateNotifier` | `ValueNotifier<ToastState>` | Current state |
| `iconNotifier` | `ValueNotifier<IconData?>` | Current icon |

### Methods

| Method | Description |
|--------|-------------|
| `dismiss()` | Dismiss the toast |
| `pause()` | Pause auto-dismiss timer |
| `resume()` | Resume auto-dismiss timer |
| `update({message, progressValue, state, icon})` | Update any fields |
| `success(message, {icon})` | Transition to success |
| `error(message, {icon})` | Transition to error |
| `warning(message, {icon})` | Transition to warning |
| `info(message, {icon})` | Transition to info |
| `dispose()` | Release resources |

---

## ToastAction

An action button attached to a toast.

```dart
const ToastAction({
  required String label,
  required VoidCallback onPressed,
  Color? color,
})
```

---

## ToastConfig

Global configuration for the SDK.

```dart
const ToastConfig({
  ToastPosition defaultPosition = ToastPosition.top,
  Duration defaultDuration = const Duration(seconds: 3),
  int maxVisibleToasts = 3,
  bool enableQueue = true,
  QueueMode queueMode = QueueMode.fifo,
  Duration defaultAnimationDuration = const Duration(milliseconds: 300),
  ToastAnimationType defaultAnimation = ToastAnimationType.slideFromTop,
  bool safeAreaEnabled = true,
  bool keyboardAvoidance = true,
  ToastDensity density = ToastDensity.comfortable,
  double toastSpacing = 8.0,
  int maxQueueSize = 50,
})
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `defaultPosition` | `top` | Default screen position |
| `defaultDuration` | `3s` | Default auto-dismiss duration |
| `maxVisibleToasts` | `3` | Max toasts on screen |
| `enableQueue` | `true` | Whether to queue excess events |
| `queueMode` | `fifo` | Queue ordering |
| `defaultAnimationDuration` | `300ms` | Animation duration |
| `defaultAnimation` | `slideFromTop` | Default animation type |
| `safeAreaEnabled` | `true` | Respect safe-area insets |
| `keyboardAvoidance` | `true` | Move above keyboard |
| `density` | `comfortable` | Content density |
| `toastSpacing` | `8.0` | Spacing between stacked toasts |
| `maxQueueSize` | `50` | Max queued events (0 = unlimited) |

---

## RouterConfig

Configuration for the notification router.

```dart
const RouterConfig({
  bool enableDeduplication = true,
  Duration deduplicationWindow = const Duration(seconds: 2),
  bool enableThrottling = false,
  Duration throttleInterval = const Duration(milliseconds: 500),
  ReplacementStrategy replacementStrategy = ReplacementStrategy.dropNew,
  bool urgentInterruptsLower = true,
})
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `enableDeduplication` | `true` | Coalesce same-key events |
| `deduplicationWindow` | `2s` | Window for deduplication |
| `enableThrottling` | `false` | Minimum interval between same-type toasts |
| `throttleInterval` | `500ms` | Throttle interval |
| `replacementStrategy` | `dropNew` | What to do when full |
| `urgentInterruptsLower` | `true` | Urgent events can replace lower priority |

---

## ToastChannel

A named notification channel with per-channel policies.

```dart
const ToastChannel({
  required String id,
  required String label,
  int? maxVisible,
  ToastPriority? defaultPriority,
  ToastPosition? defaultPosition,
  Duration? defaultDuration,
  ToastAnimationType? defaultAnimation,
  ToastVariant? defaultVariant,
  bool enabled = true,
})
```

### Built-in Channels

| Channel | ID | maxVisible | Priority |
|---------|----|------------|----------|
| `ToastChannel.auth` | `'auth'` | 1 | high |
| `ToastChannel.network` | `'network'` | — | normal |
| `ToastChannel.sync` | `'sync'` | — | normal |
| `ToastChannel.payment` | `'payment'` | 1 | urgent |
| `ToastChannel.debug` | `'debug'` | — | low |

---

## ChannelConfig

Per-channel queue and display configuration.

```dart
const ChannelConfig({
  int? maxVisible,
  Duration? duration,
  bool interruptCurrent = false,
  bool enableDeduplication = false,
  Duration deduplicationWindow = const Duration(seconds: 2),
  bool enableThrottling = false,
  Duration throttleInterval = const Duration(milliseconds: 500),
})
```

---

## RuleConfig

Simple threshold-based rule configuration.

```dart
const RuleConfig({
  int errorThreshold = 5,
  Duration deduplicateWindow = const Duration(seconds: 30),
  int maxTriggers = 0,  // 0 = unlimited
})
```

---

## ToastRule

A custom smart rule with condition/action pattern.

```dart
const ToastRule({
  required String id,
  required String channel,
  required bool Function(ToastStats, ToastEvent) condition,
  required void Function(ToastRuleContext) action,
  int maxTriggers = 0,        // 0 = unlimited
  Duration? deduplicateWindow, // Min interval between triggers
})
```

---

## ToastStats

Per-channel statistics available in rule conditions.

| Field | Type | Description |
|-------|------|-------------|
| `totalCount` | `int` | Total toasts |
| `errorCount` | `int` | Errors |
| `warningCount` | `int` | Warnings |
| `successCount` | `int` | Successes |
| `infoCount` | `int` | Infos |
| `dismissedCount` | `int` | Dismissed |
| `droppedCount` | `int` | Dropped |

### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `errorsInWindow(Duration)` | `int` | Errors within time window |
| `reset()` | `void` | Reset all stats |

---

## Enums

### ToastType

`success`, `error`, `warning`, `info`, `loading`, `custom`

### ToastState

`idle`, `loading`, `success`, `error`, `warning`, `info`, `custom`

### ToastPosition

`top`, `topLeft`, `topRight`, `center`, `centerLeft`, `centerRight`, `bottom`, `bottomLeft`, `bottomRight`

### ToastPriority

`low`, `normal`, `high`, `urgent`

### ToastVariant

`minimal`, `material`, `ios`, `glassmorphism`, `neumorphism`, `gradient`, `blurredBackground`, `floatingCard`, `topBanner`, `bottomSheet`, `inline`, `compact`, `fullWidth`, `iconBased`, `textOnly`, `richContent`, `loading`, `progress`, `action`, `retry`, `undo`, `persistent`, `expandable`, `chatBubble`, `debug`, `customBuilder`

### ToastAnimationType

`fade`, `slideFromTop`, `slideFromBottom`, `slideFromLeft`, `slideFromRight`, `scale`, `bounce`, `elastic`, `spring`, `shake`, `blur`, `glow`, `custom`

### QueueMode

`fifo`, `lifo`, `priority`

### ToastDensity

`compact`, `comfortable`, `spacious`

### SwipeDismissDirection

`left`, `right`, `up`, `down`, `horizontal`, `vertical`, `any`

### ReplacementStrategy

`dropNew`, `replaceOldest`, `replaceSamePriority`

---

## ToastPlugin (Abstract)

Base class for plugins. Override the hooks you need:

```dart
abstract class ToastPlugin {
  String get name;

  void onToastQueued(ToastEvent event) {}
  void onToastShown(ToastEvent event) {}
  void onToastDismissed(ToastEvent event, DismissReason reason) {}
  void onToastDropped(ToastEvent event, String reason) {}
  void onToastReplaced(ToastEvent event, String replacedId) {}
  void onRuleTriggered(String ruleId, String channel) {}
  void onChannelRegistered(String channelId) {}
  void dispose() {}
}
```

---

## ToastPersistence (Abstract)

Interface for persisting critical toasts across app restarts.

```dart
abstract class ToastPersistence {
  Future<void> save(ToastEvent event);
  Future<void> remove(String id);
  Future<List<ToastEvent>> loadPending();
}
```

---

[← Core Concepts](core_concepts.md) | [Next: Examples →](examples/)
