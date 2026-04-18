import 'dart:async';

import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

import '../widgets/buttons/demo_button.dart';
import '../widgets/cards/rule_scenario_card.dart';

// =============================================================================
// Toast Rules Demo — Comprehensive Rule Engine Showcase
//
// 10 real-world scenarios demonstrating every ToastKit rule feature:
//
//  1. Auth Guard          — Config rule + custom rules, errorThreshold, maxTriggers
//  2. Error Burst Detector — errorsInWindow(), deduplicateWindow on custom rule
//  3. Toast Flood Shield   — Config dedup, deduplicationKey
//  4. Payment Recovery     — Action toasts from rules, persistent, multiple actions
//  5. Auto-Save Cooldown   — maxTriggers + dedup window for success noise
//  6. Combined Stats       — warningCount + errorCount + totalCount conditions
//  7. Checkout Wizard      — Channel-scoped contextual toasts per step
//  8. Form Help Escalation — errorCount threshold, proactive action toast
//  9. Connectivity Banner  — Persistent dismissible banner, reconnect action
// 10. Token Refresh Guard  — Non-dismissible blocking, dynamic rule removal
// =============================================================================

class ToastRulesDemo extends StatefulWidget {
  const ToastRulesDemo({super.key});

  @override
  State<ToastRulesDemo> createState() => _ToastRulesDemoState();
}

class _ToastRulesDemoState extends State<ToastRulesDemo> {
  // ── Shared state ──
  bool _rulesRegistered = false;

  // ── Scenario 1: Auth guard ──
  int _signInAttempts = 0;
  bool _accountLocked = false;

  // ── Scenario 2: Error burst ──
  int _burstErrors = 0;
  String _burstStatus = 'Stable';

  // ── Scenario 3: Toast flood shield ──
  int _rapidClickCount = 0;

  // ── Scenario 4: Payment recovery ──
  int _paymentRetries = 0;
  bool _paymentBlocked = false;
  bool _paymentProcessing = false;

  // ── Scenario 5: Auto-save cooldown ──
  int _successCount = 0;

  // ── Scenario 6: Combined stats ──
  int _syncErrors = 0;
  int _syncWarnings = 0;
  int _syncTotal = 0;
  bool _syncHelpShown = false;

  // ── Scenario 7: Checkout wizard ──
  String _checkoutStep = 'cart';

  // ── Scenario 8: Form help ──
  int _formSubmits = 0;

  // ── Scenario 9: Connectivity banner ──
  bool _isOffline = false;
  int _offlineAttempts = 0;

  // ── Scenario 10: Token refresh guard ──
  int _tokenFailures = 0;
  bool _tokenExpired = false;

  // ── Timers ──
  Timer? _lockTimer;

  // ── Guards ──
  bool _isSigningIn = false;

  // ── Channel IDs — each scenario uses a unique channel to avoid interference ──
  static const _chAuth = 'rules-auth';
  static const _chBurst = 'rules-burst';
  static const _chFlood = 'rules-flood';
  static const _chPayment = 'rules-payment';
  static const _chAutoSave = 'rules-autosave';
  static const _chSync = 'rules-sync';
  static const _chCheckout = 'rules-checkout';
  static const _chForm = 'rules-form';
  static const _chConnectivity = 'rules-connectivity';
  static const _chToken = 'rules-token';

