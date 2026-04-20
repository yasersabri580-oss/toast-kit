import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

import '../mock/custom_variants.dart';
import '../services/toast_service.dart';
import '../widgets/buttons/demo_button.dart';
import '../widgets/cards/feature_card.dart';
import '../widgets/responsive_body.dart';
import '../widgets/see_code_button.dart';

// =============================================================================
// Toast Builder Demo — Comprehensive Channel/Variant-Aware Usage
//
// This screen demonstrates the full power of ToastKit's builder system:
//
//   1. Multi-channel toasts (default, payment, system, notification)
//   2. Custom variant registration and per-channel assignment
//   3. Config-based and custom rules with real-time feedback
//   4. Progress/loading toast lifecycle
//   5. Fluent channel API
//   6. Runtime rule management
//
// Each section is self-contained and copy-paste ready.
// =============================================================================

class ToastBuilderDemo extends StatefulWidget {
  const ToastBuilderDemo({super.key});

  @override
  State<ToastBuilderDemo> createState() => _ToastBuilderDemoState();
}

class _ToastBuilderDemoState extends State<ToastBuilderDemo> {
  // ── State for interactive demos ──
  bool _serviceInitialized = false;
  int _paymentErrors = 0;
  int _systemErrors = 0;
  bool _isUploading = false;
  ToastController? _uploadCtrl;
  bool _customRuleAdded = false;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  void _initService() {
    // The ToastService registers channels, variants, and rules.
    // In a real app this is done once in app.dart; here we do it
    // from the demo screen for illustration.
    if (!_serviceInitialized) {
      _registerChannelsAndVariants();
      setState(() => _serviceInitialized = true);
    }
  }

  /// Register custom channels and variants for the demo.
  ///
  /// In production, this would be in your app's initialization code.
  void _registerChannelsAndVariants() {
    // Register custom variants.
    if (!ToastKit.isVariantRegistered('payment_success')) {
      ToastKit.registerVariant(PaymentSuccessVariant());
    }
    if (!ToastKit.isVariantRegistered('system_error')) {
      ToastKit.registerVariant(SystemErrorVariant());
    }
    if (!ToastKit.isVariantRegistered('notification_banner')) {
      ToastKit.registerVariant(NotificationBannerVariant());
    }

    // Register channels with custom variant assignments.
    ToastKit.registerChannel(
      ToastService.paymentChannel,
      config: const ChannelConfig(
        maxVisible: 1,
        enableDeduplication: true,
        deduplicationWindow: Duration(seconds: 3),
      ),
    );
    ToastKit.registerChannel(
      ToastService.systemChannel,
      config: const ChannelConfig(
        maxVisible: 2,
        enableDeduplication: true,
        deduplicationWindow: Duration(seconds: 2),
      ),
    );
    ToastKit.registerChannel(
      ToastService.notificationChannel,
      config: const ChannelConfig(
        maxVisible: 3,
      ),
    );

    // Set up rules.
    _setupRules();
  }

  void _setupRules() {
    // Config-based rule on payment channel.
    ToastKit.configureRule(
      ToastService.channelPayment,
      const RuleConfig(
        errorThreshold: 3,
        deduplicateWindow: Duration(seconds: 60),
        maxTriggers: 1,
      ),
    );

    // Custom rule: suggest help after 2 payment errors.
    ToastKit.addRule(ToastRule(
      id: 'demo-payment-help',
      channel: ToastService.channelPayment,
      maxTriggers: 1,
      condition: (stats, event) => stats.errorCount >= 2,
      action: (context) {
        ToastKit.show(ToastEvent.info(
          message: 'Need help? Try switching your payment method.',
          title: 'Payment Tip',
          variant: ToastVariant.action,
          deduplicationKey: 'demo-payment-help-toast',
          actions: [
            ToastAction(
              label: 'Switch Method',
              onPressed: () => ToastKit.success(
                'Payment method updated!',
                channel: ToastService.channelPayment,
              ),
            ),
          ],
          channel: ToastService.channelPayment,
        ));
      },
    ));

    // Custom rule: error burst detection on system channel.
    ToastKit.addRule(ToastRule(
      id: 'demo-system-burst',
      channel: ToastService.channelSystem,
      deduplicateWindow: const Duration(seconds: 60),
      condition: (stats, event) {
        return stats.errorsInWindow(const Duration(seconds: 30)) >= 3;
      },
      action: (context) {
        ToastKit.show(ToastEvent.error(
          message:
              'Error burst detected: ${context.stats.errorCount} errors in the last 30s.',
          title: 'System Alert',
          persistent: true,
          dismissible: true,
          deduplicationKey: 'demo-system-burst-toast',
          channel: ToastService.channelSystem,
        ));
      },
    ));
  }

