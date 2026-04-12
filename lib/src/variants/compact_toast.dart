import 'package:flutter/material.dart';
import '../events/toast_event.dart';
import '../theme/toast_theme.dart';
import 'toast_variant_helpers.dart';

/// Small pill-shaped toast.
class CompactToast extends StatelessWidget {
  final ToastEvent event;
  final ToastController controller;

  const CompactToast({super.key, required this.event, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = resolveTheme(context);
    final accent = colorForType(event.type, theme);

    return Container(
      margin: theme.margin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: theme.shadowColor, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(event.icon ?? iconForType(event.type), color: accent, size: 18),
          const SizedBox(width: 8),
          Text(event.message ?? '', style: theme.textStyle.copyWith(color: theme.foregroundColor, fontSize: 13)),
        ],
      ),
    );
  }
}
