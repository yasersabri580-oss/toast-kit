# 🍞 ToastKit SDK

[![Dart](https://img.shields.io/badge/Dart-3.0+-blue)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**A production-grade Flutter SDK for in-app notifications.**

ToastKit is not a simple toast widget — it is a **headless + UI hybrid notification engine** built with SDK-level architecture. It operates without requiring `BuildContext`, provides an event-driven pipeline, manages queue/lifecycle/rendering internally, and ships with 12+ ready-made toast variants and a fully extensible animation system.

---

## ✨ Features

| Category | Highlights |
|---|---|
| **Architecture** | Global singleton, event-driven pipeline, overlay-based rendering, no `BuildContext` in public API |
| **Queue & Router** | FIFO / LIFO / priority modes, max-visible limit, deduplication, throttling, replacement strategies |
| **Animations** | 12 built-in types (fade, slide ×4, scale, bounce, elastic, spring, shake, blur, glow) + custom builder |
| **Gestures** | Swipe dismiss (any direction), velocity detection, drag, hover pause (web/desktop), tap/long-press |
| **Theme System** | 21 design tokens, light/dark/adaptive presets, `InheritedWidget` provider |
| **Layout** | 9 positions, safe-area awareness, keyboard avoidance, RTL support, responsive width |
| **Variants** | 12 fully implemented: Minimal, Material, iOS, Glassmorphism, Gradient, Floating Card, Compact, Full Width, Loading, Progress, Action, Debug |

---

## 🚀 Quick Start

### 1. Add dependency

```yaml
dependencies:
  toast_kit:
    git:
      url: https://github.com/yasersabri580-oss/toast-kit.git
```

### 2. Initialize

```dart
import 'package:toast_kit/toast_kit.dart';

final navigatorKey = GlobalKey<NavigatorState>();

// In your MaterialApp
MaterialApp(
  navigatorKey: navigatorKey,
  home: const MyApp(),
);

// Initialize once (after first frame)
WidgetsBinding.instance.addPostFrameCallback((_) {
  ToastKit.init(navigatorKey: navigatorKey);
});
```

### 3. Show toasts — anywhere, no context needed

```dart
ToastKit.success('Operation completed!');
ToastKit.error('Something went wrong');
ToastKit.warning('Battery low');
ToastKit.info('Update available');
ToastKit.loading('Processing…');
```

### 4. Stateful loading → success / error

```dart
final ctrl = ToastKit.showLoading('Saving…');
try {
  await saveData();
  ctrl.success('Saved!');
} catch (_) {
  ctrl.error('Save failed');
}
```

### 5. Toast channels

```dart
// Register channels during init
ToastKit.init(
  navigatorKey: navigatorKey,
  channels: [ToastChannel.auth, ToastChannel.network],
);

// Show a toast on a channel
ToastKit.success('Logged in!', channel: 'auth');
```

### 6. Persistence for critical toasts

```dart
ToastKit.init(
  navigatorKey: navigatorKey,
  persistence: InMemoryToastPersistence(),
);

// Persistent toasts are auto-saved and can be restored:
await ToastKit.restorePersistedToasts();
```

---

## 🎨 Variants

```dart
// Minimal
ToastKit.show(ToastEvent.success(message: 'Done', variant: ToastVariant.minimal));

// Glassmorphism
ToastKit.show(ToastEvent.info(message: 'Glass', variant: ToastVariant.glassmorphism));

// Gradient
ToastKit.show(ToastEvent.error(message: 'Oops', variant: ToastVariant.gradient));

// Compact pill
ToastKit.show(ToastEvent.success(message: 'OK', variant: ToastVariant.compact));

// Full-width banner
ToastKit.show(ToastEvent.warning(message: 'Alert!', variant: ToastVariant.fullWidth));

// Debug (monospace)
ToastKit.show(ToastEvent.info(message: 'debug data', variant: ToastVariant.debug));

// Action buttons
ToastKit.show(ToastEvent.error(
  message: 'Send failed',
  variant: ToastVariant.action,
  actions: [
    ToastAction(label: 'Retry', onPressed: () => retry()),
    ToastAction(label: 'Cancel', onPressed: () {}),
  ],
));

// Progress bar
ToastKit.show(ToastEvent.loading(
  message: 'Uploading…',
  variant: ToastVariant.progress,
));

// Custom builder
ToastKit.custom(builder: (context, controller) {
  return Container(
    padding: const EdgeInsets.all(16),
    color: Colors.purple,
    child: Text('Fully custom!', style: TextStyle(color: Colors.white)),
  );
});
```

---

## ⚙️ Configuration

```dart
ToastKit.init(
  navigatorKey: navigatorKey,
  config: const ToastConfig(
    defaultPosition: ToastPosition.top,
    defaultDuration: Duration(seconds: 3),
    maxVisibleToasts: 3,
    enableQueue: true,
    queueMode: QueueMode.fifo,
    defaultAnimation: ToastAnimationType.slideFromTop,
    safeAreaEnabled: true,
    keyboardAvoidance: true,
    density: ToastDensity.comfortable,
    toastSpacing: 8.0,
  ),
  routerConfig: const RouterConfig(
    enableDeduplication: true,
    deduplicationWindow: Duration(seconds: 2),
    enableThrottling: false,
    replacementStrategy: ReplacementStrategy.dropNew,
  ),
);
```

---

## 🏗 Architecture

```
┌──────────────────────────────────────────────────┐
│  Public API: ToastKit.success() / .showLoading() │
└──────────────┬───────────────────────────────────┘
               │ ToastEvent (+ channel)
               ▼
┌──────────────────────────────┐
│  EventBus (broadcast stream) │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│  ChannelRegistry             │
│  • per-channel policies      │
│  • max visible per channel   │
│  • enable / disable          │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│  NotificationRouter          │
│  • deduplication             │
│  • throttling                │
│  • priority interruption     │
│  • replacement strategy      │
└──────────────┬───────────────┘
               │ RouterDecision
               ▼
┌──────────────────────────────┐
│  QueueManager                │
│  • FIFO / LIFO / priority    │
│  • max visible enforcement   │
│  • auto-promote on dismiss   │
└──────────────┬───────────────┘
               │ onReadyToShow
               ▼
┌──────────────────────────────┐
│  OverlayEngine               │
│  • OverlayEntry management   │
│  • position calculation      │
│  • animation lifecycle       │
│  • auto-dismiss timers       │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│  ToastGestureHandler         │
│  • swipe dismiss             │
│  • tap / hover / drag        │
│  • timer pause/resume        │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│  VariantFactory → Widget     │
│  12+ prebuilt toast variants │
└──────────────────────────────┘

Side systems:
 • ToastController: stateful (idle → loading → success/error)
 • ToastPersistence: save/restore critical toasts
 • GroupCollapser: smart stacking for repeated messages
```

---

## 📂 Project Structure

```
lib/
├── toast_kit.dart              # Barrel export
└── src/
    ├── core/
    │   ├── toast_config.dart   # Global config + all enums (incl. ToastState)
    │   └── toast_kit.dart      # SDK singleton & public API
    ├── events/
    │   ├── toast_event.dart    # ToastEvent + ToastController + ToastAction
    │   └── event_bus.dart      # Broadcast stream event bus
    ├── queue/
    │   └── queue_manager.dart  # FIFO/LIFO/priority queue
    ├── router/
    │   ├── notification_router.dart  # Decision engine
    │   └── router_config.dart  # Router configuration
    ├── overlay/
    │   └── overlay_engine.dart # OverlayEntry lifecycle
    ├── channels/
    │   └── toast_channel.dart  # Channel definitions + registry
    ├── persistence/
    │   └── toast_persistence.dart  # Persistence interface + in-memory impl
    ├── stacking/
    │   └── group_collapser.dart    # Smart stacking / group collapsing
    ├── animation/
    │   ├── animation_factory.dart  # 12 animations + factory
    │   └── animation_curves.dart   # Custom physics curves
    ├── gestures/
    │   └── toast_gesture_handler.dart # Swipe/tap/hover
    ├── theme/
    │   └── toast_theme.dart    # Design tokens + provider
    ├── layout/
    │   └── toast_position_calculator.dart # Position utils
    └── variants/
        ├── variant_factory.dart
        ├── toast_variant_helpers.dart
        ├── minimal_toast.dart
        ├── material_toast.dart
        ├── ios_toast.dart
        ├── glassmorphism_toast.dart
        ├── gradient_toast.dart
        ├── floating_card_toast.dart
        ├── compact_toast.dart
        ├── full_width_toast.dart
        ├── loading_toast.dart
        ├── progress_toast.dart
        ├── action_toast.dart
        └── debug_toast.dart
```

---

## 🧪 Testing

```bash
flutter test
```

Unit tests cover: ToastEvent, EventBus, ToastConfig, ToastController, QueueManager, NotificationRouter, RouterConfig, ToastThemeData, ToastPositionCalculator, animation curves, and ToastVariant enum.

---

## 📜 License

MIT © 2026 ToastKit Contributors