  // ── Demo actions ──

  void _showChannelToast(String channelId, ToastType type, String message,
      {String? title}) {
    switch (type) {
      case ToastType.success:
        ToastKit.success(message, title: title, channel: channelId);
      case ToastType.error:
        ToastKit.error(message, title: title, channel: channelId);
      case ToastType.warning:
        ToastKit.warning(message, title: title, channel: channelId);
      case ToastType.info:
        ToastKit.info(message, title: title, channel: channelId);
      default:
        ToastKit.info(message, title: title, channel: channelId);
    }
  }

  void _showPaymentSuccess() {
    ToastKit.channel(ToastService.channelPayment).success(
      'Payment of \$49.99 processed successfully!',
      title: 'Payment Received',
    );
  }

  void _showPaymentError() {
    setState(() => _paymentErrors++);
    ToastKit.channel(ToastService.channelPayment).error(
      'Card ending in 4242 was declined.',
      title: 'Payment Failed',
    );
  }

  void _showSystemError() {
    setState(() => _systemErrors++);
    ToastKit.error(
      'Database connection timeout after 30s.',
      title: 'System Error',
      channel: ToastService.channelSystem,
    );
  }

  void _showCriticalError() {
    ToastKit.show(ToastEvent(
      type: ToastType.error,
      message: 'Unrecoverable error. Please restart the application.',
      title: 'Critical Failure',
      icon: Icons.dangerous_rounded,
      persistent: true,
      dismissible: false,
      priority: ToastPriority.urgent,
      channel: ToastService.channelSystem,
      actions: [
        ToastAction(
          label: 'Acknowledge',
          onPressed: () => ToastKit.dismissAll(),
        ),
      ],
    ));
  }

  void _showNotification() {
    ToastKit.info(
      'Your weekly report is ready for download.',
      title: 'New Report',
      channel: ToastService.channelNotification,
    );
  }

  void _showVariantOverride() {
    // Demonstrate per-event variant override — use glassmorphism on payment
    // channel even though the channel default is payment_success.
    ToastKit.show(ToastEvent.success(
      message: 'Variant override: using glassmorphism on payment channel',
      title: 'Override Demo',
      variant: ToastVariant.glassmorphism,
      channel: ToastService.channelPayment,
    ));
  }

