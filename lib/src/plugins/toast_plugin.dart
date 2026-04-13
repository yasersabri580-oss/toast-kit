import '../events/toast_event.dart';
import '../analytics/toast_telemetry_event.dart';

/// Base class for all ToastKit plugins.
///
/// Plugins observe lifecycle events without blocking the core pipeline.
/// Plugin errors are always caught and logged — they never crash ToastKit.
///
/// ```dart
/// class MyPlugin extends ToastPlugin {
///   @override
///   String get name => 'my_plugin';
///
///   @override
///   void onToastShown(ToastEvent event) {
///     print('Toast shown: ${event.message}');
///   }
/// }
/// ```
abstract class ToastPlugin {
  /// Unique name for this plugin (used for deduplication).
  String get name;

  /// Called when a toast is displayed.
  void onToastShown(ToastEvent event) {}

  /// Called when a toast is placed in the queue.
  void onToastQueued(ToastEvent event) {}

  /// Called when a toast is dismissed.
  void onToastDismissed(ToastEvent event, DismissReason? reason) {}

  /// Called when a toast is silently dropped.
  void onToastDropped(ToastEvent event, String reason) {}

  /// Called when a toast replaces another.
  void onToastReplaced(ToastEvent newEvent, String replacedId) {}

  /// Called when a toast action button is pressed.
  void onToastAction(ToastEvent event, String actionLabel) {}

  /// Called when a channel is registered.
  void onChannelRegistered(String channelId) {}

  /// Called when a rule is triggered.
  void onRuleTriggered(String ruleId, String channel) {}

  /// Called for every telemetry event (structured analytics).
  void onTelemetryEvent(ToastTelemetryEvent telemetryEvent) {}

  /// Called when the plugin is registered with ToastKit.
  void onAttach() {}

  /// Called when the plugin is removed or ToastKit is disposed.
  void onDetach() {}
}

/// A plugin specializing in analytics / telemetry forwarding.
///
/// Override [onTelemetryEvent] to forward events to your analytics backend.
abstract class ToastAnalyticsPlugin extends ToastPlugin {
  @override
  String get name;
}

/// A plugin specializing in toast persistence.
///
/// Override lifecycle hooks to persist and restore toasts.
abstract class ToastPersistencePlugin extends ToastPlugin {
  @override
  String get name;
}

/// A plugin specializing in lifecycle observation.
///
/// Override any lifecycle hooks to observe toast behavior.
abstract class ToastLifecyclePlugin extends ToastPlugin {
  @override
  String get name;
}
