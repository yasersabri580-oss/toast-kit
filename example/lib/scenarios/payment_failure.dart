import 'dart:math';

import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

// ---------------------------------------------------------------------------
// Payment Failure Scenario
//
// Demonstrates:
// - Payment processing with loading → success/error
// - Channel + rule system for repeated payment failures
// - Action toasts for recovery (retry, contact support)
// - Custom rule to escalate after multiple failures
// ---------------------------------------------------------------------------

class PaymentFailureScenario extends StatefulWidget {
  const PaymentFailureScenario({super.key});

  @override
  State<PaymentFailureScenario> createState() => _PaymentFailureScenarioState();
}

class _PaymentFailureScenarioState extends State<PaymentFailureScenario> {
  final _amountController = TextEditingController(text: '49.99');
  final _random = Random();
  int _failureCount = 0;

  @override
  void initState() {
    super.initState();
    _setupPaymentRules();
  }

  void _setupPaymentRules() {
    // Register the payment channel.
    ToastKit.registerChannel(ToastChannel.payment);

    // Config-based rule: trigger after 3 payment errors.
    ToastKit.configureRule(
      'payment',
      const RuleConfig(
        errorThreshold: 3,
        deduplicateWindow: Duration(seconds: 30),
        maxTriggers: 1,
      ),
    );

    // Custom rule: offer support chat after 3 failures.
    ToastKit.addRule(ToastRule(
      id: 'payment-support',
      channel: 'payment',
      condition: (stats, event) => stats.errorCount >= 3,
      action: (context) {
        ToastKit.show(ToastEvent.info(
          message: 'Having trouble? Our support team can help.',
          variant: ToastVariant.action,
          actions: [
            ToastAction(
              label: 'Contact Support',
              onPressed: () {
                ToastKit.success('Opening support chat…');
              },
            ),
          ],
          channel: 'payment',
        ));
      },
    ));

    // Custom rule: suggest alternative payment after 5 failures.
    ToastKit.addRule(ToastRule(
      id: 'payment-alternative',
      channel: 'payment',
      condition: (stats, event) => stats.errorCount >= 5,
      action: (context) {
        ToastKit.show(ToastEvent.warning(
          message: 'Try a different payment method?',
          variant: ToastVariant.action,
          actions: [
            ToastAction(
              label: 'Switch Card',
              onPressed: () {
                ToastKit.info('Opening payment methods…');
              },
            ),
            ToastAction(
              label: 'Use PayPal',
              onPressed: () {
                ToastKit.info('Redirecting to PayPal…');
              },
            ),
          ],
          channel: 'payment',
        ));
      },
    ));
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  /// Simulate payment processing with random failure types.
  Future<void> _processPayment() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ToastKit.warning('Please enter a valid amount');
      return;
    }

    final ctrl = ToastKit.showLoading(
      'Processing \$${amount.toStringAsFixed(2)}…',
    );

    try {
      // Simulate payment processing delay.
      await Future.delayed(const Duration(seconds: 2));

      // Simulate different failure scenarios (70% failure rate for demo).
      final outcome = _random.nextInt(10);
      if (outcome < 3) {
        // Success (30% chance).
        ctrl.success('Payment of \$${amount.toStringAsFixed(2)} successful!');
        setState(() => _failureCount = 0);
        return;
      }

      // Simulate various payment failures.
      if (outcome < 5) {
        throw _CardDeclinedException();
      } else if (outcome < 7) {
        throw _InsufficientFundsException();
      } else if (outcome < 9) {
        throw _NetworkException();
      } else {
        throw Exception('Unknown payment error');
      }
    } on _CardDeclinedException {
      ctrl.error('Card declined');
      _recordPaymentFailure('Card declined');
    } on _InsufficientFundsException {
      ctrl.error('Insufficient funds');
      _recordPaymentFailure('Insufficient funds');
    } on _NetworkException {
      ctrl.error('Network error during payment');
      _recordPaymentFailure('Network error');
    } catch (e) {
      ctrl.error('Payment failed');
      _recordPaymentFailure('Unknown error');
    }
  }

  void _recordPaymentFailure(String reason) {
    _failureCount++;
    setState(() {});

    // Record on the payment channel — rules will evaluate automatically.
    ToastKit.error(reason, channel: 'payment');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Failure')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Simulate payment attempts. Most will fail randomly. '
            'After 3 failures, a support suggestion appears. '
            'After 5, an alternative payment method is offered.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Consecutive failures: $_failureCount',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _failureCount >= 3 ? Colors.red : null,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount (\$)',
              border: OutlineInputBorder(),
              prefixText: '\$ ',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _processPayment,
            icon: const Icon(Icons.payment),
            label: const Text('Process Payment'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => ToastKit.dismissAll(),
            child: const Text('Dismiss All Toasts'),
          ),
        ],
      ),
    );
  }
}

class _CardDeclinedException implements Exception {}

class _InsufficientFundsException implements Exception {}

class _NetworkException implements Exception {}
