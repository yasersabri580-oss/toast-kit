# Quick Start

Get your first toast on screen in under 2 minutes.

## Step 1: Initialize

```dart
import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    ToastKit.init(navigatorKey: _navigatorKey);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      home: const HomeScreen(),
    );
  }
}
```

## Step 2: Show Your First Toast

```dart
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => ToastKit.success('Hello, ToastKit!'),
          child: const Text('Show Toast'),
        ),
      ),
    );
  }
}
```

**What happens**: A green success toast slides in from the top and auto-dismisses after 3 seconds.

## Step 3: Try All Toast Types

```dart
ToastKit.success('File saved');
ToastKit.error('Upload failed');
ToastKit.warning('Storage almost full');
ToastKit.info('New version available');
```

## Step 4: Loading → Result Pattern

This is the most powerful pattern in ToastKit. Show a loading toast, then transition it to success or error:

```dart
Future<void> saveData() async {
  final ctrl = ToastKit.showLoading('Saving…');

  try {
    await api.save(data);
    ctrl.success('Saved successfully!');
  } catch (e) {
    ctrl.error('Save failed: $e');
  }
}
```

**What happens**:
1. A loading spinner toast appears with "Saving…"
2. On success: the toast smoothly transitions to a green ✓ with "Saved successfully!"
3. On failure: the toast transitions to a red ✗ with the error message
4. The result toast auto-dismisses after the default duration

## Step 5: Custom Position and Duration

```dart
ToastKit.success(
  'Bottom toast!',
  position: ToastPosition.bottom,
  duration: const Duration(seconds: 5),
);
```

## Step 6: Toast with Actions

```dart
ToastKit.show(ToastEvent.info(
  message: 'Message deleted',
  variant: ToastVariant.action,
  actions: [
    ToastAction(
      label: 'Undo',
      onPressed: () => restoreMessage(),
    ),
  ],
));
```

## What to Expect

| Feature | Default Behavior |
|---------|-----------------|
| Position | Top center |
| Duration | 3 seconds |
| Animation | Slide from top |
| Max visible | 3 toasts |
| Queue | FIFO, enabled, max 50 |
| Dismiss | Swipe or tap |
| Loading toasts | Persistent until state change |

## Next Steps

- Learn about [Core Concepts](core_concepts.md) to understand the architecture
- See [API Reference](api_reference.md) for every option available
- Check [Examples](examples/) for real-world use cases

---

[← Installation](installation.md) | [Next: Core Concepts →](core_concepts.md)
