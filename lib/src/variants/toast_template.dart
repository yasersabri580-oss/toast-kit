import 'package:flutter/material.dart';

import '../core/toast_config.dart';
import '../events/toast_event.dart';
import '../theme/toast_theme.dart';
import 'toast_variant_helpers.dart';

/// A template-based API for building custom toast layouts without
/// implementing a full variant widget from scratch.
///
/// [ToastTemplate] provides named slots — [title], [body], [icon],
/// [leading], [trailing], [subtitle], and [progress] — which are laid
/// out in a standard card-style arrangement. Unused slots are simply
/// omitted from the layout.
///
/// ```dart
/// ToastTemplate(
///   event: event,
///   controller: controller,
///   title: Text('Upload complete'),
///   body: Text('Your file has been saved.'),
///   icon: Icon(Icons.cloud_done),
///   trailing: IconButton(icon: Icon(Icons.close), onPressed: controller.dismiss),
///   progress: LinearProgressIndicator(value: 0.75),
/// )
/// ```
class ToastTemplate extends StatelessWidget {
  /// Creates a [ToastTemplate].
  const ToastTemplate({
    required this.event,
    required this.controller,
    this.title,
    this.body,
    this.icon,
    this.leading,
    this.trailing,
    this.subtitle,
    this.progress,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.margin,
    super.key,
  });

  /// The toast event that drives this template.
  final ToastEvent event;

  /// Lifecycle controller for the toast.
  final ToastController controller;

  /// Primary title widget displayed at the top.
  final Widget? title;

  /// Secondary body widget displayed below [title].
  final Widget? body;

  /// Icon displayed to the left of the text content.
  final Widget? icon;

  /// Arbitrary leading widget placed before the icon.
  final Widget? leading;

  /// Arbitrary trailing widget placed at the end of the row.
  final Widget? trailing;

  /// Subtitle widget displayed below [body] in a lighter style.
  final Widget? subtitle;

  /// Progress indicator displayed at the bottom of the toast.
  final Widget? progress;

  /// Background colour override. Falls back to the theme.
  final Color? backgroundColor;

  /// Corner radius override. Falls back to the theme.
  final BorderRadius? borderRadius;

  /// Inner padding override. Falls back to the theme.
  final EdgeInsets? padding;

  /// Outer margin override. Falls back to the theme.
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    final theme = resolveTheme(context);
    final accent = colorForType(event.type, theme);
    final effectiveBg = backgroundColor ?? theme.backgroundColor;
    final effectiveRadius = borderRadius ?? theme.borderRadius;
    final effectivePadding = padding ?? theme.padding;
    final effectiveMargin = margin ?? theme.margin;

    return Container(
      constraints: BoxConstraints(
        maxWidth: theme.maxWidth,
        minHeight: theme.minHeight,
      ),
      margin: effectiveMargin,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: effectiveRadius,
        border: Border.all(color: accent.withAlpha(60), width: 1),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor,
            blurRadius: theme.elevation,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: effectivePadding,
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 8)],
                if (icon != null) ...[
                  IconTheme(
                    data: IconThemeData(color: accent, size: theme.iconSize),
                    child: icon!,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        DefaultTextStyle(
                          style: theme.titleStyle.copyWith(
                            color: theme.foregroundColor,
                          ),
                          child: title!,
                        ),
                      if (body != null) ...[
                        if (title != null) const SizedBox(height: 2),
                        DefaultTextStyle(
                          style: theme.textStyle.copyWith(
                            color: theme.foregroundColor,
                          ),
                          child: body!,
                        ),
                      ],
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        DefaultTextStyle(
                          style: theme.textStyle.copyWith(
                            color: theme.foregroundColor.withAlpha(160),
                            fontSize: (theme.textStyle.fontSize ?? 14) - 2,
                          ),
                          child: subtitle!,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              ],
            ),
          ),
          if (progress != null)
            ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: effectiveRadius.bottomLeft,
                bottomRight: effectiveRadius.bottomRight,
              ),
              child: progress!,
            ),
        ],
      ),
    );
  }
}
