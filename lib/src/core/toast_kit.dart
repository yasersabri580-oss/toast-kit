import 'dart:async';
import 'package:flutter/material.dart' hide RouterConfig;

import 'toast_config.dart';
import '../events/toast_event.dart';
import '../events/event_bus.dart';
import '../queue/queue_manager.dart';
import '../router/notification_router.dart';
import '../router/router_config.dart';
import '../overlay/overlay_engine.dart';
import '../animation/animation_factory.dart';
import '../gestures/toast_gesture_handler.dart';
import '../variants/variant_factory.dart';
import '../channels/toast_channel.dart';
import '../channels/channel_config.dart';
import '../channels/channel_manager.dart';
import '../persistence/toast_persistence.dart';
import '../stacking/group_collapser.dart';
import '../plugins/toast_plugin.dart';
import '../plugins/plugin_hub.dart';
import '../analytics/toast_telemetry_event.dart';
import '../rules/rule_config.dart';
import '../rules/toast_rule.dart';
import '../rules/rule_engine.dart';

/// The main entry point for the ToastKit SDK.
///
/// ```dart
/// final navigatorKey = GlobalKey<NavigatorState>();
///
/// // In your MaterialApp
/// MaterialApp(navigatorKey: navigatorKey, home: MyApp());
///
/// // Initialize once
/// ToastKit.init(navigatorKey: navigatorKey);
///
/// // Show toasts anywhere — no BuildContext required
/// ToastKit.success('Saved!');
/// ToastKit.error('Network failed');
///
/// // Stateful loading → success pattern
/// final ctrl = ToastKit.showLoading('Saving…');
/// try {
///   await saveData();
///   ctrl.success('Saved!');
/// } catch (_) {
///   ctrl.error('Save failed');
/// }
/// ```
class ToastKit {
  static ToastKit? _instance;

  final GlobalKey<NavigatorState> _navigatorKey;
  ToastConfig _config;
  final EventBus _eventBus;
  late final QueueManager _queueManager;
  late final NotificationRouter _router;
  late final OverlayEngine _overlayEngine;
  StreamSubscription<ToastEvent>? _subscription;

  final Map<String, ToastController> _controllers = {};
  final ChannelRegistry _channelRegistry = ChannelRegistry();
  final ChannelManager _channelManager = ChannelManager();
  final PluginHub _pluginHub = PluginHub();
  final RuleEngine _ruleEngine = RuleEngine();
  ToastPersistence? _persistence;
  late final GroupCollapser _groupCollapser;

  ToastKit._({
    required GlobalKey<NavigatorState> navigatorKey,
    required ToastConfig config,
    RouterConfig routerConfig = const RouterConfig(),
    ToastPersistence? persistence,
    List<ToastChannel>? channels,
    List<ToastPlugin>? plugins,
  })  : _navigatorKey = navigatorKey,
        _config = config,
        _persistence = persistence,
        _eventBus = EventBus() {
    _overlayEngine = OverlayEngine(
      navigatorKey: _navigatorKey,
      config: _config,
    );
    _queueManager = QueueManager(
      config: _config,
      onReadyToShow: _presentToast,
    );
    _router = NotificationRouter(
      queueManager: _queueManager,
      config: routerConfig,
    );
    _groupCollapser = GroupCollapser();

    // Register pre-defined channels.
    if (channels != null) {
      for (final ch in channels) {
        _channelRegistry.register(ch);
        _channelManager.register(ch);
      }
    }

    // Register plugins.
    if (plugins != null) {
      for (final plugin in plugins) {
        _pluginHub.register(plugin);
      }
    }

    // Wire rule engine callback to plugin hub.
    _ruleEngine.onRuleTriggered = (ruleId, channel) {
      _pluginHub.notifyRuleTriggered(ruleId, channel);
    };

    _subscription = _eventBus.stream.listen(_onEvent);
  }

  // -----------------------------------------------------------------------
  // Initialization
  // -----------------------------------------------------------------------

