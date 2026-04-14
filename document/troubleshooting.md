# Troubleshooting

Common errors, why they happen, and how to fix them.

---

## Assertion: "ToastKit.init() must be called first"

**Error**:
```
'ToastKit.init() must be called first.'
```

**Cause**: You called `ToastKit.success()` (or any other method) before `ToastKit.init()`.

**Fix**: Initialize ToastKit in your app's `initState()` or `main()`:

```dart
class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    ToastKit.init(navigatorKey: _navigatorKey);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(navigatorKey: _navigatorKey, home: const Home());
  }
}
```

---

## Toasts Don't Appear

**Symptoms**: `ToastKit.success('test')` runs without error but nothing shows.

**Possible causes**:

1. **Wrong navigator key**: The `GlobalKey<NavigatorState>` passed to `ToastKit.init()` must be the same key on `MaterialApp`:

   ```dart
   // ❌ Wrong: different keys
   ToastKit.init(navigatorKey: GlobalKey());
   MaterialApp(navigatorKey: GlobalKey());

   // ✅ Correct: same key
   final key = GlobalKey<NavigatorState>();
   ToastKit.init(navigatorKey: key);
   MaterialApp(navigatorKey: key);
   ```

2. **Called before MaterialApp is mounted**: The navigator must exist when the toast tries to insert an overlay entry. Make sure `init()` is called in `initState()`, not before `runApp()`.

3. **Channel is full**: If the toast is on a channel with `maxVisible: 1` and a toast is already showing, new toasts are silently dropped.

4. **Deduplication**: If the same message was shown recently, dedup may coalesce it. Check `RouterConfig.enableDeduplication`.

5. **Throttling**: If throttling is enabled and the same type was shown recently, the toast is dropped.

---

## Toast Shows But Rule Doesn't Fire

**Symptoms**: Error count should trigger a rule, but the rule action never executes.

**Possible causes**:

1. **Wrong channel**: The rule's `channel` must match the toast's `channel`:

   ```dart
   // ❌ Rule watches 'auth', but toast is on 'network'
   ToastKit.addRule(ToastRule(id: 'r', channel: 'auth', ...));
   ToastKit.error('fail', channel: 'network');

   // ✅ Both use 'auth'
   ToastKit.addRule(ToastRule(id: 'r', channel: 'auth', ...));
   ToastKit.error('fail', channel: 'auth');
   ```

2. **No channel on toast**: Toasts without a `channel` go to the default channel. Rules watch specific channels.

3. **Event was dropped/deduped**: Dropped or deduplicated events don't increment stats and don't trigger rule evaluation.

4. **maxTriggers exceeded**: If `maxTriggers: 1` and the rule already fired, it won't fire again.

5. **Condition uses `==` instead of `>=`**: If errorCount jumps from 2 to 4 (because an event was dropped), `== 3` is never true.

---

## App Becomes Unresponsive After Multiple Toasts

**Symptoms**: After several failed operations (e.g., login attempts), the app stops responding to taps.

**Possible causes**:

1. **Missing concurrency guard**: Without an `_isSigningIn` flag, rapid taps create multiple concurrent async operations:

   ```dart
   // ❌ No guard — rapid taps create parallel operations
   Future<void> _submit() async {
     final ctrl = ToastKit.showLoading('Working…');
     await api.call();
     ctrl.success('Done!');
   }

   // ✅ With guard
   bool _isSubmitting = false;

   Future<void> _submit() async {
     if (_isSubmitting) return;
     setState(() => _isSubmitting = true);
     try {
       final ctrl = ToastKit.showLoading('Working…');
       await api.call();
       ctrl.success('Done!');
     } finally {
       if (mounted) setState(() => _isSubmitting = false);
     }
   }
   ```

2. **Rule fires repeatedly**: A `>= N` condition without `maxTriggers` fires on every subsequent event:

   ```dart
   // ❌ Fires on every event after 5 errors
   condition: (stats, event) => stats.errorCount >= 5,

   // ✅ Fires once
   maxTriggers: 1,
   condition: (stats, event) => stats.errorCount >= 5,
   ```

3. **Persistent toast blocking interaction**: A persistent, non-dismissible toast may overlay interactive elements. Ensure persistent toasts are eventually dismissed.

---

## Loading Toast Stays On Screen Forever

**Symptoms**: `showLoading('Working…')` toast never goes away.

**Cause**: Loading toasts are `persistent: true, dismissible: false` by default. They won't auto-dismiss.

**Fix**: Always transition the loading toast to a result state, even in error cases:

```dart
final ctrl = ToastKit.showLoading('Working…');
try {
  await doWork();
  ctrl.success('Done!');
} catch (e) {
  ctrl.error('Failed');  // Don't forget this!
}
```

> **Note**: If you need to dismiss without a state transition, use `ctrl.dismiss()`.

---

## Multiple Loading Toasts Appearing

**Symptoms**: Multiple loading spinners on screen simultaneously.

**Cause**: Loading toast exclusivity only applies within the same ToastKit instance. This shouldn't normally happen.

**Debug steps**:
1. Verify only one `ToastKit.init()` call exists
2. Check that `ToastKit.dispose()` isn't called between showing loading toasts
3. Loading toasts on different channels are NOT subject to exclusivity

---

## Rule Action Toast Gets Dropped

**Symptoms**: A rule fires (confirmed via plugin/log), but its action's toast doesn't show.

**Cause**: The toast emitted inside the rule action goes through `_onEvent`, which checks channel capacity. If the channel is already full (from the error toast that triggered the rule), the action's toast is dropped.

**Fix options**:

1. Use `showOrReplace` to replace the existing toast
2. Emit the action toast without a channel: `channel: null`
3. Use a different channel for the action toast
4. Set a `deduplicationKey` and allow the router to coalesce naturally

---

## Debug Tips

### Enable the Logger Plugin

```dart
class DebugLoggerPlugin extends ToastPlugin {
  @override
  String get name => 'debug-logger';

  @override
  void onToastShown(ToastEvent event) =>
      debugPrint('🍞 SHOWN: [${event.type.name}] ${event.message} (ch: ${event.channel})');

  @override
  void onToastDropped(ToastEvent event, String reason) =>
      debugPrint('🚫 DROPPED: ${event.message} — $reason');

  @override
  void onRuleTriggered(String ruleId, String channel) =>
      debugPrint('⚡ RULE: $ruleId on $channel');
}

// Register in debug builds
assert(() {
  ToastKit.registerPlugin(DebugLoggerPlugin());
  return true;
}());
```

### Check Queue State

```dart
final qm = ToastKit.instance._queueManager;  // Internal, but useful for debugging
print('Visible: ${qm.visibleCount}, Queued: ${qm.queuedEvents.length}');
```

### Monitor Rule Stats

```dart
final stats = ToastKit.ruleEngine.statsFor('auth');
print('Auth errors: ${stats.errorCount}, warnings: ${stats.warningCount}');
```

---

[← Advanced](advanced/) | [Next: FAQ →](faq.md)
