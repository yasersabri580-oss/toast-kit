import 'dart:async';

import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

import '../widgets/cards/feature_card.dart';
import '../widgets/buttons/demo_button.dart';
import '../widgets/see_code_button.dart';

/// Demonstrates progress and loading toast behaviors using [ToastKit].
///
/// Covers file-upload simulation, multi-step pipelines, concurrent tasks,
/// and manual slider-driven progress control.
class ToastProgressDemo extends StatefulWidget {
  const ToastProgressDemo({super.key});

  @override
  State<ToastProgressDemo> createState() => _ToastProgressDemoState();
}

class _ToastProgressDemoState extends State<ToastProgressDemo> {
  // ── File Upload ──────────────────────────────────────────────────────
  bool _isUploading = false;
  int _uploadPct = 0;
  Timer? _uploadTimer;

  // ── Multi-Step Pipeline ──────────────────────────────────────────────
  bool _isPipelineRunning = false;
  int _currentStep = 0; // 0 = idle, 1–4 = active step

  // ── Concurrent Tasks ─────────────────────────────────────────────────
  bool _concurrentRunning = false;

  // ── Manual Progress ──────────────────────────────────────────────────
  double _manualProgress = 0;
  ToastController? _manualCtrl;
  bool get _manualActive => _manualCtrl != null && !_manualCtrl!.isDisposed;

