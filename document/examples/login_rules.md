# Example: Login with Rules

A realistic authentication flow that uses channels, rules, and stateful loading toasts.

## What This Example Demonstrates

- Channel-based error tracking (`auth` channel)
- Config-based rule for threshold warnings
- Custom rule for password reset suggestion after 3 failures
- Custom rule for account lockout after 5 failures
- Stateful loading toast (`showLoading` → `ctrl.error()`)
- Concurrency guard to prevent rapid-tap issues

---

## Setup: Register Channel and Rules

```dart
import 'package:toast_kit/toast_kit.dart';

void setupAuthRules() {
  // Register the auth channel (maxVisible: 1, priority: high)
  ToastKit.registerChannel(ToastChannel.auth);

  // Config-based rule: warn after 3 errors, once per 60 seconds
  ToastKit.configureRule(
    'auth',
    const RuleConfig(
      errorThreshold: 3,
      deduplicateWindow: Duration(seconds: 60),
      maxTriggers: 1,
    ),
  );

  // Custom rule: suggest password reset after 3 failures
  ToastKit.addRule(ToastRule(
    id: 'suggest-reset',
    channel: 'auth',
    maxTriggers: 1,  // Only suggest once
    condition: (stats, event) =>
        stats.errorCount >= 3 && stats.errorCount < 5,
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

  // Custom rule: lockout after 5 failures
  ToastKit.addRule(ToastRule(
    id: 'login-lockout',
    channel: 'auth',
    maxTriggers: 1,  // Only lock once per session
    condition: (stats, event) => stats.errorCount >= 5,
    action: (context) {
      ToastKit.show(ToastEvent.error(
        message: 'Too many failed attempts. Account locked for 30 seconds.',
        persistent: true,
        dismissible: false,
        deduplicationKey: 'login-lockout',
        channel: 'auth',
      ));
    },
  ));
}
```

## Login Attempt with Loading Toast

```dart
class _LoginState extends State<LoginScreen> {
  bool _isSigningIn = false;
  bool _isLocked = false;
  int _attemptCount = 0;

  Future<void> _attemptLogin() async {
    // Guard: prevent concurrent calls from rapid taps
    if (_isSigningIn || _isLocked) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ToastKit.warning('Please enter email and password', channel: 'auth');
      return;
    }

    setState(() {
      _isSigningIn = true;
      _attemptCount++;
    });

    // Show loading toast on auth channel
    final ctrl = ToastKit.showLoading('Signing in…', channel: 'auth');

    try {
      await authService.login(email, password);
      ctrl.success('Welcome back!');
      setState(() => _attemptCount = 0);
    } catch (e) {
      ctrl.error('Invalid email or password');
      // Record error on auth channel — rules evaluate automatically
      ToastKit.error(
        'Login attempt $_attemptCount failed',
        channel: 'auth',
      );
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }
}
```

## What Happens at Each Attempt

| Attempt | What Fires | User Sees |
|---------|------------|-----------|
| 1 | Nothing | "Invalid email or password" error toast |
| 2 | Nothing | "Invalid email or password" error toast |
| 3 | `suggest-reset` rule | "Forgot your password?" with Reset button |
| 4 | Nothing | "Invalid email or password" error toast |
| 5 | `login-lockout` rule | "Too many failed attempts. Account locked." |

## Key Design Decisions

1. **`maxTriggers: 1`** on both custom rules prevents them from firing repeatedly
2. **`channel: 'auth'`** on the loading toast ensures proper channel capacity tracking
3. **`_isSigningIn` guard** prevents concurrent login attempts from rapid taps
4. **`setState` wraps `_attemptCount++`** so the UI updates immediately
5. **`suggest-reset` condition uses `>= 3 && < 5`** instead of `== 3` to be resilient if a count is skipped

---

[← Examples Index](index.md) | [Next: Network Retry →](network_retry.md)
