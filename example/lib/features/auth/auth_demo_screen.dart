import 'dart:async';

import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

import '../../services/api_service.dart';
import '../../widgets/buttons/demo_button.dart';
import '../../widgets/cards/feature_card.dart';
import '../../widgets/see_code_button.dart';

/// Demonstrates login success/failure toasts, retry logic, and rate limiting.
class AuthDemoScreen extends StatefulWidget {
  const AuthDemoScreen({super.key});

  @override
  State<AuthDemoScreen> createState() => _AuthDemoScreenState();
}

class _AuthDemoScreenState extends State<AuthDemoScreen> {
  final _emailController = TextEditingController(text: 'user@example.com');
  final _passwordController = TextEditingController(text: 'password123');

  int _failedAttempts = 0;
  bool _isSigningIn = false;
  bool _isLoggingOut = false;
  bool _isLocked = false;
  int _lockCountdown = 0;
  Timer? _lockTimer;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _lockTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool get _loginDisabled => _isSigningIn || _isLocked;

  void _startLockout() {
    setState(() {
      _isLocked = true;
      _lockCountdown = 30;
    });

    ToastKit.warning(
      'Account locked for 30 seconds',
      channel: 'auth',
    );

    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _lockCountdown--);
      if (_lockCountdown <= 0) {
        timer.cancel();
        setState(() {
          _isLocked = false;
          _failedAttempts = 0;
        });
        ToastKit.info('You may try again', channel: 'auth');
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _attemptLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ToastKit.warning(
        'Please enter email and password',
        channel: 'auth',
      );
      return;
    }

    setState(() => _isSigningIn = true);

    final ctrl = ToastKit.showLoading('Signing in…', channel: 'auth');

