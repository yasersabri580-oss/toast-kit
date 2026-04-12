import 'dart:async';
import 'package:flutter/material.dart';

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

  ToastKit._({
    required GlobalKey<NavigatorState> navigatorKey,
    required ToastConfig config,
    RouterConfig routerConfig = const RouterConfig(),
  })  : _navigatorKey = navigatorKey,
        _config = config,
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

    _subscription = _eventBus.stream.listen(_onEvent);
  }

  // -----------------------------------------------------------------------
  // Initialization
  // -----------------------------------------------------------------------

  /// Initialize the SDK. Must be called once before any other method.
  static void init({
    required GlobalKey<NavigatorState> navigatorKey,
    ToastConfig? config,
    RouterConfig? routerConfig,
  }) {
    _instance?.dispose();
    _instance = ToastKit._(
      navigatorKey: navigatorKey,
      config: config ?? const ToastConfig(),
      routerConfig: routerConfig ?? const RouterConfig(),
    );
  }

  /// The current singleton instance.
  static ToastKit get instance {
    assert(_instance != null, 'ToastKit.init() must be called first.');
    return _instance!;
  }

  // -----------------------------------------------------------------------
  // Simple API (static, no context)
  // -----------------------------------------------------------------------

  /// Show an arbitrary [ToastEvent].
  static void show(ToastEvent event) => instance._eventBus.emit(event);

  /// Show a success toast.
  static void success(String message, {
    String? title,
    Duration? duration,
    ToastPosition? position,
    ToastVariant? variant,
    ToastAnimationType? animation,
  }) {
    show(ToastEvent.success(
      message: message,
      title: title,
      duration: duration,
      position: position,
      variant: variant,
      animation: animation,
    ));
  }

  /// Show an error toast.
  static void error(String message, {
    String? title,
    Duration? duration,
    ToastPosition? position,
    ToastVariant? variant,
    ToastAnimationType? animation,
  }) {
    show(ToastEvent.error(
      message: message,
      title: title,
      duration: duration,
      position: position,
      variant: variant,
      animation: animation,
    ));
  }

  /// Show a warning toast.
  static void warning(String message, {
    String? title,
    Duration? duration,
    ToastPosition? position,
    ToastVariant? variant,
    ToastAnimationType? animation,
  }) {
    show(ToastEvent.warning(
      message: message,
      title: title,
      duration: duration,
      position: position,
      variant: variant,
      animation: animation,
    ));
  }

  /// Show an info toast.
  static void info(String message, {
    String? title,
    Duration? duration,
    ToastPosition? position,
    ToastVariant? variant,
    ToastAnimationType? animation,
  }) {
    show(ToastEvent.info(
      message: message,
      title: title,
      duration: duration,
      position: position,
      variant: variant,
      animation: animation,
    ));
  }

  /// Show a loading toast (persistent, not dismissible by default).
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
  // Management
  // -----------------------------------------------------------------------

  /// Dismiss a specific toast by ID.
  static void dismiss(String id) {
    instance._overlayEngine.removeToast(id, onDismissed: () {
      instance._queueManager.markDismissed(id);
      instance._controllers[id]?.dispose();
      instance._controllers.remove(id);
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
    final decision = _router.route(event);
    switch (decision) {
      case ShowDecision():
        _queueManager.enqueue(event);
        break;
      case QueueDecision():
        _queueManager.enqueue(event);
        break;
      case ReplaceDecision(:final targetId):
        dismiss(targetId);
        _queueManager.enqueue(event);
        break;
      case DropDecision():
      case DeduplicateDecision():
        // Do nothing.
        break;
    }
  }

  void _presentToast(ToastEvent event) {
    final position = event.position ?? _config.defaultPosition;
    final animType = event.animation ?? _config.defaultAnimation;
    final animObj = AnimationFactory.fromType(animType);
    final duration = event.duration ?? _config.defaultDuration;

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
        _queueManager.markDismissed(event.id);
        _controllers[event.id]?.dispose();
        _controllers.remove(event.id);
      },
    );
  }
}
