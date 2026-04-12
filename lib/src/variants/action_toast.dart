import 'package:flutter/material.dart';
import '../events/toast_event.dart';
import '../theme/toast_theme.dart';
import 'toast_variant_helpers.dart';

/// Action toast with prominent buttons.
class ActionToast extends StatelessWidget {
  final ToastEvent event;
  final ToastController controller;

  const ActionToast({super.key, required this.event, required this.controller});

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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(event.icon ?? iconForType(event.type), color: accent, size: theme.iconSize),
              const SizedBox(width: 12),
              Flexible(
                child: Text(event.message ?? '', style: theme.textStyle.copyWith(color: theme.foregroundColor)),
              ),
              if (event.actions != null && event.actions!.isNotEmpty) ...[
                const SizedBox(width: 12),
                for (final a in event.actions!)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: FilledButton(
                      onPressed: () {
                        a.onPressed();
                        controller.dismiss();
                      },
                      style: FilledButton.styleFrom(backgroundColor: a.color ?? accent),
                      child: Text(a.label),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
