# Example: Payment Failure

Handle payment failures with multi-step escalation, action toasts, and smart rules.

## What This Example Demonstrates

- Payment channel with `maxVisible: 1` and `urgent` priority
- **Escalating rules** — warning at 2 failures, blocking at 4
- **Action toasts** with multiple recovery options (Switch Card, PayPal, Support)
- **Persistent toast** for critical failures that blocks further attempts
- Config-based rule for analytics alongside custom rules

---

## Setup

```dart
void setupPaymentRules() {
  // Register payment channel (built-in: maxVisible=1, priority=urgent)
  ToastKit.registerChannel(ToastChannel.payment);

  // Config-based rule: fire analytics callback after 3 payment errors.
  ToastKit.configureRule(
    'payment',
    const RuleConfig(
      errorThreshold: 3,
      deduplicateWindow: Duration(seconds: 30),
      maxTriggers: 1,
    ),
  );

  // Step 1: Warning after 2 failures — early feedback.
  ToastKit.addRule(ToastRule(
    id: 'payment-warn',
    channel: 'payment',
    maxTriggers: 1,
    condition: (stats, event) =>
        stats.errorCount >= 2 && stats.errorCount < 4,
    action: (context) {
      ToastKit.show(ToastEvent.warning(
        message: 'Multiple payment failures. Check your card details.',
        deduplicationKey: 'payment-warn',
        channel: 'payment',
      ));
    },
  ));

  // Step 2: Block and offer recovery after 4 failures.
  // persistent: true keeps the toast until the user acts.
  // Multiple ToastAction buttons offer different recovery paths.
  ToastKit.addRule(ToastRule(
    id: 'payment-block',
    channel: 'payment',
    maxTriggers: 1,
    condition: (stats, event) => stats.errorCount >= 4,
    action: (context) {
      ToastKit.show(ToastEvent.error(
        message: 'Payment processing suspended after repeated failures.',
        variant: ToastVariant.action,
        persistent: true,
        deduplicationKey: 'payment-block',
        actions: [
          ToastAction(
            label: 'Switch Card',
            onPressed: () {
              ToastKit.dismissAll();
              openPaymentMethodPicker();
            },
          ),
          ToastAction(
            label: 'Use PayPal',
            onPressed: () {
              ToastKit.dismissAll();
              redirectToPayPal();
            },
          ),
          ToastAction(
            label: 'Contact Support',
            onPressed: () {
              ToastKit.dismissAll();
              openSupportChat();
            },
          ),
        ],
        channel: 'payment',
      ));
    },
  ));
}
```

## Payment Processing

```dart
Future<void> processPayment(double amount) async {
  final ctrl = ToastKit.showLoading(
    'Processing \$${amount.toStringAsFixed(2)}…',
    channel: 'payment',
  );

  try {
    await paymentService.charge(amount);
    ctrl.success('Payment of \$${amount.toStringAsFixed(2)} successful!');
  } on PaymentDeclinedException catch (e) {
    ctrl.error('Payment declined: ${e.reason}');
    ToastKit.error(
      'Payment failed',
      channel: 'payment',
    );
  } on NetworkException {
    ctrl.error('Network error — please try again');
    ToastKit.error(
      'Payment network error',
      channel: 'payment',
    );
  } catch (e) {
    ctrl.error('Unexpected error');
    ToastKit.error(
      'Payment error',
      channel: 'payment',
    );
  }
}
```

## Escalation Flow

| Failure # | Rule | User Sees |
|-----------|------|-----------|
| 1 | — | "Payment declined" error toast |
| 2 | `payment-warn` | "Multiple payment failures. Check your card." warning |
| 3 | Config rule | Analytics event fired (no toast) |
| 4 | `payment-block` | Persistent action toast: Switch Card / PayPal / Support |
| 5+ | — | Actions blocked until user uses a recovery option |

## Key Design Decisions

1. **Two-step escalation** gives users early feedback (warning) before blocking (error)
2. **`maxTriggers: 1`** prevents rules from re-firing after threshold is crossed
3. **Multiple `ToastAction` buttons** give users concrete recovery paths
4. **`persistent: true`** keeps the blocking toast visible until the user acts
5. **`deduplicationKey`** prevents duplicate toasts if errors continue after blocking

---

[← Network Retry](network_retry.md) | [Next: Form Validation →](form_validation.md)
