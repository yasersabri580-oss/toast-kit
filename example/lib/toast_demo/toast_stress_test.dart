import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

import '../widgets/cards/feature_card.dart';
import '../widgets/buttons/demo_button.dart';
import '../widgets/see_code_button.dart';

/// A stress-test screen that pushes ToastKit to its limits under extreme load.
///
/// Every test is designed to verify stability: no crashes, no overlapping
/// layout glitches, and predictable queue / dedup behaviour even when dozens
/// of toasts are fired in quick succession.
class ToastStressTest extends StatefulWidget {
  const ToastStressTest({super.key});

  @override
  State<ToastStressTest> createState() => _ToastStressTestState();
}

class _ToastStressTestState extends State<ToastStressTest> {
  int _totalFired = 0;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _elapsedTimer;

  // Cached values for the running timer display.
  String _elapsed = '00:00.0';

  static const _types = [
    ToastType.success,
    ToastType.error,
    ToastType.warning,
    ToastType.info,
  ];

  static const _variants = [
    ToastVariant.minimal,
    ToastVariant.material,
    ToastVariant.ios,
    ToastVariant.glassmorphism,
    ToastVariant.gradient,
    ToastVariant.floatingCard,
    ToastVariant.compact,
    ToastVariant.fullWidth,
  ];

  static const _positions = [
    ToastPosition.top,
    ToastPosition.topLeft,
    ToastPosition.topRight,
    ToastPosition.bottom,
    ToastPosition.bottomLeft,
    ToastPosition.bottomRight,
    ToastPosition.center,
  ];

  // ------------------------------------------------------------------
  // Lifecycle
  // ------------------------------------------------------------------

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  void _incrementFired([int count = 1]) {
    setState(() => _totalFired += count);
  }

