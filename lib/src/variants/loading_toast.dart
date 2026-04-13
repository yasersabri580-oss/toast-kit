import 'package:flutter/material.dart';
import '../events/toast_event.dart';
import 'toast_variant_helpers.dart';

/// Toast with a loading spinner.
class LoadingToast extends StatelessWidget {

  const LoadingToast({super.key, required this.event, required this.controller});
  final ToastEvent event;
  final ToastController controller;

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
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: accent),
              ),
              const SizedBox(width: 14),
              Flexible(
                child: ValueListenableBuilder<String>(
                  valueListenable: controller.messageNotifier,
                  builder: (_, msg, __) {
                    return Text(
                      msg.isNotEmpty ? msg : (event.message ?? 'Loading…'),
                      style: theme.textStyle.copyWith(color: theme.foregroundColor),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
