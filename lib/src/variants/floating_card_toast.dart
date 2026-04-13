import 'package:flutter/material.dart';
import '../events/toast_event.dart';
import '../theme/toast_theme.dart';
import 'toast_variant_helpers.dart';

/// Floating elevated card toast.
class FloatingCardToast extends StatelessWidget {
  final ToastEvent event;
  final ToastController controller;

  const FloatingCardToast({super.key, required this.event, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = resolveTheme(context);
    final accent = colorForType(event.type, theme);

    return Container(
      constraints: BoxConstraints(maxWidth: theme.maxWidth),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Material(
        color: theme.backgroundColor,
        elevation: 12,
        shadowColor: theme.shadowColor,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(event.icon ?? iconForType(event.type), color: accent, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(event.title ?? '', style: theme.titleStyle.copyWith(color: theme.foregroundColor)),
                  ),
                ],
              ),
              if (event.message != null) ...[
                const SizedBox(height: 8),
                Text(event.message!, style: theme.textStyle.copyWith(color: theme.foregroundColor)),
              ],
              if (event.actions != null && event.actions!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: event.actions!
                      .map((a) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: TextButton(
                              onPressed: () {
                                a.onPressed();
                                controller.dismiss();
                              },
                              child: Text(a.label, style: TextStyle(color: a.color ?? accent)),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