  @override
  void initState() {
    super.initState();
    _registerAll();
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Rule Registration — all 10 scenarios
  // ---------------------------------------------------------------------------

  void _registerAll() {
    // Register all channels.
    for (final ch in [
      _chAuth,
      _chBurst,
      _chFlood,
      _chPayment,
      _chAutoSave,
      _chSync,
      _chCheckout,
      _chForm,
      _chConnectivity,
      _chToken,
    ]) {
      ToastKit.registerChannel(ToastChannel(id: ch, label: ch));
    }

    // ── 1. Auth Guard ──
    // Config-based rule: triggers onRuleTriggered callback after 3 errors.
    ToastKit.configureRule(
      _chAuth,
      const RuleConfig(
        errorThreshold: 3,
        deduplicateWindow: Duration(seconds: 60),
        maxTriggers: 1,
      ),
    );

    // Custom rule: suggest password reset after 3 failures.
    ToastKit.addRule(ToastRule(
      id: 'auth-suggest-reset',
      channel: _chAuth,
      maxTriggers: 1,
      condition: (stats, event) =>
          stats.errorCount >= 3 && stats.errorCount < 5,
      action: (_) {
        ToastKit.show(ToastEvent.info(
          message: 'Having trouble signing in? Try resetting your password.',
          variant: ToastVariant.action,
          deduplicationKey: 'auth-suggest-reset',
          actions: [
            ToastAction(
              label: 'Reset Password',
              onPressed: () =>
                  ToastKit.success('Password reset email sent!'),
            ),
          ],
          channel: _chAuth,
        ));
      },
    ));

    // Custom rule: lock account after 5 failures.
    ToastKit.addRule(ToastRule(
      id: 'auth-lockout',
      channel: _chAuth,
      maxTriggers: 1,
      condition: (stats, event) => stats.errorCount >= 5,
      action: (_) {
        if (!mounted) return;
        setState(() => _accountLocked = true);
        ToastKit.show(ToastEvent.error(
          message:
              'Account locked for 15 seconds due to too many failed attempts.',
          persistent: true,
          dismissible: false,
          deduplicationKey: 'auth-lockout-toast',
          channel: _chAuth,
        ));
        _lockTimer?.cancel();
        _lockTimer = Timer(const Duration(seconds: 15), () {
          if (mounted) {
            setState(() => _accountLocked = false);
            ToastKit.dismissAll();
            ToastKit.info('Account unlocked. You may try again.');
          }
        });
      },
    ));

    // ── 2. Error Burst Detector ── uses errorsInWindow() for time-based analysis
    ToastKit.addRule(ToastRule(
      id: 'burst-spike-detector',
      channel: _chBurst,
      deduplicateWindow: const Duration(seconds: 15),
      condition: (stats, event) {
        // Detect 4+ errors within a 10-second sliding window.
        return stats.errorsInWindow(const Duration(seconds: 10)) >= 4;
      },
      action: (context) {
        if (!mounted) return;
        setState(() => _burstStatus = 'Spike detected!');
        ToastKit.show(ToastEvent.warning(
          message:
              '⚡ Error spike detected: ${context.stats.errorsInWindow(const Duration(seconds: 10))} '
              'errors in the last 10 seconds.',
          variant: ToastVariant.action,
          deduplicationKey: 'burst-spike-toast',
          actions: [
            ToastAction(
              label: 'View Details',
              onPressed: () => ToastKit.info(
                'Total: ${context.stats.totalCount} events, '
                'Errors: ${context.stats.errorCount}',
              ),
            ),
          ],
          channel: _chBurst,
        ));
      },
    ));

    // ── 3. Toast Flood Shield ── config-based dedup window
    ToastKit.configureRule(
      _chFlood,
      const RuleConfig(
        errorThreshold: 1,
        deduplicateWindow: Duration(seconds: 3),
        maxTriggers: 0,
      ),
    );

    // ── 4. Payment Recovery ── action toasts with multiple recovery options
    ToastKit.addRule(ToastRule(
      id: 'payment-warn',
      channel: _chPayment,
      maxTriggers: 1,
      condition: (stats, event) =>
          stats.errorCount >= 2 && stats.errorCount < 4,
      action: (_) {
        ToastKit.show(ToastEvent.warning(
          message: 'Multiple payment failures. Check your card details.',
          deduplicationKey: 'payment-warn-toast',
          channel: _chPayment,
        ));
      },
    ));

    ToastKit.addRule(ToastRule(
      id: 'payment-block',
      channel: _chPayment,
      maxTriggers: 1,
      condition: (stats, event) => stats.errorCount >= 4,
      action: (_) {
        if (!mounted) return;
        setState(() => _paymentBlocked = true);
        ToastKit.show(ToastEvent.error(
          message: 'Payment processing suspended after repeated failures.',
          persistent: true,
          dismissible: true,
          variant: ToastVariant.action,
          deduplicationKey: 'payment-block-toast',
          actions: [
            ToastAction(
              label: 'Switch Card',
              onPressed: () {
                ToastKit.dismissAll();
                ToastKit.info('Opening payment methods…');
                if (mounted) setState(() => _paymentBlocked = false);
              },
            ),
            ToastAction(
              label: 'Use PayPal',
              onPressed: () {
                ToastKit.dismissAll();
                ToastKit.info('Redirecting to PayPal…');
                if (mounted) setState(() => _paymentBlocked = false);
              },
            ),
            ToastAction(
              label: 'Contact Support',
              onPressed: () {
                ToastKit.dismissAll();
                ToastKit.success('Opening support chat…');
              },
            ),
          ],
          channel: _chPayment,
        ));
      },
    ));

    // ── 5. Auto-Save Cooldown ── maxTriggers + dedup for success events
    ToastKit.configureRule(
      _chAutoSave,
      const RuleConfig(
        errorThreshold: 1,
        deduplicateWindow: Duration(seconds: 5),
        maxTriggers: 3,
      ),
    );

    // ── 6. Combined Stats Monitor ── uses errorCount + warningCount + totalCount
    ToastKit.addRule(ToastRule(
      id: 'sync-combined-alert',
      channel: _chSync,
      maxTriggers: 1,
      condition: (stats, event) {
        // Fire when BOTH errors AND warnings are high relative to total.
        return stats.errorCount >= 2 &&
            stats.warningCount >= 2 &&
            stats.totalCount >= 6;
      },
      action: (context) {
        if (!mounted) return;
        setState(() => _syncHelpShown = true);
        ToastKit.show(ToastEvent.info(
          message: 'Sync is struggling: '
              '${context.stats.errorCount} errors, '
              '${context.stats.warningCount} warnings out of '
              '${context.stats.totalCount} total events. Check connection.',
          variant: ToastVariant.action,
          persistent: true,
          deduplicationKey: 'sync-combined-toast',
          actions: [
            ToastAction(
              label: 'Force Sync',
              onPressed: () {
                ToastKit.dismissAll();
                ToastKit.success('Full sync initiated…');
              },
            ),
          ],
          channel: _chSync,
        ));
      },
    ));

    // ── 8. Form Help Escalation ── proactive help after repeated failures
    ToastKit.addRule(ToastRule(
      id: 'form-help-guide',
      channel: _chForm,
      maxTriggers: 1,
      condition: (stats, event) => stats.errorCount >= 3,
      action: (_) {
        ToastKit.show(ToastEvent.info(
          message: 'Having trouble with the form? Check our help guide.',
          variant: ToastVariant.action,
          deduplicationKey: 'form-help-toast',
          actions: [
            ToastAction(
              label: 'View Guide',
              onPressed: () => ToastKit.success('Opening help guide…'),
            ),
            ToastAction(
              label: 'Contact Us',
              onPressed: () => ToastKit.info('Opening contact form…'),
            ),
          ],
          channel: _chForm,
        ));
      },
    ));

    // ── 9. Connectivity Banner ── persistent reconnect banner
    ToastKit.addRule(ToastRule(
      id: 'connectivity-banner',
      channel: _chConnectivity,
      deduplicateWindow: const Duration(seconds: 30),
      condition: (stats, event) => stats.errorCount >= 2,
      action: (_) {
        ToastKit.show(ToastEvent.warning(
          message: 'You appear to be offline. '
              'We\'ll reconnect automatically when network is available.',
          persistent: true,
          dismissible: true,
          variant: ToastVariant.action,
          deduplicationKey: 'connectivity-banner-toast',
          actions: [
            ToastAction(
              label: 'Retry Now',
              onPressed: () {
                ToastKit.dismissAll();
                ToastKit.info('Checking connection…');
              },
            ),
          ],
          channel: _chConnectivity,
        ));
      },
    ));

    // ── 10. Token Refresh Guard ── non-dismissible blocking + dynamic rule removal
    ToastKit.addRule(ToastRule(
      id: 'token-expired-guard',
      channel: _chToken,
      maxTriggers: 1,
      condition: (stats, event) => stats.errorCount >= 3,
      action: (_) {
        if (!mounted) return;
        setState(() => _tokenExpired = true);
        ToastKit.show(ToastEvent.error(
          message: 'Your authentication token has expired. '
              'Please sign in again to continue.',
          persistent: true,
          dismissible: false,
          deduplicationKey: 'token-expired-toast',
          channel: _chToken,
        ));
      },
    ));

    setState(() => _rulesRegistered = true);
  }

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------

  void _resetAll() {
    _lockTimer?.cancel();
    ToastKit.ruleEngine.clear();
    ToastKit.dismissAll();

    setState(() {
      _signInAttempts = 0;
      _accountLocked = false;
      _isSigningIn = false;
      _burstErrors = 0;
      _burstStatus = 'Stable';
      _rapidClickCount = 0;
      _paymentRetries = 0;
      _paymentBlocked = false;
      _paymentProcessing = false;
      _successCount = 0;
      _syncErrors = 0;
      _syncWarnings = 0;
      _syncTotal = 0;
      _syncHelpShown = false;
      _checkoutStep = 'cart';
      _formSubmits = 0;
      _isOffline = false;
      _offlineAttempts = 0;
      _tokenFailures = 0;
      _tokenExpired = false;
      _rulesRegistered = false;
    });

    _registerAll();
    ToastKit.success('All demos reset.', title: '✓ Reset');
  }

  // ---------------------------------------------------------------------------
  // Scenario action handlers
  // ---------------------------------------------------------------------------

  // 1) Auth guard
  Future<void> _attemptSignIn() async {
    if (_isSigningIn || _accountLocked) {
      if (_accountLocked) {
        ToastKit.warning('Account is locked. Please wait.');
      }
      return;
    }
    _isSigningIn = true;
    setState(() => _signInAttempts++);
    final ctrl = ToastKit.showLoading('Signing in…');
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      ctrl.error('Invalid email or password');
      ToastKit.error(
        'Sign-in attempt $_signInAttempts failed',
        channel: _chAuth,
      );
    } finally {
      _isSigningIn = false;
    }
  }