  void _startUpload() {
    if (_isUploading) return;
    setState(() => _isUploading = true);

    _uploadCtrl = ToastKit.showLoading('Uploading report.pdf…');
    int pct = 0;

    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 150));
      if (_uploadCtrl == null || _uploadCtrl!.isDisposed) {
        setState(() => _isUploading = false);
        return false;
      }
      pct += 5;
      _uploadCtrl!.update(message: 'Uploading report.pdf… $pct%');
      _uploadCtrl!.progress.value = pct / 100;

      if (pct >= 100) {
        _uploadCtrl!.success('report.pdf uploaded!');
        setState(() {
          _isUploading = false;
          _uploadCtrl = null;
        });
        return false;
      }
      return true;
    });
  }

  void _startFailingUpload() {
    if (_isUploading) return;
    setState(() => _isUploading = true);

    _uploadCtrl = ToastKit.showLoading('Uploading data.csv…');
    int pct = 0;

    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 150));
      if (_uploadCtrl == null || _uploadCtrl!.isDisposed) {
        setState(() => _isUploading = false);
        return false;
      }
      pct += 5;
      _uploadCtrl!.update(message: 'Uploading data.csv… $pct%');
      _uploadCtrl!.progress.value = pct / 100;

      if (pct >= 60) {
        _uploadCtrl!.error('Upload failed at $pct% — connection lost');
        setState(() {
          _isUploading = false;
          _uploadCtrl = null;
        });
        return false;
      }
      return true;
    });
  }

  void _toggleCustomRule() {
    if (_customRuleAdded) {
      ToastKit.removeRule('demo-runtime-rule');
      setState(() => _customRuleAdded = false);
    } else {
      ToastKit.addRule(ToastRule(
        id: 'demo-runtime-rule',
        channel: ToastService.channelNotification,
        maxTriggers: 1,
        condition: (stats, event) => stats.totalCount >= 3,
        action: (context) {
          ToastKit.show(ToastEvent.warning(
            message: 'You have ${context.stats.totalCount} notifications. '
                'Consider reviewing them.',
            title: 'Notification Overload',
            channel: ToastService.channelNotification,
          ));
        },
      ));
      setState(() => _customRuleAdded = true);
    }
  }

  void _resetAllStats() {
    ToastKit.ruleEngine.resetStats();
    setState(() {
      _paymentErrors = 0;
      _systemErrors = 0;
    });
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Toast Builder Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset stats',
            onPressed: _resetAllStats,
          ),
          IconButton(
            icon: const Icon(Icons.clear_all_rounded),
            tooltip: 'Dismiss all',
            onPressed: () => ToastKit.dismissAll(),
          ),
        ],
      ),
      body: ResponsiveBody(
        children: [
          _buildChannelSection(cs),
          const SizedBox(height: 16),
          _buildVariantSection(cs),
          const SizedBox(height: 16),
          _buildRulesSection(cs),
          const SizedBox(height: 16),
          _buildProgressSection(cs),
          const SizedBox(height: 16),
          _buildRuntimeRulesSection(cs),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Section 1: Channels ──

  Widget _buildChannelSection(ColorScheme cs) {
    return FeatureCard(
      title: 'Multi-Channel Toasts',
      subtitle: 'Each channel has its own variant, priority, and limits',
      icon: Icons.layers_rounded,
      iconColor: cs.primary,
      trailing: const SeeCodeButton(
        title: 'Channel Setup',
        description:
            'Define multiple channels with per-channel variants and config.',
        code: _channelSetupCode,
      ),
      children: [
        DemoButton(
          label: 'Default Channel — Info',
          icon: Icons.info_outline_rounded,
          onPressed: () => _showChannelToast(
            ToastService.channelDefault,
            ToastType.info,
            'A new version is available.',
            title: 'Update',
          ),
        ),
        DemoButton(
          label: 'Payment Channel — Success',
          icon: Icons.payment_rounded,
          color: Colors.green,
          onPressed: _showPaymentSuccess,
        ),
        DemoButton(
          label: 'System Channel — Error',
          icon: Icons.error_outline_rounded,
          color: cs.error,
          onPressed: _showSystemError,
        ),
        DemoButton(
          label: 'Notification Channel — Banner',
          icon: Icons.notifications_active_rounded,
          color: cs.tertiary,
          onPressed: _showNotification,
        ),
      ],
    );
  }

  // ── Section 2: Variants ──

  Widget _buildVariantSection(ColorScheme cs) {
    return FeatureCard(
      title: 'Custom Variants & Overrides',
      subtitle: 'Register once, use everywhere — or override per-event',
      icon: Icons.palette_rounded,
      iconColor: Colors.purple,
      trailing: const SeeCodeButton(
        title: 'Custom Variants',
        description:
            'Create reusable variant builders and assign them to channels.',
        code: _variantCode,
      ),
      children: [
        DemoButton(
          label: 'Payment Variant (channel default)',
          icon: Icons.payment_rounded,
          color: Colors.green,
          onPressed: _showPaymentSuccess,
        ),
        DemoButton(
          label: 'System Error Variant (channel default)',
          icon: Icons.error_rounded,
          color: Colors.red,
          onPressed: _showCriticalError,
        ),
        DemoButton(
          label: 'Notification Banner Variant',
          icon: Icons.notifications_rounded,
          color: Colors.indigo,
          onPressed: _showNotification,
        ),
        DemoButton(
          label: 'Per-Event Override (glassmorphism on payment)',
          icon: Icons.auto_awesome_rounded,
          color: Colors.deepPurple,
          onPressed: _showVariantOverride,
        ),
      ],
    );
  }

  // ── Section 3: Rules ──

  Widget _buildRulesSection(ColorScheme cs) {
    return FeatureCard(
      title: 'Rules & Assignment',
      subtitle:
          'Tap payment/system errors multiple times to trigger rules',
      icon: Icons.rule_rounded,
      iconColor: Colors.orange,
      trailing: const SeeCodeButton(
        title: 'Rules Engine',
        description:
            'Config-based and custom rules with stats-driven conditions.',
        code: _rulesCode,
      ),
      children: [
        DemoButton(
          label: 'Payment Error ($_paymentErrors errors — rule at 2)',
          icon: Icons.credit_card_off_rounded,
          color: Colors.red.shade700,
          onPressed: _showPaymentError,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Text(
            'After 2 payment errors, a help suggestion rule triggers automatically.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.outline),
          ),
        ),
        DemoButton(
          label: 'System Error ($_systemErrors errors — burst at 3)',
          icon: Icons.warning_amber_rounded,
          color: Colors.deepOrange,
          onPressed: _showSystemError,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Text(
            'After 3 system errors in 30 seconds, an error burst alert triggers.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.outline),
          ),
        ),
        DemoButton(
          label: 'Reset Rule Stats',
          icon: Icons.restart_alt_rounded,
          color: cs.outline,
          onPressed: _resetAllStats,
        ),
      ],
    );
  }

  // ── Section 4: Progress ──

  Widget _buildProgressSection(ColorScheme cs) {
    return FeatureCard(
      title: 'Progress & Loading',
      subtitle: 'Start, update, complete, or fail a loading toast',
      icon: Icons.cloud_upload_rounded,
      iconColor: cs.primary,
      trailing: const SeeCodeButton(
        title: 'Progress Toast',
        description:
            'Use ToastController to update progress, message, and final state.',
        code: _progressCode,
      ),
      children: [
        DemoButton(
          label: 'Upload File (success)',
          icon: Icons.upload_file_rounded,
          onPressed: _isUploading ? null : _startUpload,
          loading: _isUploading,
        ),
        DemoButton(
          label: 'Upload File (fails at 60%)',
          icon: Icons.error_outline_rounded,
          color: cs.error,
          onPressed: _isUploading ? null : _startFailingUpload,
          loading: _isUploading,
        ),
      ],
    );
  }

  // ── Section 5: Runtime Rules ──

  Widget _buildRuntimeRulesSection(ColorScheme cs) {
    return FeatureCard(
      title: 'Runtime Rule Management',
      subtitle: 'Add or remove rules dynamically at runtime',
      icon: Icons.tune_rounded,
      iconColor: Colors.teal,
      trailing: const SeeCodeButton(
        title: 'Dynamic Rules',
        description: 'Add, remove, and reset rules at runtime.',
        code: _runtimeRulesCode,
      ),
      children: [
        DemoButton(
          label: _customRuleAdded
              ? 'Remove Runtime Rule'
              : 'Add Runtime Rule (notification overload)',
          icon: _customRuleAdded
              ? Icons.remove_circle_outline_rounded
              : Icons.add_circle_outline_rounded,
          color: _customRuleAdded ? Colors.red : Colors.teal,
          onPressed: _toggleCustomRule,
        ),
        if (_customRuleAdded)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              'Rule added: after 3 notification toasts, a warning fires. '
              'Send notifications above to trigger it.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.outline),
            ),
          ),
        DemoButton(
          label: 'Send Notification (to trigger rule)',
          icon: Icons.send_rounded,
          color: cs.tertiary,
          onPressed: _showNotification,
        ),
      ],
    );
  }
}

