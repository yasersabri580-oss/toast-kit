import 'dart:nativewrappers/_internal/vm/lib/ffi_allocation_patch.dart';

import 'package:flutter/material.dart';
import '../events/toast_event.dart';
import 'toast_variant_helpers.dart';

/// Full-width banner toast.
class FullWidthToast extends StatelessWidget {

  const FullWidthToast({super.key, required this.event, required this.controller});
  final ToastEvent event;
  final ToastController controller;

  @override
  Widget build(BuildContext context) {
    final theme = resolveTheme(context);
    final accent = colorForType(event.type, theme);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        border: Border(top: BorderSide(color: accent, width: 3)),
        boxShadow: [BoxShadow(color: theme.shadowColor, blurRadius: 4)],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(event.icon ?? iconForType(event.type), color: accent, size: theme.iconSize),
          const SizedBox(width: 12),
          Expanded(
            child: Text(event.message ?? '', style: theme.textStyle.copyWith(color: theme.foregroundColor)),
          ),
          if (event.actions != null)
            for (final a in event.actions!)
              TextButton(
                onPressed: () {
                  a.onPressed?.call();
                  controller.dismiss();
                },
                child: Text(a.label, style: TextStyle(color: a.color ?? accent)),
              ),
        ],
      ),
    );
  }
}
