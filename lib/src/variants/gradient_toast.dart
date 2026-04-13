import 'package:flutter/material.dart';
import '../events/toast_event.dart';
import '../theme/toast_theme.dart';
import 'toast_variant_helpers.dart';

/// Gradient background toast.
class GradientToast extends StatelessWidget {
  final ToastEvent event;
  final ToastController controller;

  const GradientToast({super.key, required this.event, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = resolveTheme(context);
    final accent = colorForType(event.type, theme);

    final gradient = LinearGradient(
      colors: [accent, accent.withAlpha(180)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      constraints: BoxConstraints(maxWidth: theme.maxWidth, minHeight: theme.minHeight),
      margin: theme.margin,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: theme.borderRadius,
        boxShadow: [BoxShadow(color: accent.withAlpha(80), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: theme.padding,
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
                  Text(event.message!, style: theme.textStyle.copyWith(color: Colors.white.withAlpha(230))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
