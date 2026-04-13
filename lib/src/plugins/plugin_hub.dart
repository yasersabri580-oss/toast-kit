import 'package:flutter/foundation.dart';

import '../events/toast_event.dart';
import '../analytics/toast_telemetry_event.dart';
import 'toast_plugin.dart';

/// Central dispatcher that manages all registered plugins and safely
/// forwards lifecycle events to them.
///
/// Plugin errors are caught and logged — they never crash ToastKit.
class PluginHub {
  final Map<String, ToastPlugin> _plugins = {};

  /// Register a plugin. Replaces any existing plugin with the same name.
  void register(ToastPlugin plugin) {
    final existing = _plugins[plugin.name];
    if (existing != null) {
      _safeCall(() => existing.onDetach(), existing.name, 'onDetach');
    }
    _plugins[plugin.name] = plugin;
    _safeCall(() => plugin.onAttach(), plugin.name, 'onAttach');
  }

  /// Unregister a plugin by name.
  void unregister(String name) {
    final plugin = _plugins.remove(name);
    if (plugin != null) {
      _safeCall(() => plugin.onDetach(), plugin.name, 'onDetach');
    }
  }

  /// All registered plugin names.
  Iterable<String> get pluginNames => _plugins.keys;

  /// Number of registered plugins.
  int get pluginCount => _plugins.length;

  /// Whether any plugins are registered.
  bool get hasPlugins => _plugins.isNotEmpty;

  // -----------------------------------------------------------------------
  // Lifecycle dispatchers
  // -----------------------------------------------------------------------

  /// Notify all plugins that a toast was shown.
  void notifyToastShown(ToastEvent event) {
    for (final plugin in _plugins.values) {
      _safeCall(() => plugin.onToastShown(event), plugin.name, 'onToastShown');
    }
  }

  /// Notify all plugins that a toast was queued.
  void notifyToastQueued(ToastEvent event) {
    for (final plugin in _plugins.values) {
      _safeCall(
          () => plugin.onToastQueued(event), plugin.name, 'onToastQueued');
    }
  }

  /// Notify all plugins that a toast was dismissed.
  void notifyToastDismissed(ToastEvent event, DismissReason? reason) {
    for (final plugin in _plugins.values) {
      _safeCall(() => plugin.onToastDismissed(event, reason), plugin.name,
          'onToastDismissed');
    }
  }

  /// Notify all plugins that a toast was dropped.
  void notifyToastDropped(ToastEvent event, String reason) {
    for (final plugin in _plugins.values) {
      _safeCall(() => plugin.onToastDropped(event, reason), plugin.name,
          'onToastDropped');
    }
  }

  /// Notify all plugins that a toast replaced another.
  void notifyToastReplaced(ToastEvent newEvent, String replacedId) {
    for (final plugin in _plugins.values) {
      _safeCall(() => plugin.onToastReplaced(newEvent, replacedId), plugin.name,
          'onToastReplaced');
    }
  }

  /// Notify all plugins that a toast action was clicked.
  void notifyToastAction(ToastEvent event, String actionLabel) {
    for (final plugin in _plugins.values) {
      _safeCall(() => plugin.onToastAction(event, actionLabel), plugin.name,
          'onToastAction');
    }
  }

  /// Notify all plugins that a channel was registered.
  void notifyChannelRegistered(String channelId) {
    for (final plugin in _plugins.values) {
      _safeCall(() => plugin.onChannelRegistered(channelId), plugin.name,
          'onChannelRegistered');
    }
  }

  /// Notify all plugins that a rule was triggered.
  void notifyRuleTriggered(String ruleId, String channel) {
    for (final plugin in _plugins.values) {
      _safeCall(() => plugin.onRuleTriggered(ruleId, channel), plugin.name,
          'onRuleTriggered');
    }
  }

  /// Dispatch a structured telemetry event to all plugins.
  void dispatchTelemetryEvent(ToastTelemetryEvent telemetryEvent) {
    for (final plugin in _plugins.values) {
      _safeCall(() => plugin.onTelemetryEvent(telemetryEvent), plugin.name,
          'onTelemetryEvent');
    }
  }

  /// Detach all plugins and clear the registry.
  void dispose() {
    for (final plugin in _plugins.values) {
      _safeCall(() => plugin.onDetach(), plugin.name, 'onDetach');
    }
    _plugins.clear();
  }

  // -----------------------------------------------------------------------
  // Safety wrapper
  // -----------------------------------------------------------------------

  /// Execute [fn] in a try/catch. Plugin errors are logged, not rethrown.
  void _safeCall(VoidCallback fn, String pluginName, String hookName) {
    try {
      fn();
    } catch (e, stack) {
      debugPrint(
          'ToastKit plugin error [$pluginName.$hookName]: $e\n$stack');
    }
  }
}
