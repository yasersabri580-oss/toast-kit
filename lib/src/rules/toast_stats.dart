import '../core/toast_config.dart';

/// Tracks statistics per channel for the rule engine.
class ToastStats {
  /// Total toast count.
  int totalCount = 0;

  /// Count of error toasts.
  int errorCount = 0;

  /// Count of warning toasts.
  int warningCount = 0;

  /// Count of success toasts.
  int successCount = 0;

  /// Count of info toasts.
  int infoCount = 0;

  /// Count of dismissed toasts.
  int dismissedCount = 0;

  /// Count of dropped toasts.
  int droppedCount = 0;

  /// Timestamps of recent errors (for windowed analysis).
  final List<DateTime> _recentErrors = [];

  /// Record a toast event.
  void record(ToastType type) {
    totalCount++;
    switch (type) {
      case ToastType.error:
        errorCount++;
        _recentErrors.add(DateTime.now());
        break;
      case ToastType.warning:
        warningCount++;
        break;
      case ToastType.success:
        successCount++;
        break;
      case ToastType.info:
        infoCount++;
        break;
      case ToastType.loading:
      case ToastType.custom:
        break;
    }
  }

  /// Record a dismissal.
  void recordDismissed() {
    dismissedCount++;
  }

  /// Record a drop.
  void recordDropped() {
    droppedCount++;
  }

  /// Count of errors within a given time window.
  int errorsInWindow(Duration window) {
    final cutoff = DateTime.now().subtract(window);
    return _recentErrors.where((t) => t.isAfter(cutoff)).length;
  }

  /// Reset all stats.
  void reset() {
    totalCount = 0;
    errorCount = 0;
    warningCount = 0;
    successCount = 0;
    infoCount = 0;
    dismissedCount = 0;
    droppedCount = 0;
    _recentErrors.clear();
  }

  @override
  String toString() =>
      'ToastStats(total: $totalCount, errors: $errorCount, warnings: $warningCount)';
}
