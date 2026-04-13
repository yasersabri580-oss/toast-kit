import '../analytics/toast_telemetry_event.dart';
import '../events/toast_event.dart';
import 'toast_plugin.dart';

/// Example Firebase analytics plugin adapter.
///
/// This demonstrates how to integrate Firebase Analytics with ToastKit
/// as a plugin. ToastKit core does **not** depend on Firebase — this
/// class should live in the app or a separate package that depends on
/// `firebase_analytics`.
///
/// ```dart
/// // In your app (not in ToastKit core):
/// import 'package:firebase_analytics/firebase_analytics.dart';
///
/// ToastKit.configure(
///   plugins: [
///     FirebaseToastAnalyticsPlugin(FirebaseAnalytics.instance),
///   ],
/// );
/// ```
///
/// This example class uses a generic callback to avoid a hard dependency
/// on `firebase_analytics`. Replace [_logEvent] with your actual
/// `FirebaseAnalytics.logEvent` call.
class FirebaseToastAnalyticsPlugin extends ToastAnalyticsPlugin {

  /// Creates a [FirebaseToastAnalyticsPlugin].
  ///
  /// Pass a [logEvent] callback that forwards to your analytics SDK.
  FirebaseToastAnalyticsPlugin({required this.logEvent});
  /// Callback that logs an event to your analytics backend.
  /// Signature matches `FirebaseAnalytics.logEvent`.
  final void Function({required String name, Map<String, Object>? parameters})
      logEvent;

  @override
  String get name => 'firebase_analytics';

  @override
  void onToastShown(ToastEvent event) {
    logEvent(
      name: 'toast_shown',
      parameters: _baseParams(event),
    );
  }

  @override
  void onToastDismissed(ToastEvent event, DismissReason? reason) {
    logEvent(
      name: 'toast_dismissed',
      parameters: {
        ..._baseParams(event),
        if (reason != null) 'dismiss_reason': reason.name,
      },
    );
  }

  @override
  void onToastAction(ToastEvent event, String actionLabel) {
    logEvent(
      name: 'toast_action',
      parameters: {
        ..._baseParams(event),
        'action_label': actionLabel,
      },
    );
  }

  @override
  void onToastDropped(ToastEvent event, String reason) {
    logEvent(
      name: 'toast_dropped',
      parameters: {
        ..._baseParams(event),
        'drop_reason': reason,
      },
    );
  }

  @override
  void onTelemetryEvent(ToastTelemetryEvent telemetryEvent) {
    logEvent(
      name: 'toast_${telemetryEvent.type.name}',
      parameters: telemetryEvent.toMap().map(
            (key, value) => MapEntry(key, value is String ? value : '$value'),
          ),
    );
  }

  Map<String, Object> _baseParams(ToastEvent event) {
    return {
      'toast_id': event.id,
      'toast_type': event.type.name,
      if (event.channel != null) 'channel': event.channel!,
      if (event.message != null) 'message': event.message!,
    };
  }
}
