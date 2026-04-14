import 'package:flutter/material.dart' hide RouterConfig;
import 'package:toast_kit/toast_kit.dart';

import '../utils/demo_logger.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Plugins (kept from the original main.dart)
// ---------------------------------------------------------------------------

/// Logger plugin — prints lifecycle events to the console.
class LoggerPlugin extends ToastPlugin {
  @override
  String get name => 'logger';

  @override
  void onAttach() => debugPrint('[ToastKit:Logger] Plugin attached');

  @override
  void onDetach() => debugPrint('[ToastKit:Logger] Plugin detached');

  @override
  void onToastShown(ToastEvent event) {
    final msg = '[ToastKit:Logger] SHOWN — ${event.type.name}: '
        '"${event.message}"'
        '${event.channel != null ? " [${event.channel}]" : ""}';
    debugPrint(msg);
    DemoLogger.instance.log(msg);
  }

  @override
  void onToastQueued(ToastEvent event) {
    final msg = '[ToastKit:Logger] QUEUED — ${event.id}';
    debugPrint(msg);
    DemoLogger.instance.log(msg);
  }

  @override
  void onToastDismissed(ToastEvent event, DismissReason? reason) {
    final msg = '[ToastKit:Logger] DISMISSED — ${event.id} '
        '(${reason?.name ?? "auto"})';
    debugPrint(msg);
    DemoLogger.instance.log(msg);
  }

  @override
  void onToastDropped(ToastEvent event, String reason) {
    final msg = '[ToastKit:Logger] DROPPED — ${event.id}: $reason';
    debugPrint(msg);
    DemoLogger.instance.log(msg);
  }

  @override
  void onRuleTriggered(String ruleId, String channel) {
    final msg =
        '[ToastKit:Logger] RULE TRIGGERED — $ruleId on "$channel"';
    debugPrint(msg);
    DemoLogger.instance.log(msg);
  }
}

/// Analytics plugin — simulated analytics tracking.
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
    debugPrint('[Analytics] $name: $params');
  }
}

/// Haptics plugin — simulated haptic feedback.
class HapticsPlugin extends ToastPlugin {
  @override
  String get name => 'haptics';

  @override
  void onToastShown(ToastEvent event) {
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
// App widget
// ---------------------------------------------------------------------------

/// Root application widget with Material 3 theming and ToastKit initialisation.
class ToastKitShowcaseApp extends StatefulWidget {
  const ToastKitShowcaseApp({super.key});

  @override
  State<ToastKitShowcaseApp> createState() => _ToastKitShowcaseAppState();
}

class _ToastKitShowcaseAppState extends State<ToastKitShowcaseApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initToastKit();
    });
  }

  void _initToastKit() {
    ToastKit.init(
      navigatorKey: _navigatorKey,
      config: const ToastConfig(
        defaultPosition: ToastPosition.top,
        maxVisibleToasts: 3,
        enableQueue: true,
        queueMode: QueueMode.fifo,
        maxQueueSize: 50,
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
      title: 'ToastKit Showcase',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routes: AppRouter.routes,
      initialRoute: AppRouter.dashboard,
    );
  }
}