  void _ensureTimerRunning() {
    if (_stopwatch.isRunning) return;
    _stopwatch.start();
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      final ms = _stopwatch.elapsedMilliseconds;
      final secs = (ms / 1000).floor();
      final tenths = ((ms % 1000) / 100).floor();
      setState(() {
        _elapsed =
            '${(secs ~/ 60).toString().padLeft(2, '0')}:${(secs % 60).toString().padLeft(2, '0')}.$tenths';
      });
    });
  }

  void _resetCounter() {
    _elapsedTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _totalFired = 0;
      _elapsed = '00:00.0';
    });
  }

  void _fireToast(ToastType type, String message, {String? channel}) {
    switch (type) {
      case ToastType.success:
        ToastKit.success(message, channel: channel);
      case ToastType.error:
        ToastKit.error(message, channel: channel);
      case ToastType.warning:
        ToastKit.warning(message, channel: channel);
      case ToastType.info:
        ToastKit.info(message, channel: channel);
      default:
        ToastKit.info(message, channel: channel);
    }
  }

  // ------------------------------------------------------------------
  // Rapid-Fire Tests
  // ------------------------------------------------------------------

  Future<void> _triggerBurst(int count) async {
    _ensureTimerRunning();
    for (var i = 0; i < count; i++) {
      final type = _types[i % _types.length];
      _fireToast(type, 'Burst toast #${i + 1}');
      _incrementFired();
      // Tiny yield so the framework can breathe.
      if (i % 5 == 4) await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> _spamNetworkErrors() async {
    _ensureTimerRunning();
    for (var i = 0; i < 20; i++) {
      ToastKit.error(
        'Network error #${i + 1}',
        channel: 'network',
      );
      _incrementFired();
      if (i % 5 == 4) await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> _chaosMode() async {
    _ensureTimerRunning();
    final rng = Random();
    for (var i = 0; i < 30; i++) {
      final type = _types[rng.nextInt(_types.length)];
      final variant = _variants[rng.nextInt(_variants.length)];
      final position = _positions[rng.nextInt(_positions.length)];
      ToastKit.show(ToastEvent(
        type: type,
        message: 'Chaos #${i + 1}',
        variant: variant,
        position: position,
      ));
      _incrementFired();
      if (i % 5 == 4) await Future<void>.delayed(Duration.zero);
    }
  }

  // ------------------------------------------------------------------
  // Queue Stress
  // ------------------------------------------------------------------

  Future<void> _fillQueue() async {
    _ensureTimerRunning();
    for (var i = 0; i < 50; i++) {
      final type = _types[i % _types.length];
      _fireToast(type, 'Queue fill #${i + 1}');
      _incrementFired();
      if (i % 10 == 9) await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> _burstAndClear() async {
    _ensureTimerRunning();
    for (var i = 0; i < 20; i++) {
      ToastKit.info('Burst #${i + 1}');
      _incrementFired();
    }
    ToastKit.clearQueue();
  }

  Future<void> _rapidShowDismiss() async {
    _ensureTimerRunning();
    for (var i = 0; i < 10; i++) {
      final ctrl = ToastKit.showWithController(ToastEvent(
        type: ToastType.info,
        message: 'Flash #${i + 1}',
        duration: const Duration(seconds: 3),
      ));
      _incrementFired();
      // Immediately dismiss.
      ctrl.dismiss();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  // ------------------------------------------------------------------
  // Loading Toast Stress
  // ------------------------------------------------------------------

  Future<void> _concurrentLoadingToasts() async {
    _ensureTimerRunning();
    final controllers = <ToastController>[];
    for (var i = 0; i < 10; i++) {
      controllers.add(ToastKit.showLoading('Loading #${i + 1}…'));
      _incrementFired();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    // Resolve them one by one.
    for (var i = 0; i < controllers.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!controllers[i].isDisposed) {
        controllers[i].success('Loaded #${i + 1} ✓');
      }
    }
  }

  void _progressMarathon() {
    _ensureTimerRunning();
    _incrementFired();
    final ctrl = ToastKit.showLoading('Progress 0%');
    var percent = 0;

    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      percent++;
      if (percent <= 100) {
        if (!ctrl.isDisposed) {
          ctrl.update(
            message: 'Progress $percent%',
            progressValue: percent / 100,
          );
        }
      } else {
        timer.cancel();
        if (!ctrl.isDisposed) {
          ctrl.success('Marathon complete!');
        }
      }
    });
  }

  // ------------------------------------------------------------------
  // Dedup Stress
  // ------------------------------------------------------------------

  Future<void> _sameMessage100x() async {
    _ensureTimerRunning();
    for (var i = 0; i < 100; i++) {
      ToastKit.show(ToastEvent(
        type: ToastType.info,
        message: 'Duplicate toast – should appear once',
        deduplicationKey: 'stress-same-msg',
      ));
      _incrementFired();
      if (i % 20 == 19) await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> _mixedDedupScenario() async {
    _ensureTimerRunning();
    // 10 unique toasts.
    for (var i = 0; i < 10; i++) {
      ToastKit.show(ToastEvent(
        type: _types[i % _types.length],
        message: 'Unique toast #${i + 1}',
      ));
      _incrementFired();
    }
    // 10 duplicates of the same key.
    for (var i = 0; i < 10; i++) {
      ToastKit.show(ToastEvent(
        type: ToastType.warning,
        message: 'Duplicate batch toast',
        deduplicationKey: 'stress-mixed-dup',
      ));
      _incrementFired();
    }
  }

  // ------------------------------------------------------------------
  // Build
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Stress Test'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatistics(),
          const SizedBox(height: 12),
          _buildRapidFireSection(),
          const SizedBox(height: 12),
          _buildQueueStressSection(),
          const SizedBox(height: 12),
          _buildLoadingStressSection(),
          const SizedBox(height: 12),
          _buildDedupStressSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Sections
  // ------------------------------------------------------------------

  Widget _buildStatistics() {
    return FeatureCard(
      title: 'Statistics',
      subtitle: 'Running totals for this session',
      icon: Icons.analytics_outlined,
      iconColor: Colors.deepPurple,
      trailing: IconButton(
        icon: const Icon(Icons.refresh),
        tooltip: 'Reset Counter',
        onPressed: _resetCounter,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Toasts Fired',
                value: '$_totalFired',
                icon: Icons.local_fire_department,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'Elapsed',
                value: _elapsed,
                icon: Icons.timer_outlined,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRapidFireSection() {
    return FeatureCard(
      title: 'Rapid Fire Tests',
      subtitle: 'Burst-fire toasts at high speed',
      icon: Icons.flash_on_rounded,
      iconColor: Colors.red,
      trailing: const SeeCodeButton(
        title: 'Rapid Fire',
        description: 'Fire many toasts in quick succession to test queue stability.',
        code: _rapidFireCode,
      ),
      children: [
        DemoButton(
          label: 'Trigger 20 Toasts',
          icon: Icons.bolt,
          color: Colors.orange,
          onPressed: () => _triggerBurst(20),
        ),
        DemoButton(
          label: 'Trigger 50 Toasts',
          icon: Icons.bolt,
          color: Colors.deepOrange,
          onPressed: () => _triggerBurst(50),
        ),
        DemoButton(
          label: 'Spam Network Errors',
          icon: Icons.wifi_off_rounded,
          color: Colors.red,
          onPressed: _spamNetworkErrors,
        ),
        DemoButton(
          label: 'Mixed Events Chaos Mode',
          icon: Icons.shuffle_rounded,
          color: Colors.purple,
          onPressed: _chaosMode,
        ),
      ],
    );
  }

  Widget _buildQueueStressSection() {
    return FeatureCard(
      title: 'Queue Stress',
      subtitle: 'Push the internal queue to its limits',
      icon: Icons.queue_rounded,
      iconColor: Colors.teal,
      trailing: const SeeCodeButton(
        title: 'Queue Stress',
        description: 'Fill the queue, burst + clear, and rapid show/dismiss.',
        code: _queueStressCode,
      ),
      children: [
        DemoButton(
          label: 'Fill Queue to Max',
          icon: Icons.storage_rounded,
          color: Colors.teal,
          onPressed: _fillQueue,
        ),
        DemoButton(
          label: 'Burst + Clear',
          icon: Icons.clear_all_rounded,
          color: Colors.amber.shade700,
          onPressed: _burstAndClear,
        ),
        DemoButton(
          label: 'Rapid Show/Dismiss',
          icon: Icons.flip_rounded,
          color: Colors.indigo,
          onPressed: _rapidShowDismiss,
        ),
      ],
    );
  }

  Widget _buildLoadingStressSection() {
    return FeatureCard(
      title: 'Loading Toast Stress',
      subtitle: 'Concurrent loading and progress scenarios',
      icon: Icons.hourglass_bottom_rounded,
      iconColor: Colors.cyan,
      trailing: const SeeCodeButton(
        title: 'Loading Stress',
        description: 'Run 10 concurrent loading toasts and a progress marathon.',
        code: _loadingStressCode,
      ),
      children: [
        DemoButton(
          label: '10 Concurrent Loading Toasts',
          icon: Icons.cloud_sync_rounded,
          color: Colors.cyan,
          onPressed: _concurrentLoadingToasts,
        ),
        DemoButton(
          label: 'Progress Toast Marathon',
          icon: Icons.trending_up_rounded,
          color: Colors.green,
          onPressed: _progressMarathon,
        ),
      ],
    );
  }

  Widget _buildDedupStressSection() {
    return FeatureCard(
      title: 'Dedup Stress',
      subtitle: 'Verify deduplication under load',
      icon: Icons.filter_alt_rounded,
      iconColor: Colors.pink,
      trailing: const SeeCodeButton(
        title: 'Dedup Stress',
        description: 'Fire 100 identical messages or mix unique + duplicates.',
        code: _dedupStressCode,
      ),
      children: [
        DemoButton(
          label: 'Same Message 100×',
          icon: Icons.content_copy_rounded,
          color: Colors.pink,
          onPressed: _sameMessage100x,
        ),
        DemoButton(
          label: '10 Unique + 10 Duplicates',
          icon: Icons.difference_rounded,
          color: Colors.deepPurple,
          onPressed: _mixedDedupScenario,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Private helper widgets
// ---------------------------------------------------------------------------

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Code Strings for "See Code" modals
// =============================================================================

const _rapidFireCode = '''// Burst-fire toasts at high speed
for (var i = 0; i < 20; i++) {
  final type = [ToastType.success, ToastType.error,
    ToastType.warning, ToastType.info][i % 4];
  ToastKit.show(ToastEvent(
    type: type,
    message: 'Burst toast #\${i + 1}',
  ));
  // Yield to framework every 5 toasts
  if (i % 5 == 4) await Future.delayed(Duration.zero);
}''';

const _queueStressCode = '''// Fill the queue to max capacity
for (var i = 0; i < 50; i++) {
  ToastKit.info('Queue fill #\${i + 1}');
}

// Burst + Clear: fire 20 then clear the queue
for (var i = 0; i < 20; i++) {
  ToastKit.info('Burst #\${i + 1}');
}
ToastKit.clearQueue();

// Rapid Show/Dismiss
for (var i = 0; i < 10; i++) {
  final ctrl = ToastKit.showWithController(
    ToastEvent(type: ToastType.info, message: 'Flash #\${i + 1}'),
  );
  ctrl.dismiss(); // immediately dismiss
}''';

const _loadingStressCode = '''// 10 concurrent loading toasts
final ctrls = <ToastController>[];
for (var i = 0; i < 10; i++) {
  ctrls.add(ToastKit.showLoading('Loading #\${i + 1}…'));
  await Future.delayed(Duration(milliseconds: 100));
}
// Resolve one by one
for (var i = 0; i < ctrls.length; i++) {
  await Future.delayed(Duration(milliseconds: 400));
  if (!ctrls[i].isDisposed) {
    ctrls[i].success('Loaded #\${i + 1} ✓');
  }
}''';

const _dedupStressCode = '''// Same message 100x — should appear only once
for (var i = 0; i < 100; i++) {
  ToastKit.show(ToastEvent(
    type: ToastType.info,
    message: 'Duplicate toast – should appear once',
    deduplicationKey: 'stress-same-msg',
  ));
}

// Mixed: 10 unique + 10 duplicates
for (var i = 0; i < 10; i++) {
  ToastKit.info('Unique toast #\${i + 1}');
}
for (var i = 0; i < 10; i++) {
  ToastKit.show(ToastEvent(
    type: ToastType.warning,
    message: 'Duplicate batch toast',
    deduplicationKey: 'stress-mixed-dup',
  ));
}''';
