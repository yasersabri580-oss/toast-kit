# Overview

## What is ToastKit?

ToastKit is a production-grade Flutter SDK for in-app notifications (toasts). It provides a complete notification pipeline — from event creation to overlay rendering — with zero `BuildContext` requirement for showing toasts.

```dart
// Show a toast from anywhere — no context needed
ToastKit.success('File saved!');
ToastKit.error('Network failed');
ToastKit.warning('Low battery');
ToastKit.info('New update available');
```

## Why ToastKit?

Most Flutter toast packages are simple overlay wrappers. They work for basic use cases but fall short when you need:

- **Stateful toasts**: Loading → success/error transitions
- **Queue management**: Control how many toasts show at once
- **Channel-based policies**: Different rules for auth vs. network vs. payment toasts
- **Smart rules**: Automatically trigger actions after N errors
- **Deduplication**: Prevent the same message from spamming the user
- **Plugin system**: Analytics, haptics, logging without modifying core code
- **12+ visual variants**: From minimal to glassmorphism to Material 3

ToastKit was built to handle real production scenarios where notification management matters.

## What Problem Does It Solve?

| Problem | ToastKit Solution |
|---------|-------------------|
| Toasts need `BuildContext` everywhere | Global API via `ToastKit.success()` — no context needed |
| Loading → result flow is manual | `ToastController` with `.success()` / `.error()` transitions |
| Same error spams the user | Built-in deduplication with configurable windows |
| No way to limit toast frequency | Throttling, queue limits, channel capacity |
| Different toast categories need different behavior | Channel system with per-channel policies |
| Need analytics on toast interactions | Plugin architecture for zero-coupling telemetry |
| "Show help after 5 errors" logic is scattered | Rule engine with condition → action patterns |
| Toast UI is hard to customize | 12+ built-in variants + custom builder support |

## Key Features

### Core
- **Event-driven architecture** — Everything flows through `ToastEvent` objects
- **No BuildContext required** — Show toasts from services, blocs, repositories
- **Stateful toast lifecycle** — Loading → success/error/warning transitions via `ToastController`
- **Queue management** — FIFO, LIFO, or priority-based ordering

### Routing & Policy
- **Deduplication** — Same message/key coalesced within a configurable window
- **Throttling** — Minimum interval between same-type toasts
- **Channel system** — Named categories with independent policies
- **Replacement strategies** — Drop new, replace oldest, or replace same-priority

### Smart Rules
- **Config-based rules** — Threshold + dedup window + max triggers
- **Custom rules** — Full condition/action pattern with `ToastRule`
- **Per-channel stats** — Track error/warning/success counts per channel
- **Automatic evaluation** — Rules evaluate on every event, no manual calls

### Visual
- **12+ toast variants** — Minimal, Material, iOS, glassmorphism, gradient, compact, and more
- **Animation presets** — Fade, slide, scale, bounce, elastic, spring, shake, blur, glow
- **Gesture support** — Swipe to dismiss, tap callbacks, pause-on-hover
- **Position control** — 9 positions (top, center, bottom × left, center, right)

### Extensibility
- **Plugin system** — Hook into lifecycle events (shown, dismissed, queued, dropped)
- **Custom builders** — Full widget control with `ToastEvent.custom(builder: ...)`
- **Persistence adapter** — Save/restore critical toasts across app restarts
- **Accessibility** — Semantic labels and screen reader support

## Design Philosophy

1. **Event-driven, not imperative** — You emit events; the pipeline decides what to show
2. **Zero overhead when unused** — No rules configured? No rule evaluation. No plugins? No plugin overhead
3. **Layered architecture** — Use the simple API for basic toasts, go deeper only when needed
4. **Production-first** — Bounded queues, re-entrant guards, idempotent dismissals, memory-safe stats
5. **No external dependencies** — Only depends on Flutter SDK itself

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        ToastKit API                         │
│  success() / error() / warning() / info() / showLoading()  │
└──────────────────────────┬──────────────────────────────────┘
                           │ ToastEvent
                           ▼
┌──────────────────────────────────────────────────────────────┐
│                        EventBus                              │
│              Broadcast stream of all events                   │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│                    _onEvent Pipeline                          │
│                                                              │
│  1. Channel policy check (enabled? full?)                    │
│  2. Loading toast exclusivity                                │
│  3. Router decision (dedup → throttle → capacity)            │
│  4. Record stats + enqueue                                   │
│  5. Rule engine evaluation                                   │
│  6. Persistence (if persistent)                              │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│                     QueueManager                             │
│         FIFO / LIFO / Priority ordering                      │
│         Bounded size, promotion on dismiss                   │
└──────────────────────────┬───────────────────────────────────┘
                           │ onReadyToShow
                           ▼
┌──────────────────────────────────────────────────────────────┐
│                    OverlayEngine                             │
│           Renders toast widgets in Flutter overlay            │
│           Manages enter/exit animations + timers             │
└──────────────────────────────────────────────────────────────┘
```

---

[← Back to Index](index.md) | [Next: Installation →](installation.md)