  // ────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _uploadTimer?.cancel();
    super.dispose();
  }

  // ── File Upload helpers ──────────────────────────────────────────────

  void _startUpload({bool failAt60 = false}) {
    if (_isUploading) return;
    setState(() {
      _isUploading = true;
      _uploadPct = 0;
    });

    final ctrl = ToastKit.showLoading('Uploading file…');
    const stepMs = 120;
    const increment = 5;

    _uploadTimer = Timer.periodic(
      const Duration(milliseconds: stepMs),
      (timer) {
        final pct = (_uploadPct + increment).clamp(0, 100);

        if (failAt60 && pct >= 60) {
          timer.cancel();
          ctrl.error('Upload failed at 60 %');
          setState(() {
            _uploadPct = 60;
            _isUploading = false;
          });
          return;
        }

        setState(() => _uploadPct = pct);
        ctrl.update(message: 'Uploading… $pct%');
        ctrl.progress.value = pct / 100;

        if (pct >= 100) {
          timer.cancel();
          ctrl.success('Upload complete!');
          setState(() => _isUploading = false);
        }
      },
    );
  }

  // ── Multi-Step Pipeline helpers ──────────────────────────────────────

  Future<void> _runPipeline() async {
    if (_isPipelineRunning) return;
    setState(() {
      _isPipelineRunning = true;
      _currentStep = 0;
    });

    final ctrl = ToastKit.showLoading('Starting pipeline…');

    const steps = <_PipelineStep>[
      _PipelineStep('Validating data…', Duration(seconds: 2)),
      _PipelineStep('Processing records…', Duration(seconds: 3)),
      _PipelineStep('Generating report…', Duration(seconds: 2)),
      _PipelineStep('Finalizing…', Duration(seconds: 1)),
    ];

    for (var i = 0; i < steps.length; i++) {
      setState(() => _currentStep = i + 1);
      ctrl.update(message: steps[i].label);
      ctrl.progress.value = (i + 1) / steps.length;
      await Future<void>.delayed(steps[i].duration);
    }

    ctrl.success('Pipeline complete!');
    setState(() {
      _isPipelineRunning = false;
      _currentStep = 0;
    });
  }

  // ── Concurrent Tasks helpers ─────────────────────────────────────────

  Future<void> _startConcurrentTasks() async {
    if (_concurrentRunning) return;
    setState(() => _concurrentRunning = true);

    Future<void> runTask(String name, int durationMs, int stepMs,
        {bool shouldFail = false}) async {
      final ctrl = ToastKit.showLoading('$name: starting…');
      final total = durationMs ~/ stepMs;
      for (var i = 1; i <= total; i++) {
        await Future<void>.delayed(Duration(milliseconds: stepMs));
        if (ctrl.isDisposed) return;
        final pct = ((i / total) * 100).round();
        ctrl.update(message: '$name: $pct%');
        ctrl.progress.value = i / total;
        if (shouldFail && pct >= 70) {
          ctrl.error('$name failed!');
          return;
        }
      }
      ctrl.success('$name done!');
    }

    await Future.wait([
      runTask('Task A', 3000, 150),
      runTask('Task B', 5000, 250),
      runTask('Task C', 4000, 200, shouldFail: true),
    ]);

    setState(() => _concurrentRunning = false);
  }

  // ── Manual Progress helpers ──────────────────────────────────────────

  void _startManualProgress() {
    if (_manualActive) return;
    setState(() => _manualProgress = 0);
    _manualCtrl = ToastKit.showLoading('Manual progress: 0%');
  }

  void _updateManualProgress(double value) {
    setState(() => _manualProgress = value);
    if (_manualActive) {
      final pct = value.round();
      _manualCtrl!.update(message: 'Manual progress: $pct%');
      _manualCtrl!.progress.value = value / 100;
    }
  }

  void _completeManualProgress() {
    if (!_manualActive) return;
    _manualCtrl!.success('Manual task complete!');
    setState(() => _manualCtrl = null);
  }

  void _failManualProgress() {
    if (!_manualActive) return;
    _manualCtrl!.error('Manual task failed!');
    setState(() => _manualCtrl = null);
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Progress Demo'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildUploadSection(cs),
          const SizedBox(height: 16),
          _buildPipelineSection(cs),
          const SizedBox(height: 16),
          _buildConcurrentSection(cs),
          const SizedBox(height: 16),
          _buildManualSection(cs),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Section builders ─────────────────────────────────────────────────

  Widget _buildUploadSection(ColorScheme cs) {
    return FeatureCard(
      title: 'File Upload Simulation',
      subtitle: 'Simulates a file upload with progress updates',
      icon: Icons.cloud_upload_rounded,
      iconColor: cs.primary,
      trailing: const SeeCodeButton(
        title: 'File Upload Progress',
        description: 'Uses showLoading() and updates progress via the controller.',
        code: _uploadCode,
      ),
      children: [
        DemoButton(
          label: 'Upload File',
          icon: Icons.upload_file_rounded,
          onPressed: _isUploading ? null : () => _startUpload(),
          loading: _isUploading,
        ),
        DemoButton(
          label: 'Upload with Failure',
          icon: Icons.error_outline_rounded,
          color: cs.error,
          onPressed: _isUploading ? null : () => _startUpload(failAt60: true),
          loading: _isUploading,
        ),
        if (_isUploading || _uploadPct > 0)
          _ProgressIndicatorRow(
            label: 'Upload progress',
            pct: _uploadPct,
            color: cs.primary,
          ),
      ],
    );
  }

  Widget _buildPipelineSection(ColorScheme cs) {
    const stepLabels = [
      'Validate',
      'Process',
      'Report',
      'Finalize',
    ];

    return FeatureCard(
      title: 'Multi-Step Process',
      subtitle: 'Simulates a 4-step pipeline',
      icon: Icons.account_tree_rounded,
      iconColor: cs.tertiary,
      trailing: const SeeCodeButton(
        title: 'Multi-Step Pipeline',
        description: 'Progress toast updated at each pipeline step.',
        code: _pipelineCode,
      ),
      children: [
        DemoButton(
          label: 'Run Pipeline',
          icon: Icons.play_arrow_rounded,
          onPressed: _isPipelineRunning ? null : _runPipeline,
          loading: _isPipelineRunning,
        ),
        if (_isPipelineRunning || _currentStep > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _StepperRow(
              labels: stepLabels,
              activeStep: _currentStep,
              activeColor: cs.tertiary,
            ),
          ),
      ],
    );
  }

  Widget _buildConcurrentSection(ColorScheme cs) {
    return FeatureCard(
      title: 'Concurrent Progress',
      subtitle: 'Three tasks running simultaneously',
      icon: Icons.call_split_rounded,
      iconColor: cs.secondary,
      trailing: const SeeCodeButton(
        title: 'Concurrent Tasks',
        description: 'Multiple loading toasts running in parallel.',
        code: _concurrentCode,
      ),
      children: [
        DemoButton(
          label: 'Start 3 Tasks',
          icon: Icons.rocket_launch_rounded,
          onPressed: _concurrentRunning ? null : _startConcurrentTasks,
          loading: _concurrentRunning,
        ),
        if (_concurrentRunning)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Task A (fast) · Task B (slow) · Task C (fails at 70 %)',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.outline),
            ),
          ),
      ],
    );
  }

  Widget _buildManualSection(ColorScheme cs) {
    return FeatureCard(
      title: 'Manual Progress Control',
      subtitle: 'Use the slider to control a progress toast',
      icon: Icons.tune_rounded,
      iconColor: Colors.orange,
      trailing: const SeeCodeButton(
        title: 'Manual Progress',
        description: 'Control progress via slider and resolve with success/error.',
        code: _manualCode,
      ),
      children: [
        DemoButton(
          label: 'Start',
          icon: Icons.play_circle_outline_rounded,
          onPressed: _manualActive ? null : _startManualProgress,
        ),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _manualProgress,
                min: 0,
                max: 100,
                divisions: 100,
                label: '${_manualProgress.round()}%',
                onChanged: _manualActive ? _updateManualProgress : null,
              ),
            ),
            SizedBox(
              width: 48,
              child: Text(
                '${_manualProgress.round()}%',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: CompactDemoButton(
                label: 'Complete',
                icon: Icons.check_circle_rounded,
                color: Colors.green,
                onPressed: _manualActive ? _completeManualProgress : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CompactDemoButton(
                label: 'Fail',
                icon: Icons.cancel_rounded,
                color: cs.error,
                onPressed: _manualActive ? _failManualProgress : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Helper data class ──────────────────────────────────────────────────

class _PipelineStep {
  const _PipelineStep(this.label, this.duration);
  final String label;
  final Duration duration;
}

// ── Reusable private widgets ───────────────────────────────────────────

class _ProgressIndicatorRow extends StatelessWidget {
  const _ProgressIndicatorRow({
    required this.label,
    required this.pct,
    required this.color,
  });

  final String label;
  final int pct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  minHeight: 8,
                  backgroundColor: color.withAlpha(30),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$pct%',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.outline),
        ),
      ],
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.labels,
    required this.activeStep,
    required this.activeColor,
  });

  final List<String> labels;
  final int activeStep; // 1-indexed; 0 = none active
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bodySmall = Theme.of(context).textTheme.bodySmall;

    return Row(
      children: List.generate(labels.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line between steps
          final stepBefore = (i ~/ 2) + 1;
          final done = stepBefore < activeStep;
          return Expanded(
            child: Container(
              height: 2,
              color: done ? activeColor : cs.outlineVariant,
            ),
          );
        }

        final stepIndex = i ~/ 2; // 0-based
        final stepNumber = stepIndex + 1; // 1-based
        final isDone = stepNumber < activeStep;
        final isCurrent = stepNumber == activeStep;
        final isActive = isDone || isCurrent;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? activeColor : cs.surfaceContainerHighest,
                border: isCurrent
                    ? Border.all(color: activeColor, width: 2)
                    : null,
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '$stepNumber',
                        style: bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isCurrent ? Colors.white : cs.outline,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              labels[stepIndex],
              style: bodySmall?.copyWith(
                fontSize: 10,
                color: isActive ? activeColor : cs.outline,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        );
      }),
    );
  }
}

