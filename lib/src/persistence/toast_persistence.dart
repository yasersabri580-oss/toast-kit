import '../events/toast_event.dart';

/// Interface for persisting critical toasts so they can be restored.
///
/// Implement this interface to store pending toasts across app restarts
/// or navigation changes.
///
/// ```dart
/// class MyToastPersistence implements ToastPersistence {
///   final List<Map<String, dynamic>> _store = [];
///
///   @override
///   Future<void> save(ToastEvent event) async {
///     _store.add({'id': event.id, 'message': event.message, 'type': event.type.name});
///   }
///
///   @override
///   Future<void> remove(String id) async {
///     _store.removeWhere((e) => e['id'] == id);
///   }
///
///   @override
///   Future<List<ToastEvent>> loadPending() async {
///     return _store.map((e) => ToastEvent.info(message: e['message'] ?? '')).toList();
///   }
///
///   @override
///   Future<void> clear() async => _store.clear();
/// }
/// ```
abstract class ToastPersistence {
  /// Persist a critical toast event.
  Future<void> save(ToastEvent event);

  /// Remove a persisted toast (e.g. after it has been shown or dismissed).
  Future<void> remove(String id);

  /// Load all pending toasts that should be restored.
  Future<List<ToastEvent>> loadPending();

  /// Remove all persisted toasts.
  Future<void> clear();
}

/// A simple in-memory implementation of [ToastPersistence].
///
/// Useful for testing or when persistence across app restarts is not needed
/// but you still want to track critical toasts during the app lifecycle.
class InMemoryToastPersistence implements ToastPersistence {
  final List<ToastEvent> _store = [];

  /// The current list of stored events (unmodifiable view).
  List<ToastEvent> get store => List.unmodifiable(_store);

  @override
  Future<void> save(ToastEvent event) async {
    // Avoid duplicates.
    _store.removeWhere((e) => e.id == event.id);
    _store.add(event);
  }

  @override
  Future<void> remove(String id) async {
    _store.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<ToastEvent>> loadPending() async {
    return List.of(_store);
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }
}
