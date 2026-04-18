import 'dart:async';

import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

import '../../services/mock_backend.dart';
import '../../widgets/buttons/demo_button.dart';
import '../../widgets/cards/feature_card.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/see_code_button.dart';

/// Demonstrates queued notifications, spam prevention, and deduplication
/// using [ToastKit] and [MockBackend].
class NotificationDemoScreen extends StatefulWidget {
  const NotificationDemoScreen({super.key});

  @override
  State<NotificationDemoScreen> createState() =>
      _NotificationDemoScreenState();
}

class _NotificationDemoScreenState extends State<NotificationDemoScreen> {
  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  bool _streamActive = false;
  StreamSubscription<MockNotification>? _streamSub;

  // Stats
  int _totalReceived = 0;
  int _totalDisplayed = 0;
  int _totalDropped = 0;

  // Dedup tracking — stores messages that have already been shown once.
  final Set<String> _seenDedup = {};

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Maps a [MockNotificationType] to the appropriate [ToastType].
  ToastType _toastTypeFor(MockNotificationType type) {
    return switch (type) {
      MockNotificationType.message => ToastType.info,
      MockNotificationType.alert => ToastType.warning,
      MockNotificationType.promotion => ToastType.success,
      MockNotificationType.system => ToastType.info,
      MockNotificationType.reminder => ToastType.warning,
    };
  }

  /// Returns a representative icon for the notification type.
  IconData _iconFor(MockNotificationType type) {
    return switch (type) {
      MockNotificationType.message => Icons.chat_bubble_outline,
      MockNotificationType.alert => Icons.warning_amber_rounded,
      MockNotificationType.promotion => Icons.local_offer_outlined,
      MockNotificationType.system => Icons.settings_outlined,
      MockNotificationType.reminder => Icons.alarm,
    };
  }

  /// Shows a toast for the given [notification] and increments stats.
  void _showNotificationToast(MockNotification notification) {
    final toastType = _toastTypeFor(notification.type);
    final icon = _iconFor(notification.type);

    ToastKit.show(ToastEvent(
      type: toastType,
      title: notification.title,
      message: notification.body,
      channel: 'notifications',
      icon: icon,
    ));

    setState(() => _totalDisplayed++);
  }

  // ---------------------------------------------------------------------------
  // Live Notification Stream
  // ---------------------------------------------------------------------------

  void _toggleStream(bool active) {
    if (active) {
      MockBackend.instance.startNotificationStream();
      _streamSub = MockBackend.instance.notificationStream.listen(
        _onNotificationReceived,
      );
    } else {
      MockBackend.instance.stopNotificationStream();
      _streamSub?.cancel();
      _streamSub = null;
    }
    setState(() => _streamActive = active);
  }

  void _onNotificationReceived(MockNotification notification) {
    if (!mounted) return;
    setState(() => _totalReceived++);
    _showNotificationToast(notification);
  }

  // ---------------------------------------------------------------------------
  // Queue Management
  // ---------------------------------------------------------------------------

  void _sendSingle() {
    MockBackend.instance.pushNotification();
    // The stream listener handles toast display when the stream is active.
    // For direct pushes when the stream is off, listen for a one-off event.
    if (!_streamActive) {
      _listenOnce();
    }
  }

  void _sendBatch() {
    MockBackend.instance.pushNotificationBatch(5);
    if (!_streamActive) {
      _listenOnce(count: 5);
    }
  }

  /// Subscribes to the notification stream temporarily to capture pushed
  /// notifications when the persistent stream listener is not active.
  void _listenOnce({int count = 1}) {
    int received = 0;
    late StreamSubscription<MockNotification> sub;
    sub = MockBackend.instance.notificationStream.listen((n) {
      if (!mounted) return;
      setState(() => _totalReceived++);
      _showNotificationToast(n);
      received++;
      if (received >= count) sub.cancel();
    });
    // Safety: cancel after a timeout to avoid dangling subscriptions.
    Future<void>.delayed(const Duration(seconds: 10), () => sub.cancel());
  }

  void _clearQueue() {
    ToastKit.clearQueue();
    ToastKit.info('Queue cleared', channel: 'notifications');
  }

  // ---------------------------------------------------------------------------
  // Spam Prevention
  // ---------------------------------------------------------------------------

