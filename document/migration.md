# Migration Notes

This document covers breaking changes and how to migrate between versions.

---

## Migrating to v1.0.0

### ToastRule: New `maxTriggers` and `deduplicateWindow` Fields

**What changed**: `ToastRule` now supports `maxTriggers` and `deduplicateWindow` parameters to control how often a rule fires.

**Before (v0.x)**:
```dart
ToastKit.addRule(ToastRule(
  id: 'lockout',
  channel: 'auth',
  condition: (stats, event) => stats.errorCount >= 5,
  action: (ctx) { /* fires on EVERY event after 5 errors */ },
));
```

**After (v1.0.0)**:
```dart
ToastKit.addRule(ToastRule(
  id: 'lockout',
  channel: 'auth',
  maxTriggers: 1,  // Fire once only
  condition: (stats, event) => stats.errorCount >= 5,
  action: (ctx) { /* fires exactly once */ },
));
```

**Action required**: No breaking change — the new fields have defaults (`maxTriggers: 0` = unlimited, `deduplicateWindow: null`). However, you should audit existing rules with `>=` conditions and add `maxTriggers: 1` where appropriate.

---

### Rule Conditions: `==` vs `>=`

**What changed**: Recommended best practice changed. Using `==` for threshold checks is fragile because stats may skip values.

**Before**:
```dart
condition: (stats, event) => stats.errorCount == 3,
```

**After**:
```dart
condition: (stats, event) => stats.errorCount >= 3,
// Combined with maxTriggers: 1 to prevent repeated firing
```

**Why**: If an error event is dropped (channel full, deduplication), `errorCount` may jump from 2 to 4, and the `== 3` condition is never true.

---

### Login Scenario: Concurrency Guard

**What changed**: The `login_rules.dart` example now includes `_isSigningIn` guard and proper `setState` usage.

**Before**:
```dart
_attemptCount++;  // Not in setState
final ctrl = ToastKit.showLoading('Signing in…');  // No channel
// No guard against rapid taps
```

**After**:
```dart
setState(() {
  _isSigningIn = true;
  _attemptCount++;
});
final ctrl = ToastKit.showLoading('Signing in…', channel: 'auth');
// Guard at top of method:
if (_isSigningIn || _isLocked) return;
```

---

## General Migration Checklist

When upgrading to a new version:

- [ ] Check that all `ToastRule` conditions using `>=` have appropriate `maxTriggers`
- [ ] Verify loading toasts include the correct `channel` parameter
- [ ] Add concurrency guards (`_isSubmitting` flags) to async operations that show toasts
- [ ] Wrap state mutations like `_count++` in `setState()` when used in Flutter widgets
- [ ] Review rule conditions for `==` comparisons — consider changing to `>=` with `maxTriggers`

---

[← FAQ](faq.md) | [Next: Changelog →](changelog.md)
