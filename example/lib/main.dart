import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

import 'scenarios/api_error.dart';
import 'scenarios/form_validation.dart';
import 'scenarios/login_rules.dart';
import 'scenarios/payment_failure.dart';
import 'scenarios/network_retry.dart';
import 'scenarios/custom_ui.dart';

void main() {
  runApp(const ToastKitExampleApp());
}

// ---------------------------------------------------------------------------
// Logger Plugin — prints lifecycle events to the console.
// ---------------------------------------------------------------------------
class LoggerPlugin extends ToastPlugin {
  @override
  String get name => 'logger';

  @override
  void onAttach() => debugPrint('[ToastKit:Logger] Plugin attached');

  @override
  void onDetach() => debugPrint('[ToastKit:Logger] Plugin detached');

  @override
  void onToastShown(ToastEvent event) {
    debugPrint('[ToastKit:Logger] SHOWN — ${event.type.name}: '
        '"${event.message}"'
        '${event.channel != null ? " [${event.channel}]" : ""}');
  }

  @override
  void onToastQueued(ToastEvent event) {
    debugPrint('[ToastKit:Logger] QUEUED — ${event.id}');
  }

  @override
  void onToastDismissed(ToastEvent event, DismissReason? reason) {
    debugPrint('[ToastKit:Logger] DISMISSED — ${event.id} '
        '(${reason?.name ?? "auto"})');
  }

  @override
  void onToastDropped(ToastEvent event, String reason) {
    debugPrint('[ToastKit:Logger] DROPPED — ${event.id}: $reason');
  }

  @override
  void onRuleTriggered(String ruleId, String channel) {
    debugPrint('[ToastKit:Logger] RULE TRIGGERED — $ruleId on "$channel"');
  }
}

// ---------------------------------------------------------------------------
// Analytics Plugin — simulated analytics tracking.
// ---------------------------------------------------------------------------
class AnalyticsPlugin extends ToastPlugin {
  @override
  String get name => 'analytics';

  @override
  void onToastShown(ToastEvent event) {
    _trackEvent('toast_shown', {
      'type': event.type.name,
      'message': event.message ?? '',
      'channel': event.channel ?? 'default',
    });
  }

  @override
  void onToastDismissed(ToastEvent event, DismissReason? reason) {
    _trackEvent('toast_dismissed', {
      'toast_id': event.id,
      'dismiss_reason': reason?.name ?? 'auto',
    });
  }

  @override
  void onRuleTriggered(String ruleId, String channel) {
    _trackEvent('toast_rule_triggered', {
      'rule_id': ruleId,
      'channel': channel,
    });
  }

  void _trackEvent(String name, Map<String, String> params) {
    // Replace with your real analytics SDK (Firebase, Mixpanel, etc.)
    debugPrint('[Analytics] $name: $params');
  }
}

// ---------------------------------------------------------------------------
// Haptics Plugin — simulated haptic feedback.
// ---------------------------------------------------------------------------
class HapticsPlugin extends ToastPlugin {
  @override
  String get name => 'haptics';

  @override
  void onToastShown(ToastEvent event) {
    // In a real app, use HapticFeedback from flutter/services.dart.
    final intensity = switch (event.type) {
      ToastType.error => 'heavy',
      ToastType.warning => 'medium',
      ToastType.success => 'light',
      _ => 'selection',
    };
    debugPrint('[Haptics] ${intensity}Impact for ${event.type.name}');
  }
}

// ---------------------------------------------------------------------------
// App
// ---------------------------------------------------------------------------
class ToastKitExampleApp extends StatefulWidget {
  const ToastKitExampleApp({super.key});

  @override
  State<ToastKitExampleApp> createState() => _ToastKitExampleAppState();
}