    try {
      await ApiService.instance.login(email, password);

      ctrl.success('Welcome back!');
      setState(() => _failedAttempts = 0);
    } on ApiException catch (e) {
      ctrl.error(e.message);
      _handleFailedAttempt();
    } catch (_) {
      ctrl.error('An unexpected error occurred');
      _handleFailedAttempt();
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  void _handleFailedAttempt() {
    if (!mounted) return;

    setState(() => _failedAttempts++);

    if (_failedAttempts >= 5) {
      _startLockout();
    } else if (_failedAttempts >= 3) {
      ToastKit.warning(
        'Too many attempts ($_failedAttempts/5)',
        channel: 'auth',
      );
    }
  }

  void _forgotPassword() {
    final email = _emailController.text.trim();
    final target = email.isEmpty ? 'your email' : email;
    ToastKit.info(
      'Password reset link sent to $target',
      channel: 'auth',
    );
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);

    final ctrl = ToastKit.showLoading('Signing out…', channel: 'auth');

    try {
      await ApiService.instance.logout();
      ctrl.success('Signed out successfully');
    } on ApiException catch (e) {
      ctrl.error(e.message);
    } catch (_) {
      ctrl.error('Logout failed');
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  void _resetAttempts() {
    _lockTimer?.cancel();
    setState(() {
      _failedAttempts = 0;
      _isLocked = false;
      _lockCountdown = 0;
    });
    ToastKit.info('Attempt counter reset', channel: 'auth');
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Auth System Demo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusCard(theme),
          const SizedBox(height: 12),
          _buildLoginCard(),
          const SizedBox(height: 12),
          _buildActionsCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    final Color statusColor;
    final String statusText;
    final IconData statusIcon;

    if (_isLocked) {
      statusColor = Colors.red;
      statusText = 'Locked — $_lockCountdown s remaining';
      statusIcon = Icons.lock;
    } else if (_failedAttempts >= 3) {
      statusColor = Colors.orange;
      statusText = '$_failedAttempts failed attempt${_failedAttempts == 1 ? '' : 's'} — close to lockout';
      statusIcon = Icons.warning_amber_rounded;
    } else if (_failedAttempts > 0) {
      statusColor = Colors.amber;
      statusText = '$_failedAttempts failed attempt${_failedAttempts == 1 ? '' : 's'}';
      statusIcon = Icons.info_outline;
    } else {
      statusColor = Colors.green;
      statusText = 'Ready to sign in';
      statusIcon = Icons.check_circle_outline;
    }

    return FeatureCard(
      title: 'Status',
      subtitle: 'Login attempt tracking',
      icon: statusIcon,
      iconColor: statusColor,
      trailing: SeeCodeButton(
        title: 'Auth Status Tracking',
        description: 'Tracks failed login attempts and triggers lockout after 5 failures.',
        code: _authStatusCode,
      ),
      children: [
        Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                statusText,
                style: theme.textTheme.bodyMedium?.copyWith(color: statusColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildAttemptIndicator(theme),
        if (_failedAttempts > 0) ...[
          const SizedBox(height: 12),
          DemoButton(
            label: 'Reset Attempts',
            icon: Icons.restart_alt,
            onPressed: _resetAttempts,
            color: Colors.grey,
          ),
        ],
      ],
    );
  }

  Widget _buildAttemptIndicator(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Attempts',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              '$_failedAttempts / 5',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _failedAttempts / 5,
            minHeight: 6,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: _failedAttempts >= 5
                ? Colors.red
                : _failedAttempts >= 3
                    ? Colors.orange
                    : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return FeatureCard(
      title: 'Sign In',
      subtitle: 'Email & password login with toast feedback',
      icon: Icons.login,
      iconColor: Colors.blue,
      trailing: SeeCodeButton(
        title: 'Login with Toast Feedback',
        description: 'Shows loading → success/error toasts during sign-in.',
        code: _authLoginCode,
      ),
      children: [
        TextField(
          controller: _emailController,
          enabled: !_loginDisabled,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          enabled: !_loginDisabled,
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock_outline),
            border: OutlineInputBorder(),
          ),
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!_loginDisabled) _attemptLogin();
          },
        ),
        const SizedBox(height: 16),
        DemoButton(
          label: _isLocked
              ? 'Locked ($_lockCountdown s)'
              : 'Sign In',
          icon: _isLocked ? Icons.lock : Icons.login,
          onPressed: _loginDisabled ? null : _attemptLogin,
          loading: _isSigningIn,
          color: _isLocked ? Colors.red : Colors.blue,
        ),
        const SizedBox(height: 8),
        DemoButton(
          label: 'Forgot Password?',
          icon: Icons.help_outline,
          onPressed: _isLocked ? null : _forgotPassword,
          color: Colors.grey,
        ),
      ],
    );
  }

  Widget _buildActionsCard() {
    return FeatureCard(
      title: 'Session',
      subtitle: 'Account session management',
      icon: Icons.manage_accounts,
      iconColor: Colors.deepPurple,
      trailing: SeeCodeButton(
        title: 'Session Management',
        description: 'Logout with loading toast and error handling.',
        code: _authLogoutCode,
      ),
      children: [
        DemoButton(
          label: 'Logout',
          icon: Icons.logout,
          onPressed: _isLoggingOut ? null : _logout,
          loading: _isLoggingOut,
          color: Colors.deepPurple,
        ),
      ],
    );
  }
}

// =============================================================================
// Code Strings for "See Code" modals
// =============================================================================

const _authStatusCode = '''// Track failed login attempts
int _failedAttempts = 0;

void _handleFailedAttempt() {
  _failedAttempts++;
  if (_failedAttempts >= 5) {
    _startLockout(); // Lock for 30 seconds
  } else if (_failedAttempts >= 3) {
    ToastKit.warning(
      'Too many attempts (\$_failedAttempts/5)',
      channel: 'auth',
    );
  }
}''';

const _authLoginCode = '''// Login with loading toast
final ctrl = ToastKit.showLoading('Signing in…', channel: 'auth');

try {
  await ApiService.instance.login(email, password);
  ctrl.success('Welcome back!');
} on ApiException catch (e) {
  ctrl.error(e.message);
  _handleFailedAttempt();
}''';

const _authLogoutCode = '''// Logout with loading toast
final ctrl = ToastKit.showLoading('Signing out…', channel: 'auth');

try {
  await ApiService.instance.logout();
  ctrl.success('Signed out successfully');
} on ApiException catch (e) {
  ctrl.error(e.message);
}''';