  void _spamSameMessage() {
    const message = 'Duplicate alert — you should see this only once';
    const dedupKey = 'spam-same';

    for (var i = 0; i < 10; i++) {
      setState(() => _totalReceived++);

      if (_seenDedup.contains(dedupKey)) {
        setState(() => _totalDropped++);
        continue;
      }

      _seenDedup.add(dedupKey);
      ToastKit.showOrReplace(ToastEvent.warning(
        message: message,
        channel: 'notifications',
        deduplicationKey: dedupKey,
        icon: Icons.copy,
      ));
      setState(() => _totalDisplayed++);
    }

    // Allow the key to be reused after a cooldown.
    Future<void>.delayed(
      const Duration(seconds: 5),
      () => _seenDedup.remove(dedupKey),
    );
  }

  void _spamDifferentMessages() {
    for (var i = 1; i <= 10; i++) {
      setState(() => _totalReceived++);

      ToastKit.show(ToastEvent.info(
        message: 'Unique notification #$i',
        channel: 'notifications',
        icon: Icons.notifications_active,
      ));
      setState(() => _totalDisplayed++);
    }
  }

  // ---------------------------------------------------------------------------
  // Deduplication Demo
  // ---------------------------------------------------------------------------

  int _dedupCounter = 0;

  void _sendDeduplicatedUpdate() {
    _dedupCounter++;
    setState(() => _totalReceived++);

    ToastKit.showOrReplace(ToastEvent.info(
      message: 'Live score update v$_dedupCounter — only latest shown',
      channel: 'notifications',
      deduplicationKey: 'dedup-demo',
      icon: Icons.sports_score,
    ));
    setState(() => _totalDisplayed++);
  }

  void _resetDedupCounter() {
    setState(() => _dedupCounter = 0);
  }

  // ---------------------------------------------------------------------------
  // Stats
  // ---------------------------------------------------------------------------