  // 2) Error burst — fire errors rapidly to trigger windowed detection
  void _fireBurstError() {
    setState(() => _burstErrors++);
    ToastKit.error(
      'Service error #$_burstErrors',
      channel: _chBurst,
    );
  }

  void _fireRapidBurst() {
    for (var i = 0; i < 5; i++) {
      _fireBurstError();
    }
  }

  // 3) Toast flood shield
  void _handleRapidClick() {
    setState(() => _rapidClickCount++);
    ToastKit.show(ToastEvent.info(
      message: 'Item added to cart',
      deduplicationKey: 'flood-add-to-cart',
      channel: _chFlood,
    ));
  }

  // 4) Payment recovery
  Future<void> _retryPayment() async {
    if (_paymentProcessing || _paymentBlocked) {
      if (_paymentBlocked) {
        ToastKit.warning('Payment is blocked. Use the recovery options above.');
      }
      return;
    }
    _paymentProcessing = true;
    setState(() => _paymentRetries++);
    final ctrl = ToastKit.showLoading('Processing payment…');
    try {
      await Future.delayed(const Duration(seconds: 1));
      ctrl.error('Payment declined');
      ToastKit.error(
        'Payment attempt $_paymentRetries failed',
        channel: _chPayment,
      );
    } finally {
      _paymentProcessing = false;
    }
  }

  // 5) Auto-save cooldown
  void _triggerAutoSave() {
    setState(() => _successCount++);
    ToastKit.show(ToastEvent.success(
      message: 'Document auto-saved',
      deduplicationKey: 'autosave-success',
      channel: _chAutoSave,
    ));
  }

  // 6) Combined stats — send mix of errors, warnings, and info
  void _triggerSyncError() {
    setState(() {
      _syncErrors++;
      _syncTotal++;
    });
    ToastKit.error('Sync conflict on file #$_syncErrors', channel: _chSync);
  }

  void _triggerSyncWarning() {
    setState(() {
      _syncWarnings++;
      _syncTotal++;
    });
    ToastKit.warning(
      'Slow sync: upstream latency detected',
      channel: _chSync,
    );
  }

  void _triggerSyncInfo() {
    setState(() => _syncTotal++);
    ToastKit.info('Sync checkpoint completed', channel: _chSync);
  }

  // 7) Checkout wizard
  void _advanceCheckout() {
    const steps = ['cart', 'shipping', 'payment', 'confirmation'];
    final currentIndex = steps.indexOf(_checkoutStep);
    if (currentIndex < steps.length - 1) {
      final next = steps[currentIndex + 1];
      setState(() => _checkoutStep = next);

      const messages = {
        'shipping': 'Please verify your shipping address before proceeding.',
        'payment': 'Enter your payment details to complete the order.',
        'confirmation':
            'Order placed successfully! Confirmation #TK-38291.',
      };

      final types = {
        'shipping': ToastType.info,
        'payment': ToastType.warning,
        'confirmation': ToastType.success,
      };

      ToastKit.show(ToastEvent(
        type: types[next] ?? ToastType.info,
        message: messages[next] ?? '',
        channel: _chCheckout,
      ));
    }
  }

  void _resetCheckout() {
    setState(() => _checkoutStep = 'cart');
    ToastKit.info('Checkout reset to cart.', channel: _chCheckout);
  }

  // 8) Form help escalation
  void _submitBadForm() {
    setState(() => _formSubmits++);
    const errors = [
      'Email address is required',
      'Password must be at least 8 characters',
      'Full name cannot be empty',
    ];
    for (final err in errors) {
      ToastKit.warning(err, channel: _chForm);
    }
    ToastKit.error('Form validation failed', channel: _chForm);
  }

  // 9) Connectivity banner
  void _toggleOffline() {
    setState(() {
      _isOffline = !_isOffline;
      _offlineAttempts = 0;
    });
    if (_isOffline) {
      ToastKit.warning('You are now offline.', channel: _chConnectivity);
    } else {
      ToastKit.dismissAll();
      ToastKit.success('Back online!');
    }
  }

  void _attemptWhileOffline() {
    if (!_isOffline) {
      ToastKit.success('Request succeeded (you are online).');
      return;
    }
    setState(() => _offlineAttempts++);
    ToastKit.error(
      'No internet connection (attempt $_offlineAttempts)',
      channel: _chConnectivity,
    );
  }

  // 10) Token refresh guard — with dynamic rule removal on re-login
  void _triggerTokenError() {
    if (_tokenExpired) {
      ToastKit.warning('Token expired. Please sign in again.');
      return;
    }
    setState(() => _tokenFailures++);
    ToastKit.error(
      '401 Unauthorized — token failure #$_tokenFailures',
      channel: _chToken,
    );
  }

  void _refreshToken() {
    // Remove the rule so it can be re-added with a fresh trigger count.
    ToastKit.removeRule('token-expired-guard');
    ToastKit.ruleEngine.resetStats();
    ToastKit.dismissAll();

    setState(() {
      _tokenFailures = 0;
      _tokenExpired = false;
    });

    // Re-register the rule after successful re-login.
    ToastKit.addRule(ToastRule(
      id: 'token-expired-guard',
      channel: _chToken,
      maxTriggers: 1,
      condition: (stats, event) => stats.errorCount >= 3,
      action: (_) {
        if (!mounted) return;
        setState(() => _tokenExpired = true);
        ToastKit.show(ToastEvent.error(
          message: 'Your authentication token has expired. '
              'Please sign in again to continue.',
          persistent: true,
          dismissible: false,
          deduplicationKey: 'token-expired-toast',
          channel: _chToken,
        ));
      },
    ));

    ToastKit.success('Token refreshed. Session restored.');
  }

