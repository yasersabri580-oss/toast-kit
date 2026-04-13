import 'dart:async';

import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

// ---------------------------------------------------------------------------
// API Error Handling Scenario
//
// Demonstrates:
// - Stateful loading → success/error transitions
// - Channel-based error tracking with rules
// - Deduplication for repeated failures
// - Action toasts for user recovery
// ---------------------------------------------------------------------------

/// Simulated API client for demonstration purposes.
class _MockApiClient {
  int _callCount = 0;

  Future<Map<String, String>> getProfile() async {
    _callCount++;
    await Future.delayed(const Duration(seconds: 1));

    // Simulate intermittent failures
    if (_callCount % 3 == 0) {
      return {'name': 'Jane Doe', 'email': 'jane@example.com'};
    }
    if (_callCount % 2 == 0) {
      throw TimeoutException('Server did not respond');
    }
    throw Exception('Internal server error');
  }

  Future<List<String>> fetchItems() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (DateTime.now().second % 2 == 0) {
      return ['Item A', 'Item B', 'Item C'];
    }
    throw Exception('Failed to fetch items');
  }
}

class ApiErrorScenario extends StatefulWidget {
  const ApiErrorScenario({super.key});

  @override
  State<ApiErrorScenario> createState() => _ApiErrorScenarioState();
}

class _ApiErrorScenarioState extends State<ApiErrorScenario> {
  final _api = _MockApiClient();

  @override
  void initState() {
    super.initState();
    _setupRules();
  }

  void _setupRules() {
    // Register the network channel for tracking API errors.
    ToastKit.registerChannel(ToastChannel.network);

    // Config-based rule: after 5 errors, trigger once per 30 seconds.
    ToastKit.configureRule(
      'network',
      const RuleConfig(
        errorThreshold: 5,
        deduplicateWindow: Duration(seconds: 30),
        maxTriggers: 2,
      ),
    );

    // Custom rule: suggest offline mode after 8 errors.
    ToastKit.addRule(ToastRule(
      id: 'suggest-offline-mode',
      channel: 'network',
      condition: (stats, event) => stats.errorCount >= 8,
      action: (context) {
        ToastKit.show(ToastEvent.warning(
          message: 'Frequent errors detected. Try offline mode?',
          variant: ToastVariant.action,
          deduplicationKey: 'suggest-offline-mode',
          actions: [
            ToastAction(
              label: 'Go Offline',
              onPressed: () {
                ToastKit.info('Switched to offline mode');
              },
            ),
          ],
          channel: 'network',
        ));
      },
    ));
  }

  /// Fetch user profile with loading → success/error transition.
  Future<void> _fetchProfile() async {
    final ctrl = ToastKit.showLoading('Loading profile…');
    try {
      final user = await _api.getProfile();
      ctrl.success('Welcome back, ${user['name']}!');
    } on TimeoutException {
      ctrl.error('Request timed out — please try again');
      ToastKit.error('Profile request timeout', channel: 'network');
    } catch (e) {
      ctrl.error('Failed to load profile');
      ToastKit.error('Profile fetch error', channel: 'network');
    }
  }

  /// Fetch items with deduplication to prevent spam.
  Future<void> _fetchItems() async {
    try {
      final items = await _api.fetchItems();
      ToastKit.success('Loaded ${items.length} items');
    } catch (e) {
      ToastKit.show(ToastEvent.error(
        message: 'Could not load items',
        deduplicationKey: 'fetch-items-error',
        channel: 'network',
      ));
    }
  }

  /// Demonstrate rapid-fire API calls with deduplication.
  Future<void> _rapidFireRequests() async {
    for (var i = 0; i < 5; i++) {
      _fetchItems();
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Error Handling')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Demonstrates stateful loading, channel-based error tracking, '
            'and deduplication for API failures.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _fetchProfile,
            icon: const Icon(Icons.person),
            label: const Text('Fetch Profile (Loading → Result)'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _fetchItems,
            icon: const Icon(Icons.list),
            label: const Text('Fetch Items'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _rapidFireRequests,
            icon: const Icon(Icons.bolt),
            label: const Text('Rapid-Fire Requests (Dedup Demo)'),
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
