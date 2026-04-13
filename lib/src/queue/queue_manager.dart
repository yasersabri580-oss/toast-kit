import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../core/toast_config.dart';
import '../events/toast_event.dart';

/// Snapshot of the current queue state.
@immutable
class QueueState {

  const QueueState({
    required this.visibleCount,
    required this.queuedCount,
    required this.maxVisible,
  });
  /// Number of toasts currently visible.
  final int visibleCount;

  /// Number of toasts waiting in the queue.
  final int queuedCount;

  /// Maximum number of visible toasts.
  final int maxVisible;

  /// Whether the visible-slot limit has been reached.
  bool get isFull => visibleCount >= maxVisible;

  /// Whether there are no queued or visible toasts.
  bool get isIdle => visibleCount == 0 && queuedCount == 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueueState &&
          other.visibleCount == visibleCount &&
          other.queuedCount == queuedCount &&
          other.maxVisible == maxVisible;

  @override
  int get hashCode => Object.hash(visibleCount, queuedCount, maxVisible);

  @override
  String toString() =>
      'QueueState(visible: $visibleCount, queued: $queuedCount, '
      'max: $maxVisible)';
}

/// Manages the queue / stack of [ToastEvent]s.
///
/// Enforces [ToastConfig.maxVisibleToasts], ordering via [QueueMode], and
/// auto-promotes the next queued event when a visible toast is dismissed.
///
/// **Stability features:**
/// - Bounded queue size via [ToastConfig.maxQueueSize] to prevent memory
///   overflow under rapid-fire usage.
/// - Processing lock to prevent race conditions when promoting queued events.
/// - Duplicate ID guard to prevent the same event from being tracked twice.
class QueueManager {

  /// Creates a [QueueManager].
  QueueManager({
    required ToastConfig config,
    required this.onReadyToShow,
  }) : _config = config;
  ToastConfig _config;

  /// Callback when a queued toast is promoted and ready to display.
  final void Function(ToastEvent event) onReadyToShow;

  final ListQueue<ToastEvent> _queue = ListQueue<ToastEvent>();
  final Set<String> _visibleIds = <String>{};
  final Map<String, ToastEvent> _visibleEvents = <String, ToastEvent>{};

  /// IDs of events currently in the waiting queue (for fast duplicate check).
  final Set<String> _queuedIds = <String>{};

  final StreamController<QueueState> _stateController =
      StreamController<QueueState>.broadcast();

  bool _isDisposed = false;

  /// Guard to prevent re-entrant [_promoteNext] calls.
  bool _isProcessing = false;

  // -----------------------------------------------------------------------
  // Getters
  // -----------------------------------------------------------------------

  ToastConfig get config => _config;
  List<ToastEvent> get queuedEvents => List<ToastEvent>.unmodifiable(_queue);
  int get visibleCount => _visibleIds.length;
  bool get isEmpty => _queue.isEmpty && _visibleIds.isEmpty;
  bool get isFull => _visibleIds.length >= _config.maxVisibleToasts;
  Stream<QueueState> get stateStream => _stateController.stream;

  /// Unmodifiable list of currently visible events.
  List<ToastEvent> get visibleEvents =>
      List<ToastEvent>.unmodifiable(_visibleEvents.values);

  /// Update the configuration at runtime.
  void updateConfig(ToastConfig config) {
    _config = config;
  }

  // -----------------------------------------------------------------------
  // Core operations
  // -----------------------------------------------------------------------

  /// Add an event. If a visible slot is free it will be shown immediately;
  /// otherwise it is queued.
  ///
  /// Returns `true` if the event was accepted (shown or queued), `false` if
  /// it was dropped due to a duplicate ID or because the queue is disabled
  /// and no visible slots are available.
  ///
  /// When the queue exceeds [ToastConfig.maxQueueSize], the oldest queued
  /// events are silently dropped to keep memory bounded — but the newly
  /// enqueued event is still accepted (returns `true`).
  bool enqueue(ToastEvent event) {
    if (_isDisposed) return false;

    // Duplicate ID guard — prevent the same event from being tracked twice.
    if (_visibleIds.contains(event.id) || _queuedIds.contains(event.id)) {
      return false;
    }

    if (!isFull) {
      _markVisible(event);
      onReadyToShow(event);
    } else if (_config.enableQueue) {
      _insertIntoQueue(event);
      _enforceMaxQueueSize();
    } else {
      return false;
    }
    _emitState();
    return true;
  }

  /// Remove an event from the queue before it is shown.
  void removeById(String id) {
    _queue.removeWhere((e) => e.id == id);
    _queuedIds.remove(id);
    _emitState();
  }

  /// Mark a visible toast as dismissed and auto-promote the next queued one.
  void markDismissed(String id) {
    _visibleIds.remove(id);
    _visibleEvents.remove(id);
    _promoteNext();
    _emitState();
  }

  /// Return the next event without removing it.
  ToastEvent? peek() => _queue.isNotEmpty ? _queue.first : null;

  /// Remove and return the next event.
  ToastEvent? dequeue() {
    if (_queue.isEmpty) return null;
    final event = _queue.removeFirst();
    _queuedIds.remove(event.id);
    _emitState();
    return event;
  }

  /// Clear all queued events (visible toasts remain tracked).
  void clearQueue() {
    _queue.clear();
    _queuedIds.clear();
    _emitState();
  }

  /// Clear all queued **and** visible tracking.
  void clear() {
    _queue.clear();
    _queuedIds.clear();
    _visibleIds.clear();
    _visibleEvents.clear();
    _emitState();
  }

  /// Release resources.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _queue.clear();
    _queuedIds.clear();
    _visibleIds.clear();
    _visibleEvents.clear();
    _stateController.close();
  }

  // -----------------------------------------------------------------------
  // Internals
  // -----------------------------------------------------------------------

  void _markVisible(ToastEvent event) {
    _visibleIds.add(event.id);
    _visibleEvents[event.id] = event;
  }

  void _insertIntoQueue(ToastEvent event) {
    _queuedIds.add(event.id);
    switch (_config.queueMode) {
      case QueueMode.fifo:
        _queue.addLast(event);
        break;
      case QueueMode.lifo:
        _queue.addFirst(event);
        break;
      case QueueMode.priority:
        // Insert maintaining descending priority order.
        final list = _queue.toList();
        final idx = list.indexWhere(
          (e) => e.priority.index < event.priority.index,
        );
        if (idx == -1) {
          list.add(event);
        } else {
          list.insert(idx, event);
        }
        _queue.clear();
        _queuedIds.clear();
        _queue.addAll(list);
        for (final e in list) {
          _queuedIds.add(e.id);
        }
        break;
    }
  }

  /// Drop oldest queued events when the queue exceeds the configured limit.
  void _enforceMaxQueueSize() {
    final maxSize = _config.maxQueueSize;
    if (maxSize <= 0) return; // 0 = unlimited
    while (_queue.length > maxSize) {
      final dropped = _queue.removeFirst();
      _queuedIds.remove(dropped.id);
    }
  }

  void _promoteNext() {
    if (_isProcessing || _queue.isEmpty || isFull) return;
    _isProcessing = true;
    try {
      final next = _queue.removeFirst();
      _queuedIds.remove(next.id);
      _markVisible(next);
      onReadyToShow(next);
    } finally {
      _isProcessing = false;
    }
  }

  void _emitState() {
    if (_isDisposed) return;
    _stateController.add(QueueState(
      visibleCount: _visibleIds.length,
      queuedCount: _queue.length,
      maxVisible: _config.maxVisibleToasts,
    ));
  }
}