  void _resetStats() {
    setState(() {
      _totalReceived = 0;
      _totalDisplayed = 0;
      _totalDropped = 0;
      _dedupCounter = 0;
      _seenDedup.clear();
    });
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _streamSub?.cancel();
    if (_streamActive) {
      MockBackend.instance.stopNotificationStream();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Notifications'),
      ),
      body: ResponsiveBody(
        children: [
          _buildStatsBar(cs),
          const SizedBox(height: 12),
          _buildLiveStreamCard(cs),
          const SizedBox(height: 12),
          _buildQueueManagementCard(cs),
          const SizedBox(height: 12),
          _buildSpamPreventionCard(cs),
          const SizedBox(height: 12),
          _buildDeduplicationCard(cs),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stats Bar
  // ---------------------------------------------------------------------------

  Widget _buildStatsBar(ColorScheme cs) {
    return Card(
      color: cs.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _StatChip(
              label: 'Received',
              value: _totalReceived,
              color: cs.primary,
            ),
            const SizedBox(width: 16),
            _StatChip(
              label: 'Displayed',
              value: _totalDisplayed,
              color: cs.tertiary,
            ),
            const SizedBox(width: 16),
            _StatChip(
              label: 'Dropped',
              value: _totalDropped,
              color: cs.error,
            ),
            const Spacer(),
            IconButton(
              onPressed: _resetStats,
              icon: const Icon(Icons.restart_alt, size: 20),
              tooltip: 'Reset stats',
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Live Notification Stream
  // ---------------------------------------------------------------------------

  Widget _buildLiveStreamCard(ColorScheme cs) {
    return FeatureCard(
      title: 'Live Notification Stream',
      subtitle: 'Toggle a continuous stream of mock notifications',
      icon: Icons.stream,
      iconColor: cs.primary,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SeeCodeButton(
            title: 'Live Notification Stream',
            description:
                'Listens to a stream of mock notifications and shows each one as a toast.',
            code: _liveStreamCode,
          ),
          Switch.adaptive(
            value: _streamActive,
            onChanged: _toggleStream,
          ),
        ],
      ),
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _streamActive
              ? Row(
                  key: const ValueKey('active'),
                  children: [
                    Icon(Icons.circle, size: 10, color: Colors.green.shade400),
                    const SizedBox(width: 8),
                    Text(
                      'Stream active — notifications arriving every 4 s',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                )
              : Text(
                  'Stream paused',
                  key: const ValueKey('paused'),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.outline),
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Queue Management
  // ---------------------------------------------------------------------------

  Widget _buildQueueManagementCard(ColorScheme cs) {
    return FeatureCard(
      title: 'Queue Management',
      subtitle: 'Test toast queuing and overflow behaviour',
      icon: Icons.queue,
      iconColor: cs.secondary,
      trailing: const SeeCodeButton(
        title: 'Queue Management',
        description: 'Push single or batch notifications and clear the queue.',
        code: _queueManagementCode,
      ),
      children: [
        DemoButton(
          label: 'Send Single Notification',
          icon: Icons.send,
          onPressed: _sendSingle,
        ),
        DemoButton(
          label: 'Send Batch (5)',
          icon: Icons.dynamic_feed,
          onPressed: _sendBatch,
        ),
        DemoButton(
          label: 'Clear Queue',
          icon: Icons.clear_all,
          color: cs.error,
          onPressed: _clearQueue,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Spam Prevention
  // ---------------------------------------------------------------------------

  Widget _buildSpamPreventionCard(ColorScheme cs) {
    return FeatureCard(
      title: 'Spam Prevention',
      subtitle: 'Identical messages are deduplicated automatically',
      icon: Icons.block,
      iconColor: Colors.orange,
      trailing: const SeeCodeButton(
        title: 'Spam Prevention',
        description:
            'Demonstrates deduplication by key — 10 identical toasts collapse into 1.',
        code: _spamPreventionCode,
      ),
      children: [
        DemoButton(
          label: 'Spam Same Message (10×)',
          icon: Icons.copy,
          color: Colors.orange,
          onPressed: _spamSameMessage,
        ),
        DemoButton(
          label: 'Spam Different Messages (10×)',
          icon: Icons.list_alt,
          onPressed: _spamDifferentMessages,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'The same-message button sends 10 identical toasts — '
            'only the first is displayed. Different messages are queued '
            'individually.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.outline),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Deduplication Demo
  // ---------------------------------------------------------------------------

  Widget _buildDeduplicationCard(ColorScheme cs) {
    return FeatureCard(
      title: 'Deduplication Demo',
      subtitle: 'Repeated updates replace the previous toast in-place',
      icon: Icons.find_replace,
      iconColor: cs.tertiary,
      trailing: const SeeCodeButton(
        title: 'Deduplication (showOrReplace)',
        description:
            'Uses showOrReplace with the same deduplicationKey so only the latest update is visible.',
        code: _deduplicationCode,
      ),
      children: [
        DemoButton(
          label: 'Send Deduplicated Update (v${_dedupCounter + 1})',
          icon: Icons.sports_score,
          onPressed: _sendDeduplicatedUpdate,
        ),
        CompactDemoButton(
          label: 'Reset Counter',
          icon: Icons.restart_alt,
          onPressed: _resetDedupCounter,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Each press replaces the previous toast using the same '
            'deduplicationKey. Tap rapidly to see only the latest update.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.outline),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Private helper widgets
// ---------------------------------------------------------------------------

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color.withAlpha(180)),
        ),
      ],
    );
  }
}

// =============================================================================
// Code Strings for "See Code" modals
// =============================================================================

const _liveStreamCode = '''// Start a live notification stream
MockBackend.instance.startNotificationStream();
final sub = MockBackend.instance.notificationStream.listen(
  (notification) {
    final toastType = _toastTypeFor(notification.type);
    ToastKit.show(ToastEvent(
      type: toastType,
      title: notification.title,
      message: notification.body,
      channel: 'notifications',
      icon: _iconFor(notification.type),
    ));
  },
);

// Stop when done
MockBackend.instance.stopNotificationStream();
sub.cancel();''';

const _queueManagementCode = '''// Send a single notification
MockBackend.instance.pushNotification();

// Send a batch of 5
MockBackend.instance.pushNotificationBatch(5);

// Clear the toast queue without dismissing visible toasts
ToastKit.clearQueue();''';

const _spamPreventionCode = '''// Send 10 identical toasts — only the first shows.
const dedupKey = 'spam-same';

for (var i = 0; i < 10; i++) {
  ToastKit.showOrReplace(ToastEvent.warning(
    message: 'Duplicate alert — only shown once',
    channel: 'notifications',
    deduplicationKey: dedupKey,
  ));
}''';

const _deduplicationCode = '''// Each call replaces the previous toast in-place.
_dedupCounter++;

ToastKit.showOrReplace(ToastEvent.info(
  message: 'Live score update v\$_dedupCounter',
  channel: 'notifications',
  deduplicationKey: 'dedup-demo',
));

// Tap rapidly — only the latest version is visible.''';
