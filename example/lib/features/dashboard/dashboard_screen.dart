import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

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
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ToastKit Showcase'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            const SizedBox(height: 24),

            // --- Quick Actions ---
            _SectionHeader(title: 'Quick Actions'),
            const SizedBox(height: 12),
            _QuickActionsRow(),
            const SizedBox(height: 32),

            // --- Feature Grid ---
            _SectionHeader(title: 'Features'),
            const SizedBox(height: 12),
            _FeatureGrid(features: _features),
          ],
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
    return Row(
      children: [
        _QuickActionButton(
          label: 'Success',
          color: Colors.green,
          onPressed: () => ToastKit.success('Operation completed!'),
        ),
        const SizedBox(width: 8),
        _QuickActionButton(
          label: 'Error',
          color: Colors.red,
          onPressed: () => ToastKit.error('Something went wrong'),
        ),
        const SizedBox(width: 8),
        _QuickActionButton(
          label: 'Warning',
          color: Colors.orange,
          onPressed: () => ToastKit.warning('Check your input'),
        ),
        const SizedBox(width: 8),
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
    return Expanded(
      child: FilledButton.tonal(
        style: FilledButton.styleFrom(
          backgroundColor: color.withOpacity(0.12),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: features.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.05,
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

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.item});

  final _FeatureItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, item.route),
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
