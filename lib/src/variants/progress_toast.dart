import 'package:flutter/material.dart';
import '../events/toast_event.dart';
import '../theme/toast_theme.dart';
import 'toast_variant_helpers.dart';

/// Determinate progress bar toast.
class ProgressToast extends StatelessWidget {
  final ToastEvent event;
  final ToastController controller;

  const ProgressToast({super.key, required this.event, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = resolveTheme(context);
    final accent = colorForType(event.type, theme);

    return Container(
      constraints: BoxConstraints(maxWidth: theme.maxWidth, minHeight: theme.minHeight),
      margin: theme.margin,
      child: Material(
        color: theme.backgroundColor,
        elevation: theme.elevation,
        borderRadius: theme.borderRadius,
        child: Padding(
          padding: theme.padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(event.icon ?? iconForType(event.type), color: accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      event.message ?? 'Processing…',
                      style: theme.textStyle.copyWith(color: theme.foregroundColor),
                    ),
                  ),
                  ValueListenableBuilder<double>(
                    valueListenable: controller.progress,
                    builder: (_, value, __) {
                      return Text(
                        '${(value * 100).toInt()}%',
                        style: theme.textStyle.copyWith(color: theme.foregroundColor, fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<double>(
                valueListenable: controller.progress,
                builder: (_, value, __) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: value,
                      backgroundColor: accent.withAlpha(40),
                      color: accent,
                      minHeight: 5,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