  // ---------------------------------------------------------------------------
  // Reusable UI helpers
  // ---------------------------------------------------------------------------

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _stateIndicator({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBar(double value, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 8,
        backgroundColor: color.withAlpha(30),
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }

  Widget _checkoutStepIndicator() {
    const steps = ['cart', 'shipping', 'payment', 'confirmation'];
    final currentIdx = steps.indexOf(_checkoutStep);

    return Row(
      children: List.generate(steps.length, (i) {
        final isActive = i <= currentIdx;
        final isCurrent = i == currentIdx;
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: i < steps.length - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: isActive
                  ? (isCurrent ? Colors.blue : Colors.green)
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepLabel(String label, bool active) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          color: active ? Colors.teal : Colors.grey,
        ),
      ),
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
        title: const Text('Rules Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_outlined),
            tooltip: 'Reset All',
            onPressed: _resetAll,
          ),
        ],
      ),
      body: !_rulesRegistered
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Rule Engine Showcase',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Every ToastKit rule feature demonstrated with real-world '
                  'scenarios. Tap the buttons to see rules in action.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                _buildAuthGuardScenario(),
                const SizedBox(height: 12),
                _buildBurstDetectorScenario(),
                const SizedBox(height: 12),
                _buildFloodShieldScenario(),
                const SizedBox(height: 12),
                _buildPaymentRecoveryScenario(),
                const SizedBox(height: 12),
                _buildAutoSaveCooldownScenario(),
                const SizedBox(height: 12),
                _buildCombinedStatsScenario(),
                const SizedBox(height: 12),
                _buildCheckoutWizardScenario(),
                const SizedBox(height: 12),
                _buildFormHelpScenario(),
                const SizedBox(height: 12),
                _buildConnectivityBannerScenario(),
                const SizedBox(height: 12),
                _buildTokenRefreshScenario(),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  // ===========================================================================
  // Scenario Builders
  // ===========================================================================

  // ── 1. Auth Guard ──
  Widget _buildAuthGuardScenario() {
    return RuleScenarioCard(
      title: 'Auth Guard — Escalating Login Protection',
      icon: Icons.shield_outlined,
      iconColor: Colors.red,
      explanation:
          'Combines a config-based rule (errorThreshold: 3) with two custom '
          'rules: a password reset suggestion at 3 failures and an account '
          'lockout at 5. Each rule uses maxTriggers: 1 to fire only once.',
      whyItMatters:
          'Demonstrates the most common rule pattern: config rule for analytics '
          '+ custom rules for user-facing actions. maxTriggers prevents '
          'repeated firing once a threshold is crossed.',
      codeTitle: 'Auth Guard Rules',
      codeDescription:
          'Config rule for threshold tracking + two custom rules with '
          'maxTriggers: 1 for escalating protection.',
      code: _authGuardCode,
      trailing: _statusChip(
        _accountLocked ? '🔒 Locked' : '$_signInAttempts / 5',
        _accountLocked ? Colors.red : Colors.orange,
      ),
      resultWidget: Column(
        children: [
          _progressBar(_signInAttempts / 5, Colors.red),
          const SizedBox(height: 6),
          _stateIndicator(
            label: 'Attempts',
            value: '$_signInAttempts',
            icon: Icons.login,
            color: _signInAttempts >= 5 ? Colors.red : Colors.orange,
          ),
          _stateIndicator(
            label: 'Config rule (threshold: 3)',
            value: _signInAttempts >= 3 ? 'Triggered' : 'Waiting',
            icon: Icons.settings,
            color: _signInAttempts >= 3 ? Colors.green : Colors.grey,
          ),
          if (_accountLocked)
            _stateIndicator(
              label: 'Status',
              value: 'Locked (15s)',
              icon: Icons.lock,
              color: Colors.red,
            ),
        ],
      ),
      children: [
        DemoButton(
          label: _accountLocked ? 'Account Locked' : 'Attempt Sign In',
          icon: Icons.login,
          color: Colors.red,
          onPressed: _accountLocked ? null : _attemptSignIn,
        ),
      ],
    );
  }

  // ── 2. Error Burst Detector ──
  Widget _buildBurstDetectorScenario() {
    return RuleScenarioCard(
      title: 'Error Burst Detector — errorsInWindow()',
      icon: Icons.flash_on,
      iconColor: Colors.amber,
      explanation:
          'Uses stats.errorsInWindow(Duration(seconds: 10)) to detect error '
          'spikes in a sliding time window. Unlike cumulative errorCount, this '
          'catches sudden bursts even if total errors are still low. The rule '
          'has a 15-second deduplicateWindow to avoid re-firing immediately.',
      whyItMatters:
          'errorsInWindow() is the most advanced stat method — it enables '
          'rate-based detection that cumulative counts cannot. Essential for '
          'monitoring API health, detecting DDoS patterns, or unstable connections.',
      codeTitle: 'Windowed Error Detection',
      codeDescription:
          'Custom rule using errorsInWindow() for burst detection '
          'with deduplicateWindow to prevent rapid re-firing.',
      code: _burstDetectorCode,
      trailing: _statusChip(_burstStatus, Colors.amber),
      resultWidget: Column(
        children: [
          _stateIndicator(
            label: 'Total errors fired',
            value: '$_burstErrors',
            icon: Icons.error_outline,
            color: Colors.red,
          ),
          _stateIndicator(
            label: 'Detection method',
            value: 'errorsInWindow(10s)',
            icon: Icons.timer,
            color: Colors.amber,
          ),
          _stateIndicator(
            label: 'Status',
            value: _burstStatus,
            icon: _burstStatus == 'Stable'
                ? Icons.check_circle
                : Icons.warning,
            color:
                _burstStatus == 'Stable' ? Colors.green : Colors.orange,
          ),
        ],
      ),
      children: [
        DemoButton(
          label: 'Fire 1 Error',
          icon: Icons.error,
          color: Colors.amber,
          onPressed: _fireBurstError,
        ),
        DemoButton(
          label: 'Fire 5 Rapid Errors (triggers burst!)',
          icon: Icons.bolt,
          color: Colors.amber.shade800,
          onPressed: _fireRapidBurst,
        ),
      ],
    );
  }

  // ── 3. Toast Flood Shield ──
  Widget _buildFloodShieldScenario() {
    return RuleScenarioCard(
      title: 'Toast Flood Shield — Deduplication Window',
      icon: Icons.touch_app,
      iconColor: Colors.indigo,
      explanation:
          'A config-based rule with a 3-second deduplicateWindow suppresses '
          'identical toasts fired in rapid succession. Combined with a '
          'deduplicationKey on the toast event, only 1 toast appears per window.',
      whyItMatters:
          'Config rules are the simplest way to add dedup — no condition or '
          'action code needed. Perfect for "fire-and-forget" scenarios like '
          'add-to-cart, bookmark, or like buttons.',
      codeTitle: 'Config-Based Deduplication',
      codeDescription:
          'RuleConfig with deduplicateWindow: 3s + deduplicationKey '
          'on the toast event.',
      code: _floodShieldCode,
      trailing: _statusChip('$_rapidClickCount taps', Colors.indigo),
      resultWidget: Column(
        children: [
          _stateIndicator(
            label: 'Button taps (all)',
            value: '$_rapidClickCount',
            icon: Icons.ads_click,
            color: Colors.indigo,
          ),
          _stateIndicator(
            label: 'Dedup window',
            value: '3 seconds',
            icon: Icons.timer,
            color: Colors.indigo,
          ),
        ],
      ),
      children: [
        DemoButton(
          label: 'Add to Cart (tap rapidly!)',
          icon: Icons.add_shopping_cart,
          color: Colors.indigo,
          onPressed: _handleRapidClick,
        ),
      ],
    );
  }

  // ── 4. Payment Recovery ──
  Widget _buildPaymentRecoveryScenario() {
    return RuleScenarioCard(
      title: 'Payment Recovery — Multi-Step Escalation',
      icon: Icons.payment,
      iconColor: Colors.deepOrange,
      explanation:
          'Two custom rules escalate payment failure handling: a warning toast '
          'at 2 errors and a persistent action toast with 3 recovery options at '
          '4 errors. The blocking toast prevents further payment attempts.',
      whyItMatters:
          'Shows how multiple rules on the same channel create escalating '
          'responses. Action toasts with multiple ToastAction buttons let users '
          'recover without navigating away.',
      codeTitle: 'Payment Escalation Rules',
      codeDescription:
          'Two custom rules with escalating conditions and action toasts '
          'offering recovery options.',
      code: _paymentRecoveryCode,
      trailing: _statusChip(
        _paymentBlocked ? '⛔ Blocked' : '$_paymentRetries / 4',
        _paymentBlocked ? Colors.red : Colors.deepOrange,
      ),
      resultWidget: Column(
        children: [
          _progressBar(_paymentRetries / 4, Colors.deepOrange),
          const SizedBox(height: 6),
          _stateIndicator(
            label: 'Payment attempts',
            value: '$_paymentRetries',
            icon: Icons.credit_card,
            color: _paymentRetries >= 4 ? Colors.red : Colors.deepOrange,
          ),
          _stateIndicator(
            label: 'Warning rule (>= 2)',
            value: _paymentRetries >= 2 ? 'Fired' : 'Pending',
            icon: Icons.warning_amber,
            color: _paymentRetries >= 2 ? Colors.orange : Colors.grey,
          ),
          _stateIndicator(
            label: 'Block rule (>= 4)',
            value: _paymentBlocked ? 'Active' : 'Pending',
            icon: Icons.block,
            color: _paymentBlocked ? Colors.red : Colors.grey,
          ),
        ],
      ),
      children: [
        DemoButton(
          label:
              _paymentBlocked ? 'Payments Suspended' : 'Process Payment',
          icon: Icons.payment,
          color: Colors.deepOrange,
          onPressed: _paymentBlocked ? null : _retryPayment,
        ),
      ],
    );
  }

  // ── 5. Auto-Save Cooldown ──
  Widget _buildAutoSaveCooldownScenario() {
    return RuleScenarioCard(
      title: 'Auto-Save Cooldown — maxTriggers + Dedup',
      icon: Icons.save_outlined,
      iconColor: Colors.green,
      explanation:
          'A config rule with maxTriggers: 3 and a 5-second dedup window '
          'limits auto-save success toasts. After 3 total triggers, the rule '
          'stops permanently. Within each window, duplicates are suppressed.',
      whyItMatters:
          'maxTriggers caps the total number of rule firings across the entire '
          'session. Combined with deduplicateWindow, it creates a "show a few '
          'then go silent" pattern — perfect for auto-save, sync, or heartbeat.',
      codeTitle: 'Success Noise Reduction',
      codeDescription:
          'RuleConfig with maxTriggers: 3 and deduplicateWindow: 5s '
          'limits how often success toasts appear.',
      code: _autoSaveCooldownCode,
      trailing: _statusChip('$_successCount saves', Colors.green),
      resultWidget: Column(
        children: [
          _stateIndicator(
            label: 'Save triggers',
            value: '$_successCount',
            icon: Icons.save,
            color: Colors.green,
          ),
          _stateIndicator(
            label: 'maxTriggers',
            value: '3 total',
            icon: Icons.repeat_one,
            color: Colors.green,
          ),
          _stateIndicator(
            label: 'Dedup window',
            value: '5 seconds',
            icon: Icons.timer,
            color: Colors.green,
          ),
        ],
      ),
      children: [
        DemoButton(
          label: 'Auto-Save (tap repeatedly)',
          icon: Icons.save,
          color: Colors.green,
          onPressed: _triggerAutoSave,
        ),
      ],
    );
  }

  // ── 6. Combined Stats ──
  Widget _buildCombinedStatsScenario() {
    return RuleScenarioCard(
      title: 'Combined Stats — Multi-Condition Rule',
      icon: Icons.analytics_outlined,
      iconColor: Colors.cyan,
      explanation:
          'This rule fires only when multiple stat thresholds are met '
          'simultaneously: errorCount >= 2 AND warningCount >= 2 AND '
          'totalCount >= 6. Send a mix of errors, warnings, and info events '
          'to trigger it.',
      whyItMatters:
          'Demonstrates that rule conditions can use ANY combination of '
          'ToastStats fields: errorCount, warningCount, successCount, '
          'infoCount, totalCount, dismissedCount, and droppedCount.',
      codeTitle: 'Combined Stats Condition',
      codeDescription:
          'A custom rule using errorCount + warningCount + totalCount '
          'to detect combined degradation patterns.',
      code: _combinedStatsCode,
      trailing: _statusChip(
        _syncHelpShown ? '⚠️ Alert' : '$_syncTotal events',
        _syncHelpShown ? Colors.orange : Colors.cyan,
      ),
      resultWidget: Column(
        children: [
          _stateIndicator(
            label: 'Errors (need ≥ 2)',
            value: '$_syncErrors',
            icon: Icons.error,
            color: _syncErrors >= 2 ? Colors.green : Colors.red,
          ),
          _stateIndicator(
            label: 'Warnings (need ≥ 2)',
            value: '$_syncWarnings',
            icon: Icons.warning,
            color: _syncWarnings >= 2 ? Colors.green : Colors.orange,
          ),
          _stateIndicator(
            label: 'Total events (need ≥ 6)',
            value: '$_syncTotal',
            icon: Icons.summarize,
            color: _syncTotal >= 6 ? Colors.green : Colors.blue,
          ),
          if (_syncHelpShown)
            _stateIndicator(
              label: 'Rule status',
              value: 'Triggered ✓',
              icon: Icons.check_circle,
              color: Colors.green,
            ),
        ],
      ),
      children: [
        DemoButton(
          label: 'Send Error',
          icon: Icons.error,
          color: Colors.red,
          onPressed: _triggerSyncError,
        ),
        DemoButton(
          label: 'Send Warning',
          icon: Icons.warning,
          color: Colors.orange,
          onPressed: _triggerSyncWarning,
        ),
        DemoButton(
          label: 'Send Info',
          icon: Icons.info,
          color: Colors.blue,
          onPressed: _triggerSyncInfo,
        ),
      ],
    );
  }

  // ── 7. Checkout Wizard ──
  Widget _buildCheckoutWizardScenario() {
    return RuleScenarioCard(
      title: 'Checkout Wizard — Context-Aware Messages',
      icon: Icons.shopping_cart_outlined,
      iconColor: Colors.teal,
      explanation:
          'Each checkout step shows a different toast type: info for shipping, '
          'warning for payment, and success for confirmation. All toasts are '
          'scoped to the checkout channel for independent tracking.',
      whyItMatters:
          'Shows channel-scoped toast management. Each channel maintains '
          'independent stats, so checkout rules don\'t interfere with auth '
          'or payment rules — even when using the same app.',
      codeTitle: 'Channel-Scoped Checkout Flow',
      codeDescription:
          'Dynamic toast type and message selection per checkout step, '
          'all scoped to a dedicated channel.',
      code: _checkoutWizardCode,
      trailing: _statusChip(
        _checkoutStep.toUpperCase(),
        _checkoutStep == 'confirmation' ? Colors.green : Colors.teal,
      ),
      resultWidget: Column(
        children: [
          _checkoutStepIndicator(),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStepLabel('Cart', _checkoutStep == 'cart'),
              _buildStepLabel('Ship', _checkoutStep == 'shipping'),
              _buildStepLabel('Pay', _checkoutStep == 'payment'),
              _buildStepLabel('Done', _checkoutStep == 'confirmation'),
            ],
          ),
        ],
      ),
      children: [
        DemoButton(
          label: _checkoutStep == 'confirmation'
              ? 'Order Complete ✓'
              : 'Next Step →',
          icon: _checkoutStep == 'confirmation'
              ? Icons.check
              : Icons.arrow_forward,
          color: Colors.teal,
          onPressed:
              _checkoutStep == 'confirmation' ? null : _advanceCheckout,
        ),
        DemoButton(
          label: 'Reset Checkout',
          icon: Icons.restart_alt,
          color: Colors.grey,
          onPressed: _resetCheckout,
        ),
      ],
    );
  }

