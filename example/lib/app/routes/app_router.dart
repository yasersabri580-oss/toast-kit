import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_demo_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/network/network_demo_screen.dart';
import '../../features/notifications/notification_demo_screen.dart';
import '../../features/payments/payment_demo_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../toast_demo/toast_autodismiss_demo.dart';
import '../../toast_demo/toast_builder_demo.dart';
import '../../toast_demo/toast_configurator_screen.dart';
import '../../toast_demo/toast_progress_demo.dart';
import '../../toast_demo/toast_rules_demo.dart';
import '../../toast_demo/toast_showcase.dart';
import '../../toast_demo/toast_stress_test.dart';
import '../../utils/responsive/responsive_helper.dart';

/// Route path constants.
class AppRoutes {
  AppRoutes._();

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
  static const String builderDemo = '/toast/builder';
  static const String configurator = '/toast/configurator';
}

/// Creates the app's [GoRouter] configuration.
GoRouter createRouter(GlobalKey<NavigatorState> navigatorKey) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.dashboard,
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return _AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.auth,
            builder: (context, state) => const AuthDemoScreen(),
          ),
          GoRoute(
            path: AppRoutes.network,
            builder: (context, state) => const NetworkDemoScreen(),
          ),
          GoRoute(
            path: AppRoutes.payments,
            builder: (context, state) => const PaymentDemoScreen(),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (context, state) => const NotificationDemoScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.showcase,
            builder: (context, state) => const ToastShowcase(),
          ),
          GoRoute(
            path: AppRoutes.stressTest,
            builder: (context, state) => const ToastStressTest(),
          ),
          GoRoute(
            path: AppRoutes.rulesDemo,
            builder: (context, state) => const ToastRulesDemo(),
          ),
          GoRoute(
            path: AppRoutes.progressDemo,
            builder: (context, state) => const ToastProgressDemo(),
          ),
          GoRoute(
            path: AppRoutes.autodismissDemo,
            builder: (context, state) => const ToastAutodismissDemo(),
          ),
          GoRoute(
            path: AppRoutes.builderDemo,
            builder: (context, state) => const ToastBuilderDemo(),
          ),
          GoRoute(
            path: AppRoutes.configurator,
            builder: (context, state) => const ToastConfiguratorScreen(),
          ),
        ],
      ),
    ],
  );
}

/// Shell widget that wraps all routes with a NavigationRail on desktop
/// and a FAB for quick access to Toast Builder.
class _AppShell extends StatelessWidget {
  const _AppShell({required this.child});

  final Widget child;

  static const _navItems = <_NavItem>[
    _NavItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Dashboard',
      route: AppRoutes.dashboard,
    ),
    _NavItem(
      icon: Icons.palette_outlined,
      selectedIcon: Icons.palette,
      label: 'Showcase',
      route: AppRoutes.showcase,
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
      route: AppRoutes.settings,
    ),
  ];

  int _selectedIndex(String location) {
    for (var i = 0; i < _navItems.length; i++) {
      if (location == _navItems[i].route) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _selectedIndex(location);

    final isOnConfigurator = location == AppRoutes.configurator;

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                context.go(_navItems[index].route);
              },
              labelType: NavigationRailLabelType.all,
              destinations: _navItems
                  .map(
                    (item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: Text(item.label),
                    ),
                  )
                  .toList(),
            ),
          if (isDesktop) const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
      floatingActionButton: isOnConfigurator
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.go(AppRoutes.configurator),
              icon: const Icon(Icons.bolt),
              label: const Text('Toast Builder'),
              tooltip: 'Open Toast Builder',
            ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;
}
