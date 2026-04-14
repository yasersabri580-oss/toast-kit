# Installation

## Add Dependency

Add `toast_kit` to your `pubspec.yaml`:

```yaml
dependencies:
  toast_kit: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Import

```dart
import 'package:toast_kit/toast_kit.dart';
```

This single import gives you access to all public APIs: `ToastKit`, `ToastEvent`, `ToastController`, `ToastChannel`, `ToastRule`, and all configuration types.

## Minimum Requirements

| Requirement | Version |
|-------------|---------|
| Dart SDK | `>= 3.0.0 < 4.0.0` |
| Flutter | `>= 3.10.0` |

## Version Compatibility

| ToastKit Version | Flutter Version | Dart SDK |
|------------------|-----------------|----------|
| 1.0.0 | ≥ 3.10.0 | ≥ 3.0.0 |

## Dependencies

ToastKit has **zero external dependencies**. It only depends on the Flutter SDK:

```yaml
dependencies:
  flutter:
    sdk: flutter
```

## Initialize

ToastKit must be initialized once before use, typically in your app's `main()` or root widget:

```dart
import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

void main() {
  runApp(const MyApp());
}

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

> **Important**: The `navigatorKey` must be the same key passed to `MaterialApp`. ToastKit uses it to insert overlay entries above your app's widget tree.

## Verify Installation

After setup, test it works:

```dart
// In any widget or service
ToastKit.success('ToastKit is working!');
```

You should see a success toast at the top of the screen.

---

[← Overview](overview.md) | [Next: Quick Start →](quick_start.md)