// =============================================================================
// Code Strings for "See Code" modals
// =============================================================================

const _uploadCode = '''// Start a loading toast and update progress
final ctrl = ToastKit.showLoading('Uploading file…');

// In your upload callback:
ctrl.update(message: 'Uploading… 45%');
ctrl.progress.value = 0.45;

// On completion:
ctrl.success('Upload complete!');

// On failure:
ctrl.error('Upload failed at 60%');''';

const _pipelineCode = '''// Multi-step pipeline with progress
final ctrl = ToastKit.showLoading('Starting pipeline…');

const steps = ['Validating…', 'Processing…', 'Reporting…', 'Finalizing…'];
for (var i = 0; i < steps.length; i++) {
  ctrl.update(message: steps[i]);
  ctrl.progress.value = (i + 1) / steps.length;
  await Future.delayed(Duration(seconds: 2));
}

ctrl.success('Pipeline complete!');''';

const _concurrentCode = '''// Run multiple loading toasts concurrently
Future<void> runTask(String name, int durationMs) async {
  final ctrl = ToastKit.showLoading('\$name: starting…');
  final total = durationMs ~/ 150;
  for (var i = 1; i <= total; i++) {
    await Future.delayed(Duration(milliseconds: 150));
    if (ctrl.isDisposed) return;
    final pct = ((i / total) * 100).round();
    ctrl.update(message: '\$name: \$pct%');
    ctrl.progress.value = i / total;
  }
  ctrl.success('\$name done!');
}

await Future.wait([
  runTask('Task A', 3000),
  runTask('Task B', 5000),
  runTask('Task C', 4000),
]);''';

const _manualCode = '''// Start a manual progress toast
final ctrl = ToastKit.showLoading('Manual progress: 0%');

// Update from a slider or other control:
ctrl.update(message: 'Manual progress: 50%');
ctrl.progress.value = 0.5;

// Resolve the toast:
ctrl.success('Manual task complete!');
// or
ctrl.error('Manual task failed!');''';