// =============================================================================
// Code Strings for "See Code" modals
// =============================================================================

const _channelSetupCode = '''// Define channels with per-channel variants and config
const paymentChannel = ToastChannel(
  id: 'payment',
  label: 'Payment Channel',
  customVariantName: 'payment_success', // Uses registered variant
  maxVisible: 1,
  defaultPriority: ToastPriority.urgent,
  defaultDuration: Duration(seconds: 5),
  defaultPosition: ToastPosition.top,
  defaultAnimation: ToastAnimationType.slideFromTop,
);

const systemChannel = ToastChannel(
  id: 'system',
  label: 'System Channel',
  customVariantName: 'system_error',
  maxVisible: 2,
  defaultPriority: ToastPriority.high,
);

// Register at init
ToastKit.init(
  navigatorKey: navigatorKey,
  channels: [paymentChannel, systemChannel],
);

// Or register later with per-channel policies
ToastKit.registerChannel(
  paymentChannel,
  config: const ChannelConfig(
    maxVisible: 1,
    enableDeduplication: true,
    deduplicationWindow: Duration(seconds: 3),
  ),
);

// Use the fluent channel API
ToastKit.channel('payment').success('Payment received!');
ToastKit.channel('system').error('Database timeout');''';

const _variantCode = '''// 1. Define a custom variant
class PaymentSuccessVariant extends CustomToastVariantBuilder {
  @override
  String get name => 'payment_success';

  @override
  Widget build(BuildContext context, ToastEvent event,
      ToastController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green),
      ),
      child: Row(children: [
        Icon(Icons.payment, color: Colors.green),
        SizedBox(width: 12),
        Expanded(child: Text(event.message ?? '')),
        IconButton(
          icon: Icon(Icons.close),
          onPressed: controller.dismiss,
        ),
      ]),
    );
  }
}

// 2. Register it
ToastKit.registerVariant(PaymentSuccessVariant());

// 3. Assign to a channel (auto-applies to all toasts)
ToastKit.registerChannel(const ToastChannel(
  id: 'payment',
  label: 'Payment',
  customVariantName: 'payment_success',
));

// 4. Or use per-event
ToastKit.success('Paid!', customVariantName: 'payment_success');

// 5. Override per-event (glassmorphism on payment channel)
ToastKit.show(ToastEvent.success(
  message: 'Override!',
  variant: ToastVariant.glassmorphism, // Overrides channel default
  channel: 'payment',
));''';

