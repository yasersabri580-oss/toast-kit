import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/toast_config.dart';
import '../events/toast_event.dart';
import '../router/notification_router.dart';

// ---------------------------------------------------------------------------
// ToastDebugEntry
// ---------------------------------------------------------------------------

/// A single debug-log entry capturing the lifecycle of a toast event.
@immutable
class ToastDebugEntry {

  /// Creates a [ToastDebugEntry].
  const ToastDebugEntry({
    required this.eventId,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.routerDecision,
    this.dismissReason,
  });
  /// The [ToastEvent.id] this entry relates to.
  final String eventId;

  /// Short message text from the event.
  final String message;

  /// Type of the toast (success, error, …).
  final ToastType type;

  /// When the entry was recorded.
  final DateTime timestamp;

  /// Human-readable description of the router decision.
  final String routerDecision;

  /// Set once the toast is dismissed; `null` while still active.
  final String? dismissReason;

  /// Returns a copy with the given fields replaced.
  ToastDebugEntry copyWith({String? dismissReason}) {
    return ToastDebugEntry(
      eventId: eventId,
      message: message,
      type: type,
      timestamp: timestamp,
      routerDecision: routerDecision,
      dismissReason: dismissReason ?? this.dismissReason,
    );
  }
}

// ---------------------------------------------------------------------------
// ToastDebugLog
// ---------------------------------------------------------------------------

/// Accumulates debug entries for toast events.
///
/// This class is a **no-op** in release builds — every public method returns
/// immediately when [kDebugMode] is `false`, so it is safe to keep in
/// production code.
class ToastDebugLog {
  ToastDebugLog({this.maxEntries = 100});

  /// Maximum number of entries kept in memory.
  final int maxEntries;

  final List<ToastDebugEntry> _entries = [];

  final StreamController<List<ToastDebugEntry>> _streamController =
      StreamController<List<ToastDebugEntry>>.broadcast();

  // ---- counters -----------------------------------------------------------

  int _totalShown = 0;
  int _totalDropped = 0;
  int _deduplicationHits = 0;
  int _throttleHits = 0;

  /// Total number of toasts that were shown (ShowDecision).
  int get totalShown => _totalShown;

  /// Total number of toasts that were dropped.
  int get totalDropped => _totalDropped;

  /// Total number of deduplicated events.
  int get deduplicationHits => _deduplicationHits;

  /// Total number of throttle hits.
  int get throttleHits => _throttleHits;

  // ---- public API ---------------------------------------------------------

  /// An unmodifiable view of the current entries (newest first).
  UnmodifiableListView<ToastDebugEntry> get entries =>
      UnmodifiableListView(_entries);

  /// A broadcast stream that emits the entry list on every change.
  Stream<List<ToastDebugEntry>> get stream => _streamController.stream;

  /// Logs a router decision for the given [event].
  void logRouterDecision(ToastEvent event, RouterDecision decision) {
    if (!kDebugMode) return;

    if (decision is ShowDecision) {
      _totalShown++;
    } else if (decision is DropDecision) {
      _totalDropped++;
    } else if (decision is DeduplicateDecision) {
      _deduplicationHits++;
    }

    _addEntry(
      ToastDebugEntry(
        eventId: event.id,
        message: event.message ?? '',
        type: event.type,
        timestamp: DateTime.now(),
        routerDecision: decision.toString(),
      ),
    );
  }

  /// Logs a dismiss event for the toast identified by [eventId].
  void logDismiss(String eventId, String reason) {
    if (!kDebugMode) return;

    final index = _entries.indexWhere((e) => e.eventId == eventId);
    if (index != -1) {
      _entries[index] = _entries[index].copyWith(dismissReason: reason);
      _notify();
    }
  }

  /// Logs that a throttle limit was hit for [event].
  void logThrottleHit(ToastEvent event) {
    if (!kDebugMode) return;

    _throttleHits++;
    _addEntry(
      ToastDebugEntry(
        eventId: event.id,
        message: event.message ?? '',
        type: event.type,
        timestamp: DateTime.now(),
        routerDecision: 'throttled',
      ),
    );
  }

  /// Logs that [event] was identified as a duplicate of [existingId].
  void logDeduplicationHit(ToastEvent event, String existingId) {
    if (!kDebugMode) return;

    _deduplicationHits++;
    _addEntry(
      ToastDebugEntry(
        eventId: event.id,
        message: event.message ?? '',
        type: event.type,
        timestamp: DateTime.now(),
        routerDecision: 'deduplicated (existing: $existingId)',
      ),
    );
  }

  /// Removes all entries and resets counters.
  void clear() {
    _entries.clear();
    _totalShown = 0;
    _totalDropped = 0;
    _deduplicationHits = 0;
    _throttleHits = 0;
    _notify();
  }

  /// Releases the internal stream controller.
  void dispose() {
    _streamController.close();
  }

  // ---- internals ----------------------------------------------------------

  void _addEntry(ToastDebugEntry entry) {
    _entries.insert(0, entry);
    if (_entries.length > maxEntries) {
      _entries.removeLast();
    }
    _notify();
  }

  void _notify() {
    if (!_streamController.isClosed) {
      _streamController.add(UnmodifiableListView(_entries));
    }
  }
}