class _ToastKitExampleAppState extends State<ToastKitExampleApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ToastKit.init(
        navigatorKey: _navigatorKey,
        config: const ToastConfig(
          defaultPosition: ToastPosition.top,
          maxVisibleToasts: 3,
          enableQueue: true,
          queueMode: QueueMode.fifo,
        ),
        routerConfig: const RouterConfig(
          enableDeduplication: true,
          deduplicationWindow: Duration(seconds: 2),
        ),
        channels: [
          ToastChannel.auth,
          ToastChannel.network,
          ToastChannel.payment,
        ],
        plugins: [
          LoggerPlugin(),
          AnalyticsPlugin(),
          HapticsPlugin(),
        ],
      );
    });
  }

  @override
  void dispose() {
    ToastKit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'ToastKit Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}

// ---------------------------------------------------------------------------
// Home Page
// ---------------------------------------------------------------------------
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ToastKit SDK Demo'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Basic Toasts ----
          _section('Basic Toasts'),
          _row([
            _btn('Success', Colors.green,
                () => ToastKit.success('Operation completed!')),
            _btn('Error', Colors.red,
                () => ToastKit.error('Something went wrong.')),
          ]),
          const SizedBox(height: 8),
          _row([
            _btn('Warning', Colors.orange,
                () => ToastKit.warning('Battery low.')),
            _btn('Info', Colors.blue,
                () => ToastKit.info('New update available.')),
          ]),
          const SizedBox(height: 8),
          _btn('Loading → Success', Colors.purple, () async {
            final ctrl = ToastKit.showLoading('Saving…');
            await Future.delayed(const Duration(seconds: 2));
            ctrl.success('Saved successfully!');
          }),

          // ---- Variants ----
          const SizedBox(height: 24),
          _section('Variants'),
          _btn('Minimal', Colors.teal, () {
            ToastKit.show(ToastEvent.success(
                message: 'Minimal style', variant: ToastVariant.minimal));
          }),
          const SizedBox(height: 8),
          _btn('Glassmorphism', Colors.indigo, () {
            ToastKit.show(ToastEvent.info(
                message: 'Frosted glass',
                variant: ToastVariant.glassmorphism));
          }),
          const SizedBox(height: 8),
          _btn('Gradient', Colors.pink, () {
            ToastKit.show(ToastEvent.error(
                message: 'Gradient background',
                variant: ToastVariant.gradient));
          }),
          const SizedBox(height: 8),
          _btn('Compact', Colors.cyan, () {
            ToastKit.show(ToastEvent.success(
                message: 'Compact!', variant: ToastVariant.compact));
          }),
          const SizedBox(height: 8),
          _btn('Full Width', Colors.amber.shade800, () {
            ToastKit.show(ToastEvent.warning(
                message: 'Full-width banner',
                variant: ToastVariant.fullWidth));
          }),
          const SizedBox(height: 8),
          _btn('Debug', Colors.grey.shade800, () {
            ToastKit.show(ToastEvent.info(
                message: 'Debug info', variant: ToastVariant.debug));
          }),

          // ---- Action Toasts ----
          const SizedBox(height: 24),
          _section('Action Toasts'),
          _btn('With Actions', Colors.deepOrange, () {
            ToastKit.show(ToastEvent.error(
              message: 'Failed to send',
              variant: ToastVariant.action,
              actions: [
                ToastAction(label: 'Retry', onPressed: () {
                  ToastKit.info('Retrying…');
                }),
                ToastAction(label: 'Cancel', onPressed: () {}),
              ],
            ));
          }),

          // ---- Positions ----
          const SizedBox(height: 24),
          _section('Positions'),
          _row([
            _btn('Top', Colors.blueGrey, () {
              ToastKit.show(ToastEvent.info(
                  message: 'Top', position: ToastPosition.top));
            }),
            _btn('Center', Colors.blueGrey, () {
              ToastKit.show(ToastEvent.info(
                  message: 'Center', position: ToastPosition.center));
            }),
            _btn('Bottom', Colors.blueGrey, () {
              ToastKit.show(ToastEvent.info(
                  message: 'Bottom', position: ToastPosition.bottom));
            }),
          ]),

          // ---- Scenarios ----
          const SizedBox(height: 24),
          _section('Real-World Scenarios'),
          _navBtn(context, 'API Error Handling',
              Icons.cloud_off, const ApiErrorScenario()),
          const SizedBox(height: 8),
          _navBtn(context, 'Form Validation',
              Icons.edit_document, const FormValidationScenario()),
          const SizedBox(height: 8),
          _navBtn(context, 'Login Rules',
              Icons.lock, const LoginRulesScenario()),
          const SizedBox(height: 8),
          _navBtn(context, 'Payment Failure',
              Icons.payment, const PaymentFailureScenario()),
          const SizedBox(height: 8),
          _navBtn(context, 'Network Retry',
              Icons.wifi_off, const NetworkRetryScenario()),
          const SizedBox(height: 8),
          _navBtn(context, 'Custom UI',
              Icons.palette, const CustomUiScenario()),

          // ---- Management ----
          const SizedBox(height: 24),
          _section('Management'),
          _btn('Dismiss All', Colors.red.shade900,
              () => ToastKit.dismissAll()),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  // ---- Helpers ----

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _row(List<Widget> children) => Row(
        children: children
            .expand((c) => [Expanded(child: c), const SizedBox(width: 8)])
            .toList()
          ..removeLast(),
      );

  Widget _btn(String label, Color color, VoidCallback onTap) => FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(backgroundColor: color),
        child: Text(label),
      );

  Widget _navBtn(
      BuildContext context, String label, IconData icon, Widget page) {
    return FilledButton.icon(
      onPressed: () =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)),
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.deepPurple.shade700,
      ),
    );
  }
}
