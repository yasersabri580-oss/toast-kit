import 'package:flutter/material.dart';
import '../core/toast_config.dart';

// ---------------------------------------------------------------------------
// ID generation
// ---------------------------------------------------------------------------

int _idCounter = 0;

/// Generates a unique ID without external packages.
String _generateId() {
  _idCounter++;
  return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-'
      '${_idCounter.toRadixString(36)}';
}

/// An action button attached to a toast.
@immutable
class ToastAction {

  /// Creates a [ToastAction].
  const ToastAction({
    required this.label,
    required this.onPressed,
    this.color,
  });
  /// Button label text.
  final String label;

  /// Callback invoked when the button is pressed.
  final VoidCallback onPressed;

  /// Optional colour override for the button.
  final Color? color;
}

/// Represents a notification event in the ToastKit system.
///
/// This is the fundamental unit of communication. Everything in ToastKit
/// is event-driven — callers emit [ToastEvent]s and the SDK pipeline
/// (router → queue → overlay) decides how they are rendered.
@immutable
class ToastEvent {

  /// Creates a [ToastEvent].
  ///
  /// ## Rendering Precedence
  ///
  /// When multiple rendering strategies are specified, they are resolved
  /// in the following order (highest priority first):
  ///
  /// 1. **[customBuilder]** — a one-off builder function; always wins.
  /// 2. **[customVariantName]** — a named [CustomToastVariantBuilder]
  ///    registered via [ToastKit.registerVariant].
  /// 3. **Channel's `customVariantName`** — inherited from the channel.
  /// 4. **[variant]** — a built-in [ToastVariant] enum value.
  /// 5. **Channel's `defaultVariant`** — inherited from the channel.
  /// 6. **Default for [type]** — determined by [VariantFactory.defaultVariantForType].
  ToastEvent({
    String? id,
    required this.type,
    this.message,
    this.title,
    this.icon,
    this.iconColor,
    this.duration,
    this.position,
    this.animation,
    this.priority = ToastPriority.normal,
    this.deduplicationKey,
    this.metadata,
    this.onTap,
    this.onDismiss,
    this.actions,
    this.customBuilder,
    this.variant,
    this.customVariantName,
    this.persistent = false,
    this.dismissible = true,
    this.channel,
    DateTime? createdAt,
  })  : id = id ?? _generateId(),
        createdAt = createdAt ?? DateTime.now();

  // -----------------------------------------------------------------------
  // Convenience factories
  // -----------------------------------------------------------------------

  /// Creates a success toast.
  factory ToastEvent.success({
    required String message,
    String? title,
    IconData? icon,
    Duration? duration,
    ToastPosition? position,
    ToastAnimationType? animation,
    ToastPriority priority = ToastPriority.normal,
    String? deduplicationKey,
    ToastVariant? variant,
    String? customVariantName,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
    List<ToastAction>? actions,
    bool persistent = false,
    bool dismissible = true,
    String? channel,
  }) {
    return ToastEvent(
      type: ToastType.success,
      message: message,
      title: title,
      icon: icon ?? Icons.check_circle_rounded,
      duration: duration,
      position: position,
      animation: animation,
      priority: priority,
      deduplicationKey: deduplicationKey,
      variant: variant,
      customVariantName: customVariantName,
      onTap: onTap,
      onDismiss: onDismiss,
      actions: actions,
      persistent: persistent,
      dismissible: dismissible,
      channel: channel,
    );
  }

  /// Creates an error toast.
  factory ToastEvent.error({
    required String message,
    String? title,
    IconData? icon,
    Duration? duration,
    ToastPosition? position,
    ToastAnimationType? animation,
    ToastPriority priority = ToastPriority.normal,
    String? deduplicationKey,
    ToastVariant? variant,
    String? customVariantName,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
    List<ToastAction>? actions,
    bool persistent = false,
    bool dismissible = true,
    String? channel,
  }) {
    return ToastEvent(
      type: ToastType.error,
      message: message,
      title: title,
      icon: icon ?? Icons.error_rounded,
      duration: duration,
      position: position,
      animation: animation,
      priority: priority,
      deduplicationKey: deduplicationKey,
      variant: variant,
      customVariantName: customVariantName,
      onTap: onTap,
      onDismiss: onDismiss,
      actions: actions,
      persistent: persistent,
      dismissible: dismissible,
      channel: channel,
    );
  }

