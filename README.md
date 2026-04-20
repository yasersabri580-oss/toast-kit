# 🍞 ToastKit

[![Dart](https://img.shields.io/badge/Dart-3.0+-blue)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**A smart, rule-driven toast and notification system for Flutter.**

ToastKit goes beyond simple toasts — it provides a **headless + UI hybrid notification engine** with rule-based triggering, a plugin architecture, queue management, and 12+ ready-made toast variants. No `BuildContext` required.



## ✨ Features

- **No BuildContext required** — show toasts from anywhere (services, blocs, repositories)
- **Extensible custom variants** — define once, reuse everywhere with `CustomToastVariantBuilder`
- **Per-channel variant assignment** — assign different custom variants to different channels
- **Rule-based triggering** — deduplicate, set error thresholds, limit max triggers per channel
- **Plugin architecture** — hook into lifecycle events for logging, analytics, haptics, and more
- **12+ built-in variants** — Minimal, Material, iOS, Glassmorphism, Gradient, Compact, and more
- **Custom UI builders** — full control over toast rendering with your own widgets
- **Queue management** — FIFO, LIFO, priority modes with max-visible limits
- **Channel system** — group toasts by category (auth, network, payment) with per-channel policies
- **Stateful toasts** — loading → success/error transitions with `ToastController`
- **12 animation types** — fade, slide, scale, bounce, elastic, spring, shake, blur, glow
- **Gesture support** — swipe dismiss, tap, hover pause, drag
- **Persistence** — save and restore critical toasts across app restarts
- **Accessibility** — semantics, screen reader support, keyboard avoidance

---

## 📦 Installation

Add ToastKit to your `pubspec.yaml`:

```yaml
dependencies:
  toast_kit:
    git:
      url: https://github.com/yasersabri580-oss/toast-kit.git
```

Then run:

```bash
flutter pub get
```

---

## 🚀 Quick Start

### 1. Initialize

```dart
import 'package:toast_kit/toast_kit.dart';

final navigatorKey = GlobalKey<NavigatorState>();

MaterialApp(
  navigatorKey: navigatorKey,
  home: const MyApp(),
);

// Initialize once after the first frame
WidgetsBinding.instance.addPostFrameCallback((_) {
  ToastKit.init(navigatorKey: navigatorKey);
});
```

### 2. Show Toasts — Anywhere

```dart
ToastKit.success('File saved successfully!');
ToastKit.error('Connection lost');
ToastKit.warning('Battery below 20%');
ToastKit.info('New version available');
```

### 3. Stateful Loading → Result

```dart
final ctrl = ToastKit.showLoading('Uploading file…');
try {
  await uploadFile();
  ctrl.success('Upload complete!');
} catch (e) {
  ctrl.error('Upload failed');
}
```

---

## 📖 Core Concepts

### Toasts

A **toast** is a `ToastEvent` — the fundamental unit in ToastKit. Every toast has a type (success, error, warning, info, loading, custom), optional message, icon, position, animation, priority, and more.

```dart
// Using convenience factories
ToastKit.show(ToastEvent.success(message: 'Done!'));
ToastKit.show(ToastEvent.error(message: 'Oops', variant: ToastVariant.gradient));

// Using the full constructor for complete control
ToastKit.show(ToastEvent(
  type: ToastType.info,
  message: 'Custom event',
  position: ToastPosition.bottom,
  animation: ToastAnimationType.slideFromBottom,
  priority: ToastPriority.high,
  deduplicationKey: 'unique-info',
));
```

### Rules

**Rules** let you define smart behavior based on toast activity — error thresholds, deduplication windows, trigger limits, and windowed rate detection per channel.

#### Config-Based Rules (Simple)

```dart
// Trigger after 5 errors on the "payment" channel,
// with a 30-second deduplication window and a maximum of 1 trigger.
ToastKit.configureRule(
  'payment',
  RuleConfig(
    errorThreshold: 5,           // Fire when errorCount >= 5
    deduplicateWindow: Duration(seconds: 30),  // Cooldown between triggers
    maxTriggers: 1,              // Fire at most once
  ),
);
```

#### Custom Rules (Full Control)

```dart
// Suggest password reset after 3 login failures (fire once)
ToastKit.addRule(ToastRule(
  id: 'suggest-reset',
  channel: 'auth',
  maxTriggers: 1,
  condition: (stats, event) => stats.errorCount >= 3,
  action: (context) {
    ToastKit.show(ToastEvent.info(
      message: 'Forgot your password?',
      variant: ToastVariant.action,
      actions: [
        ToastAction(
          label: 'Reset Password',
          onPressed: () => ToastKit.success('Reset email sent!'),
        ),
      ],
      channel: 'auth',
    ));
  },
));
```

#### Windowed Rate Detection

```dart
// Detect error bursts: 5+ errors within 30 seconds
ToastKit.addRule(ToastRule(
  id: 'error-burst',
  channel: 'network',
  deduplicateWindow: Duration(seconds: 60),
  condition: (stats, event) {
    return stats.errorsInWindow(const Duration(seconds: 30)) >= 5;
  },
  action: (context) {
    ToastKit.warning('Unstable connection detected');
  },
));
```

#### Combined Stat Conditions

```dart
// Fire only when BOTH errors AND warnings are high
ToastKit.addRule(ToastRule(
  id: 'sync-degraded',
  channel: 'sync',
  maxTriggers: 1,
  condition: (stats, event) =>
      stats.errorCount >= 2 &&
      stats.warningCount >= 2 &&
      stats.totalCount >= 6,
  action: (context) {
    ToastKit.info(
      'Sync degraded: ${context.stats.errorCount} errors, '
      '${context.stats.warningCount} warnings',
    );
  },
));
```

#### Dynamic Rule Management

```dart
// Add, remove, and re-register rules at runtime
ToastKit.addRule(ToastRule(id: 'guard', channel: 'session', ...));

// Remove when no longer needed (e.g., after re-authentication)
ToastKit.removeRule('guard');

// Reset stats but keep rules
ToastKit.ruleEngine.resetStats();

// Clear everything (rules + stats + trigger counts)
ToastKit.ruleEngine.clear();
```

### Plugins

**Plugins** observe the toast lifecycle without blocking the core pipeline. Plugin errors are always caught — they never crash ToastKit.

```dart
class LoggerPlugin extends ToastPlugin {
  @override
  String get name => 'logger';

  @override
  void onToastShown(ToastEvent event) {
    print('[TOAST] Shown: ${event.type.name} — ${event.message}');
  }

  @override
  void onToastDismissed(ToastEvent event, DismissReason? reason) {
    print('[TOAST] Dismissed: ${event.id} (${reason?.name ?? "auto"})');
  }
}

// Register at init or later
ToastKit.init(navigatorKey: key, plugins: [LoggerPlugin()]);
// or
ToastKit.registerPlugin(LoggerPlugin());
```

### Builders

**Custom builders** give you full control over toast UI. The builder receives a `BuildContext` and a `ToastController` for state management.

```dart
ToastKit.custom(builder: (context, controller) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.deepPurple,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.rocket_launch, color: Colors.white),
        const SizedBox(width: 12),
        Text(
          'Custom toast!',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: controller.dismiss,
        ),
      ],
    ),
  );
});
```

---

## 🎯 Usage

### Basic Toasts

```dart
ToastKit.success('Profile updated!');
ToastKit.error('Failed to load data');
ToastKit.warning('Disk space running low');
ToastKit.info('Syncing your data…');
```

### Toast Variants

```dart
// Minimal style
ToastKit.show(ToastEvent.success(message: 'Saved', variant: ToastVariant.minimal));

// Glassmorphism (frosted glass)
ToastKit.show(ToastEvent.info(message: 'New message', variant: ToastVariant.glassmorphism));

// Gradient background
ToastKit.show(ToastEvent.error(message: 'Error!', variant: ToastVariant.gradient));

// Compact pill
ToastKit.show(ToastEvent.success(message: 'OK', variant: ToastVariant.compact));

// Full-width banner
ToastKit.show(ToastEvent.warning(message: 'Maintenance window', variant: ToastVariant.fullWidth));

// Action buttons
ToastKit.show(ToastEvent.error(
  message: 'Send failed',
  variant: ToastVariant.action,
  actions: [
    ToastAction(label: 'Retry', onPressed: () => retrySend()),
    ToastAction(label: 'Cancel', onPressed: () {}),
  ],
));
```

### Rule Configuration

Rules are configured per **channel**. A channel is a logical grouping for toasts (e.g., `"auth"`, `"network"`, `"payment"`). Both config-based and custom rules work together on the same channel.

```dart
// Register channels
ToastKit.registerChannel(ToastChannel.auth);
ToastKit.registerChannel(ToastChannel.payment);

// Config-based rule: after 10 errors on "payment", trigger once
ToastKit.configureRule(
  'payment',
  RuleConfig(
    errorThreshold: 10,          // Fire when errorCount >= 10
    deduplicateWindow: Duration(seconds: 60),  // 60s cooldown
    maxTriggers: 1,              // Fire at most once total
  ),
);

// Custom rule on the same channel for user-facing actions
ToastKit.addRule(ToastRule(
  id: 'payment-help',
  channel: 'payment',
  maxTriggers: 1,
  condition: (stats, event) => stats.errorCount >= 5,
  action: (context) {
    ToastKit.show(ToastEvent.info(
      message: 'Need help? Contact support.',
      variant: ToastVariant.action,
      actions: [
        ToastAction(
          label: 'Contact Support',
          onPressed: () => openSupportChat(),
        ),
      ],
      channel: 'payment',
    ));
  },
));

// Send errors on that channel — rules evaluate automatically
ToastKit.error('Payment declined', channel: 'payment');
```

#### Rule Properties Reference

| Property | Default | Description |
|----------|---------|-------------|
| `RuleConfig.errorThreshold` | `5` | Fire when `errorCount >= threshold` |
| `RuleConfig.deduplicateWindow` | `30s` | Cooldown between triggers |
| `RuleConfig.maxTriggers` | `0` (unlimited) | Total trigger limit |
| `ToastRule.maxTriggers` | `0` (unlimited) | Total trigger limit |
| `ToastRule.deduplicateWindow` | `null` | Cooldown between triggers |

#### Available ToastStats Fields

| Field | Description |
|-------|-------------|
| `totalCount` | All events regardless of type |
| `errorCount` | Error events only |
| `warningCount` | Warning events only |
| `successCount` | Success events only |
| `infoCount` | Info events only |
| `dismissedCount` | Toasts dismissed by user |
| `droppedCount` | Toasts dropped (channel full, dedup) |
| `errorsInWindow(Duration)` | Errors within a sliding time window |

### Using Keys with Rules

Deduplication keys prevent the same toast from appearing multiple times:

```dart
// These two calls produce only one visible toast
ToastKit.show(ToastEvent.error(
  message: 'Network unavailable',
  deduplicationKey: 'network-error',
  channel: 'network',
));

ToastKit.show(ToastEvent.error(
  message: 'Network unavailable',
  deduplicationKey: 'network-error',
  channel: 'network',
));
```

### Plugin Implementation and Registration

```dart
class AnalyticsPlugin extends ToastPlugin {
  @override
  String get name => 'analytics';

  @override
  void onToastShown(ToastEvent event) {
    // Forward to your analytics service
    analytics.track('toast_shown', {
      'type': event.type.name,
      'message': event.message,
      'channel': event.channel,
    });
  }

  @override
  void onRuleTriggered(String ruleId, String channel) {
    analytics.track('toast_rule_triggered', {
      'rule_id': ruleId,
      'channel': channel,
    });
  }
}

// Register at init
ToastKit.init(
  navigatorKey: navigatorKey,
  plugins: [AnalyticsPlugin()],
);

// Or register later
ToastKit.registerPlugin(AnalyticsPlugin());
```

### Custom UI Builder

```dart
ToastKit.show(ToastEvent.custom(
  builder: (context, controller) {
    return Card(
      color: Colors.black87,
      child: ListTile(
        leading: const CircularProgressIndicator(color: Colors.white),
        title: ValueListenableBuilder<String>(
          valueListenable: controller.messageNotifier,
          builder: (_, msg, __) =>
              Text(msg, style: const TextStyle(color: Colors.white)),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: controller.dismiss,
        ),
      ),
    );
  },
  duration: const Duration(seconds: 5),
  position: ToastPosition.bottom,
));
```

### Queue Handling

```dart
ToastKit.init(
  navigatorKey: navigatorKey,
  config: const ToastConfig(
    maxVisibleToasts: 3,       // Show up to 3 toasts at once
    enableQueue: true,          // Queue extras instead of dropping
    queueMode: QueueMode.fifo,  // First-in, first-out
  ),
  routerConfig: const RouterConfig(
    enableDeduplication: true,
    deduplicationWindow: Duration(seconds: 2),
    replacementStrategy: ReplacementStrategy.dropNew,
  ),
);

// Rapid-fire: only 3 visible, rest queued
for (var i = 1; i <= 10; i++) {
  ToastKit.info('Notification #$i');
}
```

### Global Configuration

```dart
ToastKit.init(
  navigatorKey: navigatorKey,
  config: const ToastConfig(
    defaultPosition: ToastPosition.top,
    defaultDuration: Duration(seconds: 4),
    maxVisibleToasts: 3,
    enableQueue: true,
    queueMode: QueueMode.fifo,
    defaultAnimation: ToastAnimationType.slideFromTop,
    safeAreaEnabled: true,
    keyboardAvoidance: true,
    density: ToastDensity.comfortable,
    toastSpacing: 8.0,
  ),
  routerConfig: const RouterConfig(
    enableDeduplication: true,
    deduplicationWindow: Duration(seconds: 2),
    enableThrottling: false,
    replacementStrategy: ReplacementStrategy.dropNew,
  ),
  channels: [
    ToastChannel.auth,
    ToastChannel.network,
    ToastChannel.payment,
  ],
  plugins: [LoggerPlugin(), AnalyticsPlugin()],
);
```

---

## 🔥 Advanced Usage

### Preventing Toast Spam

Use deduplication and throttling to prevent users from seeing the same toast repeatedly:

```dart
ToastKit.init(
  navigatorKey: navigatorKey,
  routerConfig: const RouterConfig(
    enableDeduplication: true,
    deduplicationWindow: Duration(seconds: 5),
    enableThrottling: true,
  ),
);

// Even if called 100 times, only one toast appears within the 5-second window
void onNetworkError() {
  ToastKit.show(ToastEvent.error(
    message: 'No internet connection',
    deduplicationKey: 'no-internet',
  ));
}
```

### API Error Handling

```dart
Future<void> fetchUserProfile() async {
  final ctrl = ToastKit.showLoading('Loading profile…');
  try {
    final user = await api.getProfile();
    ctrl.success('Welcome back, ${user.name}!');
  } on NotFoundException {
    ctrl.error('Profile not found');
  } on TimeoutException {
    ctrl.error('Request timed out — please try again');
  } catch (e) {
    ctrl.error('Something went wrong');
    ToastKit.error('Error: $e', channel: 'network');
  }
}
```

### Form Validation

```dart
void onSubmitForm(String email, String password) {
  final errors = <String>[];

  if (email.isEmpty || !email.contains('@')) {
    errors.add('Please enter a valid email');
  }
  if (password.length < 8) {
    errors.add('Password must be at least 8 characters');
  }

  if (errors.isNotEmpty) {
    for (final error in errors) {
      ToastKit.warning(error, channel: 'form');
    }
    return;
  }

  // Proceed with submission
  submitForm(email, password);
}
```

### Login Attempt Limiting

```dart
// Register auth channel and configure escalating rules
ToastKit.registerChannel(ToastChannel.auth);

// Config-based rule: fire analytics callback after 3 errors
ToastKit.configureRule(
  'auth',
  RuleConfig(
    errorThreshold: 3,
    deduplicateWindow: Duration(seconds: 60),
    maxTriggers: 1,
  ),
);

// Custom rule: suggest password reset after 3 failures
ToastKit.addRule(ToastRule(
  id: 'suggest-reset',
  channel: 'auth',
  maxTriggers: 1,
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
          onPressed: () => ToastKit.success('Reset email sent!'),
        ),
      ],
      channel: 'auth',
    ));
  },
));

// Custom rule: lock account after 5 failures
ToastKit.addRule(ToastRule(
  id: 'login-lockout',
  channel: 'auth',
  maxTriggers: 1,
  condition: (stats, event) => stats.errorCount >= 5,
  action: (context) {
    setState(() => _isLocked = true);
    ToastKit.show(ToastEvent.error(
      message: 'Account locked for 30 seconds.',
      persistent: true,
      dismissible: false,
      deduplicationKey: 'login-lockout',
      channel: 'auth',
    ));
  },
));

Future<void> attemptLogin(String email, String password) async {
  final ctrl = ToastKit.showLoading('Signing in…');
  try {
    await authService.login(email, password);
    ctrl.success('Welcome back!');
  } catch (e) {
    ctrl.error('Invalid credentials');
    // Error recorded on auth channel — rules evaluate automatically
    ToastKit.error('Login failed', channel: 'auth');
  }
}
```

### Payment Failure Scenario

```dart
ToastKit.registerChannel(ToastChannel.payment);

// Step 1: Warning after 2 failures
ToastKit.addRule(ToastRule(
  id: 'payment-warn',
  channel: 'payment',
  maxTriggers: 1,
  condition: (stats, event) =>
      stats.errorCount >= 2 && stats.errorCount < 4,
  action: (context) {
    ToastKit.warning(
      'Multiple payment failures. Check your card details.',
      channel: 'payment',
    );
  },
));

// Step 2: Block and offer recovery after 4 failures
ToastKit.addRule(ToastRule(
  id: 'payment-block',
  channel: 'payment',
  maxTriggers: 1,
  condition: (stats, event) => stats.errorCount >= 4,
  action: (context) {
    ToastKit.show(ToastEvent.error(
      message: 'Payment processing suspended.',
      persistent: true,
      variant: ToastVariant.action,
      deduplicationKey: 'payment-block-toast',
      actions: [
        ToastAction(
          label: 'Switch Card',
          onPressed: () => switchPaymentMethod(),
        ),
        ToastAction(
          label: 'Use PayPal',
          onPressed: () => redirectToPayPal(),
        ),
        ToastAction(
          label: 'Contact Support',
          onPressed: () => openSupportChat(),
        ),
      ],
      channel: 'payment',
    ));
  },
));

Future<void> processPayment(double amount) async {
  final ctrl = ToastKit.showLoading('Processing payment…');
  try {
    await paymentService.charge(amount);
    ctrl.success('Payment of \$${amount.toStringAsFixed(2)} successful!');
  } on PaymentDeclinedException {
    ctrl.error('Card declined — please try another card');
    ToastKit.error('Payment declined', channel: 'payment');
  } on InsufficientFundsException {
    ctrl.error('Insufficient funds');
    ToastKit.error('Insufficient funds', channel: 'payment');
  } catch (e) {
    ctrl.error('Payment failed');
    ToastKit.error('Payment error', channel: 'payment');
  }
}
```

### Network Retry Messaging

```dart
ToastKit.registerChannel(ToastChannel.network);

// Config rule for general error tracking
ToastKit.configureRule(
  'network',
  RuleConfig(
    errorThreshold: 3,
    deduplicateWindow: Duration(seconds: 10),
    maxTriggers: 2,
  ),
);

// Custom rule: detect error bursts using errorsInWindow()
ToastKit.addRule(ToastRule(
  id: 'network-burst',
  channel: 'network',
  deduplicateWindow: Duration(seconds: 30),
  condition: (stats, event) {
    return stats.errorsInWindow(const Duration(seconds: 15)) >= 3;
  },
  action: (context) {
    ToastKit.show(ToastEvent.error(
      message: 'Connection unstable. Check your network.',
      persistent: true,
      variant: ToastVariant.action,
      deduplicationKey: 'network-unstable',
      actions: [
        ToastAction(
          label: 'Retry',
          onPressed: () {
            ToastKit.dismissAll();
            ToastKit.info('Retrying…');
          },
        ),
      ],
      channel: 'network',
    ));
  },
));

Future<T> fetchWithRetry<T>(
  Future<T> Function() request, {
  int maxRetries = 3,
}) async {
  for (var attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await request();
    } catch (e) {
      ToastKit.error(
        'Retry $attempt/$maxRetries failed',
        channel: 'network',
      );

      if (attempt == maxRetries) {
        ToastKit.show(ToastEvent.error(
          message: 'All retries exhausted. Check your connection.',
          variant: ToastVariant.action,
          actions: [
            ToastAction(
              label: 'Retry',
              onPressed: () => fetchWithRetry(request),
            ),
          ],
          channel: 'network',
        ));
        rethrow;
      }

      await Future.delayed(Duration(seconds: attempt * 2));
    }
  }
  throw StateError('Unreachable');
}
```

---

## 🧩 Custom Toast Variants (Extensibility)

ToastKit supports a **plugin-style extensibility mechanism** for toast variants. Instead of repeating custom builder code across multiple screens, define a variant once and reuse it everywhere.

### Creating a Custom Variant

Extend `CustomToastVariantBuilder`:

```dart
import 'package:toast_kit/toast_kit.dart';

class PaymentSuccessVariant extends CustomToastVariantBuilder {
  @override
  String get name => 'payment_success';

  @override
  Widget build(BuildContext context, ToastEvent event, ToastController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        children: [
          const Icon(Icons.payment, color: Colors.green, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (event.title != null)
                  Text(event.title!, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(event.message ?? ''),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: controller.dismiss,
          ),
        ],
      ),
    );
  }
}
```

### Registering Custom Variants

Register at init time or later:

```dart
// At init time
ToastKit.init(navigatorKey: navigatorKey);
ToastKit.configure(variants: [
  PaymentSuccessVariant(),
  NotificationBannerVariant(),
]);

// Or register individually
ToastKit.registerVariant(PaymentSuccessVariant());
```

### Using Custom Variants

Use by name on individual toast events:

```dart
// Per-event usage
ToastKit.success('Payment received!', customVariantName: 'payment_success');
ToastKit.error('Payment failed', customVariantName: 'payment_error');
```

### Assigning Variants to Channels

Assign a custom variant to a channel so all toasts on that channel use it automatically:

```dart
ToastKit.registerChannel(
  const ToastChannel(
    id: 'payment',
    label: 'Payment',
    customVariantName: 'payment_success',  // All toasts on this channel use this variant
    defaultPriority: ToastPriority.urgent,
  ),
);

// Now all toasts on the payment channel use PaymentSuccessVariant
ToastKit.channel('payment').success('Payment received!');
ToastKit.channel('payment').error('Payment declined');
```

### Rendering Precedence Rules

When multiple rendering strategies are specified, ToastKit resolves them in order (highest priority first):

| Priority | Strategy | When to use |
|----------|----------|-------------|
| 1 (highest) | `customBuilder` on event | One-off, truly unique toast UIs |
| 2 | `customVariantName` on event | Per-event override with a registered variant |
| 3 | Channel's `customVariantName` | Channel-wide custom variant |
| 4 | `variant` (enum) on event | Per-event built-in variant |
| 5 | Channel's `defaultVariant` | Channel-wide built-in variant |
| 6 (lowest) | Default for `ToastType` | Automatic fallback (e.g., `material`) |

**Key rule:** An explicit `customBuilder` always overrides everything else. This is the escape hatch for single-use, highly custom UIs. For consistent reusable styling, prefer `CustomToastVariantBuilder`.

```dart
// This builder always wins, even if customVariantName or variant is also set
ToastKit.show(ToastEvent(
  type: ToastType.success,
  message: 'Custom!',
  customBuilder: (ctx, ctrl) => MyWidget(),     // ← Priority 1 (wins)
  customVariantName: 'payment_success',          // ← Priority 2 (ignored)
  variant: ToastVariant.material,                // ← Priority 4 (ignored)
));
```

### Composing Variants

Custom variants can delegate to other variants or compose them:

```dart
class BrandedVariant extends CustomToastVariantBuilder {
  @override
  String get name => 'branded';

  @override
  Widget build(BuildContext context, ToastEvent event, ToastController controller) {
    // Wrap a built-in variant with branding
    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: MyBrand.primaryColor, width: 4)),
      ),
      child: VariantFactory.build(ToastVariant.material, event, controller),
    );
  }
}
```

### `ToastType.custom` Deprecation

`ToastType.custom` is now **deprecated**. With the extensible custom variant system, there is no longer a need for a catch-all "custom" type:

| Before (deprecated) | After (recommended) |
|---------------------|---------------------|
| `ToastEvent.custom(builder: ...)` | `ToastKit.registerVariant(MyVariant())` + `customVariantName: 'my_variant'` |
| `ToastType.custom` | Use any `ToastType` (success, error, etc.) + `customVariantName` |
| `ToastState.custom` | Use standard states (success, error, etc.) |

**Migration:** Replace `ToastEvent.custom(builder: myBuilder)` with either:
1. A registered `CustomToastVariantBuilder` (recommended for reuse), or
2. A standard `ToastEvent` with `customBuilder: myBuilder` (for one-off cases).

---

## 🔌 Plugin System

### Plugin Interface

All plugins extend `ToastPlugin` and override lifecycle hooks:

```dart
abstract class ToastPlugin {
  String get name;

  void onToastShown(ToastEvent event) {}
  void onToastQueued(ToastEvent event) {}
  void onToastDismissed(ToastEvent event, DismissReason? reason) {}
  void onToastDropped(ToastEvent event, String reason) {}
  void onToastReplaced(ToastEvent newEvent, String replacedId) {}
  void onToastAction(ToastEvent event, String actionLabel) {}
  void onChannelRegistered(String channelId) {}
  void onRuleTriggered(String ruleId, String channel) {}
  void onTelemetryEvent(ToastTelemetryEvent telemetryEvent) {}
  void onAttach() {}
  void onDetach() {}
}
```

### LoggerPlugin

```dart
class LoggerPlugin extends ToastPlugin {
  @override
  String get name => 'logger';

  @override
  void onAttach() => print('[ToastKit:Logger] Plugin attached');

  @override
  void onDetach() => print('[ToastKit:Logger] Plugin detached');

  @override
  void onToastShown(ToastEvent event) {
    print('[ToastKit:Logger] SHOWN — ${event.type.name}: "${event.message}"'
        '${event.channel != null ? " [${event.channel}]" : ""}');
  }

  @override
  void onToastQueued(ToastEvent event) {
    print('[ToastKit:Logger] QUEUED — ${event.id}');
  }

  @override
  void onToastDismissed(ToastEvent event, DismissReason? reason) {
    print('[ToastKit:Logger] DISMISSED — ${event.id} '
        '(${reason?.name ?? "auto"})');
  }

  @override
  void onToastDropped(ToastEvent event, String reason) {
    print('[ToastKit:Logger] DROPPED — ${event.id}: $reason');
  }

  @override
  void onRuleTriggered(String ruleId, String channel) {
    print('[ToastKit:Logger] RULE TRIGGERED — $ruleId on "$channel"');
  }
}
```

### AnalyticsPlugin

```dart
class AnalyticsPlugin extends ToastPlugin {
  @override
  String get name => 'analytics';

  @override
  void onToastShown(ToastEvent event) {
    _trackEvent('toast_shown', {
      'type': event.type.name,
      'message': event.message ?? '',
      'channel': event.channel ?? 'default',
      'variant': event.variant?.name ?? 'default',
    });
  }

  @override
  void onToastDismissed(ToastEvent event, DismissReason? reason) {
    _trackEvent('toast_dismissed', {
      'toast_id': event.id,
      'dismiss_reason': reason?.name ?? 'auto',
    });
  }

  @override
  void onRuleTriggered(String ruleId, String channel) {
    _trackEvent('toast_rule_triggered', {
      'rule_id': ruleId,
      'channel': channel,
    });
  }

  void _trackEvent(String name, Map<String, String> params) {
    // Replace with your analytics SDK
    print('[Analytics] $name: $params');
  }
}
```

### HapticsPlugin

```dart
import 'package:flutter/services.dart';

class HapticsPlugin extends ToastPlugin {
  @override
  String get name => 'haptics';

  @override
  void onToastShown(ToastEvent event) {
    switch (event.type) {
      case ToastType.error:
        HapticFeedback.heavyImpact();
        break;
      case ToastType.warning:
        HapticFeedback.mediumImpact();
        break;
      case ToastType.success:
        HapticFeedback.lightImpact();
        break;
      default:
        HapticFeedback.selectionClick();
        break;
    }
  }
}
```

### Registering Plugins

```dart
// At init time
ToastKit.init(
  navigatorKey: navigatorKey,
  plugins: [
    LoggerPlugin(),
    AnalyticsPlugin(),
    HapticsPlugin(),
  ],
);

// Or after init
ToastKit.registerPlugin(LoggerPlugin());

// Remove a plugin
ToastKit.unregisterPlugin('logger');
```

**Event flow:** `ToastKit.show()` → router → queue → overlay engine. At each stage, `PluginHub` notifies all registered plugins via `onToastQueued`, `onToastShown`, `onToastDismissed`, etc.

---

## 📋 API Overview

| Method | Description |
|--------|-------------|
| `ToastKit.init(...)` | Initialize the SDK (required once) |
| `ToastKit.show(event)` | Show a `ToastEvent` |
| `ToastKit.success(msg)` | Show a success toast |
| `ToastKit.error(msg)` | Show an error toast |
| `ToastKit.warning(msg)` | Show a warning toast |
| `ToastKit.info(msg)` | Show an info toast |
| `ToastKit.showLoading(msg)` | Show loading toast, returns `ToastController` |
| `ToastKit.loading(msg)` | Show loading toast (fire-and-forget) |
| `ToastKit.custom(builder: ...)` | Show toast with custom builder (**deprecated — use `registerVariant`**) |
| `ToastKit.registerVariant(variant)` | Register a `CustomToastVariantBuilder` by name |
| `ToastKit.unregisterVariant(name)` | Remove a custom variant |
| `ToastKit.isVariantRegistered(name)` | Check if a custom variant is registered |
| `ToastKit.configure(variants: [...])` | Batch-register plugins and/or custom variants |
| `ToastKit.configureRule(ch, config)` | Set a config-based rule for a channel |
| `ToastKit.addRule(rule)` | Add a custom `ToastRule` |
| `ToastKit.removeRule(id)` | Remove a custom rule by ID |
| `ToastKit.ruleEngine.resetStats()` | Reset all stats but keep rules |
| `ToastKit.ruleEngine.clear()` | Remove all rules, stats, and trigger counts |
| `ToastKit.registerChannel(ch)` | Register a `ToastChannel` |
| `ToastKit.registerPlugin(plugin)` | Register a `ToastPlugin` |
| `ToastKit.unregisterPlugin(name)` | Remove a plugin |
| `ToastKit.dismiss(id)` | Dismiss a specific toast |
| `ToastKit.dismissAll()` | Dismiss all visible toasts |
| `ToastKit.dispose()` | Release all resources |
| `ToastKit.channel(name)` | Get a fluent `ChannelHandle` |
| `ToastKit.eventStream` | Broadcast stream of all toast events |
| `ToastKit.restorePersistedToasts()` | Restore saved persistent toasts |

---

## 📱 Example App

See the [`example/`](example/) directory for a complete demo app with real-world scenarios.

### 🛠️ Toast Builder UI

The example app includes a **full-featured interactive Toast Builder** accessible via the floating action button on any screen. The builder enables users to design, configure, and export complete ToastKit setups without writing code manually.

#### Accessing the Builder

The "Toast Builder" floating action button appears on every screen. Tap it to open the configurator at `/toast/configurator`.

#### Builder Tabs

The Toast Builder is organized into **8 tabs**:

| Tab | Purpose |
|-----|---------|
| **Content** | Set toast title, message, subtitle, icon, and action buttons |
| **Style** | Configure colors, gradients, borders, shadows, opacity, and layout |
| **Animation** | Choose from 12 animation types and configure position |
| **Behavior** | Set duration, progress bar, dismiss behavior, priority, and feedback |
| **Channels** | Define and manage toast channels with all `ToastChannel` properties |
| **Variants** | Register custom variants and assign them to channels |
| **Rules** | Create config-based and custom rules per channel |
| **Preview** | Live preview, configuration summary, and generated code |

#### Channel Management (Channels Tab)

- **Add/Edit/Remove channels** with all `ToastChannel` properties:
  - ID, label, enabled state
  - Max visible toasts, default priority, position, duration, animation
  - Built-in variant assignment and custom variant name
- **Per-channel policies** via `ChannelConfig`:
  - Deduplication with configurable window
  - Throttling with configurable interval
  - Interrupt behavior and queue limits

#### Variant Management (Variants Tab)

- **Register custom variant names** — add names of `CustomToastVariantBuilder` classes
- **Quick-add example variants** — one-tap chips for `payment_success`, `system_error`, `notification_banner`
- **Per-channel assignment** — assign a built-in `ToastVariant` or registered custom variant to each channel
- **Built-in variant gallery** — visual reference of all 12 built-in variants

#### Rules Configuration (Rules Tab)

- **Config-based rules** (`RuleConfig`):
  - Error threshold, deduplication window, max triggers per channel
- **Custom rules** (`ToastRule`):
  - Condition types: error count, total count, windowed error rate, warning count
  - Action types: show info/warning/error toast, or action toast with button
  - Persistence and dismiss settings

#### Code Generation

The **Preview tab** generates two types of code:

1. **Single Toast Code** — The exact `ToastEvent.custom(...)` code to reproduce the designed toast
2. **Full Setup Code** — Complete initialization code including:
   - `const ToastChannel(...)` definitions
   - `ToastKit.init(...)` with channel registration
   - `ToastKit.registerVariant(...)` calls with class stubs
   - `_configureRules()` with all config-based and custom rules
   - Usage examples with direct and fluent channel API

All generated code is:
- ✅ Complete (no hidden or omitted options)
- ✅ Well-commented with section headers
- ✅ Production-ready and copy-paste friendly
- ✅ Copyable to clipboard with one tap

#### Import / Export

- **Export** (↓ button in app bar) — copies the full builder configuration as JSON to clipboard
- **Import** (↑ button in app bar) — paste previously exported JSON to restore a configuration

### Full-Featured ToastService Example

The example app includes a production-quality `ToastService` that demonstrates comprehensive channel/variant/rules integration. Here is the key pattern:

#### 1. Define Custom Variants

```dart
import 'package:toast_kit/toast_kit.dart';

/// Custom variant for payment notifications.
class PaymentSuccessVariant extends CustomToastVariantBuilder {
  @override
  String get name => 'payment_success';

  @override
  Widget build(BuildContext context, ToastEvent event, ToastController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        children: [
          Icon(event.icon ?? Icons.payment, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (event.title != null)
                  Text(event.title!, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(event.message ?? ''),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: controller.dismiss),
        ],
      ),
    );
  }
}

/// Custom variant for system errors.
class SystemErrorVariant extends CustomToastVariantBuilder {
  @override
  String get name => 'system_error';

  @override
  Widget build(BuildContext context, ToastEvent event, ToastController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(event.icon ?? Icons.error_outline, color: Colors.red.shade300),
          const SizedBox(width: 12),
          Expanded(child: Text(event.message ?? '', style: TextStyle(color: Colors.red.shade100))),
          IconButton(icon: Icon(Icons.close, color: Colors.red.shade300), onPressed: controller.dismiss),
        ],
      ),
    );
  }
}
```

#### 2. Define Channels with Variant Assignments

```dart
// Payment channel — auto-applies PaymentSuccessVariant
const paymentChannel = ToastChannel(
  id: 'payment',
  label: 'Payment Channel',
  customVariantName: 'payment_success', // All toasts use this variant
  maxVisible: 1,
  defaultPriority: ToastPriority.urgent,
  defaultDuration: Duration(seconds: 5),
  defaultPosition: ToastPosition.top,
);

// System channel — auto-applies SystemErrorVariant
const systemChannel = ToastChannel(
  id: 'system',
  label: 'System Channel',
  customVariantName: 'system_error',
  maxVisible: 2,
  defaultPriority: ToastPriority.high,
);
```

#### 3. Initialize with Channels, Variants, and Rules

```dart
void initToastService(GlobalKey<NavigatorState> navigatorKey) {
  // Initialize ToastKit
  ToastKit.init(
    navigatorKey: navigatorKey,
    config: const ToastConfig(
      defaultPosition: ToastPosition.top,
      maxVisibleToasts: 3,
      enableQueue: true,
      queueMode: QueueMode.fifo,
    ),
    channels: [paymentChannel, systemChannel],
  );

  // Register custom variants
  ToastKit.configure(variants: [
    PaymentSuccessVariant(),
    SystemErrorVariant(),
  ]);

  // Config-based rule: trigger after 3 payment errors
  ToastKit.configureRule('payment', const RuleConfig(
    errorThreshold: 3,
    deduplicateWindow: Duration(seconds: 60),
    maxTriggers: 1,
  ));

  // Custom rule: suggest help after 2 payment errors
  ToastKit.addRule(ToastRule(
    id: 'payment-help',
    channel: 'payment',
    maxTriggers: 1,
    condition: (stats, event) => stats.errorCount >= 2,
    action: (context) {
      ToastKit.show(ToastEvent.info(
        message: 'Try switching your payment method.',
        variant: ToastVariant.action,
        actions: [
          ToastAction(
            label: 'Switch Method',
            onPressed: () => ToastKit.success('Updated!', channel: 'payment'),
          ),
        ],
        channel: 'payment',
      ));
    },
  ));

  // Error burst detection on system channel
  ToastKit.addRule(ToastRule(
    id: 'system-burst',
    channel: 'system',
    deduplicateWindow: const Duration(seconds: 60),
    condition: (stats, event) =>
        stats.errorsInWindow(const Duration(seconds: 30)) >= 3,
    action: (context) {
      ToastKit.show(ToastEvent.error(
        message: 'Error burst: ${context.stats.errorCount} errors detected.',
        persistent: true,
        channel: 'system',
      ));
    },
  ));
}
```

#### 4. Use Anywhere — No BuildContext Required

```dart
// Payment success — auto-uses PaymentSuccessVariant via channel
ToastKit.channel('payment').success('Payment of \$49.99 received!');

// Payment error — rules evaluate automatically
ToastKit.channel('payment').error('Card declined');

// System error — auto-uses SystemErrorVariant via channel
ToastKit.error('Database timeout', channel: 'system');

// Progress toast with lifecycle
final ctrl = ToastKit.showLoading('Uploading file…');
try {
  for (var pct = 0; pct <= 100; pct += 10) {
    await Future.delayed(Duration(milliseconds: 200));
    ctrl.update(message: 'Uploading… $pct%');
    ctrl.progress.value = pct / 100;
  }
  ctrl.success('Upload complete!');
} catch (e) {
  ctrl.error('Upload failed');
}

// Per-event variant override (use glassmorphism on payment channel)
ToastKit.show(ToastEvent.success(
  message: 'Override!',
  variant: ToastVariant.glassmorphism, // Overrides channel default
  channel: 'payment',
));

// Runtime rule management
ToastKit.addRule(ToastRule(id: 'temp', channel: 'system', ...));
ToastKit.removeRule('temp');
ToastKit.ruleEngine.resetStats();
```

---

## 📂 Folder Structure

```
toast_kit/
├── lib/
│   ├── toast_kit.dart                    # Barrel export
│   └── src/
│       ├── core/                         # Config + SDK singleton
│       ├── events/                       # ToastEvent + EventBus
│       ├── queue/                        # FIFO/LIFO/priority queue
│       ├── router/                       # Dedup, throttle, replacement
│       ├── overlay/                      # OverlayEntry lifecycle
│       ├── channels/                     # Channel definitions + policies
│       ├── rules/                        # Rule engine + config + stats
│       ├── plugins/                      # Plugin base class + hub
│       ├── persistence/                  # Save/restore critical toasts
│       ├── animation/                    # 12 animations + factory
│       ├── gestures/                     # Swipe/tap/hover
│       ├── theme/                        # Design tokens + provider
│       ├── layout/                       # Position calculator
│       ├── stacking/                     # Smart group stacking
│       ├── accessibility/                # Screen reader support
│       ├── analytics/                    # Telemetry events
│       ├── debug/                        # Debug overlay
│       └── variants/                     # 12+ toast variants
├── example/
│   ├── lib/
│   │   ├── main.dart                     # Full demo app
│   │   ├── mock/
│   │   │   └── custom_variants.dart      # Reusable custom variant builders
│   │   ├── services/
│   │   │   └── toast_service.dart        # Production-quality ToastService
│   │   ├── toast_demo/
│   │   │   ├── toast_configurator_screen.dart # Full Toast Builder UI (8 tabs)
│   │   │   ├── toast_builder_demo.dart   # Channel/variant/rules demo
│   │   │   ├── toast_showcase.dart       # All types/variants/positions
│   │   │   ├── toast_rules_demo.dart     # Rule engine demonstrations
│   │   │   ├── toast_progress_demo.dart  # Progress tracking
│   │   │   ├── builder/
│   │   │   │   ├── builder_models.dart        # Builder data models
│   │   │   │   ├── channel_builder_tab.dart   # Channel management tab
│   │   │   │   ├── variant_builder_tab.dart   # Variant management tab
│   │   │   │   ├── rules_builder_tab.dart     # Rules configuration tab
│   │   │   │   └── full_code_generator.dart   # Complete code generator
│   │   │   └── ...
│   │   └── scenarios/
│   │       ├── api_error.dart            # API failure handling
│   │       ├── form_validation.dart      # Form validation errors
│   │       ├── login_rules.dart          # Login retry limits
│   │       ├── payment_failure.dart      # Payment failure with rules
│   │       ├── network_retry.dart        # Network retry messaging
│   │       └── custom_ui.dart            # Custom toast builder
│   └── pubspec.yaml
├── test/
├── pubspec.yaml
├── README.md
└── analysis_options.yaml
```

---

## 🔧 Troubleshooting

### Toast not showing

- Ensure `ToastKit.init()` is called **after** the first frame:
  ```dart
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ToastKit.init(navigatorKey: navigatorKey);
  });
  ```
- Verify `navigatorKey` is the same instance passed to `MaterialApp`.

### Toasts getting dropped

- Check if deduplication is enabled and the `deduplicationKey` is the same.
- Check if the channel's `maxVisible` limit is reached.
- Verify `enableQueue: true` in `ToastConfig` to queue overflow toasts.

### Rules not triggering

- Ensure the channel is registered with `ToastKit.registerChannel(...)`.
- Verify toast events include the correct `channel` parameter.
- Check `RuleConfig.errorThreshold` — the rule only triggers after this many errors.
- Check `maxTriggers` — a value of `1` means it triggers only once.

### Plugin not receiving events

- Confirm the plugin is registered via `ToastKit.init(plugins: [...])` or `ToastKit.registerPlugin(...)`.
- Plugin names must be unique — a second plugin with the same name replaces the first.

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes and add tests
4. Run tests: `flutter test`
5. Commit: `git commit -m "feat: add my feature"`
6. Push and open a pull request

Please ensure:
- All existing tests pass
- New features include test coverage
- Code follows the existing style (run `flutter analyze`)

---

## 📜 License

MIT © 2026 ToastKit Contributors