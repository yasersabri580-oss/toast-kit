import 'dart:math';

import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

// ---------------------------------------------------------------------------
// Network Retry Messaging Scenario
//
// Demonstrates:
// - Retry logic with progressive toast feedback
// - Channel-based error tracking for network requests
// - configureRule for retry exhaustion warnings
// - Action toasts for manual retry
// - Deduplication to avoid toast flooding during retries
// ---------------------------------------------------------------------------

class NetworkRetryScenario extends StatefulWidget {
  const NetworkRetryScenario({super.key});

  @override
  State<NetworkRetryScenario> createState() => _NetworkRetryScenarioState();
}

class _NetworkRetryScenarioState extends State<NetworkRetryScenario> {
  final _random = Random();
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _setupNetworkRules();
  }

  void _setupNetworkRules() {
    ToastKit.registerChannel(ToastChannel.network);

    // Rule: after 3 network errors, suggest checking connection.
    ToastKit.configureRule(
      'network',
      const RuleConfig(
        errorThreshold: 3,
        deduplicateWindow: Duration(seconds: 15),
        maxTriggers: 2,
      ),
    );

    // Custom rule: show persistent "offline" banner after 6 errors.
    ToastKit.addRule(ToastRule(
      id: 'offline-banner',
      channel: 'network',
      condition: (stats, event) => stats.errorCount >= 6,
      action: (context) {
        ToastKit.show(ToastEvent.error(
          message: 'You appear to be offline.',
          variant: ToastVariant.fullWidth,
          persistent: true,
          dismissible: true,
          channel: 'network',
        ));
      },
    ));
  }

  /// Fetch data with automatic retry and progressive toast feedback.
  Future<String?> _fetchWithRetry({int maxRetries = 3}) async {
    setState(() => _isRetrying = true);

    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Simulate network request.
        await Future.delayed(Duration(seconds: 1 + attempt));

        // 30% success rate for demo purposes.
        if (_random.nextInt(10) < 3) {
          ToastKit.success('Data loaded successfully!');
          setState(() => _isRetrying = false);
          return 'Fetched data at ${DateTime.now()}';
        }

        throw Exception('Server responded with 500');
      } catch (e) {
        ToastKit.error(
          'Attempt $attempt/$maxRetries failed',
          channel: 'network',
        );

        if (attempt == maxRetries) {
          // All retries exhausted.
          ToastKit.show(ToastEvent.error(
            message: 'All $maxRetries retries failed. Please try again later.',
            variant: ToastVariant.action,
            actions: [
              ToastAction(
                label: 'Retry Again',
                onPressed: () => _fetchWithRetry(),
              ),
            ],
            channel: 'network',
          ));
          setState(() => _isRetrying = false);
          return null;
        }

        // Exponential backoff feedback.
        final waitSeconds = attempt * 2;
        ToastKit.info('Retrying in $waitSeconds seconds…');
        await Future.delayed(Duration(seconds: waitSeconds));
      }
    }

    setState(() => _isRetrying = false);
    return null;
  }

  /// Simulate a single request that uses deduplication.
  Future<void> _singleRequest() async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      if (_random.nextBool()) {
        ToastKit.success('Request succeeded');
        return;
      }
      throw Exception('Connection refused');
    } catch (e) {
      ToastKit.show(ToastEvent.error(
        message: 'Connection failed',
        deduplicationKey: 'connection-refused',
        channel: 'network',
      ));
    }
  }

  /// Fire multiple requests in parallel — deduplication prevents flooding.
  Future<void> _parallelRequests() async {
    ToastKit.info('Firing 5 parallel requests…');
    await Future.wait(List.generate(5, (_) => _singleRequest()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network Retry')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Demonstrates retry logic with progressive toast feedback, '
            'deduplication, and rules that suggest offline mode after '
            'repeated failures.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _isRetrying ? null : () => _fetchWithRetry(),
            icon: const Icon(Icons.refresh),
            label: Text(_isRetrying ? 'Retrying…' : 'Fetch with Retry (3 attempts)'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _singleRequest,
            icon: const Icon(Icons.cloud_download),
            label: const Text('Single Request'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _parallelRequests,
            icon: const Icon(Icons.cloud_sync),
            label: const Text('5 Parallel Requests (Dedup Demo)'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => ToastKit.dismissAll(),
            child: const Text('Dismiss All'),
          ),
        ],
      ),
    );
  }
}
