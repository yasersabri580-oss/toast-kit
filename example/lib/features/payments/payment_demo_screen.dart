import 'dart:async';

import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

import '../../services/api_service.dart';
import '../../widgets/buttons/demo_button.dart';
import '../../widgets/cards/feature_card.dart';
import '../../widgets/see_code_button.dart';

/// Demonstrates payment processing toasts, progress updates, failure tracking,
/// and escalating recovery suggestions via [ToastKit].
class PaymentDemoScreen extends StatefulWidget {
  const PaymentDemoScreen({super.key});

  @override
  State<PaymentDemoScreen> createState() => _PaymentDemoScreenState();
}

class _PaymentDemoScreenState extends State<PaymentDemoScreen> {
  final _amountController = TextEditingController(text: '49.99');

  // Payment method: 0 = Credit Card, 1 = PayPal, 2 = Bank Transfer
  int _selectedMethod = 0;
  static const _methods = ['Credit Card', 'PayPal', 'Bank Transfer'];
  static const _methodIcons = [
    Icons.credit_card,
    Icons.account_balance_wallet,
    Icons.account_balance,
  ];

  bool _isProcessing = false;
  int _failureCount = 0;

  final List<_PaymentRecord> _history = [];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double? get _parsedAmount {
    final text = _amountController.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  String get _methodLabel => _methods[_selectedMethod];
  bool get _canProcess => !_isProcessing && (_parsedAmount ?? 0) > 0;

  Future<void> _processPayment() async {
    final amount = _parsedAmount;
    if (amount == null || amount <= 0) {
      ToastKit.warning('Enter a valid amount', channel: 'payment');
      return;
    }

    setState(() => _isProcessing = true);

    final ctrl = ToastKit.showLoading(
      'Processing payment\u2026',
      channel: 'payment',
    );

    try {
      // Simulate progress updates while the API call runs.
      final progressTimer = Timer.periodic(
        const Duration(milliseconds: 600),
        (timer) {
          final steps = [0.3, 0.6, 0.9];
          final tick = timer.tick - 1;
          if (tick < steps.length) {
            ctrl.update(
              message: 'Processing payment\u2026 ${(steps[tick] * 100).toInt()}%',
              progressValue: steps[tick],
            );
          }
        },
      );

      await ApiService.instance.processPayment(
        amount: amount,
        method: _methodLabel,
      );

      progressTimer.cancel();

      ctrl.success('Payment of \$${amount.toStringAsFixed(2)} completed!');
      _addRecord(_PaymentStatus.success, amount);
      setState(() => _failureCount = 0);
    } on PaymentException catch (e) {
      ctrl.error('Payment failed: ${e.message}');
      _handleFailure(amount, e.message);
    } on ApiException catch (e) {
      ctrl.error('Payment failed: ${e.message}');
      _handleFailure(amount, e.message);
    } catch (_) {
      ctrl.error('An unexpected error occurred');
      _handleFailure(amount, 'Unexpected error');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handleFailure(double amount, String reason) {
    _addRecord(_PaymentStatus.failed, amount, reason: reason);
    if (!mounted) return;

    setState(() => _failureCount++);

    if (_failureCount >= 5) {
      ToastKit.show(ToastEvent.warning(
        message: 'Multiple failures — try a different payment method.',
        channel: 'payment',
        deduplicationKey: 'payment-escalation',
        actions: [
          ToastAction(
            label: 'Switch to PayPal',
            onPressed: () {
              setState(() => _selectedMethod = 1);
              ToastKit.info('Switched to PayPal', channel: 'payment');
            },
          ),
        ],
      ));
    } else if (_failureCount >= 3) {
      ToastKit.show(ToastEvent.warning(
        message: 'Having trouble? Contact support for help.',
        channel: 'payment',
        deduplicationKey: 'payment-escalation',
        actions: [
          ToastAction(
            label: 'Contact Support',
            onPressed: () {
              ToastKit.info('Support ticket opened (demo)', channel: 'payment');
            },
          ),
        ],
      ));
    }
  }

  void _cancelPayment() {
    ToastKit.warning(
      'Payment cancelled by user',
      channel: 'payment',
    );
    _addRecord(_PaymentStatus.cancelled, _parsedAmount ?? 0);
  }

  void _resetFailures() {
    setState(() => _failureCount = 0);
    ToastKit.info('Failure counter reset', channel: 'payment');
  }

  void _clearHistory() {
    setState(() => _history.clear());
    ToastKit.info('Payment history cleared', channel: 'payment');
  }

  void _addRecord(_PaymentStatus status, double amount, {String? reason}) {
    if (!mounted) return;
    setState(() {
      _history.insert(
        0,
        _PaymentRecord(
          status: status,
          amount: amount,
          method: _methodLabel,
          reason: reason,
          timestamp: DateTime.now(),
        ),
      );
    });
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
        title: const Text('Payment Flow'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFailureStatusCard(theme),
          const SizedBox(height: 12),
          _buildPaymentDetailsCard(theme),
          const SizedBox(height: 12),
          _buildActionsCard(),
          const SizedBox(height: 12),
          _buildHistoryCard(theme),
        ],
      ),
    );
  }

  // ---- Failure Status -------------------------------------------------------

  Widget _buildFailureStatusCard(ThemeData theme) {
    final Color statusColor;
    final String statusText;
    final IconData statusIcon;

    if (_failureCount >= 5) {
      statusColor = Colors.red;
      statusText = '$_failureCount failures — alternative method suggested';
      statusIcon = Icons.error;
    } else if (_failureCount >= 3) {
      statusColor = Colors.orange;
      statusText = '$_failureCount failures — contact support suggested';
      statusIcon = Icons.warning_amber_rounded;
    } else if (_failureCount > 0) {
      statusColor = Colors.amber;
      statusText =
          '$_failureCount failure${_failureCount == 1 ? '' : 's'} recorded';
      statusIcon = Icons.info_outline;
    } else {
      statusColor = Colors.green;
      statusText = 'No recent failures';
      statusIcon = Icons.check_circle_outline;
    }

    return FeatureCard(
      title: 'Payment Status',
      subtitle: 'Failure tracking & escalation',
      icon: statusIcon,
      iconColor: statusColor,
      children: [
        Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                statusText,
                style:
                    theme.textTheme.bodyMedium?.copyWith(color: statusColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildFailureIndicator(theme),
        if (_failureCount > 0) ...[
          const SizedBox(height: 12),
          DemoButton(
            label: 'Reset Failures',
            icon: Icons.restart_alt,
            onPressed: _resetFailures,
            color: Colors.grey,
          ),
        ],
      ],
    );
  }

  Widget _buildFailureIndicator(ThemeData theme) {
    const maxDisplay = 5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Consecutive Failures', style: theme.textTheme.bodySmall),
            Text(
              '$_failureCount / $maxDisplay',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (_failureCount / maxDisplay).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: _failureCount >= 5
                ? Colors.red
                : _failureCount >= 3
                    ? Colors.orange
                    : Colors.green,
          ),
        ),
      ],
    );
  }

  // ---- Payment Details ------------------------------------------------------

  Widget _buildPaymentDetailsCard(ThemeData theme) {
    return FeatureCard(
      title: 'Payment Details',
      subtitle: 'Configure amount and method',
      icon: Icons.payment,
      iconColor: Colors.indigo,
      trailing: const SeeCodeButton(
        title: 'Payment Configuration',
        description: 'Configure amount and method before processing.',
        code: _paymentDetailsCode,
      ),
      children: [
        TextField(
          controller: _amountController,
          enabled: !_isProcessing,
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixIcon: Icon(Icons.attach_money),
            border: OutlineInputBorder(),
            hintText: '0.00',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 16),
        Text('Payment Method', style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(_methods.length, (i) {
            final selected = _selectedMethod == i;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _methodIcons[i],
                    size: 16,
                    color: selected
                        ? theme.colorScheme.onSecondaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(_methods[i]),
                ],
              ),
              selected: selected,
              onSelected: _isProcessing
                  ? null
                  : (value) {
                      if (value) setState(() => _selectedMethod = i);
                    },
            );
          }),
        ),
      ],
    );
  }

  // ---- Actions --------------------------------------------------------------

  Widget _buildActionsCard() {
    return FeatureCard(
      title: 'Process Payment',
      subtitle: 'Execute or cancel the current payment',
      icon: Icons.send,
      iconColor: Colors.green,
      trailing: const SeeCodeButton(
        title: 'Process Payment',
        description: 'Loading toast with progress updates for payment processing.',
        code: _processPaymentCode,
      ),
      children: [
        DemoButton(
          label: 'Pay \$${(_parsedAmount ?? 0).toStringAsFixed(2)}',
          icon: Icons.payment,
          onPressed: _canProcess ? _processPayment : null,
          loading: _isProcessing,
          color: Colors.green,
        ),
        DemoButton(
          label: 'Cancel Payment',
          icon: Icons.cancel_outlined,
          onPressed: _isProcessing ? null : _cancelPayment,
          color: Colors.red,
        ),
      ],
    );
  }

  // ---- Payment History ------------------------------------------------------

  Widget _buildHistoryCard(ThemeData theme) {
    return FeatureCard(
      title: 'Payment History',
      subtitle: 'Recent payment attempts',
      icon: Icons.history,
      iconColor: Colors.deepPurple,
      trailing: const SeeCodeButton(
        title: 'Payment History',
        description: 'Track payment attempts and outcomes.',
        code: _paymentHistoryCode,
      ),
      children: [
        if (_history.isEmpty)
          Text(
            'No payments yet — process one above.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          )
        else ...[
          ..._history
              .take(10)
              .map((r) => _PaymentHistoryRow(record: r, theme: theme)),
          if (_history.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+ ${_history.length - 10} more',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          const SizedBox(height: 8),
          DemoButton(
            label: 'Clear History',
            icon: Icons.delete_outline,
            onPressed: _clearHistory,
            color: Colors.grey,
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// Private helpers
// =============================================================================

enum _PaymentStatus { success, failed, cancelled }

class _PaymentRecord {
  const _PaymentRecord({
    required this.status,
    required this.amount,
    required this.method,
    this.reason,
    required this.timestamp,
  });
  final _PaymentStatus status;
  final double amount;
  final String method;
  final String? reason;
  final DateTime timestamp;
}

class _PaymentHistoryRow extends StatelessWidget {
  const _PaymentHistoryRow({required this.record, required this.theme});

  final _PaymentRecord record;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    final String label;

    switch (record.status) {
      case _PaymentStatus.success:
        color = Colors.green;
        icon = Icons.check_circle;
        label = 'Success';
      case _PaymentStatus.failed:
        color = Colors.red;
        icon = Icons.cancel;
        label = 'Failed';
      case _PaymentStatus.cancelled:
        color = Colors.orange;
        icon = Icons.block;
        label = 'Cancelled';
    }

    final time = record.timestamp;
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';

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
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label — \$${record.amount.toStringAsFixed(2)} via ${record.method}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                if (record.reason != null)
                  Text(
                    record.reason!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            timeStr,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
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

const _paymentDetailsCode = '''// Payment method selection
int _selectedMethod = 0;
static const _methods = ['Credit Card', 'PayPal', 'Bank Transfer'];

// Validate before processing
if (amount <= 0) {
  ToastKit.warning('Enter a valid amount', channel: 'payment');
  return;
}''';

const _processPaymentCode = '''// Payment with progress and escalation
final ctrl = ToastKit.showLoading('Processing payment…', channel: 'payment');

try {
  await ApiService.instance.processPayment(amount: amount, method: method);
  ctrl.success('Payment of \$amount completed!');
} on PaymentException catch (e) {
  ctrl.error('Payment failed: \${e.message}');
  _failureCount++;

  // Escalation rules
  if (_failureCount >= 5) {
    ToastKit.show(ToastEvent.warning(
      message: 'Try a different payment method.',
      actions: [
        ToastAction(label: 'Switch to PayPal', onPressed: () {}),
      ],
    ));
  } else if (_failureCount >= 3) {
    ToastKit.show(ToastEvent.warning(
      message: 'Contact support for help.',
      actions: [
        ToastAction(label: 'Contact Support', onPressed: () {}),
      ],
    ));
  }
}''';

const _paymentHistoryCode = '''// Track payment history
final _history = <PaymentRecord>[];

void _addRecord(PaymentStatus status, double amount) {
  _history.insert(0, PaymentRecord(
    status: status,
    amount: amount,
    method: _methodLabel,
    timestamp: DateTime.now(),
  ));
}''';
