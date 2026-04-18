import 'dart:async';

import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

import '../../services/api_service.dart';
import '../../services/retry_service.dart';
import '../../widgets/buttons/demo_button.dart';
import '../../widgets/cards/feature_card.dart';
import '../../widgets/see_code_button.dart';

/// Demonstrates fetch-with-retry, exponential back-off, toast-per-failure, and
/// overlap prevention using [ToastKit.showOrReplace].
class NetworkDemoScreen extends StatefulWidget {
  const NetworkDemoScreen({super.key});

  @override
  State<NetworkDemoScreen> createState() => _NetworkDemoScreenState();
}

class _NetworkDemoScreenState extends State<NetworkDemoScreen> {
  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  /// Incremented on every new request so stale retries are discarded.
  int _generation = 0;

  bool _isFetching = false;
  bool _isParallelRunning = false;

  // Statistics
  int _totalRequests = 0;
  int _successes = 0;
  int _failures = 0;

  // Backoff visualisation — each entry holds {attempt, delay, status}.
  final List<_BackoffAttempt> _backoffAttempts = [];

  // Channel-level error accumulator for offline-mode suggestion.
  int _channelErrors = 0;

  // ---------------------------------------------------------------------------
  // Actions — Fetch with Retry
  // ---------------------------------------------------------------------------

  Future<void> _fetchWithRetry() async {
    final gen = ++_generation;
    setState(() {
      _isFetching = true;
      _backoffAttempts.clear();
    });

    try {
      final result = await RetryService.instance.withRetry<Map<String, dynamic>>(
        action: () {
          setState(() => _totalRequests++);
          return ApiService.instance.fetchProfile();
        },
        maxRetries: 3,
        onAttempt: (attempt, max, error) {
          if (!mounted) return;

          // Mirror the retry service formula: baseDelay * (backoffMultiplier * attempt).
          // With defaults (baseDelay=1s, multiplier=2.0): attempt 1 → 2s, attempt 2 → 4s.
          // No delay after the final attempt.
          final delaySec = attempt < max ? (2.0 * attempt).round() : 0;

          setState(() {
            _failures++;
            _channelErrors++;
            _backoffAttempts.add(_BackoffAttempt(
              attempt: attempt,
              delaySec: delaySec,
              status: _AttemptStatus.failed,
            ));
          });

          // Replace the previous error toast instead of stacking.
          if (attempt < max) {
            ToastKit.showOrReplace(ToastEvent.info(
              message: 'Retry ${attempt + 1}/$max — waiting ${delaySec}s…',
              channel: 'network',
              deduplicationKey: 'network-retry',
              icon: Icons.refresh,
            ));
          }

          _checkOfflineSuggestion();
        },
        generation: gen,
        currentGeneration: () => _generation,
      );

      if (!mounted) return;

      // Successful response.
      setState(() {
        _successes++;
        _backoffAttempts.add(_BackoffAttempt(
          attempt: _backoffAttempts.length + 1,
          delaySec: 0,
          status: _AttemptStatus.success,
        ));
      });

      ToastKit.showOrReplace(ToastEvent.success(
        message: 'Profile loaded (${result['name'] ?? 'OK'})',
        channel: 'network',
        deduplicationKey: 'network-retry',
      ));
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _failures++;
        _channelErrors++;
      });

      // Final failure — offer a manual retry action.
      ToastKit.showOrReplace(ToastEvent.error(
        message: 'Connection failed: ${e.message}',
        channel: 'network',
        deduplicationKey: 'network-retry',
        actions: [
          ToastAction(
            label: 'Retry',
            onPressed: _fetchWithRetry,
          ),
        ],
      ));