  /// Creates a warning toast.
  factory ToastEvent.warning({
    required String message,
    String? title,
    IconData? icon,
    Duration? duration,
    ToastPosition? position,
    ToastAnimationType? animation,
    ToastPriority priority = ToastPriority.normal,
    String? deduplicationKey,
    ToastVariant? variant,
    String? customVariantName,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
    List<ToastAction>? actions,
    bool persistent = false,
    bool dismissible = true,
    String? channel,
  }) {
    return ToastEvent(
      type: ToastType.warning,
      message: message,
      title: title,
      icon: icon ?? Icons.warning_rounded,
      duration: duration,
      position: position,
      animation: animation,
      priority: priority,
      deduplicationKey: deduplicationKey,
      variant: variant,
      customVariantName: customVariantName,
      onTap: onTap,
      onDismiss: onDismiss,
      actions: actions,
      persistent: persistent,
      dismissible: dismissible,
      channel: channel,
    );
  }

  /// Creates an info toast.
  factory ToastEvent.info({
    required String message,
    String? title,
    IconData? icon,
    Duration? duration,
    ToastPosition? position,
    ToastAnimationType? animation,
    ToastPriority priority = ToastPriority.normal,
    String? deduplicationKey,
    ToastVariant? variant,
    String? customVariantName,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
    List<ToastAction>? actions,
    bool persistent = false,
    bool dismissible = true,
    String? channel,
  }) {
    return ToastEvent(
      type: ToastType.info,
      message: message,
      title: title,
      icon: icon ?? Icons.info_rounded,
      duration: duration,
      position: position,
      animation: animation,
      priority: priority,
      deduplicationKey: deduplicationKey,
      variant: variant,
      customVariantName: customVariantName,
      onTap: onTap,
      onDismiss: onDismiss,
      actions: actions,
      persistent: persistent,
      dismissible: dismissible,
      channel: channel,
    );
  }

  /// Creates a loading toast (persistent by default).
  factory ToastEvent.loading({
    required String message,
    String? title,
    Duration? duration,
    ToastPosition? position,
    ToastAnimationType? animation,
    ToastPriority priority = ToastPriority.normal,
    String? deduplicationKey,
    ToastVariant? variant,
    String? customVariantName,
    VoidCallback? onDismiss,
    bool persistent = true,
    bool dismissible = false,
    String? channel,
  }) {
    return ToastEvent(
      type: ToastType.loading,
      message: message,
      title: title,
      icon: Icons.hourglass_empty_rounded,
      duration: duration,
      position: position,
      animation: animation,
      priority: priority,
      deduplicationKey: deduplicationKey,
      variant: variant ?? ToastVariant.loading,
      customVariantName: customVariantName,
      onDismiss: onDismiss,
      persistent: persistent,
      dismissible: dismissible,
      channel: channel,
    );
  }

  /// Creates a toast with a fully custom builder.
  factory ToastEvent.custom({
    required Widget Function(BuildContext, ToastController) builder,
    Duration? duration,
    ToastPosition? position,
    ToastAnimationType? animation,
    ToastPriority priority = ToastPriority.normal,
    String? deduplicationKey,
    VoidCallback? onDismiss,
    bool persistent = false,
    bool dismissible = true,
    String? channel,
  }) {
    return ToastEvent(
      // ignore: deprecated_member_use_from_same_package
      type: ToastType.custom,
      customBuilder: builder,
      duration: duration,
      position: position,
      animation: animation,
      priority: priority,
      deduplicationKey: deduplicationKey,
      variant: ToastVariant.customBuilder,
      onDismiss: onDismiss,
      persistent: persistent,
      dismissible: dismissible,
      channel: channel,
    );
  }
  /// Unique identifier (auto-generated).
  final String id;

  /// Semantic type of this notification.
  final ToastType type;

  /// Primary text content.
  final String? message;

  /// Optional title displayed above the message.
  final String? title;

  /// Leading icon.
  final IconData? icon;

  /// Colour override for the icon.
  final Color? iconColor;

  /// Auto-dismiss duration (overrides global default).
  final Duration? duration;

  /// Screen position (overrides global default).
  final ToastPosition? position;

  /// Enter / exit animation type (overrides global default).
  final ToastAnimationType? animation;

  /// Queue priority.
  final ToastPriority priority;

  /// Key used for deduplication – events with the same key are coalesced.
  final String? deduplicationKey;

  /// Arbitrary metadata bag.
  final Map<String, dynamic>? metadata;

  /// Tap callback.
  final VoidCallback? onTap;

  /// Callback invoked after the toast is dismissed.
  final VoidCallback? onDismiss;

  /// Action buttons.
  final List<ToastAction>? actions;