  /// Initialize the SDK. Must be called once before any other method.
  ///
  /// Optionally accepts a [persistence] adapter for critical toast storage,
  /// a list of [channels] for category-based policies, and a list of
  /// [plugins] for analytics, telemetry, and lifecycle observation.
  static void init({
    required GlobalKey<NavigatorState> navigatorKey,
    ToastConfig? config,
    RouterConfig? routerConfig,
    ToastPersistence? persistence,
    List<ToastChannel>? channels,
    List<ToastPlugin>? plugins,
  }) {
    ToastKit.dispose();
    _instance = ToastKit._(
      navigatorKey: navigatorKey,
      config: config ?? const ToastConfig(),
      routerConfig: routerConfig ?? const RouterConfig(),
      persistence: persistence,
      channels: channels,
      plugins: plugins,
    );
  }

  /// The current singleton instance.
  static ToastKit get instance {
    assert(_instance != null, 'ToastKit.init() must be called first.');
    return _instance!;
  }

  /// Whether the SDK has been initialized.
  static bool get isInitialized => _instance != null;

  // -----------------------------------------------------------------------
  // Simple API (static, no context)
  // -----------------------------------------------------------------------

  /// Show an arbitrary [ToastEvent].
  static void show(ToastEvent event) => instance._eventBus.emit(event);

  /// Show an arbitrary [ToastEvent] and return its [ToastController].
  ///
  /// This is useful for stateful toasts where you need to update the
  /// displayed message, state, or progress after creation.
  static ToastController showWithController(ToastEvent event) {
    final inst = instance;
    inst._eventBus.emit(event);
    // The controller is created in _presentToast. Return it (or a deferred
    // version if the event goes through the queue first).
    return inst._getOrCreateDeferredController(event);
  }

  /// Show a success toast.
  static void success(String message, {
    String? title,
    Duration? duration,
    ToastPosition? position,
    ToastVariant? variant,
    ToastAnimationType? animation,
    String? channel,
  }) {
    show(ToastEvent.success(
      message: message,
      title: title,
      duration: duration,
      position: position,
      variant: variant,
      animation: animation,
      channel: channel,
    ));
  }

  /// Show an error toast.
  static void error(String message, {
    String? title,
    Duration? duration,
    ToastPosition? position,
    ToastVariant? variant,
    ToastAnimationType? animation,
    String? channel,
  }) {
    show(ToastEvent.error(
      message: message,
      title: title,
      duration: duration,
      position: position,
      variant: variant,
      animation: animation,
      channel: channel,
    ));
  }

  /// Show a warning toast.
  static void warning(String message, {
    String? title,
    Duration? duration,
    ToastPosition? position,
    ToastVariant? variant,
    ToastAnimationType? animation,
    String? channel,
  }) {
    show(ToastEvent.warning(
      message: message,
      title: title,
      duration: duration,
      position: position,
      variant: variant,
      animation: animation,
      channel: channel,
    ));
  }

  /// Show an info toast.
  static void info(String message, {
    String? title,
    Duration? duration,
    ToastPosition? position,
    ToastVariant? variant,
    ToastAnimationType? animation,
    String? channel,
  }) {
    show(ToastEvent.info(
      message: message,
      title: title,
      duration: duration,
      position: position,
      variant: variant,
      animation: animation,
      channel: channel,
    ));
  }

  /// Show a loading toast and return its [ToastController].
  ///
  /// The returned controller can transition the toast to a new state:
  ///
  /// ```dart
  /// final ctrl = ToastKit.showLoading('Saving…');
  /// try {
  ///   await saveData();
  ///   ctrl.success('Saved!');
  /// } catch (_) {
  ///   ctrl.error('Save failed');
  /// }
  /// ```
  static ToastController showLoading(String message, {
    Duration? duration,
    ToastPosition? position,
    String? channel,
  }) {
    final event = ToastEvent.loading(
      message: message,
      duration: duration,
      position: position,
      channel: channel,
    );
    return showWithController(event);
  }

