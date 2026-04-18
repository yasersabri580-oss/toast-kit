import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:toast_kit/toast_kit.dart';

import '../../app/routes/app_router.dart';
import '../../app/theme/theme_selector.dart';
import '../../utils/responsive/responsive_helper.dart';
import '../../widgets/see_code_button.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const _features = <_FeatureItem>[
    _FeatureItem(
      title: 'Auth System',
      subtitle: 'Login, registration & session management',
      icon: Icons.lock_outline,
      route: '/auth',
      color: Colors.green,
    ),
    _FeatureItem(
      title: 'Network & Retry',
      subtitle: 'Connectivity handling with automatic retries',
      icon: Icons.wifi,
      route: '/network',
      color: Colors.blue,
    ),
    _FeatureItem(
      title: 'Payments',
      subtitle: 'Payment flows with toast feedback',
      icon: Icons.payment,
      route: '/payments',
      color: Colors.orange,
    ),
    _FeatureItem(
      title: 'Notifications',
      subtitle: 'Push & in-app notification toasts',
      icon: Icons.notifications_outlined,
      route: '/notifications',
      color: Colors.purple,
    ),
    _FeatureItem(
      title: 'Toast Showcase',
      subtitle: 'Explore every toast style and option',
      icon: Icons.palette_outlined,
      route: '/toast/showcase',
      color: Colors.teal,
    ),
    _FeatureItem(
      title: 'Stress Test',
      subtitle: 'Queue handling under heavy load',
      icon: Icons.speed,
      route: '/toast/stress-test',
      color: Colors.red,
    ),
    _FeatureItem(
      title: 'Rules Demo',
      subtitle: 'Deduplication, priority & display rules',
      icon: Icons.rule_outlined,
      route: '/toast/rules',
      color: Colors.indigo,
    ),
    _FeatureItem(
      title: 'Progress Demo',
      subtitle: 'Long-running tasks with live progress',
      icon: Icons.trending_up,
      route: '/toast/progress',
      color: Colors.amber,
    ),
    _FeatureItem(
      title: 'Auto-Dismiss',
      subtitle: 'Progress countdown & toast auto-dismiss',
      icon: Icons.timer_outlined,
      route: '/toast/autodismiss',
      color: Colors.cyan,
    ),
    _FeatureItem(
      title: 'Toast Builder',
      subtitle: 'Design your own toast interactively',
      icon: Icons.design_services_outlined,
      route: '/toast/configurator',
      color: Colors.pink,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hPadding = ResponsiveHelper.horizontalPadding(context);
    final vPadding = ResponsiveHelper.verticalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ToastKit Showcase'),
        centerTitle: false,
        actions: [
          const ThemeSelector(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => context.go(AppRoutes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: ResponsiveHelper.maxContentWidth,
            ),
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: hPadding,
                vertical: vPadding,
              ),
              children: [
                // --- Header ---
                Text(
                  'Welcome to ToastKit',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Explore features and see toasts in action.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.sectionSpacing(context)),

                // --- Quick Actions ---
                const _SectionHeader(title: 'Quick Actions'),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerRight,
                  child: SeeCodeButton(
                    title: 'Quick Toast Actions',
                    description:
                        'Show success, error, warning, and info toasts with a single line.',
                    code: _quickActionsCode,
                  ),
                ),
                const SizedBox(height: 8),
                const _QuickActionsRow(),
                SizedBox(height: ResponsiveHelper.sectionSpacing(context) + 8),

                // --- Feature Grid ---
                const _SectionHeader(title: 'Features'),
                const SizedBox(height: 12),
                const _FeatureGrid(features: _features),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick Actions
// ---------------------------------------------------------------------------

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _QuickActionButton(
          label: 'Success',
          color: Colors.green,
          onPressed: () => ToastKit.success('Operation completed!'),
        ),
        _QuickActionButton(
          label: 'Error',
          color: Colors.red,
          onPressed: () => ToastKit.error('Something went wrong'),
        ),
        _QuickActionButton(
          label: 'Warning',
          color: Colors.orange,
          onPressed: () => ToastKit.warning('Check your input'),
        ),
        _QuickActionButton(
          label: 'Info',
          color: Colors.blue,
          onPressed: () => ToastKit.info('New version available'),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      style: FilledButton.styleFrom(
        backgroundColor: color.withOpacity(0.12),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feature Grid
// ---------------------------------------------------------------------------

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.features});

  final List<_FeatureItem> features;

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveHelper.gridColumns(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: features.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: columns == 1 ? 2.2 : 1.05,
      ),
      itemBuilder: (context, index) {
        return _FeatureCard(item: features[index]);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Feature Card
// ---------------------------------------------------------------------------

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({required this.item});

  final _FeatureItem item;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: _isHovered
            ? Matrix4.translationValues(0, -2.0, 0)
            : Matrix4.identity(),
        child: Card(
          elevation: _isHovered ? 4 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _isHovered
                  ? item.color.withOpacity(0.4)
                  : theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.go(item.route),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: item.color, size: 24),
                  ),
                  const Spacer(),
                  // Title
                  Text(
                    item.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Subtitle
                  Text(
                    item.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class _FeatureItem {
  const _FeatureItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color color;
}

// =============================================================================
// Code Strings
// =============================================================================

const _quickActionsCode = '''// One-liner convenience methods
ToastKit.success('Operation completed!');
ToastKit.error('Something went wrong');
ToastKit.warning('Check your input');
ToastKit.info('New version available');

// With optional parameters
ToastKit.success(
  'Saved!',
  title: 'Success',
  duration: Duration(seconds: 3),
  position: ToastPosition.bottom,
  variant: ToastVariant.material,
);''';
