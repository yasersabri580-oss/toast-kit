import 'package:flutter/material.dart';
import '../events/toast_event.dart';
import 'toast_variant_helpers.dart';

/// Developer / debug toast with monospace font and metadata.
class DebugToast extends StatelessWidget {

  const DebugToast({super.key, required this.event, required this.controller});
  final ToastEvent event;
  final ToastController controller;

  @override
  Widget build(BuildContext context) {
    final theme = resolveTheme(context);
    final accent = colorForType(event.type, theme);

    const mono = TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.5);

    return Container(
      constraints: BoxConstraints(maxWidth: theme.maxWidth),
      margin: theme.margin,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report_rounded, color: accent, size: 16),
              const SizedBox(width: 6),
              Text('DEBUG', style: mono.copyWith(color: accent, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(
                '${event.createdAt.hour.toString().padLeft(2, '0')}:'
                '${event.createdAt.minute.toString().padLeft(2, '0')}:'
                '${event.createdAt.second.toString().padLeft(2, '0')}',
                style: mono.copyWith(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('type: ${event.type.name}  priority: ${event.priority.name}',
              style: mono.copyWith(color: Colors.grey.shade400)),
          if (event.message != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(event.message!, style: mono.copyWith(color: Colors.greenAccent.shade200)),
            ),
        ],
      ),
    );
  }
}
