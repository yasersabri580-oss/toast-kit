import 'dart:async';

import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

import '../widgets/buttons/demo_button.dart';
import '../widgets/cards/feature_card.dart';
import '../widgets/see_code_button.dart';

/// Demonstrates toast auto-dismiss with a visible countdown progress bar.
///
/// Many apps show a toast that fades out with a smooth progress indicator
/// showing how long remains. This screen provides interactive controls to
/// configure duration and see the effect in real time.
class ToastAutodismissDemo extends StatefulWidget {
  const ToastAutodismissDemo({super.key});

  @override
  State<ToastAutodismissDemo> createState() => _ToastAutodismissDemoState();
}

class _ToastAutodismissDemoState extends State<ToastAutodismissDemo> {
  double _durationSec = 4.0;
  int _demosLaunched = 0;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _showCountdownToast() {
    final totalMs = (_durationSec * 1000).round();
    final duration = Duration(milliseconds: totalMs);
    setState(() => _demosLaunched++);

    ToastKit.custom(
      duration: duration,
      builder: (context, controller) {
        return _CountdownToastWidget(
          durationMs: totalMs,
          controller: controller,
        );
      },
    );
  }

  void _showSuccessCountdown() {
    const totalMs = 3000;
    setState(() => _demosLaunched++);

    ToastKit.custom(
      duration: const Duration(milliseconds: totalMs),
      builder: (context, controller) {
        return _CountdownToastWidget(
          durationMs: totalMs,
          controller: controller,
          icon: Icons.check_circle,
          title: 'Saved successfully',
          message: 'Your changes have been saved.',
          accentColor: Colors.green,
        );
      },
    );
  }

  void _showErrorCountdown() {
    const totalMs = 5000;
    setState(() => _demosLaunched++);

    ToastKit.custom(
      duration: const Duration(milliseconds: totalMs),
      builder: (context, controller) {
        return _CountdownToastWidget(
          durationMs: totalMs,
          controller: controller,
          icon: Icons.error_outline,
          title: 'Upload failed',
          message: 'Please try again or check your connection.',
          accentColor: Colors.red,
        );
      },
    );
  }

