import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

import '../../utils/demo_logger.dart';
import '../../widgets/buttons/demo_button.dart';
import '../../widgets/cards/feature_card.dart';
import '../../widgets/see_code_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _debugEnabled = DemoLogger.instance.enabled;

  static const String _appVersion = '1.0.0';
  static const String _packageName = 'toast_kit';
  static const String _packageVersion = '0.1.0';

  // --- Helpers ---------------------------------------------------------------

  Color _colorForLevel(LogLevel level, ColorScheme colors) {
    return switch (level) {
      LogLevel.info => colors.primary,
      LogLevel.warning => colors.tertiary,
      LogLevel.error => colors.error,
      LogLevel.success => Colors.green,
    };
  }

  IconData _iconForLevel(LogLevel level) {
    return switch (level) {
      LogLevel.info => Icons.info_outline,
      LogLevel.warning => Icons.warning_amber_rounded,
      LogLevel.error => Icons.error_outline,
      LogLevel.success => Icons.check_circle_outline,
    };
  }

  // --- Build Sections --------------------------------------------------------

  Widget _buildDebugModeSection() {
    return FeatureCard(
      title: 'Debug Mode',
      icon: Icons.bug_report_outlined,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SeeCodeButton(
            title: 'Debug Mode Toggle',
            description:
                'Enables or disables the in-memory debug logger that records toast events.',
            code: _debugModeCode,
          ),
          Switch.adaptive(
            value: _debugEnabled,
            onChanged: (value) {
              setState(() {
                _debugEnabled = value;
                DemoLogger.instance.enabled = value;
              });
            },
          ),
        ],
      ),
      children: [
        Text(
          _debugEnabled
              ? 'Logger is active — events are being recorded.'
              : 'Logger is disabled — no events will be captured.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildDebugLogSection() {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FeatureCard(
      title: 'Debug Log',
      icon: Icons.terminal_outlined,
      children: [
        ValueListenableBuilder<List<LogEntry>>(
          valueListenable: DemoLogger.instance.entriesNotifier,
          builder: (context, entries, _) {
            if (entries.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 32,
                      color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No log entries yet',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    shrinkWrap: true,
                    reverse: true,
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = entries[entries.length - 1 - index];
                      final levelColor = _colorForLevel(entry.level, colors);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _iconForLevel(entry.level),
                              size: 16,
                              color: levelColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.message,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    entry.formattedTime,
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colors.onSurfaceVariant
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        CompactDemoButton(
          label: 'Clear Log',
          icon: Icons.delete_sweep_outlined,
          onPressed: () {
            DemoLogger.instance.clear();
          },
        ),
      ],
    );
  }

  Widget _buildToastConfigSection() {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    final configItems = <(String, String)>[
      ('Max Visible Toasts', '3'),
      ('Queue Mode', 'standard'),
      ('Deduplication Window', '2 s'),
      ('Throttle Interval', '300 ms'),
    ];

    return FeatureCard(
      title: 'Toast Configuration',
      icon: Icons.tune_outlined,
      children: [
        ...configItems.map((item) {
          final (label, value) = item;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    value,
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return FeatureCard(
      title: 'Quick Actions',
      icon: Icons.flash_on_outlined,
      trailing: const SeeCodeButton(
        title: 'Quick Actions',
        description:
            'Dismiss all visible toasts, clear the queue, or reset debug stats.',
        code: _quickActionsCode,
      ),
      children: [
        DemoButton(
          label: 'Dismiss All Toasts',
          icon: Icons.clear_all_rounded,
          onPressed: () {
            ToastKit.dismissAll();
            DemoLogger.instance.info('All toasts dismissed');
          },
        ),
        DemoButton(
          label: 'Clear Queue',
          icon: Icons.playlist_remove_rounded,
          onPressed: () {
            ToastKit.clearQueue();
            DemoLogger.instance.info('Toast queue cleared');
          },
        ),
        DemoButton(
          label: 'Reset Stats',
          icon: Icons.restart_alt_rounded,
          color: Theme.of(context).colorScheme.error,
          onPressed: () {
            DemoLogger.instance.clear();
            DemoLogger.instance.info('Stats and log reset');
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    final aboutItems = <(String, String)>[
      ('App Version', _appVersion),
      ('Package', _packageName),
      ('Package Version', _packageVersion),
      ('Flutter', 'Material 3'),
    ];

    return FeatureCard(
      title: 'About',
      icon: Icons.info_outline,
      children: [
        ...aboutItems.map((item) {
          final (label, value) = item;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Built with ToastKit 💬',
            style: textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  // --- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Debug'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildDebugModeSection(),
          const SizedBox(height: 12),
          _buildDebugLogSection(),
          const SizedBox(height: 12),
          _buildToastConfigSection(),
          const SizedBox(height: 12),
          _buildQuickActionsSection(),
          const SizedBox(height: 12),
          _buildAboutSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// =============================================================================
// Code Strings for "See Code" modals
// =============================================================================

const _debugModeCode = '''// Toggle the in-memory debug logger
DemoLogger.instance.enabled = true;

// Log entries from your app
DemoLogger.instance.info('Toast shown');
DemoLogger.instance.warning('Queue full');
DemoLogger.instance.error('Overlay render failed');

// Access log entries reactively
ValueListenableBuilder<List<LogEntry>>(
  valueListenable: DemoLogger.instance.entriesNotifier,
  builder: (context, entries, _) {
    // build your log viewer
  },
);''';

const _quickActionsCode = '''// Dismiss all visible toasts
ToastKit.dismissAll();

// Clear the waiting queue (visible toasts stay)
ToastKit.clearQueue();

// Full reset: clear queue + dismiss all
ToastKit.dismissAll();
ToastKit.clearQueue();''';