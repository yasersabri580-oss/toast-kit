import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

/// Reusable helper patterns for showing toasts in the demo.
///
/// Encapsulates common toast patterns so feature screens stay concise.
class ToastHelpers {
  ToastHelpers._();

  // ---------------------------------------------------------------------------
  // Simple convenience
  // ---------------------------------------------------------------------------

  static void success(String message, {String? title, String? channel}) {
    ToastKit.success(
      message,
      title: title,
      channel: channel,
    );
  }

  static void error(String message, {String? title, String? channel}) {
    ToastKit.error(
      message,
      title: title,
      channel: channel,
    );
  }

  static void warning(String message, {String? title, String? channel}) {
    ToastKit.warning(
      message,
      title: title,
      channel: channel,
    );
  }

  static void info(String message, {String? title, String? channel}) {
    ToastKit.info(
      message,
      title: title,
      channel: channel,
    );
  }

  // ---------------------------------------------------------------------------
  // Pattern: async action with loading → success / error
  // ---------------------------------------------------------------------------

  /// Wraps an async [action] with a loading toast that transitions to
  /// success or error automatically.
  static Future<T?> withLoading<T>({
    required Future<T> Function() action,
    required String loadingMessage,
    required String successMessage,
    String? errorMessage,
    String? channel,
  }) async {
    final ctrl = ToastKit.showLoading(loadingMessage, channel: channel);
    try {
      final result = await action();
      ctrl.success(successMessage);
      return result;
    } catch (e) {
      ctrl.error(errorMessage ?? e.toString());
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Pattern: progress toast
  // ---------------------------------------------------------------------------

  /// Shows a progress toast and returns its controller so the caller can
  /// update progress and finalise.
  static ToastController showProgress(
    String message, {
    String? channel,
    IconData icon = Icons.cloud_upload_outlined,
  }) {
    return ToastKit.showWithController(
      ToastEvent.loading(
        message: message,
        channel: channel,
        
        persistent: true,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pattern: action toast
  // ---------------------------------------------------------------------------

  /// Shows a toast with one or more action buttons.
  static void withAction({
    required String message,
    required ToastType type,
    required List<ToastAction> actions,
    String? title,
    String? channel,
    Duration duration = const Duration(seconds: 6),
  }) {
    ToastKit.show(ToastEvent(
      type: type,
      message: message,
      title: title,
      channel: channel,
      duration: duration,
      actions: actions,
      icon: _iconForType(type),
    ));
  }

  static IconData _iconForType(ToastType type) {
    return switch (type) {
      ToastType.success => Icons.check_circle_outline,
      ToastType.error => Icons.error_outline,
      ToastType.warning => Icons.warning_amber_rounded,
      ToastType.info => Icons.info_outline,
      ToastType.loading => Icons.hourglass_empty,
      _ => Icons.notifications_outlined,
    };
  }
}