  void _showUndoCountdown() {
    const totalMs = 6000;
    setState(() => _demosLaunched++);

    ToastKit.custom(
      duration: const Duration(milliseconds: totalMs),
      builder: (context, controller) {
        return _UndoCountdownToast(
          durationMs: totalMs,
          controller: controller,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Auto-Dismiss Progress'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Toast Progress Dismiss',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'A polished countdown progress bar shows how long the toast will '
            'remain before auto-dismissing. Drag the slider to change duration.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // Custom duration
          _buildDurationSection(),
          const SizedBox(height: 12),

          // Preset variants
          _buildPresetsSection(),
          const SizedBox(height: 12),

          // Undo pattern
          _buildUndoSection(),
          const SizedBox(height: 12),

          // Stats
          _buildStatsSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDurationSection() {
    return FeatureCard(
      title: 'Custom Duration Countdown',
      subtitle: 'Adjust duration and watch the progress bar drain',
      icon: Icons.timer_outlined,
      iconColor: Colors.cyan,
      trailing: const SeeCodeButton(
        title: 'Countdown Toast',
        description:
            'A custom toast builder that animates a progress bar from full to empty.',
        code: _countdownCode,
      ),
      children: [
        Row(
          children: [
            const Icon(Icons.schedule, size: 18),
            const SizedBox(width: 8),
            Text('${_durationSec.toStringAsFixed(1)}s'),
            Expanded(
              child: Slider(
                value: _durationSec,
                min: 1.0,
                max: 10.0,
                divisions: 18,
                label: '${_durationSec.toStringAsFixed(1)}s',
                onChanged: (v) => setState(() => _durationSec = v),
              ),
            ),
          ],
        ),
        DemoButton(
          label: 'Show Countdown Toast (${_durationSec.toStringAsFixed(1)}s)',
          icon: Icons.play_arrow,
          color: Colors.cyan,
          onPressed: _showCountdownToast,
        ),
      ],
    );
  }

  Widget _buildPresetsSection() {
    return FeatureCard(
      title: 'Preset Variants',
      subtitle: 'Success, error, and info toasts with progress dismiss',
      icon: Icons.palette_outlined,
      iconColor: Colors.green,
      trailing: const SeeCodeButton(
        title: 'Preset Countdown Toasts',
        description:
            'Predefined success/error countdown toasts with customized colors.',
        code: _presetsCode,
      ),
      children: [
        DemoButton(
          label: 'Success (3s)',
          icon: Icons.check_circle_outline,
          color: Colors.green,
          onPressed: _showSuccessCountdown,
        ),
        DemoButton(
          label: 'Error (5s)',
          icon: Icons.error_outline,
          color: Colors.red,
          onPressed: _showErrorCountdown,
        ),
      ],
    );
  }

  Widget _buildUndoSection() {
    return FeatureCard(
      title: 'Undo with Countdown',
      subtitle: 'A common pattern: undo action with visible time remaining',
      icon: Icons.undo,
      iconColor: Colors.amber,
      trailing: const SeeCodeButton(
        title: 'Undo Countdown Toast',
        description:
            'An "Item deleted" toast with an Undo button and a progress bar '
            'showing how long the user has to reverse the action.',
        code: _undoCountdownCode,
      ),
      children: [
        DemoButton(
          label: 'Delete Item (Undo for 6s)',
          icon: Icons.delete_outline,
          color: Colors.amber.shade800,
          onPressed: _showUndoCountdown,
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return FeatureCard(
      title: 'Demo Stats',
      subtitle: 'Track how many countdown toasts you\'ve launched',
      icon: Icons.bar_chart,
      iconColor: Colors.deepPurple,
      children: [
        Row(
          children: [
            const Icon(Icons.play_circle_outline, size: 18),
            const SizedBox(width: 8),
            Text('Toasts launched: $_demosLaunched'),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// Countdown Toast Widget
// =============================================================================

/// A custom toast widget that shows a progress bar draining from right to left
/// over the given [durationMs] milliseconds.
class _CountdownToastWidget extends StatefulWidget {
  const _CountdownToastWidget({
    required this.durationMs,
    required this.controller,
    this.icon,
    this.title,
    this.message,
    this.accentColor,
  });

  final int durationMs;
  final ToastController controller;
  final IconData? icon;
  final String? title;
  final String? message;
  final Color? accentColor;

  @override
  State<_CountdownToastWidget> createState() => _CountdownToastWidgetState();
}

class _CountdownToastWidgetState extends State<_CountdownToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    )..forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.accentColor ?? Colors.cyan;
    final title = widget.title ?? 'Auto-dismiss toast';
    final message = widget.message ??
        'This toast will dismiss in ${(widget.durationMs / 1000).toStringAsFixed(1)}s';
    final icon = widget.icon ?? Icons.timer_outlined;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                Icon(icon, color: accent, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 18,
                      color: theme.colorScheme.onSurfaceVariant),
                  onPressed: widget.controller.dismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),
          // Progress bar
          AnimatedBuilder(
            animation: _animCtrl,
            builder: (context, _) {
              return ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                child: LinearProgressIndicator(
                  value: 1.0 - _animCtrl.value,
                  minHeight: 4,
                  backgroundColor: accent.withAlpha(30),
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Undo Countdown Toast
// =============================================================================

class _UndoCountdownToast extends StatefulWidget {
  const _UndoCountdownToast({
    required this.durationMs,
    required this.controller,
  });

  final int durationMs;
  final ToastController controller;

  @override
  State<_UndoCountdownToast> createState() => _UndoCountdownToastState();
}

class _UndoCountdownToastState extends State<_UndoCountdownToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  bool _undone = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    )..forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _undo() {
    if (_undone) return;
    setState(() => _undone = true);
    _animCtrl.stop();
    // Dismiss after showing undo confirmation briefly
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) widget.controller.dismiss();
    });
    ToastKit.success('Item restored');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Icon(
                  _undone ? Icons.check_circle : Icons.delete_outline,
                  color: theme.colorScheme.onInverseSurface,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _undone ? 'Item restored!' : 'Item deleted',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onInverseSurface,
                    ),
                  ),
                ),
                if (!_undone)
                  TextButton(
                    onPressed: _undo,
                    child: Text(
                      'UNDO',
                      style: TextStyle(
                        color: Colors.amber.shade300,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _animCtrl,
            builder: (context, _) {
              return LinearProgressIndicator(
                value: 1.0 - _animCtrl.value,
                minHeight: 3,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(
                  _undone ? Colors.green : Colors.amber.shade300,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Code Strings
// =============================================================================

const _countdownCode = '''// Custom toast with countdown progress bar
ToastKit.custom(
  duration: Duration(seconds: 4),
  builder: (context, controller) {
    return _CountdownToastWidget(
      durationMs: 4000,
      controller: controller,
    );
  },
);

// The widget uses AnimationController to animate
// a LinearProgressIndicator from 1.0 → 0.0
// over the toast duration.
class _CountdownToastWidget extends StatefulWidget {
  // ...
}

class _State extends State<_CountdownToastWidget>
    with SingleTickerProviderStateMixin {
  late final animCtrl = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: durationMs),
  )..forward();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animCtrl,
      builder: (_, __) => LinearProgressIndicator(
        value: 1.0 - animCtrl.value,
      ),
    );
  }
}''';

const _presetsCode = '''// Success variant with 3-second countdown
ToastKit.custom(
  duration: Duration(seconds: 3),
  builder: (context, controller) {
    return _CountdownToastWidget(
      durationMs: 3000,
      controller: controller,
      icon: Icons.check_circle,
      title: 'Saved successfully',
      message: 'Your changes have been saved.',
      accentColor: Colors.green,
    );
  },
);

// Error variant with 5-second countdown
ToastKit.custom(
  duration: Duration(seconds: 5),
  builder: (context, controller) {
    return _CountdownToastWidget(
      durationMs: 5000,
      controller: controller,
      icon: Icons.error_outline,
      title: 'Upload failed',
      accentColor: Colors.red,
    );
  },
);''';

const _undoCountdownCode = '''// Undo pattern: user has 6 seconds to reverse
ToastKit.custom(
  duration: Duration(seconds: 6),
  builder: (context, controller) {
    // Stateful widget with AnimationController
    // Progress bar drains from right to left
    // "UNDO" button stops the timer and restores
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(children: [
            Text('Item deleted'),
            TextButton(
              onPressed: () {
                animCtrl.stop();
                controller.dismiss();
                ToastKit.success('Item restored');
              },
              child: Text('UNDO'),
            ),
          ]),
          LinearProgressIndicator(
            value: 1.0 - animCtrl.value,
          ),
        ],
      ),
    );
  },
);''';
