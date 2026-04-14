# Changelog

All notable changes to ToastKit.

---

## v1.0.0

### Bug Fixes

- **Fixed: App unresponsive on 3rd login attempt** — The `login_rules.dart` scenario caused the app to become unresponsive due to multiple compounding issues:
  - Added `_isSigningIn` concurrency guard to prevent rapid-tap race conditions
  - Wrapped `_attemptCount++` in `setState()` so the UI updates immediately
  - Added `channel: 'auth'` to the loading toast for proper channel capacity tracking
  - Changed `login-lockout` rule condition to include `!_isLocked` guard
  - Changed `suggest-reset` rule condition from `== 3` to `>= 3 && < 5` for resilience
  - Added `maxTriggers: 1` to both custom rules to prevent repeated firing

### New Features

- **`maxTriggers` for custom rules** — `ToastRule` now accepts a `maxTriggers` parameter (default: `0` = unlimited). Set to `1` to fire a rule exactly once. This prevents rules with `>=` conditions from firing on every subsequent event.

- **`deduplicateWindow` for custom rules** — `ToastRule` now accepts a `deduplicateWindow` parameter. When set, the rule won't fire again within this duration after the last trigger. Works independently of `maxTriggers`.

### Improvements

- Rule engine now checks `maxTriggers` and `deduplicateWindow` before evaluating custom rule conditions
- Login rules example demonstrates production-ready patterns: concurrency guards, proper setState, channel usage

---

## v0.1.0 (Initial Release)

### Features

- Event-driven toast notification system
- 6 toast types: success, error, warning, info, loading, custom
- 12+ visual variants
- 12 animation types
- 9 screen positions
- Queue management (FIFO, LIFO, priority)
- Deduplication and throttling
- Channel system with per-channel policies
- Rule engine with config-based and custom rules
- Plugin system for lifecycle hooks
- Toast persistence adapter
- Gesture support (swipe, tap, pause-on-hover)
- Stateful loading → result pattern via ToastController
- Zero external dependencies

---

[← Migration Notes](migration.md) | [Back to Index →](index.md)
