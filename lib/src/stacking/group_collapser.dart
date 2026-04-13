import '../events/toast_event.dart';

/// Tracks and groups repeated toast messages for smart stacking.
///
/// When the same deduplication key or message is shown multiple times within
/// a configured window, the [GroupCollapser] can merge them into a single
/// grouped toast with a count badge.
class GroupCollapser {
  /// Time window within which repeated messages are grouped.
  final Duration groupWindow;

  /// Maximum number of individual messages before collapsing into a group.
  final int collapseThreshold;

  final Map<String, _GroupEntry> _groups = {};

  GroupCollapser({
    this.groupWindow = const Duration(seconds: 5),
    this.collapseThreshold = 3,
  });

  /// Determine the grouping key for an event.
  ///
  /// Uses the deduplication key if available, otherwise falls back
  /// to the message text.
  String? groupKeyFor(ToastEvent event) {
    return event.deduplicationKey ?? event.message;
  }

  /// Record an occurrence and return the current count.
  ///
  /// Returns the number of times this group key has been seen within
  /// the active window. If the window has expired, resets the count.
  int recordAndCount(ToastEvent event) {
    final key = groupKeyFor(event);
    if (key == null) return 1;

    final now = DateTime.now();
    final entry = _groups[key];

    if (entry != null && now.difference(entry.firstSeen) < groupWindow) {
      entry.count++;
      entry.lastId = event.id;
      return entry.count;
    }

    // Start a new group window.
    _groups[key] = _GroupEntry(
      firstSeen: now,
      count: 1,
      lastId: event.id,
    );
    return 1;
  }

  /// Whether the group for this event has exceeded the collapse threshold.
  bool shouldCollapse(ToastEvent event) {
    final key = groupKeyFor(event);
    if (key == null) return false;
    final entry = _groups[key];
    if (entry == null) return false;
    return entry.count >= collapseThreshold;
  }

  /// Get the current count for a group key.
  int countFor(String key) => _groups[key]?.count ?? 0;

  /// Get the last event ID for a group key.
  String? lastIdFor(String key) => _groups[key]?.lastId;

  /// Clean up expired group entries.
  void cleanUp() {
    final now = DateTime.now();
    _groups.removeWhere(
      (_, entry) => now.difference(entry.firstSeen) >= groupWindow,
    );
  }

  /// Clear all group tracking.
  void clear() => _groups.clear();
}

class _GroupEntry {
  final DateTime firstSeen;
  int count;
  String lastId;

  _GroupEntry({
    required this.firstSeen,
    required this.count,
    required this.lastId,
  });
}
