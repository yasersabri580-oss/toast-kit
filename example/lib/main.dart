import 'package:flutter/material.dart' hide RouterConfig;
import 'package:toast_kit/toast_kit.dart';

import 'screens/demo_screen.dart';

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
          maxQueueSize: 50,
          globalRateLimit: Duration(milliseconds: 150),
        ),
        routerConfig: const RouterConfig(
          enableDeduplication: true,
          deduplicationWindow: Duration(seconds: 2),
          enableThrottling: true,
          throttleInterval: Duration(milliseconds: 300),
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

  // -- Theme ------------------------------------------------------------------

  static const _seed = Colors.deepPurple;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'ToastKit Demo',
      debugShowCheckedModeBanner: false,
      // Light theme — Material 3
      theme: ThemeData(
        colorSchemeSeed: _seed,
        useMaterial3: true,
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(centerTitle: true),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      // Dark theme — Material 3
      darkTheme: ThemeData(
        colorSchemeSeed: _seed,
        useMaterial3: true,
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(centerTitle: true),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const DemoScreen(),
    );
  }
}
