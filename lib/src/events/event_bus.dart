import 'dart:async';
import 'toast_event.dart';

/// Internal broadcast event bus for [ToastEvent]s.
///
/// Multiple listeners (overlay engine, analytics, logging) can subscribe
/// to the same stream.
class EventBus {
  final StreamController<ToastEvent> _controller =
      StreamController<ToastEvent>.broadcast();

  bool _isDisposed = false;

  /// Broadcast stream of [ToastEvent]s.
  Stream<ToastEvent> get stream => _controller.stream;

  /// Whether this bus has been disposed.
  bool get isDisposed => _isDisposed;

  /// Emit a [ToastEvent] to all listeners.
  void emit(ToastEvent event) {
    if (_isDisposed) {
      throw StateError(
        'Cannot emit events on a disposed EventBus. '
        'Call ToastKit.init() to create a new instance.',
      );
    }
    _controller.add(event);
  }

  /// Release resources.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _controller.close();
  }
}
