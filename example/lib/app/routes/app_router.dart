import 'package:flutter/material.dart';

import '../../features/auth/auth_demo_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/network/network_demo_screen.dart';
import '../../features/notifications/notification_demo_screen.dart';
import '../../features/payments/payment_demo_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../toast_demo/toast_autodismiss_demo.dart';
import '../../toast_demo/toast_configurator_screen.dart';
import '../../toast_demo/toast_progress_demo.dart';
import '../../toast_demo/toast_rules_demo.dart';
import '../../toast_demo/toast_showcase.dart';
import '../../toast_demo/toast_stress_test.dart';

/// Named-route table for the showcase application.
class AppRouter {
  AppRouter._();

  // Route names ---------------------------------------------------------------
  static const String dashboard = '/';
  static const String auth = '/auth';
  static const String network = '/network';
  static const String payments = '/payments';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String showcase = '/toast/showcase';
  static const String stressTest = '/toast/stress-test';
  static const String rulesDemo = '/toast/rules';
  static const String progressDemo = '/toast/progress';
  static const String autodismissDemo = '/toast/autodismiss';
  static const String configurator = '/toast/configurator';

  // Route map -----------------------------------------------------------------
  static Map<String, WidgetBuilder> routes = {
    dashboard: (_) => const DashboardScreen(),
    auth: (_) => const AuthDemoScreen(),
    network: (_) => const NetworkDemoScreen(),
    payments: (_) => const PaymentDemoScreen(),
    notifications: (_) => const NotificationDemoScreen(),
    settings: (_) => const SettingsScreen(),
    showcase: (_) => const ToastShowcase(),
    stressTest: (_) => const ToastStressTest(),
    rulesDemo: (_) => const ToastRulesDemo(),
    progressDemo: (_) => const ToastProgressDemo(),
    autodismissDemo: (_) => const ToastAutodismissDemo(),
    configurator: (_) => const ToastConfiguratorScreen(),
  };
}
