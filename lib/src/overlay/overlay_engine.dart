// ignore_for_file: unused_element_parameter

import 'dart:async';
import 'package:flutter/material.dart';

import '../core/toast_config.dart';
import '../animation/animation_factory.dart';
import '../layout/toast_position_calculator.dart';

/// Data associated with a single overlay entry.
class _EntryData {

  _EntryData({
    required this.entry,
    required this.position,
    required this.animController,
    this.autoTimer,
    this.isRemoving = false,
  });
  final OverlayEntry entry;
  final ToastPosition position;
  final AnimationController animController;
  Timer? autoTimer;
  bool isRemoving;
}

/// Manages the Flutter [Overlay] to display toast widgets.
///
/// This is the render layer of ToastKit — it knows how to mount, animate,
/// position, and unmount overlay entries without leaking memory.
///
/// **Stability features:**
/// - Duplicate entry guard: calling [showToast] with an ID that already has
///   an active overlay entry is a no-op (prevents stacking duplicates).
/// - Safe removal: [removeToast] is idempotent and guards against double-
///   removal via the [_EntryData.isRemoving] flag.
/// - Resource cleanup: [dispose] cancels all timers and removes all entries
///   synchronously without waiting for exit animations.
class OverlayEngine {

  OverlayEngine({
    required GlobalKey<NavigatorState> navigatorKey,
    required ToastConfig config,
  })  : _navigatorKey = navigatorKey,
        _config = config;
  final GlobalKey<NavigatorState> _navigatorKey;
  ToastConfig _config;

  final Map<String, _EntryData> _entries = <String, _EntryData>{};

  bool _isDisposed = false;

  /// The current toast configuration.
  ToastConfig get config => _config;

  /// Update configuration at runtime.
  void updateConfig(ToastConfig config) {
    _config = config;
  }

  /// Number of currently mounted overlay entries.
  int get activeCount => _entries.length;

  /// IDs of all active toasts.
  Iterable<String> get activeIds => _entries.keys;

  /// Whether an entry for the given [id] is currently mounted.
  bool hasEntry(String id) => _entries.containsKey(id);

  // -----------------------------------------------------------------------
  // Show / Remove
  // -----------------------------------------------------------------------

  /// Mount a toast widget in the overlay. Returns the toast ID.
  ///
  /// If an entry with the same [id] already exists (and is not currently
  /// being removed), this method returns immediately without creating a
  /// duplicate overlay entry.
  String showToast({
    required String id,
    required Widget toastWidget,
    required ToastPosition position,
    required Duration animationDuration,
    required ToastAnimation animation,
    Duration? autoDismiss,
    VoidCallback? onDismissed,
  }) {
    if (_isDisposed) return id;

    // Duplicate guard — prevent overlapping overlays for the same ID.
    if (_entries.containsKey(id) && !_entries[id]!.isRemoving) {
      return id;
    }

    final overlay = _navigatorKey.currentState?.overlay;
    if (overlay == null) {
      // Overlay not yet available — retry on next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isDisposed) return;
        showToast(
          id: id,
          toastWidget: toastWidget,
          position: position,
          animationDuration: animationDuration,
          animation: animation,
          autoDismiss: autoDismiss,
          onDismissed: onDismissed,
        );
      });
      return id;
    }

    // We need a TickerProvider — overlay's context works for this.
    final animController = AnimationController(
      vsync: overlay,
      duration: animationDuration,
    );

    late final OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) {
        final mq = MediaQuery.of(context);
        final alignment = ToastPositionCalculator.toAlignment(position);
        final safePadding =
            _config.safeAreaEnabled
                ? ToastPositionCalculator.calculateSafeAreaPadding(mq, position)
                : EdgeInsets.zero;
        final kbOffset =
            _config.keyboardAvoidance
                ? ToastPositionCalculator.calculateKeyboardOffset(mq, position)
                : 0.0;

        // Calculate stack index for vertical offset.
        final stackIndex = _stackIndexFor(id, position);
        // Use an estimated toast height for stacking. This is approximate;
        // actual heights vary by variant. A more advanced implementation
        // would measure widgets after layout.
        const double estimatedToastHeight = 64.0;
        final stackOffset = ToastPositionCalculator.calculateStackOffset(
          stackIndex,
          _config.toastSpacing,
          toastHeight: estimatedToastHeight,
        );

        final isTop = position == ToastPosition.top ||
            position == ToastPosition.topLeft ||
            position == ToastPosition.topRight;

        return Positioned(
          left: 0,
          right: 0,
          top: isTop ? safePadding.top + stackOffset : null,
          bottom: !isTop ? safePadding.bottom + kbOffset + stackOffset : null,
          child: Align(
            alignment: alignment,
            child: animation.buildEnterAnimation(
              toastWidget,
              animController,
            ),
          ),
        );
      },
    );

    final data = _EntryData(
      entry: overlayEntry,
      position: position,
      animController: animController,
    );

    _entries[id] = data;
    overlay.insert(overlayEntry);
    animController.forward();

    // Auto-dismiss timer.
    if (autoDismiss != null) {
      data.autoTimer = Timer(autoDismiss, () {
        removeToast(id, onDismissed: onDismissed);
      });
    }

    return id;
  }

  /// Remove a toast with an exit animation.
  ///
  /// This method is idempotent — calling it on an already-removing or
  /// non-existent toast is safe and has no effect.
  void removeToast(String id, {VoidCallback? onDismissed}) {
    final data = _entries[id];
    if (data == null || data.isRemoving) return;
    data.isRemoving = true;
    data.autoTimer?.cancel();

    data.animController.reverse().then((_) {
      _safeRemoveEntry(id, data);
      onDismissed?.call();
    });
  }

  /// Pause the auto-dismiss timer for a toast.
  void pauseTimer(String id) {
    _entries[id]?.autoTimer?.cancel();
  }

  /// Resume (restart) the auto-dismiss timer.
  void resumeTimer(String id, Duration remaining, {VoidCallback? onExpired}) {
    final data = _entries[id];
    if (data == null || data.isRemoving) return;
    data.autoTimer?.cancel();
    data.autoTimer = Timer(remaining, () {
      onExpired?.call();
    });
  }

  /// Remove all visible toasts immediately.
  void removeAll() {
    for (final id in _entries.keys.toList()) {
      removeToast(id);
    }
  }

  /// Release all resources.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    for (final data in _entries.values) {
      data.autoTimer?.cancel();
      data.entry.remove();
      data.animController.dispose();
    }
    _entries.clear();
  }

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  /// Safely remove a single overlay entry and clean up its resources.
  void _safeRemoveEntry(String id, _EntryData data) {
    try {
      data.entry.remove();
    } catch (_) {
      // Entry may already have been removed (e.g. by dispose).
    }
    try {
      data.animController.dispose();
    } catch (_) {
      // Controller may already have been disposed.
    }
    _entries.remove(id);
  }

  int _stackIndexFor(String id, ToastPosition position) {
    int idx = 0;
    for (final entry in _entries.entries) {
      if (entry.key == id) return idx;
      if (entry.value.position == position) idx++;
    }
    return idx;
  }
}