  // ── 8. Form Help Escalation ──
  Widget _buildFormHelpScenario() {
    return RuleScenarioCard(
      title: 'Form Help — Proactive Guidance After Failures',
      icon: Icons.help_outline,
      iconColor: Colors.amber.shade800,
      explanation:
          'Each invalid form submission shows per-field warning toasts and '
          'records an error on the form channel. After 3 failed submissions, '
          'a custom rule proactively offers a help guide with action buttons.',
      whyItMatters:
          'Instead of showing the same validation errors endlessly, the rule '
          'engine detects frustration (3+ failures) and offers contextual help. '
          'The action toast provides direct links to assistance.',
      codeTitle: 'Form Validation + Help Rule',
      codeDescription:
          'Custom rule on the form channel triggers an action toast '
          'with help links after 3 validation failures.',
      code: _formHelpCode,
      trailing:
          _statusChip('$_formSubmits submits', Colors.amber.shade800),
      resultWidget: Column(
        children: [
          _progressBar(_formSubmits / 3, Colors.amber.shade800),
          const SizedBox(height: 6),
          _stateIndicator(
            label: 'Failed submissions',
            value: '$_formSubmits',
            icon: Icons.error_outline,
            color: _formSubmits >= 3 ? Colors.red : Colors.amber.shade800,
          ),
          _stateIndicator(
            label: 'Help rule (>= 3)',
            value: _formSubmits >= 3 ? 'Triggered' : 'Waiting',
            icon: Icons.help,
            color: _formSubmits >= 3 ? Colors.green : Colors.grey,
          ),
        ],
      ),
      children: [
        DemoButton(
          label: 'Submit Invalid Form',
          icon: Icons.send,
          color: Colors.amber.shade800,
          onPressed: _submitBadForm,
        ),
      ],
    );
  }