      _checkOfflineSuggestion();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _failures++;
        _channelErrors++;
      });

      ToastKit.showOrReplace(ToastEvent.error(
        message: 'Unexpected error: $e',
        channel: 'network',
        deduplicationKey: 'network-retry',
      ));

      _checkOfflineSuggestion();
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Actions — Parallel Requests
  // ---------------------------------------------------------------------------

  Future<void> _fireParallelRequests() async {
    setState(() => _isParallelRunning = true);

    final futures = List.generate(5, (i) async {
      setState(() => _totalRequests++);
      try {
        await ApiService.instance.fetchItems();
        if (mounted) setState(() => _successes++);
      } on ApiException catch (e) {
        if (!mounted) return;
        setState(() {
          _failures++;
          _channelErrors++;
        });

        // All parallel errors share one deduplication key so only the latest
        // error toast is visible — no toast storm.
        ToastKit.showOrReplace(ToastEvent.error(
          message: 'Request ${i + 1} failed: ${e.message}',
          channel: 'network',
          deduplicationKey: 'parallel-fetch',
        ));

        _checkOfflineSuggestion();
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _failures++;
          _channelErrors++;
        });

        ToastKit.showOrReplace(ToastEvent.error(
          message: 'Request ${i + 1}: $e',
          channel: 'network',
          deduplicationKey: 'parallel-fetch',
        ));

        _checkOfflineSuggestion();
      }
    });

    await Future.wait(futures);

    if (!mounted) return;

    setState(() => _isParallelRunning = false);
    ToastKit.info('Parallel batch complete', channel: 'network');
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _checkOfflineSuggestion() {
    if (_channelErrors >= 6) {
      ToastKit.showOrReplace(ToastEvent.warning(
        message: 'Multiple failures detected — consider switching to offline mode.',
        channel: 'network',
        deduplicationKey: 'offline-suggestion',
        actions: [
          ToastAction(
            label: 'Go Offline',
            onPressed: () {
              ToastKit.info('Offline mode enabled (demo)', channel: 'network');
            },
          ),
        ],
      ));
    }
  }

  void _resetStats() {
    setState(() {
      _totalRequests = 0;
      _successes = 0;
      _failures = 0;
      _channelErrors = 0;
      _backoffAttempts.clear();
    });
    ToastKit.info('Statistics reset', channel: 'network');
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Network & Retry'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatsCard(theme),
          const SizedBox(height: 12),
          _buildFetchRetryCard(),
          const SizedBox(height: 12),
          _buildBackoffCard(theme),
          const SizedBox(height: 12),
          _buildParallelCard(),
          const SizedBox(height: 12),
          _buildChannelRulesCard(theme),
        ],
      ),
    );
  }

  // ---- Statistics -----------------------------------------------------------

  Widget _buildStatsCard(ThemeData theme) {
    return FeatureCard(
      title: 'Statistics',
      subtitle: 'Aggregate request metrics',
      icon: Icons.bar_chart,
      iconColor: Colors.indigo,
      children: [
        Row(
          children: [
            _StatChip(
              label: 'Total',
              value: '$_totalRequests',
              color: Colors.indigo,
            ),
            const SizedBox(width: 8),
            _StatChip(
              label: 'OK',
              value: '$_successes',
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            _StatChip(
              label: 'Fail',
              value: '$_failures',
              color: Colors.red,
            ),
          ],
        ),
        if (_totalRequests > 0)
          DemoButton(
            label: 'Reset',
            icon: Icons.restart_alt,
            onPressed: _resetStats,
            color: Colors.grey,
          ),
      ],
    );
  }

  // ---- Fetch with Retry -----------------------------------------------------

  Widget _buildFetchRetryCard() {
    return FeatureCard(
      title: 'Fetch with Retry',
      subtitle: 'Uses showOrReplace to prevent toast overlap',
      icon: Icons.cloud_download,
      iconColor: Colors.blue,
      trailing: const SeeCodeButton(
        title: 'Fetch with Retry',
        description: 'Uses showOrReplace to prevent toast overlap during retries.',
        code: _fetchRetryCode,
      ),
      children: [
        DemoButton(
          label: 'Fetch Profile (3 retries)',
          icon: Icons.person_search,
          onPressed: _isFetching ? null : _fetchWithRetry,
          loading: _isFetching,
          color: Colors.blue,
        ),
      ],
    );
  }

  // ---- Backoff Visualisation ------------------------------------------------

  Widget _buildBackoffCard(ThemeData theme) {
    return FeatureCard(
      title: 'Exponential Backoff Visualization',
      subtitle: 'Per-attempt timing and status',
      icon: Icons.timer,
      iconColor: Colors.orange,
      children: [
        if (_backoffAttempts.isEmpty)
          Text(
            'No attempts yet — trigger a fetch above.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          )
        else
          ..._backoffAttempts.map((a) => _BackoffRow(attempt: a, theme: theme)),
      ],
    );
  }

  // ---- Parallel Requests ----------------------------------------------------

  Widget _buildParallelCard() {
    return FeatureCard(
      title: 'Parallel Requests',
      subtitle: 'Fires 5 requests; deduplicates error toasts',
      icon: Icons.alt_route,
      iconColor: Colors.teal,
      trailing: const SeeCodeButton(
        title: 'Parallel Requests',
        description: 'Fires 5 requests; deduplicates error toasts with shared key.',
        code: _parallelCode,
      ),
      children: [
        DemoButton(
          label: 'Fire 5 Parallel Requests',
          icon: Icons.rocket_launch,
          onPressed: _isParallelRunning ? null : _fireParallelRequests,
          loading: _isParallelRunning,
          color: Colors.teal,
        ),
      ],
    );
  }

  // ---- Channel Rules --------------------------------------------------------

  Widget _buildChannelRulesCard(ThemeData theme) {
    return FeatureCard(
      title: 'Network Channel Rules',
      subtitle: 'After 6 errors an offline-mode suggestion appears',
      icon: Icons.rule,
      iconColor: Colors.deepOrange,
      trailing: const SeeCodeButton(
        title: 'Network Channel Rules',
        description: 'Suggests offline mode after 6 errors on the network channel.',
        code: _channelRulesCode,
      ),
      children: [
        Row(
          children: [
            Icon(
              _channelErrors >= 6
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline,
              size: 20,
              color: _channelErrors >= 6 ? Colors.deepOrange : Colors.green,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _channelErrors >= 6
                    ? 'Threshold reached ($_channelErrors errors) — offline mode suggested'
                    : 'Errors on channel: $_channelErrors / 6',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      _channelErrors >= 6 ? Colors.deepOrange : Colors.green,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (_channelErrors / 6).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: _channelErrors >= 6 ? Colors.deepOrange : Colors.green,
          ),
        ),
        if (_channelErrors > 0)
          DemoButton(
            label: 'Reset Channel Errors',
            icon: Icons.restart_alt,
            onPressed: () {
              setState(() => _channelErrors = 0);
              ToastKit.info('Channel error count reset', channel: 'network');
            },
            color: Colors.grey,
          ),
      ],
    );
  }
}

// =============================================================================
// Private helpers
// =============================================================================

enum _AttemptStatus { success, failed }

class _BackoffAttempt {
  const _BackoffAttempt({
    required this.attempt,
    required this.delaySec,
    required this.status,
  });

  final int attempt;
  final int delaySec;
  final _AttemptStatus status;
}

class _BackoffRow extends StatelessWidget {
  const _BackoffRow({required this.attempt, required this.theme});

  final _BackoffAttempt attempt;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isSuccess = attempt.status == _AttemptStatus.success;
    final color = isSuccess ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              '${attempt.attempt}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSuccess ? 'Success' : 'Failed',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                if (!isSuccess && attempt.delaySec > 0)
                  Text(
                    'Waiting ${attempt.delaySec}s before next attempt',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            isSuccess ? Icons.check_circle : Icons.cancel,
            color: color,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Code Strings for "See Code" modals
// =============================================================================

const _fetchRetryCode = '''// Fetch with retry and replace-based toast updates
final result = await RetryService.instance.withRetry(
  action: () => ApiService.instance.fetchProfile(),
  maxRetries: 3,
  onAttempt: (attempt, max, error) {
    ToastKit.showOrReplace(ToastEvent.info(
      message: 'Retry \${attempt + 1}/\$max…',
      channel: 'network',
      deduplicationKey: 'network-retry',
    ));
  },
);

ToastKit.showOrReplace(ToastEvent.success(
  message: 'Profile loaded!',
  channel: 'network',
  deduplicationKey: 'network-retry',
));''';

const _parallelCode = '''// Parallel requests with shared dedup key
final futures = List.generate(5, (i) async {
  try {
    await ApiService.instance.fetchItems();
  } on ApiException catch (e) {
    // All errors share one key — only the latest is visible
    ToastKit.showOrReplace(ToastEvent.error(
      message: 'Request \${i + 1} failed: \${e.message}',
      channel: 'network',
      deduplicationKey: 'parallel-fetch',
    ));
  }
});
await Future.wait(futures);''';

const _channelRulesCode = '''// Suggest offline mode after 6+ channel errors
void _checkOfflineSuggestion() {
  if (_channelErrors >= 6) {
    ToastKit.showOrReplace(ToastEvent.warning(
      message: 'Multiple failures — consider offline mode.',
      channel: 'network',
      deduplicationKey: 'offline-suggestion',
      actions: [
        ToastAction(
          label: 'Go Offline',
          onPressed: () {
            ToastKit.info('Offline mode enabled (demo)');
          },
        ),
      ],
    ));
  }
}''';
