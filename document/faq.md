# FAQ

Short answers to common developer questions.

---

### Do I need BuildContext to show a toast?

No. All static methods (`ToastKit.success()`, `ToastKit.error()`, etc.) work without `BuildContext`. You can call them from services, blocs, repositories, or any Dart code.

---

### How do I show a loading toast that transitions to success/error?

```dart
final ctrl = ToastKit.showLoading('Working…');
try {
  await doWork();
  ctrl.success('Done!');
} catch (e) {
  ctrl.error('Failed');
}
```

---

### Can I show multiple toasts at once?

Yes. By default, up to 3 toasts are visible simultaneously (`maxVisibleToasts: 3`). Excess events are queued. Change the limit in `ToastConfig`.

---

### How do I prevent the same error from spamming the user?

Use deduplication:

```dart
ToastKit.init(
  navigatorKey: navigatorKey,
  routerConfig: const RouterConfig(
    enableDeduplication: true,
    deduplicationWindow: Duration(seconds: 3),
  ),
);
```

Or use a `deduplicationKey`:

```dart
ToastKit.show(ToastEvent.error(
  message: 'Network error: $details',
  deduplicationKey: 'network-error',  // All variants coalesce to one
));
```

---

### What happens when I create a new loading toast while one is already showing?

The old loading toast is automatically dismissed. Only one loading toast exists at a time (loading exclusivity).

---

### How do I make a toast that doesn't auto-dismiss?

Set `persistent: true`:

```dart
ToastKit.show(ToastEvent.error(
  message: 'Action required',
  persistent: true,
  actions: [
    ToastAction(label: 'Fix Now', onPressed: fixIssue),
  ],
));
```

---

### How do I dismiss all toasts?

```dart
ToastKit.dismissAll();  // Dismisses all visible + clears queue
ToastKit.clearQueue();  // Clears queue only, visible toasts remain
```

---

### What's the difference between channels and deduplication?

- **Channels**: Group toasts by category (auth, network, payment) with independent policies (max visible, throttling, etc.)
- **Deduplication**: Prevent the same message from appearing twice within a time window, regardless of channel

You can use both together: a toast on the `auth` channel with a `deduplicationKey`.

---

### Can rule actions emit new toasts?

Yes. The rule engine has re-entrant protection. Toasts emitted inside rule actions are shown normally but don't trigger further rule evaluation in the same pass.

---

### How do I create a custom toast with my own widgets?

```dart
ToastKit.show(ToastEvent.custom(
  builder: (context, controller) {
    return MyCustomWidget(
      controller: controller,
      onDismiss: controller.dismiss,
    );
  },
));
```

---

### Does ToastKit work with GoRouter / AutoRoute / other navigation?

Yes, as long as you use `MaterialApp`'s `navigatorKey`. If your router uses its own navigator, pass that navigator's key to `ToastKit.init()`.

---

### Can I use ToastKit without the queue?

Yes. Disable the queue and excess events will be dropped:

```dart
ToastKit.init(
  navigatorKey: key,
  config: const ToastConfig(enableQueue: false),
);
```

---

### How do I test code that uses ToastKit?

Initialize ToastKit in your test setup with a test navigator key:

```dart
testWidgets('shows success toast', (tester) async {
  final key = GlobalKey<NavigatorState>();

  await tester.pumpWidget(MaterialApp(
    navigatorKey: key,
    home: const MyWidget(),
  ));

  ToastKit.init(navigatorKey: key);
  ToastKit.success('Test');

  await tester.pumpAndSettle();
  // Assert toast content...
});
```

---

### What happens if I call ToastKit.init() twice?

The second call disposes the first instance and creates a new one. This is safe but clears all state (queues, rules, stats, plugins).

---

### Are toasts accessible to screen readers?

ToastKit uses Flutter's `Semantics` system. Toast content is announced when it appears. Custom builders should include appropriate `Semantics` widgets.

---

### Does ToastKit add any external dependencies?

No. ToastKit depends only on the Flutter SDK. Zero third-party packages.

---

[← Troubleshooting](troubleshooting.md) | [Next: Migration Notes →](migration.md)