  // ── 9. Connectivity Banner ──
  Widget _buildConnectivityBannerScenario() {
    return RuleScenarioCard(
      title: 'Connectivity Banner — Persistent Reconnect',
      icon: Icons.signal_wifi_off,
      iconColor: Colors.blueGrey,
      explanation:
          'Toggle offline mode and make requests. After 2 failures, a '
          'persistent dismissible banner appears with a "Retry Now" action. '
          'The rule uses a 30-second deduplicateWindow to avoid re-firing '
          'immediately if the user dismisses and more errors occur.',
      whyItMatters:
          'Persistent + dismissible toasts create non-intrusive banners that '
          'stay visible until the user acts. deduplicateWindow on custom rules '
          'prevents re-showing the banner too quickly after dismissal.',
      codeTitle: 'Offline Detection + Reconnect',
      codeDescription:
          'Custom rule with deduplicateWindow: 30s showing a persistent '
          'action toast with reconnect option.',
      code: _connectivityBannerCode,
      trailing: _statusChip(
        _isOffline ? '📴 Offline' : '🟢 Online',
        _isOffline ? Colors.red : Colors.green,
      ),
      resultWidget: Column(
        children: [
          _stateIndicator(
            label: 'Status',
            value: _isOffline ? 'Offline' : 'Online',
            icon: _isOffline ? Icons.cloud_off : Icons.cloud_done,
            color: _isOffline ? Colors.red : Colors.green,
          ),
          if (_isOffline)
            _stateIndicator(
              label: 'Failed attempts',
              value: '$_offlineAttempts',
              icon: Icons.error_outline,
              color: Colors.red,
            ),
          _stateIndicator(
            label: 'Dedup window',
            value: '30 seconds',
            icon: Icons.timer,
            color: Colors.blueGrey,
          ),
        ],
      ),
      children: [
        DemoButton(
          label: _isOffline ? 'Go Online' : 'Go Offline',
          icon: _isOffline ? Icons.wifi : Icons.wifi_off,
          color: Colors.blueGrey,
          onPressed: _toggleOffline,
        ),
        DemoButton(
          label: 'Make API Request',
          icon: Icons.cloud_download,
          color: Colors.blueGrey.shade700,
          onPressed: _attemptWhileOffline,
        ),
      ],
    );
  }

  // ── 10. Token Refresh Guard ──
  Widget _buildTokenRefreshScenario() {
    return RuleScenarioCard(
      title: 'Token Guard — Non-Dismissible Block + Rule Removal',
      icon: Icons.vpn_key_outlined,
      iconColor: Colors.purple,
      explanation:
          'After 3 unauthorized (401) errors, a non-dismissible persistent '
          'toast blocks all actions. Signing in again calls removeRule() to '
          'clear the guard, then re-adds it with fresh trigger counts. This '
          'demonstrates dynamic rule lifecycle management.',
      whyItMatters:
          'Non-dismissible toasts (dismissible: false) create hard blocks. '
          'removeRule() + addRule() shows that rules can be dynamically '
          'managed at runtime — added, removed, and re-registered as needed.',
      codeTitle: 'Token Guard + Dynamic Rule Removal',
      codeDescription:
          'Custom rule with maxTriggers: 1 and non-dismissible toast. '
          'removeRule() clears the guard on successful re-authentication.',
      code: _tokenGuardCode,
      trailing: _statusChip(
        _tokenExpired ? '🔐 Expired' : '$_tokenFailures / 3',
        _tokenExpired ? Colors.red : Colors.purple,
      ),
      resultWidget: Column(
        children: [
          _progressBar(_tokenFailures / 3, Colors.purple),
          const SizedBox(height: 6),
          _stateIndicator(
            label: 'Token errors',
            value: '$_tokenFailures',
            icon: Icons.vpn_key,
            color: _tokenFailures >= 3 ? Colors.red : Colors.purple,
          ),
          if (_tokenExpired)
            _stateIndicator(
              label: 'Status',
              value: 'Blocked — must re-authenticate',
              icon: Icons.lock,
              color: Colors.red,
            ),
        ],
      ),
      children: [
        DemoButton(
          label: _tokenExpired
              ? 'Actions Blocked'
              : 'Simulate 401 Error',
          icon: Icons.error_outline,
          color: Colors.purple,
          onPressed: _tokenExpired ? null : _triggerTokenError,
        ),
        if (_tokenExpired)
          DemoButton(
            label: 'Sign In Again (removes + re-adds rule)',
            icon: Icons.login,
            color: Colors.green,
            onPressed: _refreshToken,
          ),
      ],
    );
  }
}

