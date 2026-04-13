import 'package:flutter/material.dart';
import '../events/toast_event.dart';
import 'toast_variant_helpers.dart';

/// Clean, minimal design with thin left colour bar.
class MinimalToast extends StatelessWidget {

  const MinimalToast({
    super.key,
    required this.event,
    required this.controller,
  });
  final ToastEvent event;
  final ToastController controller;

  @override
  Widget build(BuildContext context) {
    final theme = resolveTheme(context);
    final accent = colorForType(event.type, theme);

    return Container(
      constraints: BoxConstraints(maxWidth: theme.maxWidth, minHeight: theme.minHeight),
      margin: theme.margin,
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: theme.borderRadius,
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      padding: theme.padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (event.icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(event.icon, color: accent, size: theme.iconSize),
            ),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event.title != null)
                  Text(event.title!, style: theme.titleStyle.copyWith(color: theme.foregroundColor)),
                if (event.message != null)
                  Text(event.message!, style: theme.textStyle.copyWith(color: theme.foregroundColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
