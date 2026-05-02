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
    required this.spacing,
    this.autoTimer,
    this.isRemoving = false,
  });
  final OverlayEntry entry;
  final ToastPosition position;
  final AnimationController animController;
  final double spacing;
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
  ///
  /// If the existing entry is in the process of being removed
  /// ([_EntryData.isRemoving] is `true`), it is force-cleaned synchronously
  /// before creating the new entry.  This prevents the old removal callback
  /// from inadvertently removing the **new** entry from [_entries].
  String showToast({
    required String id,
    required Widget toastWidget,
    required ToastPosition position,
    required Duration animationDuration,
    required ToastAnimation animation,
    double spacing = 8.0,
    Duration? autoDismiss,
    VoidCallback? onDismissed,
  }) {
    if (_isDisposed) return id;

    // Duplicate guard — prevent overlapping overlays for the same ID.
    final existing = _entries[id];
    if (existing != null) {
      if (!existing.isRemoving) {
        return id;
      }
      // The old entry is animating out.  Force-cleanup synchronously so the
      // deferred removal callback cannot interfere with the new entry.
      _forceCleanupEntry(id, existing);
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
          spacing: spacing,
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

        // Calculate cumulative stack offset using per-entry spacing.
        final stackOffset = _stackOffsetFor(id, position);

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
            child: DefaultTextStyle(
              style: const TextStyle(
                decoration: TextDecoration.none,
              ),
              child: animation.buildEnterAnimation(
                toastWidget,
                animController,
              ),
            ),
          ),
        );
      },
    );

    final data = _EntryData(
      entry: overlayEntry,
      position: position,
      animController: animController,
      spacing: spacing,
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
  ///
  /// Only removes [id] from [_entries] when the stored value is still
  /// [data].  A newer entry may have replaced [data] while the exit
  /// animation was running; removing the newer entry would leak it.
  void _safeRemoveEntry(String id, _EntryData data) {
    try {
      data.entry.remove();
    } catch (e) {
      debugPrint('ToastKit: overlay entry removal failed for "$id": $e');
    }
    try {
      data.animController.dispose();
    } catch (e) {
      debugPrint('ToastKit: animation controller dispose failed for "$id": $e');
    }
    // Only remove from the map if this is still the current entry.
    if (identical(_entries[id], data)) {
      _entries.remove(id);
    }
  }

  /// Synchronously tear down an entry that is currently animating out.
  ///
  /// Used by [showToast] when it needs to reclaim an ID whose previous
  /// entry is mid-removal.  The overlay entry and animation controller are
  /// disposed immediately so no deferred callback can leak them.
  void _forceCleanupEntry(String id, _EntryData data) {
    data.autoTimer?.cancel();
    try {
      data.entry.remove();
    } catch (_) {}
    try {
      data.animController.dispose();
    } catch (_) {}
    _entries.remove(id);
  }

  /// Computes the cumulative vertical offset (in logical pixels) for [id]
  /// at the given [position] by summing spacing and estimated heights for
  /// all preceding entries at the same position.
  ///
  /// Each entry contributes its own [_EntryData.spacing] plus the estimated
  /// toast height (64 logical pixels) to the total.  This allows independent
  /// spacing per channel when different channels supply different spacing
  /// values.
  double _stackOffsetFor(String id, ToastPosition position) {
    const double estimatedToastHeight = 64.0;
    double offset = 0;
    for (final entry in _entries.entries) {
      if (entry.key == id) break;
      if (entry.value.position == position) {
        offset += entry.value.spacing + estimatedToastHeight;
      }
    }
    return offset;
  }
}
