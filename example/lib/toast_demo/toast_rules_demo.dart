import 'dart:async';

import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

import '../widgets/buttons/demo_button.dart';
import '../widgets/cards/rule_scenario_card.dart';

// =============================================================================
// Redesigned Rules Demo
//
// 10 real-world scenarios that showcase the ToastKit rule engine with
// interactive controls, visible state, code samples, and "why it matters" notes.
// =============================================================================

class ToastRulesDemo extends StatefulWidget {
  const ToastRulesDemo({super.key});

  @override
  State<ToastRulesDemo> createState() => _ToastRulesDemoState();
}

class _ToastRulesDemoState extends State<ToastRulesDemo> {
  // ── Shared state ──
  bool _rulesRegistered = false;

  // ── Scenario 1: Failed sign-in ──
  int _signInAttempts = 0;
  bool _accountLocked = false;

  // ── Scenario 2: Network escalation ──
  int _networkFailures = 0;

  // ── Scenario 3: Rapid clicks / dedup ──
  int _rapidClickCount = 0;

  // ── Scenario 4: Payment retries ──
  int _paymentRetries = 0;
  bool _paymentBlocked = false;

  // ── Scenario 5: Success noise reduction ──
  int _successCount = 0;

  // ── Scenario 6: API error dedup window ──
  int _apiErrors = 0;
  int _apiToastsShown = 0;

  // ── Scenario 7: Checkout context ──
  String _checkoutStep = 'cart';

  // ── Scenario 8: Form validation ──
  int _formSubmits = 0;

  // ── Scenario 9: Offline mode ──
  bool _isOffline = false;
  int _offlineAttempts = 0;

  // ── Scenario 10: Session expired ──
  int _sessionFailures = 0;
  bool _sessionForceLogout = false;

  // ── Timers ──
  Timer? _lockTimer;

  // ── Channel IDs ──
  static const _chSignIn = 'rules-signin';
  static const _chNetwork = 'rules-network-escalation';
  static const _chRapid = 'rules-rapid-clicks';
  static const _chPayment = 'rules-payment-retry';
  static const _chSuccess = 'rules-success-noise';
  static const _chApiDedup = 'rules-api-dedup';
  static const _chCheckout = 'rules-checkout';
  static const _chForm = 'rules-form-validation';
  static const _chOffline = 'rules-offline';
  static const _chSession = 'rules-session';

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
  // Registration
  // ---------------------------------------------------------------------------

