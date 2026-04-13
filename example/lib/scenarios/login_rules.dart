import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

// ---------------------------------------------------------------------------
// Login Rules Scenario
//
// Demonstrates:
// - Channel-based error tracking for authentication
// - configureRule for threshold-based lockout warnings
// - Custom ToastRule for advanced lockout logic
// - Stateful loading toasts for login flow
// ---------------------------------------------------------------------------

class LoginRulesScenario extends StatefulWidget {
  const LoginRulesScenario({super.key});

  @override
  State<LoginRulesScenario> createState() => _LoginRulesScenarioState();
}

class _LoginRulesScenarioState extends State<LoginRulesScenario> {
  final _emailController = TextEditingController(text: 'user@example.com');
  final _passwordController = TextEditingController();
  int _attemptCount = 0;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _setupAuthRules();
  }

  void _setupAuthRules() {
    // Register the auth channel.
    ToastKit.registerChannel(ToastChannel.auth);

    // Config-based rule: warn after 3 errors, once per 60 seconds.
    ToastKit.configureRule(
      'auth',
      const RuleConfig(
        errorThreshold: 3,
        deduplicateWindow: Duration(seconds: 60),
        maxTriggers: 1,
      ),
    );

    // Custom rule: lockout after 5 consecutive failures.
    ToastKit.addRule(ToastRule(
      id: 'login-lockout',
      channel: 'auth',
      condition: (stats, event) => stats.errorCount >= 5,
      action: (context) {
        setState(() => _isLocked = true);

        ToastKit.show(ToastEvent.error(
          message: 'Too many failed attempts. Account locked for 30 seconds.',
          persistent: true,
          dismissible: false,
          deduplicationKey: 'login-lockout',
          channel: 'auth',
        ));

        // Auto-unlock after 30 seconds.
        Future.delayed(const Duration(seconds: 30), () {
          if (mounted) {
            setState(() => _isLocked = false);
            ToastKit.dismissAll();
            ToastKit.info('Account unlocked. You may try again.');
          }
        });
      },
    ));

    // Custom rule: suggest password reset after 3 failures.
    ToastKit.addRule(ToastRule(
      id: 'suggest-reset',
      channel: 'auth',
      condition: (stats, event) => stats.errorCount == 3,
      action: (context) {
        ToastKit.show(ToastEvent.info(
          message: 'Forgot your password?',
          variant: ToastVariant.action,
          deduplicationKey: 'suggest-reset',
          actions: [
            ToastAction(
              label: 'Reset Password',
              onPressed: () {
                ToastKit.success('Password reset email sent!');
              },
            ),
          ],
          channel: 'auth',
        ));
      },
    ));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Simulate a login attempt. All attempts fail for demonstration.
  Future<void> _attemptLogin() async {
    if (_isLocked) {
      ToastKit.warning('Account is temporarily locked');
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ToastKit.warning('Please enter email and password', channel: 'auth');
      return;
    }

    _attemptCount++;

    final ctrl = ToastKit.showLoading('Signing in…');
    try {
      // Simulate network delay.
      await Future.delayed(const Duration(seconds: 1));

      // Simulate authentication failure (wrong password).
      if (password != 'correct-password') {
        throw Exception('Invalid credentials');
      }

      ctrl.success('Welcome back!');
      setState(() => _attemptCount = 0);
    } catch (e) {
      ctrl.error('Invalid email or password');
      // Record the error on the auth channel — rules evaluate automatically.
      ToastKit.error(
        'Login attempt $_attemptCount failed',
        channel: 'auth',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Rules')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Try logging in with any password (all will fail). '
            'After 3 attempts you\'ll see a password reset suggestion. '
            'After 5, the account locks for 30 seconds.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Attempts: $_attemptCount${_isLocked ? '  🔒 LOCKED' : ''}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _isLocked ? Colors.red : null,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            enabled: !_isLocked,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
              hintText: 'Try any password',
            ),
            obscureText: true,
            enabled: !_isLocked,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isLocked ? null : _attemptLogin,
            child: Text(_isLocked ? 'Account Locked' : 'Sign In'),
          ),
        ],
      ),
    );
  }
}
