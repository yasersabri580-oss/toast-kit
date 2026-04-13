import 'package:flutter/material.dart';

/// A polished action button used throughout the demo app.
///
/// Renders as a full-width [FilledButton] with a leading [icon], label text,
/// and a customizable background [color]. When no [color] is provided the
/// button uses the theme's primary color.
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  /// Button label text.
  final String label;

  /// Leading icon displayed before the label.
  final IconData icon;

  /// Callback when the button is tapped.
  final VoidCallback onPressed;

  /// Optional background color override.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// A compact, tonal action button that sits well in a row of buttons.
///
/// Uses [FilledButton.tonal] for a softer visual hierarchy compared to
/// [ActionButton].
class CompactActionButton extends StatelessWidget {
  const CompactActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  /// Button label text.
  final String label;

  /// Leading icon displayed before the label.
  final IconData icon;

  /// Callback when the button is tapped.
  final VoidCallback onPressed;

  /// Optional foreground/icon color override.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
