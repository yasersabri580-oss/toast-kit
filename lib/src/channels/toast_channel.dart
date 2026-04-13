import 'package:flutter/foundation.dart';
import '../core/toast_config.dart';

/// A named notification channel with its own display and queue policies.
///
/// Channels allow grouping toasts by category (e.g. auth, network, sync)
/// and applying per-category configuration overrides.
///
/// ```dart
/// const authChannel = ToastChannel(
///   id: 'auth',
///   label: 'Authentication',
///   maxVisible: 1,
///   defaultPriority: ToastPriority.high,
/// );
/// ```
@immutable
class ToastChannel {

  /// Creates a [ToastChannel].
  const ToastChannel({
    required this.id,
    required this.label,
    this.maxVisible,
    this.defaultPriority,
    this.defaultPosition,
    this.defaultDuration,
    this.defaultAnimation,
    this.defaultVariant,
    this.enabled = true,
  });
  /// Unique identifier for this channel.
  final String id;

  /// Human-readable label.
  final String label;

  /// Override: maximum visible toasts for this channel.
  final int? maxVisible;

  /// Override: default priority for toasts in this channel.
  final ToastPriority? defaultPriority;

  /// Override: default position for toasts in this channel.
  final ToastPosition? defaultPosition;

  /// Override: default auto-dismiss duration.
  final Duration? defaultDuration;

  /// Override: default animation type.
  final ToastAnimationType? defaultAnimation;

  /// Override: default visual variant.
  final ToastVariant? defaultVariant;

  /// Whether this channel is enabled. Disabled channels silently drop events.
  final bool enabled;

  /// Pre-defined authentication channel.
  static const auth = ToastChannel(
    id: 'auth',
    label: 'Authentication',
    maxVisible: 1,
    defaultPriority: ToastPriority.high,
  );

  /// Pre-defined network channel.
  static const network = ToastChannel(
    id: 'network',
    label: 'Network',
    defaultPriority: ToastPriority.normal,
  );

  /// Pre-defined sync channel.
  static const sync = ToastChannel(
    id: 'sync',
    label: 'Sync',
    defaultPriority: ToastPriority.normal,
  );

  /// Pre-defined payment channel.
  static const payment = ToastChannel(
    id: 'payment',
    label: 'Payment',
    maxVisible: 1,
    defaultPriority: ToastPriority.urgent,
  );

  /// Pre-defined debug channel.
  static const debug = ToastChannel(
    id: 'debug',
    label: 'Debug',
    defaultPriority: ToastPriority.low,
    defaultVariant: ToastVariant.debug,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToastChannel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ToastChannel($id)';
}

/// Registry that manages all known channels and their active toast counts.
class ChannelRegistry {
  final Map<String, ToastChannel> _channels = {};
  final Map<String, int> _activeCounts = {};

  /// Register a channel. Replaces any existing channel with the same id.
  void register(ToastChannel channel) {
    _channels[channel.id] = channel;
    _activeCounts.putIfAbsent(channel.id, () => 0);
  }

  /// Unregister a channel by id.
  void unregister(String channelId) {
    _channels.remove(channelId);
    _activeCounts.remove(channelId);
  }

  /// Look up a channel by id. Returns `null` if not registered.
  ToastChannel? operator [](String channelId) => _channels[channelId];

  /// Whether the channel's max-visible limit has been reached.
  bool isChannelFull(String channelId) {
    final channel = _channels[channelId];
    if (channel == null || channel.maxVisible == null) return false;
    return (_activeCounts[channelId] ?? 0) >= channel.maxVisible!;
  }

  /// Increment the active count for a channel.
  void markActive(String channelId) {
    _activeCounts[channelId] = (_activeCounts[channelId] ?? 0) + 1;
  }

  /// Decrement the active count for a channel.
  void markDismissed(String channelId) {
    final count = _activeCounts[channelId] ?? 0;
    _activeCounts[channelId] = (count - 1).clamp(0, count);
  }

  /// Get the active count for a channel.
  int activeCount(String channelId) => _activeCounts[channelId] ?? 0;

  /// All registered channel IDs.
  Iterable<String> get channelIds => _channels.keys;

  /// Clear all registrations.
  void clear() {
    _channels.clear();
    _activeCounts.clear();
  }
}