  /// Show a loading toast (persistent, not dismissible by default).
  ///
  /// For a version that returns a [ToastController], use [showLoading].
  static void loading(String message, {
    Duration? duration,
    ToastPosition? position,
  }) {
    show(ToastEvent.loading(message: message, duration: duration, position: position));
  }

  /// Show a toast with a fully custom builder.
  static void custom({
    required Widget Function(BuildContext, ToastController) builder,
    Duration? duration,
    ToastPosition? position,
  }) {
    show(ToastEvent.custom(builder: builder, duration: duration, position: position));
  }

  // -----------------------------------------------------------------------
  // Channels
  // -----------------------------------------------------------------------

  /// Register a [ToastChannel] for category-based policies.
  ///
  /// Optionally accepts a [ChannelConfig] for per-channel queue/display
  /// policies. Re-registering the same channel ID replaces the previous
  /// registration (idempotent override).
  static void registerChannel(ToastChannel channel, {ChannelConfig? config}) {
    final inst = instance;
    inst._channelRegistry.register(channel);
    inst._channelManager.register(channel, config: config);
    inst._pluginHub.notifyChannelRegistered(channel.id);
  }

  /// Unregister a channel by id.
  static void unregisterChannel(String channelId) {
    final inst = instance;
    inst._channelRegistry.unregister(channelId);
    inst._channelManager.unregister(channelId);
  }

  /// The channel registry (legacy API).
  static ChannelRegistry get channelRegistry => instance._channelRegistry;

  /// The channel manager.
  static ChannelManager get channelManager => instance._channelManager;

  /// Get a fluent [ChannelHandle] for emitting toasts on a specific channel.
  ///
  /// ```dart
  /// ToastKit.channel("payment").error("Payment failed");
  /// ```
  static ChannelHandle channel(String channelName) {
    return ChannelHandle(channelName, (event) => show(event));
  }

  // -----------------------------------------------------------------------
  // Plugins
  // -----------------------------------------------------------------------

  /// Configure ToastKit with plugins after initialization.
  ///
  /// ```dart
  /// ToastKit.configure(
  ///   plugins: [
  ///     FirebaseToastAnalyticsPlugin(logEvent: analytics.logEvent),
  ///   ],
  /// );
  /// ```
  static void configure({List<ToastPlugin>? plugins}) {
    final inst = instance;
    if (plugins != null) {
      for (final plugin in plugins) {
        inst._pluginHub.register(plugin);
      }
    }
  }

  /// Register a single plugin.
  static void registerPlugin(ToastPlugin plugin) {
    instance._pluginHub.register(plugin);
  }

  /// Unregister a plugin by name.
  static void unregisterPlugin(String name) {
    instance._pluginHub.unregister(name);
  }

  /// The plugin hub.
  static PluginHub get pluginHub => instance._pluginHub;

  // -----------------------------------------------------------------------
  // Rules
  // -----------------------------------------------------------------------

  /// Configure a simple threshold-based rule for a channel.
  ///
  /// ```dart
  /// ToastKit.configureRule(
  ///   "payment",
  ///   RuleConfig(
  ///     errorThreshold: 10,
  ///     deduplicateWindow: Duration(seconds: 30),
  ///     maxTriggers: 1,
  ///   ),
  /// );
  /// ```
  static void configureRule(String channel, RuleConfig config) {
    instance._ruleEngine.configureRule(channel, config);
  }

  /// Add a custom smart rule.
  ///
  /// ```dart
  /// ToastKit.addRule(
  ///   ToastRule(
  ///     id: "payment-help",
  ///     channel: "payment",
  ///     condition: (stats, event) => stats.errorCount >= 10,
  ///     action: (context) { /* show help */ },
  ///   ),
  /// );
  /// ```
  static void addRule(ToastRule rule) {
    instance._ruleEngine.addRule(rule);
  }

  /// Remove a custom rule by ID.
  static void removeRule(String ruleId) {
    instance._ruleEngine.removeRule(ruleId);
  }

