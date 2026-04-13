import 'package:flutter/foundation.dart';

import '../core/toast_config.dart';
import '../events/toast_event.dart';
import '../queue/queue_manager.dart';
import 'router_config.dart';

// ---------------------------------------------------------------------------
// RouterDecision hierarchy
// ---------------------------------------------------------------------------

/// Outcome of routing a [ToastEvent].
@immutable
sealed class RouterDecision {
  const RouterDecision();
}

/// Show the toast immediately (or enqueue normally).
class ShowDecision extends RouterDecision {
  const ShowDecision();
  @override
  String toString() => 'RouterDecision.show';
}

/// Place the toast in the waiting queue.
class QueueDecision extends RouterDecision {
  const QueueDecision();
  @override
  String toString() => 'RouterDecision.queue';
}

/// Replace an existing visible toast.
class ReplaceDecision extends RouterDecision {
  const ReplaceDecision(this.targetId);
  final String targetId;
  @override
  String toString() => 'RouterDecision.replace($targetId)';
}

/// Silently drop the event.
class DropDecision extends RouterDecision {
  const DropDecision(this.reason);
  final String reason;
  @override
  String toString() => 'RouterDecision.drop($reason)';
}

/// Event is a duplicate and will not be shown.
class DeduplicateDecision extends RouterDecision {
  const DeduplicateDecision(this.existingId);
  final String existingId;
  @override
  String toString() => 'RouterDecision.deduplicate($existingId)';
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

class _DeduplicationEntry {
  _DeduplicationEntry(this.toastId, this.timestamp);
  final String toastId;
  final DateTime timestamp;
}

// ---------------------------------------------------------------------------
// NotificationRouter
// ---------------------------------------------------------------------------

/// Decision engine that evaluates each [ToastEvent] and returns a
/// [RouterDecision] describing how it should be handled.
///
/// Pipeline order:
/// 1. Deduplication
/// 2. Throttling
/// 3. Urgent interruption
/// 4. Capacity / replacement strategy
///
/// **Stability features:**
/// - Bounded deduplication log: expired entries are periodically pruned to
///   prevent unbounded memory growth.
/// - Message-based deduplication fallback: even without an explicit dedup key,
///   identical messages shown within the dedup window are coalesced.
class NotificationRouter {

  NotificationRouter({
    required this.queueManager,
    RouterConfig config = const RouterConfig(),
  }) : _config = config;
  final QueueManager queueManager;
  RouterConfig _config;

  final Map<ToastType, DateTime> _lastEmitByType = <ToastType, DateTime>{};
  final Map<String, _DeduplicationEntry> _deduplicationLog =
      <String, _DeduplicationEntry>{};

  /// Maximum number of entries kept in the deduplication log before a forced
  /// cleanup pass. This prevents unbounded memory growth when many unique
  /// deduplication keys are used.
  static const int _maxDeduplicationEntries = 200;

  RouterConfig get config => _config;

  void updateConfig(RouterConfig config) {
    _config = config;
  }

  /// Evaluate a [ToastEvent] and decide how to handle it.
  RouterDecision route(ToastEvent event) {
    // 1. Deduplication
    final dedup = _checkDeduplication(event);
    if (dedup != null) return dedup;

    // 2. Throttling
    final throttle = _checkThrottling(event);
    if (throttle != null) return throttle;

    // 3. Urgent interruption
    if (_config.urgentInterruptsLower &&
        event.priority == ToastPriority.urgent &&
        queueManager.isFull) {
      final target = _findLowestPriorityVisible();
      if (target != null && target.priority.index < event.priority.index) {
        _recordEmission(event);
        return ReplaceDecision(target.id);
      }
    }

    // 4. Capacity check
    if (!queueManager.isFull) {
      _recordEmission(event);
      return const ShowDecision();
    }

    // Queue is full — apply replacement strategy
    switch (_config.replacementStrategy) {
      case ReplacementStrategy.dropNew:
        if (queueManager.config.enableQueue) {
          return const QueueDecision();
        }
        return const DropDecision('Queue full, strategy=dropNew');
      case ReplacementStrategy.replaceOldest:
        final oldest = _findOldestVisible();
        if (oldest != null) {
          _recordEmission(event);
          return ReplaceDecision(oldest.id);
        }
        return const QueueDecision();
      case ReplacementStrategy.replaceSamePriority:
        final same = _findSamePriorityVisible(event.priority);
        if (same != null) {
          _recordEmission(event);
          return ReplaceDecision(same.id);
        }
        return const QueueDecision();
    }
  }

  /// Clear internal caches (useful for testing and dispose).
  void clear() {
    _lastEmitByType.clear();
    _deduplicationLog.clear();
  }

  // -----------------------------------------------------------------------
  // Pipeline steps
  // -----------------------------------------------------------------------

  RouterDecision? _checkDeduplication(ToastEvent event) {
    if (!_config.enableDeduplication) return null;

    // Use explicit dedup key if provided, otherwise fall back to message text
    // as an implicit dedup key to prevent identical toast spam.
    final key = event.deduplicationKey ?? event.message;
    if (key == null) return null;

    final entry = _deduplicationLog[key];
    if (entry != null) {
      final elapsed = DateTime.now().difference(entry.timestamp);
      if (elapsed < _config.deduplicationWindow) {
        return DeduplicateDecision(entry.toastId);
      }
    }
    _deduplicationLog[key] = _DeduplicationEntry(event.id, DateTime.now());

    // Prune expired entries when the log exceeds its size limit.
    if (_deduplicationLog.length > _maxDeduplicationEntries) {
      _pruneDeduplicationLog();
    }
    return null;
  }

  RouterDecision? _checkThrottling(ToastEvent event) {
    if (!_config.enableThrottling) return null;
    final last = _lastEmitByType[event.type];
    if (last != null) {
      final elapsed = DateTime.now().difference(last);
      if (elapsed < _config.throttleInterval) {
        return const DropDecision('Throttled');
      }
    }
    return null;
  }

  void _recordEmission(ToastEvent event) {
    _lastEmitByType[event.type] = DateTime.now();
    final key = event.deduplicationKey ?? event.message;
    if (key != null) {
      _deduplicationLog[key] =
          _DeduplicationEntry(event.id, DateTime.now());
    }
  }

  /// Remove expired entries from the deduplication log to free memory.
  void _pruneDeduplicationLog() {
    final now = DateTime.now();
    _deduplicationLog.removeWhere(
      (_, entry) => now.difference(entry.timestamp) >= _config.deduplicationWindow,
    );
  }

  // -----------------------------------------------------------------------
  // Visible-toast queries (delegated to queue manager)
  // -----------------------------------------------------------------------

  ToastEvent? _findLowestPriorityVisible() {
    final events = queueManager.visibleEvents;
    if (events.isEmpty) return null;
    return events.reduce((a, b) =>
        a.priority.index <= b.priority.index ? a : b);
  }

  ToastEvent? _findOldestVisible() {
    final events = queueManager.visibleEvents;
    if (events.isEmpty) return null;
    return events.reduce((a, b) =>
        a.createdAt.isBefore(b.createdAt) ? a : b);
  }

  ToastEvent? _findSamePriorityVisible(ToastPriority priority) {
    final events = queueManager.visibleEvents;
    for (final e in events) {
      if (e.priority == priority) return e;
    }
    return null;
  }
}
