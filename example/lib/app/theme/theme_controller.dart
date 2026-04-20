import 'package:flutter/material.dart';

/// Holds and notifies listeners of the current [ThemeMode].
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController([super.initial = ThemeMode.system]);
}

/// An [InheritedNotifier] that exposes [ThemeController] to the widget tree.
class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Returns the nearest [ThemeController] from the widget tree.
  static ThemeController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'No ThemeScope found in the widget tree.');
    return scope!.notifier!;
  }
}
