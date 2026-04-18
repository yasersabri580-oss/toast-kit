# Example: Network Retry

Retry failed network requests with exponential backoff, real-time toast feedback, and burst detection using `errorsInWindow()`.

## What This Example Demonstrates

- Loading toast with progress updates
- Retry with exponential backoff
- Generation counter for concurrency safety
- Channel-based error tracking
- **`errorsInWindow()`** for burst detection (sliding time window analysis)
- **`deduplicateWindow`** on custom rules to prevent rapid re-firing

---

## Setup: Network Channel and Burst Detection Rule

```dart
void setupNetworkRules() {
  ToastKit.registerChannel(ToastChannel.network);

  // Config-based rule for general error tracking
  ToastKit.configureRule(
    'network',
    RuleConfig(
      errorThreshold: 3,
      deduplicateWindow: Duration(seconds: 10),
      maxTriggers: 2,
    ),
  );

  // Custom rule: detect error bursts using errorsInWindow()
  // This catches sudden spikes that cumulative errorCount would miss.
  ToastKit.addRule(ToastRule(
    id: 'network-burst',
    channel: 'network',
    deduplicateWindow: const Duration(seconds: 30),  // 30s cooldown
    condition: (stats, event) {
      // 3+ errors within the last 15 seconds = spike
      return stats.errorsInWindow(const Duration(seconds: 15)) >= 3;
    },
    action: (context) {
      final recentErrors = context.stats.errorsInWindow(
        const Duration(seconds: 15),
      );
      ToastKit.show(ToastEvent.error(
        message: 'Connection unstable: $recentErrors errors in 15 seconds.',
        persistent: true,
        variant: ToastVariant.action,
        deduplicationKey: 'network-unstable',
        actions: [
          ToastAction(
            label: 'Retry',
            onPressed: () {
              ToastKit.dismissAll();
              ToastKit.info('Retrying…');
            },
          ),
        ],
        channel: 'network',
      ));
    },
  ));
}
```

## Retry Service

```dart
class RetryService {
  /// Retry an async operation with exponential backoff and toast feedback.
  static Future<T> retryWithFeedback<T>({
    required Future<T> Function() operation,
    required String loadingMessage,
    required String successMessage,
    required String failureMessage,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    String? channel,
  }) async {
    final ctrl = ToastKit.showLoading(loadingMessage, channel: channel);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final result = await operation();
        ctrl.success(successMessage);
        return result;
      } catch (e) {
        // Record error on channel — rules (including burst detection) evaluate
        if (channel != null) {
          ToastKit.error(
            'Retry $attempt/$maxRetries failed',
            channel: channel,
          );
        }

        if (attempt == maxRetries) {
          ctrl.error(failureMessage);
          rethrow;
        }

        // Update loading message with retry info
        final delay = initialDelay * (1 << (attempt - 1)); // Exponential backoff
        ctrl.update(
          message: 'Retry $attempt/$maxRetries in ${delay.inSeconds}s…',
        );

        await Future.delayed(delay);
        ctrl.update(message: '$loadingMessage (attempt ${attempt + 1})');
      }
    }

    // Should not reach here
    ctrl.error(failureMessage);
    throw Exception('All retries exhausted');
  }
}
```

## Usage

```dart
Future<void> fetchUserData() async {
  try {
    final data = await RetryService.retryWithFeedback(
      operation: () => api.getUserProfile(),
      loadingMessage: 'Loading profile…',
      successMessage: 'Profile loaded',
      failureMessage: 'Could not load profile',
      maxRetries: 3,
      channel: 'network',
    );

    setState(() => _profile = data);
  } catch (e) {
    // All retries failed — toast already shown by RetryService
  }
}
```

## Concurrency Safety with Generation Counter

When multiple retry chains can run concurrently, use a generation counter to cancel stale operations:

```dart
class _NetworkScreenState extends State<NetworkScreen> {
  int _generation = 0;

  Future<void> _fetchData() async {
    final gen = ++_generation;  // Increment generation

    final ctrl = ToastKit.showLoading('Loading…', channel: 'network');

    try {
      final data = await api.fetch();

      // Check if this generation is still current
      if (gen != _generation) {
        ctrl.dismiss();  // A newer request superseded this one
        return;
      }

      ctrl.success('Loaded!');
      setState(() => _data = data);
    } catch (e) {
      if (gen != _generation) {
        ctrl.dismiss();
        return;
      }
      ctrl.error('Failed to load');
    }
  }
}
```

## What the User Sees

```
[Loading…]                           ← Initial loading toast
[Retry 1/3 in 1s…]                  ← First failure, waiting
[Loading… (attempt 2)]               ← Second attempt
[Retry 2/3 in 2s…]                  ← Second failure, waiting
[Loading… (attempt 3)]               ← Third attempt
[Profile loaded ✓]                   ← Success on third try
```

If multiple requests fail rapidly (within 15 seconds), the burst detection rule fires and shows a persistent "Connection unstable" toast with a Retry button.

---

[← Login Rules](login_rules.md) | [Next: Payment Failure →](payment_failure.md)
