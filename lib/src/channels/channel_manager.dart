import '../channels/toast_channel.dart';
import '../channels/channel_config.dart';
import '../events/toast_event.dart';
import '../core/toast_config.dart';

/// A fluent API handle for emitting toasts on a specific channel.
///
/// Obtained via `ToastKit.channel("name")`.
class ChannelHandle {

  ChannelHandle(this._channelName, this._emit);
  final String _channelName;
  final void Function(ToastEvent) _emit;

  /// Show a success toast on this channel.
  void success(String message, {
    String? title,
    Duration? duration,
    ToastPosition? position,
    ToastVariant? variant,
    ToastAnimationType? animation,
  }) {
    _emit(ToastEvent.success(
      message: message,
      title: title,
      duration: duration,
      position: position,
      variant: variant,
      animation: animation,
      channel: _channelName,
    ));
  }

  /// Show an error toast on this channel.
  void error(String message, {
    String? title,
    Duration? duration,
    ToastPosition? position,
    ToastVariant? variant,
    ToastAnimationType? animation,
  }) {
    _emit(ToastEvent.error(
      message: message,
      title: title,
      duration: duration,
      position: position,
      variant: variant,
      animation: animation,
      channel: _channelName,
    ));
  }

  /// Show a warning toast on this channel.
  void warning(String message, {
    String? title,
    Duration? duration,
    ToastPosition? position,
    ToastVariant? variant,
    ToastAnimationType? animation,
  }) {
    _emit(ToastEvent.warning(
      message: message,
      title: title,
      duration: duration,
      position: position,
      variant: variant,
      animation: animation,
      channel: _channelName,
    ));
  }

  /// Show an info toast on this channel.
  void info(String message, {
    String? title,
    Duration? duration,
    ToastPosition? position,
    ToastVariant? variant,
    ToastAnimationType? animation,
  }) {
    _emit(ToastEvent.info(
      message: message,
      title: title,
      duration: duration,
      position: position,
      variant: variant,
      animation: animation,
      channel: _channelName,
    ));
  }

  /// Show a toast event on this channel.
  void show(ToastEvent event) {
    _emit(ToastEvent(
      id: event.id,
      type: event.type,
      message: event.message,
      title: event.title,
      icon: event.icon,
      iconColor: event.iconColor,
      duration: event.duration,
      position: event.position,
      animation: event.animation,
      priority: event.priority,
      deduplicationKey: event.deduplicationKey,
      metadata: event.metadata,
      onTap: event.onTap,
      onDismiss: event.onDismiss,
      actions: event.actions,
      customBuilder: event.customBuilder,
      variant: event.variant,
      persistent: event.persistent,
      dismissible: event.dismissible,
      channel: _channelName,
    ));
  }
}

/// Manages registered channels with their configs and active toast counts.
///
/// Provides safe registration, override, and lookup of channels. A default
/// channel always exists.
class ChannelManager {

  ChannelManager() {
    // Always register a default channel.
    _channels[defaultChannelName] = const ToastChannel(
      id: defaultChannelName,
      label: 'Default',
    );
    _configs[defaultChannelName] = const ChannelConfig();
    _activeCounts[defaultChannelName] = 0;
  }
  /// The default channel name.
  static const String defaultChannelName = 'default';

  final Map<String, ToastChannel> _channels = {};
  final Map<String, ChannelConfig> _configs = {};
  final Map<String, int> _activeCounts = {};

  /// Register a channel with optional config. Replaces any existing channel
  /// with the same name (idempotent override).
  void register(ToastChannel channel, {ChannelConfig? config}) {
    _channels[channel.id] = channel;
    _configs[channel.id] = config ?? const ChannelConfig();
    _activeCounts.putIfAbsent(channel.id, () => 0);
  }

  /// Unregister a channel by name. Cannot unregister the default channel.
  void unregister(String channelId) {
    if (channelId == defaultChannelName) return;
    _channels.remove(channelId);
    _configs.remove(channelId);
    _activeCounts.remove(channelId);
  }

  /// Look up a channel by id. Returns `null` if not registered.
  ToastChannel? operator [](String channelId) => _channels[channelId];

  /// Get the config for a channel.
  ChannelConfig? configFor(String channelId) => _configs[channelId];

  /// Whether a channel is registered.
  bool isRegistered(String channelId) => _channels.containsKey(channelId);

  /// Whether the channel's max-visible limit has been reached.
  bool isChannelFull(String channelId) {
    final config = _configs[channelId];
    if (config == null || config.maxVisible == null) return false;
    return (_activeCounts[channelId] ?? 0) >= config.maxVisible!;
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

  /// Clear all registrations except the default channel.
  void clear() {
    _channels.clear();
    _configs.clear();
    _activeCounts.clear();
    // Re-create the default channel.
    _channels[defaultChannelName] = const ToastChannel(
      id: defaultChannelName,
      label: 'Default',
    );
    _configs[defaultChannelName] = const ChannelConfig();
    _activeCounts[defaultChannelName] = 0;
  }
}
