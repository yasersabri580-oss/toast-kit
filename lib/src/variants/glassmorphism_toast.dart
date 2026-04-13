import 'dart:ui';
import 'package:flutter/material.dart';
import '../events/toast_event.dart';
import 'toast_variant_helpers.dart';

/// Frosted-glass (glassmorphism) toast.
class GlassmorphismToast extends StatelessWidget {

  const GlassmorphismToast({super.key, required this.event, required this.controller});
  final ToastEvent event;
  final ToastController controller;

  @override
  Widget build(BuildContext context) {
    final theme = resolveTheme(context);
    final accent = colorForType(event.type, theme);

    return Container(
      constraints: BoxConstraints(maxWidth: theme.maxWidth, minHeight: theme.minHeight),
      margin: theme.margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: theme.padding,
            decoration: BoxDecoration(
              color: accent.withAlpha(40),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(50), width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(event.icon ?? iconForType(event.type), color: Colors.white, size: theme.iconSize),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (event.title != null)
                        Text(event.title!, style: theme.titleStyle.copyWith(color: Colors.white)),
                      if (event.message != null)
                        Text(event.message!, style: theme.textStyle.copyWith(color: Colors.white.withAlpha(220))),
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
