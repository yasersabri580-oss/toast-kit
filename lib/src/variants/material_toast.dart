import 'package:flutter/material.dart';
import '../events/toast_event.dart';
import '../theme/toast_theme.dart';
import 'toast_variant_helpers.dart';

/// Material Design 3 style toast with elevation and rounded corners.
class MaterialToast extends StatelessWidget {
  final ToastEvent event;
  final ToastController controller;

  const MaterialToast({
    super.key,
    required this.event,
    required this.controller,
  });

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
        shadowColor: theme.shadowColor,
        borderRadius: theme.borderRadius,
        child: Padding(
          padding: theme.padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(event.icon ?? iconForType(event.type), color: accent, size: theme.iconSize),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (event.title != null)
                      Text(event.title!, style: theme.titleStyle.copyWith(color: theme.foregroundColor)),
                    if (event.message != null)
                      Text(event.message!, style: theme.textStyle.copyWith(color: theme.foregroundColor)),
                  ],
                ),
              ),
              if (event.actions != null && event.actions!.isNotEmpty) ...[
                const SizedBox(width: 8),
                for (final action in event.actions!)
                  TextButton(
                    onPressed: () {
                      action.onPressed();
                      controller.dismiss();
                    },
                    child: Text(action.label, style: TextStyle(color: action.color ?? accent)),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