  /// Fully custom builder (overrides variant rendering).
  ///
  /// **Precedence:** This always takes the highest priority. If set, neither
  /// [variant] nor [customVariantName] are used for rendering.
  final Widget Function(BuildContext, ToastController)? customBuilder;

  /// Visual variant preset.
  final ToastVariant? variant;

  /// Name of a registered [CustomToastVariantBuilder] to use for rendering.
  ///
  /// Takes precedence over [variant] but is overridden by [customBuilder].
  /// The named variant must be registered via [ToastKit.registerVariant]
  /// before the toast is displayed.
  final String? customVariantName;

  /// When this event was created.
  final DateTime createdAt;

  /// If `true` the toast will NOT auto-dismiss.
  final bool persistent;

  /// If `true` the user can swipe / tap to dismiss.
  final bool dismissible;

  /// Optional channel ID for category-based policies.
  final String? channel;

  @override
  String toString() => 'ToastEvent(id: $id, type: $type, message: $message)';
}

/// Controller for an individual toast's lifecycle.
///
/// Provided to custom builders so they can interact with their own toast.
/// The controller is **stateful** — it can transition between [ToastState]
/// values, allowing patterns like loading → success or loading → error.
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
class ToastController {

  /// Creates a [ToastController].
  ToastController({
    required this.id,
    required VoidCallback dismiss,
    required VoidCallback pause,
    required VoidCallback resume,
    String initialMessage = '',
    ToastState initialState = ToastState.idle,
    IconData? initialIcon,
  })  : _dismiss = dismiss,
        _pause = pause,
        _resume = resume,
        progress = ValueNotifier<double>(0.0),
        messageNotifier = ValueNotifier<String>(initialMessage),
        stateNotifier = ValueNotifier<ToastState>(initialState),
        iconNotifier = ValueNotifier<IconData?>(initialIcon);
  /// Unique toast identifier.
  final String id;

  /// Dismiss this toast immediately.
  final VoidCallback _dismiss;

  /// Pause the auto-dismiss timer.
  final VoidCallback _pause;

  /// Resume the auto-dismiss timer.
  final VoidCallback _resume;

  /// Progress value notifier (0.0 – 1.0) for progress-type toasts.
  final ValueNotifier<double> progress;

  /// Message notifier – update to change the displayed message.
  final ValueNotifier<String> messageNotifier;

  /// Current lifecycle state of the toast.
  final ValueNotifier<ToastState> stateNotifier;

  /// Icon notifier – update to change the displayed icon.
  final ValueNotifier<IconData?> iconNotifier;

  /// Whether this controller has been disposed.
  bool _isDisposed = false;

  /// Whether this controller has been disposed.
  bool get isDisposed => _isDisposed;

  /// Current lifecycle state.
  ToastState get state => stateNotifier.value;

  /// Dismiss this toast.
  void dismiss() => _dismiss();

  /// Pause the auto-dismiss timer.
  void pause() => _pause();

  /// Resume the auto-dismiss timer.
  void resume() => _resume();

  /// Update progress, message, state, and/or icon.
  void update({
    String? message,
    double? progressValue,
    ToastState? state,
    IconData? icon,
  }) {
    if (_isDisposed) return;
    if (progressValue != null) {
      progress.value = progressValue.clamp(0.0, 1.0);
    }
    if (message != null) {
      messageNotifier.value = message;
    }
    if (state != null) {
      stateNotifier.value = state;
    }
    if (icon != null) {
      iconNotifier.value = icon;
    }
  }

  /// Transition to [ToastState.success] with the given [message].
  void success(String message, {IconData? icon}) {
    update(
      message: message,
      state: ToastState.success,
      icon: icon ?? Icons.check_circle_rounded,
    );
  }

  /// Transition to [ToastState.error] with the given [message].
  void error(String message, {IconData? icon}) {
    update(
      message: message,
      state: ToastState.error,
      icon: icon ?? Icons.error_rounded,
    );
  }

  /// Transition to [ToastState.warning] with the given [message].
  void warning(String message, {IconData? icon}) {
    update(
      message: message,
      state: ToastState.warning,
      icon: icon ?? Icons.warning_rounded,
    );
  }

  /// Transition to [ToastState.info] with the given [message].
  void info(String message, {IconData? icon}) {
    update(
      message: message,
      state: ToastState.info,
      icon: icon ?? Icons.info_rounded,
    );
  }

  /// Release resources held by this controller.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    progress.dispose();
    messageNotifier.dispose();
    stateNotifier.dispose();
    iconNotifier.dispose();
  }
}
