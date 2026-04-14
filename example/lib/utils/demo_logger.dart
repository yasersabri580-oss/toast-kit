import 'dart:collection';

import 'package:flutter/foundation.dart';

/// A simple in-memory debug logger that stores the last [maxEntries] messages
/// and exposes them as a [ValueNotifier] so UI can react.
class DemoLogger {
  DemoLogger._();
  static final DemoLogger instance = DemoLogger._();

  static const int maxEntries = 200;

  final _entries = Queue<LogEntry>();

  /// Notifies listeners whenever the log list changes.
  final ValueNotifier<List<LogEntry>> entriesNotifier =
      ValueNotifier<List<LogEntry>>([]);

  /// Whether debug logging is enabled. Defaults to true in debug mode.
  bool enabled = kDebugMode;

  /// Adds a log entry.
  void log(String message, {LogLevel level = LogLevel.info}) {
    if (!enabled) return;
    final entry = LogEntry(
      message: message,
      level: level,
      timestamp: DateTime.now(),
    );
    _entries.addFirst(entry);
    while (_entries.length > maxEntries) {
      _entries.removeLast();
    }
    entriesNotifier.value = List.unmodifiable(_entries);
  }

  /// Convenience for info level.
  void info(String message) => log(message, level: LogLevel.info);

  /// Convenience for warning level.
  void warn(String message) => log(message, level: LogLevel.warning);

  /// Convenience for error level.
  void error(String message) => log(message, level: LogLevel.error);

  /// Convenience for success level.
  void success(String message) => log(message, level: LogLevel.success);

  /// Clears the log.
  void clear() {
    _entries.clear();
    entriesNotifier.value = [];
  }

  /// Returns the current entries (newest first).
  List<LogEntry> get entries => List.unmodifiable(_entries);
}

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

enum LogLevel { info, warning, error, success }

class LogEntry {
  const LogEntry({
    required this.message,
    required this.level,
    required this.timestamp,
  });

  final String message;
  final LogLevel level;
  final DateTime timestamp;

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