  /// The rule engine.
  static RuleEngine get ruleEngine => instance._ruleEngine;

  // -----------------------------------------------------------------------
  // Persistence
  // -----------------------------------------------------------------------

  /// Restore persisted critical toasts and re-display them.
  static Future<void> restorePersistedToasts() async {
    final inst = instance;
    if (inst._persistence == null) return;
    final pending = await inst._persistence!.loadPending();
    for (final event in pending) {
      inst._eventBus.emit(event);
    }
  }

  // -----------------------------------------------------------------------
  // Management
  // -----------------------------------------------------------------------

  /// Look up the [ToastController] for an active toast by ID.
  static ToastController? controllerFor(String id) =>
      instance._controllers[id];

  /// Dismiss a specific toast by ID.
  static void dismiss(String id) {
    final inst = instance;
    final event = inst._queueManager.visibleEvents
        .cast<ToastEvent?>()
        .firstWhere((e) => e?.id == id, orElse: () => null);
    inst._overlayEngine.removeToast(id, onDismissed: () {
      if (event != null) {
        inst._pluginHub.notifyToastDismissed(event, DismissReason.programmatic);
      }
      if (event?.channel != null) {
        inst._channelRegistry.markDismissed(event!.channel!);
        inst._channelManager.markDismissed(event.channel!);
        inst._ruleEngine.recordDismissed(event.channel!);
      }
      inst._queueManager.markDismissed(id);
      inst._controllers[id]?.dispose();
      inst._controllers.remove(id);
      inst._persistence?.remove(id);
    });
  }

  /// Dismiss all visible toasts.
  static void dismissAll() {
    for (final id in instance._overlayEngine.activeIds.toList()) {
      dismiss(id);
    }
  }

  /// Broadcast stream of all events.
  static Stream<ToastEvent> get eventStream => instance._eventBus.stream;

  /// Release all resources.
  static void dispose() {
    final inst = _instance;
    if (inst == null) return;
    inst._subscription?.cancel();
    inst._overlayEngine.dispose();
    inst._queueManager.dispose();
    inst._eventBus.dispose();
    inst._groupCollapser.clear();
    inst._channelRegistry.clear();
    inst._channelManager.clear();
    inst._pluginHub.dispose();
    inst._ruleEngine.clear();
    for (final c in inst._controllers.values) {
      c.dispose();
    }
    inst._controllers.clear();
    _instance = null;
  }

  // -----------------------------------------------------------------------
  // Internal pipeline
  // -----------------------------------------------------------------------

  void _onEvent(ToastEvent event) {
    // Record event in rule engine stats.
    _ruleEngine.recordEvent(event);

    // Channel policy check.
    if (event.channel != null) {
      final channel = _channelRegistry[event.channel!];
      if (channel != null && !channel.enabled) return;
      if (channel != null && _channelRegistry.isChannelFull(event.channel!)) {
        return;
      }
      // Also check new channel manager.
      if (_channelManager.isChannelFull(event.channel!)) {
        _pluginHub.notifyToastDropped(event, 'Channel full');
        _ruleEngine.recordDropped(event.channel!);
        return;
      }
    }

    final decision = _router.route(event);
    switch (decision) {
      case ShowDecision():
        _pluginHub.notifyToastQueued(event);
        _queueManager.enqueue(event);
        break;
      case QueueDecision():
        _pluginHub.notifyToastQueued(event);
        _queueManager.enqueue(event);
        break;
      case ReplaceDecision(:final targetId):
        _pluginHub.notifyToastReplaced(event, targetId);
        dismiss(targetId);
        _queueManager.enqueue(event);
        break;
      case DropDecision(:final reason):
        _pluginHub.notifyToastDropped(event, reason);
        _ruleEngine.recordDropped(event.channel ?? 'default');
        break;
      case DeduplicateDecision():
        _pluginHub.notifyToastDropped(event, 'Deduplicated');
        break;
    }

    // Evaluate rules after processing the event.
    _ruleEngine.evaluate(event);

    // Persist critical / persistent events.
    if (event.persistent && _persistence != null) {
      _persistence!.save(event);
    }
  }