// ---------------------------------------------------------------------------
// ToastDebugOverlay
// ---------------------------------------------------------------------------

/// A draggable floating panel that visualises [ToastDebugLog] information.
///
/// Renders **only** in debug mode. In release builds the widget returns
/// [SizedBox.shrink] — zero cost.
///
/// ```dart
/// ToastDebugOverlay(debugLog: myDebugLog)
/// ```
class ToastDebugOverlay extends StatefulWidget {

  /// Creates a [ToastDebugOverlay].
  const ToastDebugOverlay({
    super.key,
    required this.debugLog,
    this.activeCountStream,
    this.queuedCountStream,
  });
  /// The debug log instance to observe.
  final ToastDebugLog debugLog;

  /// Optional queue state stream to show live queue stats.
  final Stream<int>? activeCountStream;

  /// Optional stream of queued toast count.
  final Stream<int>? queuedCountStream;

  @override
  State<ToastDebugOverlay> createState() => _ToastDebugOverlayState();
}

class _ToastDebugOverlayState extends State<ToastDebugOverlay> {
  bool _expanded = false;
  Offset _offset = const Offset(8, 80);

  StreamSubscription<List<ToastDebugEntry>>? _logSub;
  List<ToastDebugEntry> _currentEntries = const [];

  @override
  void initState() {
    super.initState();
    if (!kDebugMode) return;
    _currentEntries = widget.debugLog.entries.toList();
    _logSub = widget.debugLog.stream.listen((entries) {
      if (mounted) setState(() => _currentEntries = entries);
    });
  }

  @override
  void dispose() {
    _logSub?.cancel();
    super.dispose();
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() => _offset += details.delta);
        },
        child: Material(
          color: Colors.transparent,
          child: _expanded ? _buildExpanded() : _buildCollapsed(),
        ),
      ),
    );
  }

  // ---- collapsed pill -----------------------------------------------------

  Widget _buildCollapsed() {
    return GestureDetector(
      onTap: () => setState(() => _expanded = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xDD1E1E1E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bug_report, color: Colors.greenAccent, size: 16),
            const SizedBox(width: 4),
            Text(
              'Toast Debug (${widget.debugLog.totalShown})',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- expanded panel -----------------------------------------------------

  Widget _buildExpanded() {
    final log = widget.debugLog;

    return Container(
      width: 320,
      constraints: const BoxConstraints(maxHeight: 420),
      decoration: BoxDecoration(
        color: const Color(0xEE1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildCounterRow(log),
          const Divider(color: Colors.white24, height: 1),
          Flexible(child: _buildEntryList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bug_report, color: Colors.greenAccent, size: 14),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'Toast Debug',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          _headerButton(Icons.delete_outline, () => widget.debugLog.clear()),
          const SizedBox(width: 4),
          _headerButton(
            Icons.close,
            () => setState(() => _expanded = false),
          ),
        ],
      ),
    );
  }

  Widget _headerButton(IconData icon, void Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: Colors.white54, size: 16),
    );
  }

  Widget _buildCounterRow(ToastDebugLog log) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 10,
          fontFamily: 'monospace',
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _counter('shown', log.totalShown, Colors.greenAccent),
            _counter('dropped', log.totalDropped, Colors.redAccent),
            _counter('dedup', log.deduplicationHits, Colors.orangeAccent),
            _counter('throttle', log.throttleHits, Colors.amberAccent),
          ],
        ),
      ),
    );
  }

  Widget _counter(String label, int value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text('$label: $value'),
      ],
    );
  }

  // ---- entry list ---------------------------------------------------------

  Widget _buildEntryList() {
    if (_currentEntries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No events yet.',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(6),
      shrinkWrap: true,
      itemCount: _currentEntries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemBuilder: (_, index) => _buildEntryTile(_currentEntries[index]),
    );
  }

  Widget _buildEntryTile(ToastDebugEntry entry) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _typeIcon(entry.type),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  entry.message.length > 40
                      ? '${entry.message.substring(0, 40)}…'
                      : entry.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatTime(entry.timestamp),
                style: const TextStyle(
                  color: Colors.white30,
                  fontSize: 9,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            entry.routerDecision,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 9,
              fontFamily: 'monospace',
            ),
          ),
          if (entry.dismissReason != null)
            Text(
              'dismissed: ${entry.dismissReason}',
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontSize: 9,
                fontFamily: 'monospace',
              ),
            ),
        ],
      ),
    );
  }

  // ---- helpers ------------------------------------------------------------

  Widget _typeIcon(ToastType type) {
    final (IconData icon, Color color) = switch (type) {
      ToastType.success => (Icons.check_circle, Colors.greenAccent),
      ToastType.error => (Icons.error, Colors.redAccent),
      ToastType.warning => (Icons.warning_amber, Colors.orangeAccent),
      ToastType.info => (Icons.info_outline, Colors.lightBlueAccent),
      ToastType.loading => (Icons.hourglass_top, Colors.amberAccent),
      ToastType.custom => (Icons.widgets, Colors.purpleAccent),
    };
    return Icon(icon, size: 12, color: color);
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }
}