// =============================================================================
// Code Strings — displayed in the "See Code" modal for each scenario.
// Each code sample is self-contained and highlights specific rule features.
// =============================================================================

const _authGuardCode = '''// ─── Auth Guard: Config Rule + Custom Rules ───
//
// Features demonstrated:
//   • RuleConfig.errorThreshold — triggers after N errors
//   • ToastRule.maxTriggers — fire-once control
//   • Escalating rules on the same channel

// 1. Config-based rule for analytics/plugin notification.
ToastKit.configureRule(
  'auth',
  const RuleConfig(
    errorThreshold: 3,           // Fire when errorCount >= 3
    deduplicateWindow: Duration(seconds: 60),
    maxTriggers: 1,              // Fire only once
  ),
);

// 2. Custom rule: suggest password reset at 3 failures.
ToastKit.addRule(ToastRule(
  id: 'auth-suggest-reset',
  channel: 'auth',
  maxTriggers: 1,                // Fire at most once
  condition: (stats, event) =>
      stats.errorCount >= 3 && stats.errorCount < 5,
  action: (context) {
    ToastKit.show(ToastEvent.info(
      message: 'Having trouble? Try resetting your password.',
      variant: ToastVariant.action,
      deduplicationKey: 'auth-suggest-reset',
      actions: [
        ToastAction(
          label: 'Reset Password',
          onPressed: () =>
              ToastKit.success('Password reset email sent!'),
        ),
      ],
      channel: 'auth',
    ));
  },
));

// 3. Custom rule: lock account at 5 failures.
ToastKit.addRule(ToastRule(
  id: 'auth-lockout',
  channel: 'auth',
  maxTriggers: 1,
  condition: (stats, event) => stats.errorCount >= 5,
  action: (context) {
    ToastKit.show(ToastEvent.error(
      message: 'Account locked for 15 seconds.',
      persistent: true,          // Stays until dismissed
      dismissible: false,        // Cannot be swiped away
      deduplicationKey: 'auth-lockout-toast',
      channel: 'auth',
    ));
  },
));

// Usage: each login failure records an error on the auth channel.
// Rules evaluate automatically after each error.
ToastKit.error('Login failed', channel: 'auth');''';

const _burstDetectorCode = '''// ─── Error Burst Detector: errorsInWindow() ───
//
// Features demonstrated:
//   • stats.errorsInWindow(Duration) — sliding time window analysis
//   • ToastRule.deduplicateWindow — prevents rapid re-firing
//   • context.stats access in action callback

ToastKit.addRule(ToastRule(
  id: 'burst-spike-detector',
  channel: 'api-health',
  deduplicateWindow: const Duration(seconds: 15),  // Don't re-fire for 15s
  condition: (stats, event) {
    // Detect 4+ errors within the last 10 seconds.
    // Unlike cumulative errorCount, this catches sudden spikes
    // even if total errors are still low.
    return stats.errorsInWindow(const Duration(seconds: 10)) >= 4;
  },
  action: (context) {
    final recentCount = context.stats.errorsInWindow(
      const Duration(seconds: 10),
    );
    ToastKit.show(ToastEvent.warning(
      message: 'Error spike detected: \$recentCount errors in 10 seconds.',
      variant: ToastVariant.action,
      deduplicationKey: 'burst-spike-toast',
      actions: [
        ToastAction(
          label: 'View Details',
          onPressed: () => ToastKit.info(
            'Total: \${context.stats.totalCount}, '
            'Errors: \${context.stats.errorCount}',
          ),
        ),
      ],
      channel: 'api-health',
    ));
  },
));

// Fire errors rapidly to trigger the burst detector:
for (var i = 0; i < 5; i++) {
  ToastKit.error('Service error', channel: 'api-health');
}''';

const _floodShieldCode = '''// ─── Toast Flood Shield: Config-Based Deduplication ───
//
// Features demonstrated:
//   • RuleConfig.deduplicateWindow — suppress duplicates within time window
//   • RuleConfig.maxTriggers: 0 — unlimited (fires every time window resets)
//   • ToastEvent.deduplicationKey — identifies duplicate toasts

ToastKit.configureRule(
  'cart',
  const RuleConfig(
    errorThreshold: 1,           // Fire on every event
    deduplicateWindow: Duration(seconds: 3),  // 3-second cooldown
    maxTriggers: 0,              // Unlimited total triggers
  ),
);

// Every tap uses the same deduplication key.
// Only 1 toast appears per 3-second window, no matter how fast you tap.
void onAddToCart() {
  ToastKit.show(ToastEvent.info(
    message: 'Item added to cart',
    deduplicationKey: 'rapid-add-to-cart',  // Same key = same toast
    channel: 'cart',
  ));
}''';

const _paymentRecoveryCode = '''// ─── Payment Recovery: Multi-Step Escalation ───
//
// Features demonstrated:
//   • Multiple rules on the same channel with different thresholds
//   • ToastVariant.action with multiple ToastAction buttons
//   • persistent: true — toast stays until user acts
//   • Rule actions that modify app state (setState)

// Step 1: Warning after 2 failures.
ToastKit.addRule(ToastRule(
  id: 'payment-warn',
  channel: 'payment',
  maxTriggers: 1,
  condition: (stats, event) =>
      stats.errorCount >= 2 && stats.errorCount < 4,
  action: (_) {
    ToastKit.show(ToastEvent.warning(
      message: 'Multiple payment failures. Check your card details.',
      deduplicationKey: 'payment-warn-toast',
      channel: 'payment',
    ));
  },
));

// Step 2: Block and offer recovery after 4 failures.
ToastKit.addRule(ToastRule(
  id: 'payment-block',
  channel: 'payment',
  maxTriggers: 1,
  condition: (stats, event) => stats.errorCount >= 4,
  action: (_) {
    setState(() => _paymentBlocked = true);
    ToastKit.show(ToastEvent.error(
      message: 'Payment processing suspended.',
      persistent: true,
      dismissible: true,
      variant: ToastVariant.action,
      deduplicationKey: 'payment-block-toast',
      actions: [
        ToastAction(
          label: 'Switch Card',
          onPressed: () { /* switch payment method */ },
        ),
        ToastAction(
          label: 'Use PayPal',
          onPressed: () { /* redirect to PayPal */ },
        ),
        ToastAction(
          label: 'Contact Support',
          onPressed: () { /* open support chat */ },
        ),
      ],
      channel: 'payment',
    ));
  },
));''';

const _autoSaveCooldownCode = '''// ─── Auto-Save Cooldown: maxTriggers + Dedup ───
//
// Features demonstrated:
//   • RuleConfig.maxTriggers — caps total fires across the session
//   • RuleConfig.deduplicateWindow — suppresses within time window
//   • Combined effect: "show a few, then go silent"

ToastKit.configureRule(
  'auto-save',
  const RuleConfig(
    errorThreshold: 1,           // Trigger on every event
    deduplicateWindow: Duration(seconds: 5),   // 5s between toasts
    maxTriggers: 3,              // Only 3 toasts total, ever
  ),
);

// Auto-save fires frequently, but the rule ensures:
// - Max 1 toast per 5-second window (dedup)
// - Max 3 toasts total in the entire session (maxTriggers)
// - After 3 total triggers, no more toasts regardless of saves
void onAutoSave() {
  ToastKit.show(ToastEvent.success(
    message: 'Document auto-saved',
    deduplicationKey: 'autosave-success',
    channel: 'auto-save',
  ));
}''';