  void _presentToast(ToastEvent event) {
    final position = event.position ?? _config.defaultPosition;
    final animType = event.animation ?? _config.defaultAnimation;
    final animObj = AnimationFactory.fromType(animType);
    final duration = event.duration ?? _config.defaultDuration;

    // Track channel usage.
    if (event.channel != null) {
      _channelRegistry.markActive(event.channel!);
      _channelManager.markActive(event.channel!);
    }

    // Notify plugins that toast is shown.
    _pluginHub.notifyToastShown(event);

    final controller = ToastController(
      id: event.id,
      dismiss: () => dismiss(event.id),
      pause: () => _overlayEngine.pauseTimer(event.id),
      resume: () => _overlayEngine.resumeTimer(
        event.id,
        duration,
        onExpired: () => dismiss(event.id),
      ),
      initialMessage: event.message ?? '',
      initialState: _toastTypeToState(event.type),
      initialIcon: event.icon,
    );
    _controllers[event.id] = controller;

    // Build the variant widget.
    Widget toastWidget;
    if (event.customBuilder != null) {
      toastWidget = Builder(
        builder: (ctx) => event.customBuilder!(ctx, controller),
      );
    } else {
      final variant = event.variant ??
          VariantFactory.defaultVariantForType(event.type);
      toastWidget = Builder(
        builder: (ctx) => VariantFactory.build(variant, event, controller),
      );
    }

    // Wrap with gesture handler.
    toastWidget = ToastGestureHandler(
      onTap: event.onTap,
      onSwipeDismiss: event.dismissible ? () => dismiss(event.id) : null,
      enableSwipeDismiss: event.dismissible,
      onPauseTimer: controller.pause,
      onResumeTimer: controller.resume,
      child: toastWidget,
    );

    _overlayEngine.showToast(
      id: event.id,
      toastWidget: toastWidget,
      position: position,
      animationDuration: _config.defaultAnimationDuration,
      animation: animObj,
      autoDismiss: event.persistent ? null : duration,
      onDismissed: () {
        event.onDismiss?.call();
        _pluginHub.notifyToastDismissed(event, DismissReason.timeout);
        if (event.channel != null) {
          _channelRegistry.markDismissed(event.channel!);
          _channelManager.markDismissed(event.channel!);
          _ruleEngine.recordDismissed(event.channel!);
        }
        _queueManager.markDismissed(event.id);
        _controllers[event.id]?.dispose();
        _controllers.remove(event.id);
        _persistence?.remove(event.id);
      },
    );
  }

  /// Convert a [ToastType] to the corresponding [ToastState].
  static ToastState _toastTypeToState(ToastType type) {
    switch (type) {
      case ToastType.success:
        return ToastState.success;
      case ToastType.error:
        return ToastState.error;
      case ToastType.warning:
        return ToastState.warning;
      case ToastType.info:
        return ToastState.info;
      case ToastType.loading:
        return ToastState.loading;
      case ToastType.custom:
        return ToastState.custom;
    }
  }

  /// Get or create a deferred controller for events that may be queued.
  ToastController _getOrCreateDeferredController(ToastEvent event) {
    // If the controller was already created (event was shown immediately),
    // return it.
    final existing = _controllers[event.id];
    if (existing != null) return existing;

    // Create a deferred controller that will be wired up when the event
    // is actually presented.
    final controller = ToastController(
      id: event.id,
      dismiss: () => dismiss(event.id),
      pause: () => _overlayEngine.pauseTimer(event.id),
      resume: () => _overlayEngine.resumeTimer(
        event.id,
        event.duration ?? _config.defaultDuration,
        onExpired: () => dismiss(event.id),
      ),
      initialMessage: event.message ?? '',
      initialState: _toastTypeToState(event.type),
      initialIcon: event.icon,
    );
    _controllers[event.id] = controller;
    return controller;
  }
}
