import 'package:flutter/material.dart';

import 'theme_controller.dart';

/// A compact segmented button that lets the user switch between
/// [ThemeMode.light], [ThemeMode.system], and [ThemeMode.dark].
///
/// Reads and writes the [ThemeController] from the nearest [ThemeScope].
class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeScope.of(context);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: controller,
      builder: (context, mode, _) {
        return SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode_outlined),
              tooltip: 'Light',
            ),
            ButtonSegment(
              value: ThemeMode.system,
              icon: Icon(Icons.brightness_auto_outlined),
              tooltip: 'System',
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode_outlined),
              tooltip: 'Dark',
            ),
          ],
          selected: {mode},
          onSelectionChanged: (Set<ThemeMode> selection) {
            controller.value = selection.first;
          },
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );
      },
    );
  }
}
