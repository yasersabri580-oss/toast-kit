import 'dart:ui';
import 'package:flutter/material.dart';
import '../events/toast_event.dart';
import '../theme/toast_theme.dart';
import 'toast_variant_helpers.dart';

/// iOS Human Interface style notification with subtle blur.
class IosToast extends StatelessWidget {
  final ToastEvent event;
  final ToastController controller;

  const IosToast({super.key, required this.event, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = resolveTheme(context);
    final accent = colorForType(event.type, theme);

    return Container(
      constraints: BoxConstraints(maxWidth: theme.maxWidth, minHeight: theme.minHeight),
      margin: theme.margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.backgroundColor.withAlpha(200),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withAlpha(30)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(event.icon ?? iconForType(event.type), color: accent, size: 22),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (event.title != null)
                        Text(event.title!,
                            style: theme.titleStyle.copyWith(color: theme.foregroundColor, fontSize: 14)),
                      if (event.message != null)
                        Text(event.message!,
                            style: theme.textStyle.copyWith(color: theme.foregroundColor.withAlpha(200), fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