const _combinedStatsCode = '''// ─── Combined Stats: Multi-Condition Rule ───
//
// Features demonstrated:
//   • stats.errorCount — cumulative error count
//   • stats.warningCount — cumulative warning count
//   • stats.totalCount — all events regardless of type
//   • Combined conditions using AND logic
//   • context.stats in action for dynamic messages

ToastKit.addRule(ToastRule(
  id: 'sync-combined-alert',
  channel: 'sync',
  maxTriggers: 1,
  condition: (stats, event) {
    // Fire only when ALL three conditions are met:
    return stats.errorCount >= 2 &&     // At least 2 errors
        stats.warningCount >= 2 &&      // At least 2 warnings
        stats.totalCount >= 6;          // At least 6 total events
  },
  action: (context) {
    // Access stats in the action for dynamic messages.
    ToastKit.show(ToastEvent.info(
      message: 'Sync degraded: '
          '\${context.stats.errorCount} errors, '
          '\${context.stats.warningCount} warnings '
          'out of \${context.stats.totalCount} events.',
      variant: ToastVariant.action,
      persistent: true,
      deduplicationKey: 'sync-combined-toast',
      actions: [
        ToastAction(
          label: 'Force Sync',
          onPressed: () => ToastKit.success('Full sync initiated…'),
        ),
      ],
      channel: 'sync',
    ));
  },
));

// Available ToastStats fields:
// stats.totalCount     — all events
// stats.errorCount     — errors only
// stats.warningCount   — warnings only
// stats.successCount   — successes only
// stats.infoCount      — info only
// stats.dismissedCount — dismissed by user
// stats.droppedCount   — dropped (channel full, dedup, etc.)
// stats.errorsInWindow(Duration) — errors in time window''';

const _checkoutWizardCode = '''// ─── Checkout Wizard: Channel-Scoped Context ───
//
// Features demonstrated:
//   • Channel-scoped toast management
//   • Dynamic ToastType selection based on app state
//   • Independent channel stats (checkout doesn't affect auth)

ToastKit.registerChannel(
  ToastChannel(id: 'checkout', label: 'Checkout Flow'),
);

void advanceCheckout(String step) {
  final messages = {
    'shipping': 'Please verify your shipping address.',
    'payment': 'Enter your payment details.',
    'confirmation': 'Order placed! Confirmation #TK-38291.',
  };

  final types = {
    'shipping': ToastType.info,      // Informational
    'payment': ToastType.warning,    // Requires attention
    'confirmation': ToastType.success, // Positive outcome
  };

  ToastKit.show(ToastEvent(
    type: types[step] ?? ToastType.info,
    message: messages[step] ?? '',
    channel: 'checkout',  // Scoped to checkout channel
  ));
}''';

const _formHelpCode = '''// ─── Form Help: Proactive Guidance ───
//
// Features demonstrated:
//   • Custom rule with errorCount threshold
//   • Action toast with multiple help options
//   • Per-field warning toasts + aggregate error tracking

ToastKit.addRule(ToastRule(
  id: 'form-help-guide',
  channel: 'form',
  maxTriggers: 1,                // Show help only once
  condition: (stats, event) => stats.errorCount >= 3,
  action: (_) {
    ToastKit.show(ToastEvent.info(
      message: 'Having trouble? Check our help guide.',
      variant: ToastVariant.action,
      deduplicationKey: 'form-help-toast',
      actions: [
        ToastAction(
          label: 'View Guide',
          onPressed: () => ToastKit.success('Opening help…'),
        ),
        ToastAction(
          label: 'Contact Us',
          onPressed: () => ToastKit.info('Opening contact form…'),
        ),
      ],
      channel: 'form',
    ));
  },
));

// On each submit, show per-field warnings:
void onSubmit(List<String> errors) {
  for (final error in errors) {
    ToastKit.warning(error, channel: 'form');
  }
  // Record an error so the rule can track submissions:
  ToastKit.error('Form validation failed', channel: 'form');
}''';

const _connectivityBannerCode = '''// ─── Connectivity Banner: Persistent Dismissible ───
//
// Features demonstrated:
//   • persistent: true — toast stays visible indefinitely
//   • dismissible: true — user CAN swipe it away
//   • ToastRule.deduplicateWindow — prevents re-showing too quickly
//   • Action toast with reconnect option

ToastKit.addRule(ToastRule(
  id: 'connectivity-banner',
  channel: 'connectivity',
  deduplicateWindow: const Duration(seconds: 30),  // 30s cooldown
  condition: (stats, event) => stats.errorCount >= 2,
  action: (_) {
    ToastKit.show(ToastEvent.warning(
      message: 'You appear to be offline. '
          'We\\'ll reconnect automatically.',
      persistent: true,          // Stays on screen
      dismissible: true,         // User can dismiss
      variant: ToastVariant.action,
      deduplicationKey: 'connectivity-banner-toast',
      actions: [
        ToastAction(
          label: 'Retry Now',
          onPressed: () {
            ToastKit.dismissAll();
            ToastKit.info('Checking connection…');
          },
        ),
      ],
      channel: 'connectivity',
    ));
  },
));

// If the user dismisses the banner and 2+ more errors occur,
// the 30-second deduplicateWindow prevents immediate re-showing.''';

const _tokenGuardCode = '''// ─── Token Guard: Non-Dismissible + Rule Removal ───
//
// Features demonstrated:
//   • persistent: true + dismissible: false — hard block
//   • ToastKit.removeRule() — dynamic rule removal
//   • ToastKit.addRule() — re-register after removal
//   • ruleEngine.resetStats() — clear trigger counts

// Register the guard rule.
ToastKit.addRule(ToastRule(
  id: 'token-expired-guard',
  channel: 'session',
  maxTriggers: 1,
  condition: (stats, event) => stats.errorCount >= 3,
  action: (_) {
    setState(() => _tokenExpired = true);
    ToastKit.show(ToastEvent.error(
      message: 'Token expired. Please sign in again.',
      persistent: true,          // Stays on screen
      dismissible: false,        // CANNOT be dismissed
      deduplicationKey: 'token-expired-toast',
      channel: 'session',
    ));
  },
));

// On successful re-authentication:
void onReLogin() {
  // 1. Remove the old rule (clears its maxTriggers count).
  ToastKit.removeRule('token-expired-guard');

  // 2. Reset stats so old error counts don't carry over.
  ToastKit.ruleEngine.resetStats();

  // 3. Dismiss the blocking toast.
  ToastKit.dismissAll();

  // 4. Re-register the rule with fresh state.
  ToastKit.addRule(ToastRule(
    id: 'token-expired-guard',
    channel: 'session',
    maxTriggers: 1,
    condition: (stats, event) => stats.errorCount >= 3,
    action: (_) { /* same blocking action */ },
  ));

  ToastKit.success('Session restored.');
}''';
