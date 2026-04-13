import 'package:flutter/material.dart' hide RouterConfig;
import 'package:toast_kit/toast_kit.dart';

import '../mock/fake_api.dart';
import '../scenarios/api_error.dart';
import '../scenarios/custom_ui.dart';
import '../scenarios/form_validation.dart';
import '../scenarios/login_rules.dart';
import '../scenarios/network_retry.dart';
import '../scenarios/payment_failure.dart';
import '../widgets/action_button.dart';
import '../widgets/section_card.dart';

/// The primary showcase screen that demonstrates every major ToastKit feature
/// in a clean, Material 3 layout organised into collapsible sections.
class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  final _api = FakeApi();
  int _ruleClickCount = 0;

  // ---------------------------------------------------------------------------
  // Toast type helpers
  // ---------------------------------------------------------------------------

  void _showSuccess() => ToastKit.success('Operation completed successfully!');
  void _showError() => ToastKit.error('Something went wrong. Please retry.');
  void _showWarning() => ToastKit.warning('Battery is below 20 %.');
  void _showInfo() => ToastKit.info('A new update is available.');

  // ---------------------------------------------------------------------------
  // Rule engine helpers
  // ---------------------------------------------------------------------------

  void _triggerRuleDemo() {
    _ruleClickCount++;
    setState(() {});

    // Use deduplication key so fast taps are coalesced
    ToastKit.show(ToastEvent.error(
      message: 'Login failed (attempt $_ruleClickCount)',
      deduplicationKey: 'rule-demo-error',
      channel: 'auth',
    ));
  }

  void _resetRuleDemo() {
    _ruleClickCount = 0;
    setState(() {});
    ToastKit.dismissAll();
    ToastKit.info('Rule counters reset');
  }

  // ---------------------------------------------------------------------------
  // Real-world scenario helpers
  // ---------------------------------------------------------------------------

  Future<void> _simulateApiSuccess() async {
    final ctrl = ToastKit.showLoading('Fetching profile…');
    try {
      final profile = await _api.fetchProfile();
      ctrl.success('Welcome back, ${profile['name']}!');
    } catch (e) {
      ctrl.error('Failed to load profile');
    }
  }

  Future<void> _simulateApiFailure() async {
    final ctrl = ToastKit.showLoading('Connecting to server…');
    await Future.delayed(const Duration(milliseconds: 1200));
    ctrl.error('Server unreachable — check your connection');
  }

  void _simulateFormValidation() {
    ToastKit.dismissAll();
    const errors = [
      'Email is required',
      'Password must be at least 8 characters',
      'Please accept the terms of service',
    ];
    for (final msg in errors) {
      ToastKit.warning(msg);
    }
  }

  Future<void> _simulatePaymentFailure() async {
    final ctrl = ToastKit.showLoading('Processing payment…');
    await Future.delayed(const Duration(milliseconds: 1500));
    ctrl.error('Card declined — please try another card');
    ToastKit.show(ToastEvent.error(
      message: 'Payment failed',
      variant: ToastVariant.action,
      actions: [
        ToastAction(
          label: 'Retry',
          onPressed: () => ToastKit.info('Retrying…'),
        ),
        ToastAction(label: 'Cancel', onPressed: () {}),
      ],
    ));
  }

  // ---------------------------------------------------------------------------
  // Queue / behaviour helpers
  // ---------------------------------------------------------------------------

  Future<void> _fireQueueBurst() async {
    const messages = [
      ('Syncing contacts…', ToastType.info),
      ('Upload complete', ToastType.success),
      ('Low disk space', ToastType.warning),
      ('Connection lost', ToastType.error),
      ('Reconnected', ToastType.success),
    ];

    for (final (msg, type) in messages) {
      ToastKit.show(ToastEvent(
        type: type,
        message: msg,
        icon: _iconForType(type),
      ));
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  IconData _iconForType(ToastType type) => switch (type) {
        ToastType.success => Icons.check_circle_rounded,
        ToastType.error => Icons.error_rounded,
        ToastType.warning => Icons.warning_rounded,
        ToastType.info => Icons.info_rounded,
        _ => Icons.notifications_rounded,
      };

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ---- App bar ----
          SliverAppBar.large(
            title: const Text('ToastKit Demo'),
            centerTitle: true,
          ),

          // ---- Body ----
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList.list(
              children: [
                // Hero description
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    'A production-grade Flutter notification SDK. '
                    'Tap any button below to see ToastKit in action.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

                // ---- 1. Toast Types ----
                SectionCard(
                  title: 'Toast Types',
                  subtitle: 'Trigger each semantic toast variant',
                  icon: Icons.palette_outlined,
                  iconColor: Colors.deepPurple,
                  children: [
                    _toastTypeGrid(),
                    const SizedBox(height: 12),
                    ActionButton(
                      label: 'Loading → Success',
                      icon: Icons.hourglass_top_rounded,
                      onPressed: () async {
                        final ctrl = ToastKit.showLoading('Saving…');
                        await Future.delayed(const Duration(seconds: 2));
                        ctrl.success('Saved successfully!');
                      },
                      color: Colors.deepPurple,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ---- 2. Rule Engine ----
                SectionCard(
                  title: 'Rule Engine Demo',
                  subtitle:
                      'Tap repeatedly — deduplication and maxTriggers in action',
                  icon: Icons.rule_rounded,
                  iconColor: Colors.orange,
                  children: [
                    _ruleInfoChip(theme),
                    const SizedBox(height: 12),
                    ActionButton(
                      label: 'Trigger Login Error ($_ruleClickCount)',
                      icon: Icons.touch_app_rounded,
                      onPressed: _triggerRuleDemo,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _resetRuleDemo,
                        icon: const Icon(Icons.restart_alt_rounded, size: 18),
                        label: const Text('Reset Counters'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ---- 3. Real-world Scenarios ----
                SectionCard(
                  title: 'Real-World Scenarios',
                  subtitle: "Common patterns you'd use in production",
                  icon: Icons.public_rounded,
                  iconColor: Colors.teal,
                  children: [
                    ActionButton(
                      label: 'API Success Simulation',
                      icon: Icons.cloud_done_rounded,
                      onPressed: _simulateApiSuccess,
                      color: const Color(0xFF2E7D32),
                    ),
                    const SizedBox(height: 8),
                    ActionButton(
                      label: 'API Failure Simulation',
                      icon: Icons.cloud_off_rounded,
                      onPressed: _simulateApiFailure,
                      color: const Color(0xFFC62828),
                    ),
                    const SizedBox(height: 8),
                    ActionButton(
                      label: 'Form Validation Errors',
                      icon: Icons.edit_note_rounded,
                      onPressed: _simulateFormValidation,
                      color: const Color(0xFFE65100),
                    ),
                    const SizedBox(height: 8),
                    ActionButton(
                      label: 'Payment Failure + Retry',
                      icon: Icons.credit_card_off_rounded,
                      onPressed: _simulatePaymentFailure,
                      color: const Color(0xFF6A1B9A),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ---- 4. Queue / Behaviour ----
                SectionCard(
                  title: 'Queue & Behaviour',
                  subtitle: 'Fire multiple toasts quickly to see queue handling',
                  icon: Icons.queue_rounded,
                  iconColor: Colors.indigo,
                  children: [
                    ActionButton(
                      label: 'Fire 5 Toasts Rapidly',
                      icon: Icons.bolt_rounded,
                      onPressed: _fireQueueBurst,
                      color: Colors.indigo,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => ToastKit.dismissAll(),
                        icon: const Icon(
                          Icons.clear_all_rounded,
                          size: 18,
                        ),
                        label: const Text('Dismiss All Toasts'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ---- 5. Variant Showcase ----
                SectionCard(
                  title: 'Variant Showcase',
                  subtitle: 'Visual styles available out-of-the-box',
                  icon: Icons.auto_awesome_rounded,
                  iconColor: Colors.pink,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _variantChip(
                          'Minimal',
                          Icons.minimize_rounded,
                          () => ToastKit.show(ToastEvent.success(
                            message: 'Minimal style',
                            variant: ToastVariant.minimal,
                          )),
                        ),
                        _variantChip(
                          'Glass',
                          Icons.blur_on_rounded,
                          () => ToastKit.show(ToastEvent.info(
                            message: 'Frosted glass',
                            variant: ToastVariant.glassmorphism,
                          )),
                        ),
                        _variantChip(
                          'Gradient',
                          Icons.gradient_rounded,
                          () => ToastKit.show(ToastEvent.error(
                            message: 'Gradient background',
                            variant: ToastVariant.gradient,
                          )),
                        ),
                        _variantChip(
                          'Compact',
                          Icons.compress_rounded,
                          () => ToastKit.show(ToastEvent.success(
                            message: 'Compact!',
                            variant: ToastVariant.compact,
                          )),
                        ),
                        _variantChip(
                          'Full Width',
                          Icons.width_full_rounded,
                          () => ToastKit.show(ToastEvent.warning(
                            message: 'Full-width banner',
                            variant: ToastVariant.fullWidth,
                          )),
                        ),
                        _variantChip(
                          'Debug',
                          Icons.bug_report_rounded,
                          () => ToastKit.show(ToastEvent.info(
                            message: 'Debug info',
                            variant: ToastVariant.debug,
                          )),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ---- 6. Scenarios (navigation) ----
                SectionCard(
                  title: 'Deep-Dive Scenarios',
                  subtitle: 'Navigate to focused, interactive demos',
                  icon: Icons.science_rounded,
                  iconColor: Colors.blueGrey,
                  children: [
                    _scenarioTile(
                      context,
                      'API Error Handling',
                      'Loading states, retries & dedup',
                      Icons.cloud_off_rounded,
                      const ApiErrorScenario(),
                    ),
                    _scenarioTile(
                      context,
                      'Form Validation',
                      'Toast-based field validation',
                      Icons.edit_document,
                      const FormValidationScenario(),
                    ),
                    _scenarioTile(
                      context,
                      'Login Rules',
                      'Threshold lockout & suggestions',
                      Icons.lock_rounded,
                      const LoginRulesScenario(),
                    ),
                    _scenarioTile(
                      context,
                      'Payment Failure',
                      'Recovery actions & escalation',
                      Icons.payment_rounded,
                      const PaymentFailureScenario(),
                    ),
                    _scenarioTile(
                      context,
                      'Network Retry',
                      'Progressive retry feedback',
                      Icons.wifi_off_rounded,
                      const NetworkRetryScenario(),
                    ),
                    _scenarioTile(
                      context,
                      'Custom UI',
                      'Branded builders & progress',
                      Icons.palette_rounded,
                      const CustomUiScenario(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sub-widgets
  // ---------------------------------------------------------------------------

  /// 2×2 grid of toast-type buttons.
  Widget _toastTypeGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CompactActionButton(
                label: 'Success',
                icon: Icons.check_circle_rounded,
                onPressed: _showSuccess,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CompactActionButton(
                label: 'Error',
                icon: Icons.error_rounded,
                onPressed: _showError,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: CompactActionButton(
                label: 'Warning',
                icon: Icons.warning_rounded,
                onPressed: _showWarning,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CompactActionButton(
                label: 'Info',
                icon: Icons.info_rounded,
                onPressed: _showInfo,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Small info chip showing current rule engine state.
  Widget _ruleInfoChip(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Dedup window: 2 s · Max triggers: 2 · '
              'Taps so far: $_ruleClickCount',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Chip-style button for variant showcase.
  Widget _variantChip(String label, IconData icon, VoidCallback onPressed) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onPressed,
    );
  }

  /// A list tile that navigates to a deeper scenario page.
  Widget _scenarioTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Widget page,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => page)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      dense: true,
    );
  }
}