  void _registerAll() {
    final channels = [
      _chSignIn,
      _chNetwork,
      _chRapid,
      _chPayment,
      _chSuccess,
      _chApiDedup,
      _chCheckout,
      _chForm,
      _chOffline,
      _chSession,
    ];
    for (final ch in channels) {
      ToastKit.registerChannel(ToastChannel(id: ch, label: ch));
    }

    // ── Scenario 1: Sign-in lockout ──
    ToastKit.addRule(ToastRule(
      id: 'signin-suggest-reset',
      channel: _chSignIn,
      condition: (stats, event) => stats.errorCount == 3,
      action: (_) {
        ToastKit.show(ToastEvent.info(
          message: 'Having trouble? Try resetting your password.',
          variant: ToastVariant.action,
          deduplicationKey: 'signin-suggest-reset',
          actions: [
            ToastAction(
              label: 'Reset Password',
              onPressed: () =>
                  ToastKit.success('Password reset email sent!'),
            ),
          ],
          channel: _chSignIn,
        ));
      },
    ));

    ToastKit.addRule(ToastRule(
      id: 'signin-lockout',
      channel: _chSignIn,
      condition: (stats, event) => stats.errorCount >= 5,
      action: (_) {
        if (!mounted) return;
        setState(() => _accountLocked = true);
        ToastKit.show(ToastEvent.error(
          message: 'Account locked for 15 seconds due to too many attempts.',
          persistent: true,
          dismissible: false,
          deduplicationKey: 'signin-lockout-toast',
          channel: _chSignIn,
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

    // ── Scenario 2: Network escalation ──
    ToastKit.addRule(ToastRule(
      id: 'net-escalate-warning',
      channel: _chNetwork,
      condition: (stats, event) =>
          stats.errorCount >= 3 && stats.errorCount < 5,
      action: (_) {
        ToastKit.warning(
          'Multiple connection failures detected. Retrying…',
          channel: _chNetwork,
        );
      },
    ));

    ToastKit.addRule(ToastRule(
      id: 'net-escalate-error',
      channel: _chNetwork,
      condition: (stats, event) => stats.errorCount >= 5,
      action: (_) {
        ToastKit.show(ToastEvent.error(
          message:
              'Persistent connectivity issues. Check your network connection.',
          variant: ToastVariant.action,
          persistent: true,
          deduplicationKey: 'net-escalate-error-toast',
          actions: [
            ToastAction(
              label: 'Retry Now',
              onPressed: () {
                ToastKit.dismissAll();
                ToastKit.info('Retrying…');
              },
            ),
          ],
          channel: _chNetwork,
        ));
      },
    ));

    // ── Scenario 3: Rapid click dedup ──
    ToastKit.configureRule(
      _chRapid,
      const RuleConfig(
        errorThreshold: 1,
        deduplicateWindow: Duration(seconds: 3),
        maxTriggers: 0,
      ),
    );

    // ── Scenario 4: Payment failure ──
    ToastKit.addRule(ToastRule(
      id: 'payment-block',
      channel: _chPayment,
      condition: (stats, event) => stats.errorCount >= 3,
      action: (_) {
        if (!mounted) return;
        setState(() => _paymentBlocked = true);
        ToastKit.show(ToastEvent.error(
          message: 'Payment failed after multiple attempts. '
              'Please verify your card details or try another method.',
          persistent: true,
          dismissible: true,
          variant: ToastVariant.action,
          deduplicationKey: 'payment-block-toast',
          actions: [
            ToastAction(
              label: 'Try Another Card',
              onPressed: () {
                ToastKit.dismissAll();
                ToastKit.info('Opening payment methods…');
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

    // ── Scenario 5: Success cooldown ──
    ToastKit.configureRule(
      _chSuccess,
      const RuleConfig(
        errorThreshold: 1,
        deduplicateWindow: Duration(seconds: 5),
        maxTriggers: 2,
      ),
    );

    // ── Scenario 6: API dedup ──
    ToastKit.configureRule(
      _chApiDedup,
      const RuleConfig(
        errorThreshold: 1,
        deduplicateWindow: Duration(seconds: 10),
        maxTriggers: 0,
      ),
    );

    // ── Scenario 8: Form validation ──
    ToastKit.addRule(ToastRule(
      id: 'form-help',
      channel: _chForm,
      condition: (stats, event) => stats.errorCount >= 3,
      action: (_) {
        ToastKit.show(ToastEvent.info(
          message: 'Struggling with the form? Check our help guide.',
          variant: ToastVariant.action,
          deduplicationKey: 'form-help-toast',
          actions: [
            ToastAction(
              label: 'View Help',
              onPressed: () => ToastKit.success('Opening help guide…'),
            ),
          ],
          channel: _chForm,
        ));
      },
    ));

    // ── Scenario 9: Offline reconnect ──
    ToastKit.addRule(ToastRule(
      id: 'offline-reconnect',
      channel: _chOffline,
      condition: (stats, event) => stats.errorCount >= 2,
      action: (_) {
        ToastKit.show(ToastEvent.warning(
          message: 'You appear to be offline. '
              'We\'ll reconnect automatically when network is available.',
          persistent: true,
          dismissible: true,
          variant: ToastVariant.action,
          deduplicationKey: 'offline-reconnect-toast',
          actions: [
            ToastAction(
              label: 'Try Now',
              onPressed: () {
                ToastKit.dismissAll();
                ToastKit.info('Checking connection…');
              },
            ),
          ],
          channel: _chOffline,
        ));
      },
    ));

    // ── Scenario 10: Session expired ──
    ToastKit.addRule(ToastRule(
      id: 'session-force-logout',
      channel: _chSession,
      condition: (stats, event) => stats.errorCount >= 3,
      action: (_) {
        if (!mounted) return;
        setState(() => _sessionForceLogout = true);
        ToastKit.show(ToastEvent.error(
          message: 'Your session has expired. Please sign in again.',
          persistent: true,
          dismissible: false,
          deduplicationKey: 'session-expired-toast',
          channel: _chSession,
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
      _networkFailures = 0;
      _rapidClickCount = 0;
      _paymentRetries = 0;
      _paymentBlocked = false;
      _successCount = 0;
      _apiErrors = 0;
      _apiToastsShown = 0;
      _checkoutStep = 'cart';
      _formSubmits = 0;
      _isOffline = false;
      _offlineAttempts = 0;
      _sessionFailures = 0;
      _sessionForceLogout = false;
      _rulesRegistered = false;
    });

    _registerAll();
    ToastKit.success('All demos reset.', title: '✓ Reset');
  }

  // ---------------------------------------------------------------------------
  // Scenario action handlers
  // ---------------------------------------------------------------------------

  // 1) Sign-in
  Future<void> _attemptSignIn() async {
    if (_accountLocked) {
      ToastKit.warning('Account is locked. Please wait.');
      return;
    }
    setState(() => _signInAttempts++);
    final ctrl = ToastKit.showLoading('Signing in…');
    await Future.delayed(const Duration(milliseconds: 800));
    ctrl.error('Invalid email or password');
    ToastKit.error(
      'Sign-in attempt $_signInAttempts failed',
      channel: _chSignIn,
    );
  }

  // 2) Network failures
  void _simulateNetworkFailure() {
    setState(() => _networkFailures++);
    if (_networkFailures <= 2) {
      ToastKit.info(
        'Connection attempt failed ($_networkFailures)',
        channel: _chNetwork,
      );
    }
    ToastKit.error(
      'Network failure #$_networkFailures',
      channel: _chNetwork,
    );
  }

  // 3) Rapid clicks
  void _handleRapidClick() {
    setState(() => _rapidClickCount++);
    ToastKit.show(ToastEvent.info(
      message: 'Item added to cart',
      deduplicationKey: 'rapid-add-to-cart',
      channel: _chRapid,
    ));
  }

  // 4) Payment retry
  Future<void> _retryPayment() async {
    if (_paymentBlocked) {
      ToastKit.warning('Payment is blocked. Use the recovery options above.');
      return;
    }
    setState(() => _paymentRetries++);
    final ctrl = ToastKit.showLoading('Processing payment…');
    await Future.delayed(const Duration(seconds: 1));
    ctrl.error('Payment declined');
    ToastKit.error(
      'Payment attempt $_paymentRetries failed',
      channel: _chPayment,
    );
  }

  // 5) Success noise
  void _triggerSuccess() {
    setState(() => _successCount++);
    ToastKit.show(ToastEvent.success(
      message: 'File saved successfully',
      deduplicationKey: 'success-save',
      channel: _chSuccess,
    ));
  }

  // 6) API error dedup
  void _triggerApiError() {
    setState(() => _apiErrors++);
    final shown = ToastKit.show(ToastEvent.error(
      message: 'Failed to load user data',
      deduplicationKey: 'api-user-error',
      channel: _chApiDedup,
    ));
    if (shown) setState(() => _apiToastsShown++);
  }

  void _triggerBurstApiErrors() {
    for (var i = 0; i < 10; i++) {
      _triggerApiError();
    }
  }

  // 7) Checkout context
  void _advanceCheckout() {
    final steps = ['cart', 'shipping', 'payment', 'confirmation'];
    final currentIndex = steps.indexOf(_checkoutStep);
    if (currentIndex < steps.length - 1) {
      final next = steps[currentIndex + 1];
      setState(() => _checkoutStep = next);

      final messages = {
        'shipping': 'Please verify your shipping address.',
        'payment': 'Enter your payment details to complete the order.',
        'confirmation': 'Order placed! Your confirmation number is #38291.',
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

  // 8) Form validation
  void _submitBadForm() {
    setState(() => _formSubmits++);
    final errors = [
      'Email is required',
      'Password must be at least 8 characters',
      'Name cannot be empty',
    ];
    for (final err in errors) {
      ToastKit.warning(err, channel: _chForm);
    }
    ToastKit.error('Form validation failed', channel: _chForm);
  }

  // 9) Offline mode
  void _toggleOffline() {
    setState(() {
      _isOffline = !_isOffline;
      _offlineAttempts = 0;
    });
    if (_isOffline) {
      ToastKit.warning('You are now offline.', channel: _chOffline);
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
      channel: _chOffline,
    );
  }

  // 10) Session expired
  void _triggerSessionError() {
    if (_sessionForceLogout) {
      ToastKit.warning('Session expired. Please sign in again.');
      return;
    }
    setState(() => _sessionFailures++);
    ToastKit.error(
      '401 Unauthorized — session failure #$_sessionFailures',
      channel: _chSession,
    );
  }

  void _resetSession() {
    setState(() {
      _sessionFailures = 0;
      _sessionForceLogout = false;
    });
    ToastKit.dismissAll();
    ToastKit.success('Session restored.');
  }

  // ---------------------------------------------------------------------------
  // Helpers
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
                  'Real-World Rule Scenarios',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Each scenario demonstrates how ToastKit rules solve '
                  'real problems. Tap buttons to simulate the behavior.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),

                // Scenario 1
                _buildSignInScenario(),
                const SizedBox(height: 12),

                // Scenario 2
                _buildNetworkEscalationScenario(),
                const SizedBox(height: 12),

                // Scenario 3
                _buildRapidClickScenario(),
                const SizedBox(height: 12),

                // Scenario 4
                _buildPaymentRetryScenario(),
                const SizedBox(height: 12),

                // Scenario 5
                _buildSuccessNoiseScenario(),
                const SizedBox(height: 12),

                // Scenario 6
                _buildApiDedupScenario(),
                const SizedBox(height: 12),

                // Scenario 7
                _buildCheckoutScenario(),
                const SizedBox(height: 12),

                // Scenario 8
                _buildFormValidationScenario(),
                const SizedBox(height: 12),

                // Scenario 9
                _buildOfflineScenario(),
                const SizedBox(height: 12),

                // Scenario 10
                _buildSessionExpiredScenario(),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  // ===========================================================================
  // Scenario Builders
  // ===========================================================================

  // ── 1. Failed Sign-In ──
  Widget _buildSignInScenario() {
    return RuleScenarioCard(
      title: '5 Wrong Sign-In Attempts → Forgot Password',
      icon: Icons.lock_outline,
      iconColor: Colors.red,
      explanation:
          'Simulates a login form where every attempt fails. After 3 failures, '
          'a "Forgot Password?" suggestion appears. After 5, the account locks.',
      whyItMatters:
          'Prevents brute-force attacks while guiding legitimate users to '
          'password recovery — a pattern used by every major auth system.',
      codeTitle: 'Sign-In Lockout Rules',
      codeDescription:
          'Two custom rules: one suggests password reset at 3 failures, '
          'another locks the account at 5.',
      code: _signInCode,
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

  // ── 2. Network Escalation ──
  Widget _buildNetworkEscalationScenario() {
    return RuleScenarioCard(
      title: 'Network Failures → Escalating Severity',
      icon: Icons.wifi_off,
      iconColor: Colors.orange,
      explanation:
          'Repeated network failures escalate from info toasts (1-2) to '
          'warning (3-4) to a persistent error with retry action (5+).',
      whyItMatters:
          'Users see proportionate feedback. A single blip is informational; '
          'sustained outages demand attention and offer recovery actions.',
      codeTitle: 'Network Escalation Rules',
      codeDescription:
          'Two rules on the network channel escalate severity as errors accumulate.',
      code: _networkEscalationCode,
      trailing: _statusChip(
        '$_networkFailures failures',
        _networkFailures >= 5
            ? Colors.red
            : _networkFailures >= 3
                ? Colors.orange
                : Colors.blue,
      ),
      resultWidget: Column(
        children: [
          _progressBar(_networkFailures / 5, Colors.orange),
          const SizedBox(height: 6),
          _stateIndicator(
            label: 'Severity',
            value: _networkFailures >= 5
                ? 'Error (persistent)'
                : _networkFailures >= 3
                    ? 'Warning'
                    : 'Info',
            icon: _networkFailures >= 5
                ? Icons.error
                : _networkFailures >= 3
                    ? Icons.warning
                    : Icons.info,
            color: _networkFailures >= 5
                ? Colors.red
                : _networkFailures >= 3
                    ? Colors.orange
                    : Colors.blue,
          ),
        ],
      ),
      children: [
        DemoButton(
          label: 'Simulate Network Failure',
          icon: Icons.cloud_off,
          color: Colors.orange,
          onPressed: _simulateNetworkFailure,
        ),
      ],
    );
  }

  // ── 3. Rapid Clicks / Dedup ──
  Widget _buildRapidClickScenario() {
    return RuleScenarioCard(
      title: 'Rapid Clicks → Deduplicate Toasts',
      icon: Icons.touch_app,
      iconColor: Colors.indigo,
      explanation:
          'Clicking "Add to Cart" rapidly sends 1 toast per deduplication '
          'window (3s) instead of flooding the screen with duplicates.',
      whyItMatters:
          'Users mashing buttons shouldn\'t see 20 identical toasts. '
          'Deduplication keeps the UI clean and responsive.',
      codeTitle: 'Deduplication Rule Config',
      codeDescription:
          'A config-based rule with a 3-second dedup window suppresses '
          'repeated identical toasts.',
      code: _rapidClickCode,
      trailing: _statusChip('$_rapidClickCount taps', Colors.indigo),
      resultWidget: _stateIndicator(
        label: 'Button taps (all)',
        value: '$_rapidClickCount',
        icon: Icons.ads_click,
        color: Colors.indigo,
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

  // ── 4. Payment Failure ──
  Widget _buildPaymentRetryScenario() {
    return RuleScenarioCard(
      title: 'Payment Failure After Retries → Blocking Dialog',
      icon: Icons.payment,
      iconColor: Colors.deepOrange,
      explanation:
          'Simulates payment processing that fails. After 3 consecutive '
          'failures, a persistent action toast blocks further attempts and '
          'offers recovery options.',
      whyItMatters:
          'Repeated payment failures frustrate users. Smart escalation '
          'prevents charging a broken card and offers concrete next steps.',
      codeTitle: 'Payment Failure Escalation',
      codeDescription:
          'A custom rule triggers after 3 payment errors and presents '
          'recovery actions.',
      code: _paymentRetryCode,
      trailing: _statusChip(
        _paymentBlocked ? '⛔ Blocked' : '$_paymentRetries / 3',
        _paymentBlocked ? Colors.red : Colors.deepOrange,
      ),
      resultWidget: Column(
        children: [
          _progressBar(_paymentRetries / 3, Colors.deepOrange),
          const SizedBox(height: 6),
          _stateIndicator(
            label: 'Payment attempts',
            value: '$_paymentRetries',
            icon: Icons.credit_card,
            color: _paymentRetries >= 3 ? Colors.red : Colors.deepOrange,
          ),
        ],
      ),
      children: [
        DemoButton(
          label: _paymentBlocked ? 'Payments Blocked' : 'Process Payment',
          icon: Icons.payment,
          color: Colors.deepOrange,
          onPressed: _paymentBlocked ? null : _retryPayment,
        ),
      ],
    );
  }

  // ── 5. Success Noise Reduction ──
  Widget _buildSuccessNoiseScenario() {
    return RuleScenarioCard(
      title: 'Repeated Success → Reduce Noise with Cooldown',
      icon: Icons.check_circle_outline,
      iconColor: Colors.green,
      explanation:
          'Auto-saving a file triggers a success toast, but repeated saves '
          'within a 5-second window are suppressed to avoid visual noise.',
      whyItMatters:
          'Success messages that fire constantly (e.g., auto-save) become '
          'annoying distractions. Cooldown keeps them helpful, not noisy.',
      codeTitle: 'Success Cooldown Config',
      codeDescription:
          'A config rule with 5-second dedup window and maxTriggers: 2 '
          'limits how often success toasts appear.',
      code: _successNoiseCode,
      trailing: _statusChip('$_successCount saves', Colors.green),
      resultWidget: _stateIndicator(
        label: 'Save triggers',
        value: '$_successCount',
        icon: Icons.save,
        color: Colors.green,
      ),
      children: [
        DemoButton(
          label: 'Save File (tap repeatedly)',
          icon: Icons.save,
          color: Colors.green,
          onPressed: _triggerSuccess,
        ),
      ],
    );
  }

  // ── 6. API Error Dedup Window ──
  Widget _buildApiDedupScenario() {
    return RuleScenarioCard(
      title: 'Repeated API Errors → Show Once in Dedup Window',
      icon: Icons.api,
      iconColor: Colors.blue,
      explanation:
          'When multiple API calls fail with the same error, only the first '
          'toast is shown within a 10-second dedup window. Try the burst!',
      whyItMatters:
          'A page loading 10 resources that all fail shouldn\'t show 10 '
          'identical error toasts. Dedup shows 1 and silences the rest.',
      codeTitle: 'API Error Deduplication',
      codeDescription:
          'Uses a deduplication key + 10-second window to collapse '
          'identical API errors into a single toast.',
      code: _apiDedupCode,
      trailing: _statusChip(
        '$_apiToastsShown shown / $_apiErrors errors',
        Colors.blue,
      ),
      resultWidget: Column(
        children: [
          _stateIndicator(
            label: 'Errors triggered',
            value: '$_apiErrors',
            icon: Icons.error_outline,
            color: Colors.red,
          ),
          _stateIndicator(
            label: 'Toasts actually shown',
            value: '$_apiToastsShown',
            icon: Icons.visibility,
            color: Colors.blue,
          ),
        ],
      ),
      children: [
        DemoButton(
          label: 'Trigger 1 API Error',
          icon: Icons.cloud_off,
          color: Colors.blue,
          onPressed: _triggerApiError,
        ),
        DemoButton(
          label: 'Burst: 10 Errors at Once',
          icon: Icons.bolt,
          color: Colors.blue.shade700,
          onPressed: _triggerBurstApiErrors,
        ),
      ],
    );
  }

  // ── 7. Checkout Flow ──
  Widget _buildCheckoutScenario() {
    return RuleScenarioCard(
      title: 'Checkout Flow → Context-Aware Messages',
      icon: Icons.shopping_cart,
      iconColor: Colors.teal,
      explanation:
          'Different checkout steps show different toast types: info for '
          'shipping, warning for payment, and success for confirmation.',
      whyItMatters:
          'Users need contextual feedback at each step. A generic "Something '
          'went wrong" is useless compared to step-specific guidance.',
      codeTitle: 'Context-Based Toast Logic',
      codeDescription:
          'Switch on checkout step to select the appropriate toast type and message.',
      code: _checkoutCode,
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

  // ── 8. Form Validation ──
  Widget _buildFormValidationScenario() {
    return RuleScenarioCard(
      title: 'Form Validation Failures → Inline Guidance',
      icon: Icons.assignment,
      iconColor: Colors.amber.shade800,
      explanation:
          'Submitting an invalid form shows per-field warning toasts. '
          'After 3 failed submissions, a help guide suggestion appears.',
      whyItMatters:
          'Repeated form errors mean the user is stuck. A smart rule '
          'offers help proactively instead of showing the same errors.',
      codeTitle: 'Form Validation + Help Rule',
      codeDescription:
          'A custom rule on the form channel triggers a help toast '
          'after 3 validation error submissions.',
      code: _formValidationCode,
      trailing: _statusChip('$_formSubmits submits', Colors.amber.shade800),
      resultWidget: _stateIndicator(
        label: 'Failed submissions',
        value: '$_formSubmits',
        icon: Icons.error_outline,
        color: _formSubmits >= 3 ? Colors.red : Colors.amber.shade800,
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

  // ── 9. Offline Mode ──
  Widget _buildOfflineScenario() {
    return RuleScenarioCard(
      title: 'Offline Mode → Smart Reconnect Message',
      icon: Icons.signal_wifi_off,
      iconColor: Colors.blueGrey,
      explanation:
          'Toggle offline mode, then try to make requests. After 2 failures, '
          'a persistent reconnect banner appears with a "Try Now" action.',
      whyItMatters:
          'Offline users need a clear, non-intrusive indication with an '
          'easy retry mechanism — not a pile of error toasts.',
      codeTitle: 'Offline Detection Rule',
      codeDescription:
          'A custom rule detects 2+ errors on the offline channel and '
          'shows a persistent reconnect banner.',
      code: _offlineCode,
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

  // ── 10. Session Expired ──
  Widget _buildSessionExpiredScenario() {
    return RuleScenarioCard(
      title: 'Session Expired → Force Re-Login',
      icon: Icons.timer_off,
      iconColor: Colors.purple,
      explanation:
          'Simulates 401 Unauthorized responses. After 3 session errors, '
          'a persistent toast forces re-authentication.',
      whyItMatters:
          'Instead of silently failing, the app proactively tells users their '
          'session is expired and blocks further actions until they re-login.',
      codeTitle: 'Session Expiry Rule',
      codeDescription:
          'A custom rule detects 3 session errors and shows a persistent '
          'non-dismissible re-login toast.',
      code: _sessionCode,
      trailing: _statusChip(
        _sessionForceLogout
            ? '🔐 Re-login'
            : '$_sessionFailures / 3',
        _sessionForceLogout ? Colors.red : Colors.purple,
      ),
      resultWidget: Column(
        children: [
          _progressBar(_sessionFailures / 3, Colors.purple),
          const SizedBox(height: 6),
          _stateIndicator(
            label: 'Session errors',
            value: '$_sessionFailures',
            icon: Icons.vpn_key,
            color: _sessionFailures >= 3 ? Colors.red : Colors.purple,
          ),
          if (_sessionForceLogout)
            _stateIndicator(
              label: 'Status',
              value: 'Must re-login',
              icon: Icons.lock,
              color: Colors.red,
            ),
        ],
      ),
      children: [
        DemoButton(
          label: _sessionForceLogout
              ? 'Session Expired'
              : 'Simulate 401 Error',
          icon: Icons.error_outline,
          color: Colors.purple,
          onPressed: _sessionForceLogout ? null : _triggerSessionError,
        ),
        if (_sessionForceLogout)
          DemoButton(
            label: 'Sign In Again',
            icon: Icons.login,
            color: Colors.green,
            onPressed: _resetSession,
          ),
      ],
    );
  }
}

// =============================================================================
// Code Strings — displayed in the "See Code" modal for each scenario
// =============================================================================

const _signInCode = '''// Register the sign-in channel
ToastKit.registerChannel(
  ToastChannel(id: 'auth', label: 'Authentication'),
);

// Rule 1: Suggest password reset after 3 failures
ToastKit.addRule(ToastRule(
  id: 'signin-suggest-reset',
  channel: 'auth',
  condition: (stats, event) => stats.errorCount == 3,
  action: (_) {
    ToastKit.show(ToastEvent.info(
      message: 'Having trouble? Try resetting your password.',
      variant: ToastVariant.action,
      deduplicationKey: 'signin-suggest-reset',
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

// Rule 2: Lock account after 5 failures
ToastKit.addRule(ToastRule(
  id: 'signin-lockout',
  channel: 'auth',
  condition: (stats, event) => stats.errorCount >= 5,
  action: (_) {
    setState(() => _accountLocked = true);
    ToastKit.show(ToastEvent.error(
      message: 'Account locked for 15 seconds.',
      persistent: true,
      dismissible: false,
      deduplicationKey: 'signin-lockout-toast',
      channel: 'auth',
    ));
  },
));''';

const _networkEscalationCode = '''// Escalate from warning to persistent error
ToastKit.addRule(ToastRule(
  id: 'net-escalate-warning',
  channel: 'network',
  condition: (stats, event) =>
      stats.errorCount >= 3 && stats.errorCount < 5,
  action: (_) {
    ToastKit.warning(
      'Multiple connection failures detected. Retrying…',
    );
  },
));

ToastKit.addRule(ToastRule(
  id: 'net-escalate-error',
  channel: 'network',
  condition: (stats, event) => stats.errorCount >= 5,
  action: (_) {
    ToastKit.show(ToastEvent.error(
      message: 'Persistent connectivity issues.',
      variant: ToastVariant.action,
      persistent: true,
      deduplicationKey: 'net-escalate-error-toast',
      actions: [
        ToastAction(
          label: 'Retry Now',
          onPressed: () {
            ToastKit.dismissAll();
            ToastKit.info('Retrying…');
          },
        ),
      ],
    ));
  },
));''';

const _rapidClickCode = '''// Config-based deduplication rule:
// Identical toasts within a 3-second window are suppressed.
ToastKit.configureRule(
  'cart',
  const RuleConfig(
    errorThreshold: 1,
    deduplicateWindow: Duration(seconds: 3),
    maxTriggers: 0, // unlimited
  ),
);

// When the button is tapped, use a deduplication key:
ToastKit.show(ToastEvent.info(
  message: 'Item added to cart',
  deduplicationKey: 'rapid-add-to-cart',
  channel: 'cart',
));''';

const _paymentRetryCode = '''// Block further payments after 3 consecutive failures
ToastKit.addRule(ToastRule(
  id: 'payment-block',
  channel: 'payment',
  condition: (stats, event) => stats.errorCount >= 3,
  action: (_) {
    setState(() => _paymentBlocked = true);
    ToastKit.show(ToastEvent.error(
      message: 'Payment failed after multiple attempts. '
          'Please verify your card or try another method.',
      persistent: true,
      variant: ToastVariant.action,
      deduplicationKey: 'payment-block-toast',
      actions: [
        ToastAction(
          label: 'Try Another Card',
          onPressed: () { /* switch payment method */ },
        ),
        ToastAction(
          label: 'Contact Support',
          onPressed: () { /* open support */ },
        ),
      ],
      channel: 'payment',
    ));
  },
));''';

const _successNoiseCode = '''// Limit success toasts to reduce noise.
// maxTriggers: 2 — only fire the rule twice total.
// deduplicateWindow: 5 seconds — suppress duplicates.
ToastKit.configureRule(
  'file-ops',
  const RuleConfig(
    errorThreshold: 1,
    deduplicateWindow: Duration(seconds: 5),
    maxTriggers: 2,
  ),
);

// When auto-saving, use a deduplication key:
ToastKit.show(ToastEvent.success(
  message: 'File saved successfully',
  deduplicationKey: 'success-save',
  channel: 'file-ops',
));''';

const _apiDedupCode = '''// Dedup window: same error shown once per 10 seconds
ToastKit.configureRule(
  'api',
  const RuleConfig(
    errorThreshold: 1,
    deduplicateWindow: Duration(seconds: 10),
    maxTriggers: 0, // unlimited
  ),
);

// Every API call uses the same deduplication key:
ToastKit.show(ToastEvent.error(
  message: 'Failed to load user data',
  deduplicationKey: 'api-user-error',
  channel: 'api',
));

// Even if 10 calls fail simultaneously,
// only 1 toast is shown within the 10s window.''';

const _checkoutCode = '''// Context-aware messages per checkout step:
void _advanceCheckout(String step) {
  final messages = {
    'shipping': 'Please verify your shipping address.',
    'payment': 'Enter your payment details.',
    'confirmation': 'Order placed! Confirmation #38291.',
  };

  final types = {
    'shipping': ToastType.info,
    'payment': ToastType.warning,
    'confirmation': ToastType.success,
  };

  ToastKit.show(ToastEvent(
    type: types[step] ?? ToastType.info,
    message: messages[step] ?? '',
    channel: 'checkout',
  ));
}''';

const _formValidationCode = '''// Show per-field warnings + proactive help
ToastKit.addRule(ToastRule(
  id: 'form-help',
  channel: 'form',
  condition: (stats, event) => stats.errorCount >= 3,
  action: (_) {
    ToastKit.show(ToastEvent.info(
      message: 'Struggling with the form? Check our help guide.',
      variant: ToastVariant.action,
      deduplicationKey: 'form-help-toast',
      actions: [
        ToastAction(
          label: 'View Help',
          onPressed: () => ToastKit.success('Opening help…'),
        ),
      ],
      channel: 'form',
    ));
  },
));

// On submit, show each validation error:
for (final error in errors) {
  ToastKit.warning(error, channel: 'form');
}''';

const _offlineCode = '''// Detect offline state after 2+ failed requests
ToastKit.addRule(ToastRule(
  id: 'offline-reconnect',
  channel: 'connectivity',
  condition: (stats, event) => stats.errorCount >= 2,
  action: (_) {
    ToastKit.show(ToastEvent.warning(
      message: 'You appear to be offline. '
          'We\\'ll reconnect automatically.',
      persistent: true,
      dismissible: true,
      variant: ToastVariant.action,
      deduplicationKey: 'offline-reconnect-toast',
      actions: [
        ToastAction(
          label: 'Try Now',
          onPressed: () {
            ToastKit.dismissAll();
            ToastKit.info('Checking connection…');
          },
        ),
      ],
      channel: 'connectivity',
    ));
  },
));''';

const _sessionCode = '''// Force re-login after 3 unauthorized errors
ToastKit.addRule(ToastRule(
  id: 'session-force-logout',
  channel: 'session',
  condition: (stats, event) => stats.errorCount >= 3,
  action: (_) {
    setState(() => _sessionForceLogout = true);
    ToastKit.show(ToastEvent.error(
      message: 'Your session has expired. '
          'Please sign in again.',
      persistent: true,
      dismissible: false,
      deduplicationKey: 'session-expired-toast',
      channel: 'session',
    ));
  },
));''';
