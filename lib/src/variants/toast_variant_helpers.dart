import 'package:flutter/material.dart';
import '../core/toast_config.dart';
import '../theme/toast_theme.dart';

/// Shared helpers used by all variant widgets.

/// Return the semantic colour for a [ToastType].
Color colorForType(ToastType type, ToastThemeData theme) {
  switch (type) {
    case ToastType.success:
      return theme.successColor;
    case ToastType.error:
      return theme.errorColor;
    case ToastType.warning:
      return theme.warningColor;
    case ToastType.info:
      return theme.infoColor;
    case ToastType.loading:
      return theme.infoColor;
    // ignore: deprecated_member_use_from_same_package
    case ToastType.custom:
      return theme.foregroundColor;
  }
}

/// Default icon for a [ToastType].
IconData iconForType(ToastType type) {
  switch (type) {
    case ToastType.success:
      return Icons.check_circle_rounded;
    case ToastType.error:
      return Icons.error_rounded;
    case ToastType.warning:
      return Icons.warning_rounded;
    case ToastType.info:
      return Icons.info_rounded;
    case ToastType.loading:
      return Icons.hourglass_empty_rounded;
    // ignore: deprecated_member_use_from_same_package
    case ToastType.custom:
      return Icons.notifications_rounded;
  }
}

/// Resolve the theme from context or fall back to light.
ToastThemeData resolveTheme(BuildContext context) {
  return ToastThemeProvider.maybeOf(context) ?? ToastThemeData.light();
}
