# Example: Payment Failure

Handle payment failures with escalating severity and smart rules.

## What This Example Demonstrates

- Payment channel with `maxVisible: 1` and `urgent` priority
- Escalating toast severity as failures increase
- Rule-based help suggestion after repeated failures
- Persistent toast for critical failures

---

## Setup

```dart
void setupPaymentRules() {
  // Register payment channel (built-in: maxVisible=1, priority=urgent)
  ToastKit.registerChannel(ToastChannel.payment);

  // Config-based rule: trigger after 3 payment errors
  ToastKit.configureRule(
    'payment',
    const RuleConfig(
      errorThreshold: 3,
      deduplicateWindow: Duration(seconds: 30),
      maxTriggers: 1,
    ),
  );

  // Custom rule: suggest customer support after 3 failures
  ToastKit.addRule(ToastRule(
    id: 'payment-support',
    channel: 'payment',
    maxTriggers: 1,
    condition: (stats, event) => stats.errorCount >= 3,
    action: (context) {
      ToastKit.show(ToastEvent.info(
        message: 'Having trouble? Our support team can help.',
        variant: ToastVariant.action,
        deduplicationKey: 'payment-support',
        persistent: true,
        actions: [
          ToastAction(
            label: 'Contact Support',
            onPressed: () => launchUrl('https://support.example.com'),
          ),
          ToastAction(
            label: 'Dismiss',
            onPressed: () => ToastKit.dismissAll(),
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

| Failure # | What Happens |
|-----------|--------------|
| 1 | "Payment declined" error toast |
| 2 | "Payment declined" error toast |
| 3 | "Having trouble?" toast with Contact Support button |
| 4+ | Standard error (support toast already shown) |

---

[← Network Retry](network_retry.md) | [Next: Form Validation →](form_validation.md)