const _rulesCode = '''// Config-based rule: fire after 3 payment errors
ToastKit.configureRule(
  'payment',
  RuleConfig(
    errorThreshold: 3,
    deduplicateWindow: Duration(seconds: 60),
    maxTriggers: 1,
  ),
);

// Custom rule: suggest help after 2 errors
ToastKit.addRule(ToastRule(
  id: 'payment-help',
  channel: 'payment',
  maxTriggers: 1,
  condition: (stats, event) => stats.errorCount >= 2,
  action: (context) {
    ToastKit.show(ToastEvent.info(
      message: 'Try a different payment method.',
      variant: ToastVariant.action,
      actions: [
        ToastAction(
          label: 'Switch Method',
          onPressed: () => ToastKit.success('Updated!'),
        ),
      ],
      channel: 'payment',
    ));
  },
));

// Error burst detection on system channel
ToastKit.addRule(ToastRule(
  id: 'system-burst',
  channel: 'system',
  deduplicateWindow: Duration(seconds: 60),
  condition: (stats, event) =>
      stats.errorsInWindow(Duration(seconds: 30)) >= 3,
  action: (context) {
    ToastKit.show(ToastEvent.error(
      message: 'Error burst: \${context.stats.errorCount} errors',
      persistent: true,
      channel: 'system',
    ));
  },
));

// Send errors — rules evaluate automatically
ToastKit.error('Payment declined', channel: 'payment');''';

const _progressCode = '''// Start a loading toast with controller
final ctrl = ToastKit.showLoading('Uploading file…');

// Update progress in a loop
for (var pct = 0; pct <= 100; pct += 5) {
  await Future.delayed(Duration(milliseconds: 150));
  if (ctrl.isDisposed) break;
  ctrl.update(message: 'Uploading… \$pct%');
  ctrl.progress.value = pct / 100;
}

// Complete or fail
ctrl.success('Upload complete!');
// or
ctrl.error('Upload failed at 60%');''';

const _runtimeRulesCode = '''// Add a rule at runtime
ToastKit.addRule(ToastRule(
  id: 'notification-overload',
  channel: 'notification',
  maxTriggers: 1,
  condition: (stats, event) => stats.totalCount >= 3,
  action: (context) {
    ToastKit.warning(
      'You have \${context.stats.totalCount} notifications.',
      channel: 'notification',
    );
  },
));

// Remove when no longer needed
ToastKit.removeRule('notification-overload');

// Reset stats but keep rules
ToastKit.ruleEngine.resetStats();

// Clear everything (rules + stats + trigger counts)
ToastKit.ruleEngine.clear();''';
