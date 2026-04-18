import 'dart:async';
import 'dart:math';

/// Mock backend that simulates server-side events.
///
/// Used by the notification and dashboard features to produce event streams.
class MockBackend {
  MockBackend._();
  static final MockBackend instance = MockBackend._();

  final _rng = Random();
  StreamController<MockNotification>? _notifController;

  // ---------------------------------------------------------------------------
  // Notification stream
  // ---------------------------------------------------------------------------

  /// Returns a broadcast stream of mock push notifications arriving at random
  /// intervals.
  Stream<MockNotification> get notificationStream {
    _notifController ??= StreamController<MockNotification>.broadcast();
    return _notifController!.stream;
  }

  Timer? _notifTimer;

  /// Starts emitting mock notifications at random intervals.
  void startNotificationStream({Duration interval = const Duration(seconds: 4)}) {
    stopNotificationStream();
    _notifTimer = Timer.periodic(interval, (_) {
      if (_notifController?.isClosed ?? true) return;
      _notifController!.add(_randomNotification());
    });
  }

  /// Stops the notification stream.
  void stopNotificationStream() {
    _notifTimer?.cancel();
    _notifTimer = null;
  }

  /// Emits a single notification immediately.
  void pushNotification() {
    if (_notifController?.isClosed ?? true) return;
    _notifController!.add(_randomNotification());
  }

  /// Emits a batch of notifications at once (for spam testing).
  void pushNotificationBatch(int count) {
    for (var i = 0; i < count; i++) {
      pushNotification();
    }
  }

  MockNotification _randomNotification() {
    const types = MockNotificationType.values;
    final type = types[_rng.nextInt(types.length)];
    final titles = _titlesForType(type);
    return MockNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(9999)}',
      type: type,
      title: titles[_rng.nextInt(titles.length)],
      body: 'Simulated ${type.name} notification body.',
      timestamp: DateTime.now(),
    );
  }

  List<String> _titlesForType(MockNotificationType type) {
    return switch (type) {
      MockNotificationType.message => [
          'New message from Alex',
          'Team chat update',
          'Direct message received',
        ],
      MockNotificationType.alert => [
          'CPU usage high',
          'Disk space low',
          'Service degraded',
        ],
      MockNotificationType.promotion => [
          '50 % off today!',
          'Flash sale ending soon',
          'New feature available',
        ],
      MockNotificationType.system => [
          'Maintenance scheduled',
          'Update available',
          'Security patch applied',
        ],
      MockNotificationType.reminder => [
          'Meeting in 15 min',
          'Task deadline approaching',
          'Don\'t forget to review PR',
        ],
    };
  }

  // ---------------------------------------------------------------------------
  // Clean up
  // ---------------------------------------------------------------------------

  void dispose() {
    stopNotificationStream();
    _notifController?.close();
    _notifController = null;
  }
}

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

enum MockNotificationType { message, alert, promotion, system, reminder }

class MockNotification {
  const MockNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
  });

  final String id;
  final MockNotificationType type;
  final String title;
  final String body;
  final DateTime timestamp;
}
