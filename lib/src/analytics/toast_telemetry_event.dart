import 'package:flutter/foundation.dart';
import '../core/toast_config.dart';

/// Types of telemetry events emitted by ToastKit.
enum TelemetryEventType {
  /// A toast was displayed to the user.
  shown,

  /// A toast was dismissed (auto or manual).
  dismissed,

  /// An action button on a toast was clicked.
  actionClicked,

  /// A toast was placed in the queue.
  queued,

  /// A toast was dropped (not shown).
  dropped,

  /// A toast was replaced by another toast.
  replaced,

  /// A toast was deduplicated.
  deduplicated,

  /// A toast was throttled.
  throttled,

  /// A channel was registered.
  channelRegistered,

  /// A rule was triggered.
  ruleTriggered,
}

/// Reason a toast was dismissed.
enum DismissReason {
  /// Auto-dismissed after timeout.
  timeout,

  /// User swiped or tapped to dismiss.
  userAction,

  /// Replaced by a higher-priority toast.
  replaced,

  /// Programmatically dismissed.
  programmatic,
}

/// Structured telemetry event for analytics and observability.
///
/// All plugins receive the same event shape, making it easy to forward
/// events to Firebase, Sentry, or a custom backend.
@immutable
class ToastTelemetryEvent {
  /// Unique event identifier.
  final String eventId;

  /// Type of telemetry event.
  final TelemetryEventType type;

  /// The toast ID this event relates to.
  final String? toastId;

  /// Channel the toast belongs to.
  final String? channel;

  /// Semantic type of the toast.
  final ToastType? toastType;

  /// Visual variant used.
  final ToastVariant? variant;

  /// When this telemetry event was created.
  final DateTime timestamp;

  /// Reason for dismissal (if applicable).
  final DismissReason? dismissReason;

  /// Action label clicked (if applicable).
  final String? actionLabel;

  /// Rule ID that was triggered (if applicable).
  final String? ruleId;

  /// Queue position when queued.
  final int? queuePosition;

  /// Optional additional data.
  final Map<String, dynamic>? metadata;

  /// Creates a [ToastTelemetryEvent].
  const ToastTelemetryEvent({
    required this.eventId,
    required this.type,
    this.toastId,
    this.channel,
    this.toastType,
    this.variant,
    required this.timestamp,
    this.dismissReason,
    this.actionLabel,
    this.ruleId,
    this.queuePosition,
    this.metadata,
  });

  /// Converts this event to a map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'type': type.name,
      if (toastId != null) 'toastId': toastId,
      if (channel != null) 'channel': channel,
      if (toastType != null) 'toastType': toastType!.name,
      if (variant != null) 'variant': variant!.name,
      'timestamp': timestamp.toIso8601String(),
      if (dismissReason != null) 'dismissReason': dismissReason!.name,
      if (actionLabel != null) 'actionLabel': actionLabel,
      if (ruleId != null) 'ruleId': ruleId,
      if (queuePosition != null) 'queuePosition': queuePosition,
      if (metadata != null) 'metadata': metadata,
    };
  }

  @override
  String toString() =>
      'ToastTelemetryEvent(type: ${type.name}, toastId: $toastId)';
}
