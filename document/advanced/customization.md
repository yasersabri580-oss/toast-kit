# Advanced: Customization Guide

How to fully customize the look, feel, and behavior of ToastKit.

---

## Custom Toast Variants

Use `customBuilder` to create any toast UI:

```dart
ToastKit.show(ToastEvent.custom(
  builder: (context, controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Custom gradient toast!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: controller.dismiss,
          ),
        ],
      ),
    );
  },
  duration: const Duration(seconds: 4),
  position: ToastPosition.bottom,
));
```

---

## Custom Theme Integration

Match toasts to your app theme using `Theme.of(context)` inside builders:

```dart
ToastKit.show(ToastEvent.custom(
  builder: (context, controller) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.error, color: colorScheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: controller.messageNotifier,
                builder: (_, msg, __) => Text(
                  msg,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  },
));
```

---

## Reusable Custom Toast Widgets

Create a reusable toast component:

```dart
class BrandedToast extends StatelessWidget {
  const BrandedToast({
    super.key,
    required this.controller,
    required this.message,
    this.icon = Icons.info,
    this.color = Colors.blue,
  });

  final ToastController controller;
  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: controller.dismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// Usage
ToastKit.show(ToastEvent.custom(
  builder: (context, ctrl) => BrandedToast(
    controller: ctrl,
    message: 'Custom branded toast!',
    icon: Icons.star,
    color: Colors.amber,
  ),
));
```

---

## Overriding Defaults Safely

### Per-Toast Overrides

Any toast property can override the global default:

```dart
// Override position for this toast only
ToastKit.success(
  'Bottom right!',
  position: ToastPosition.bottomRight,
  duration: const Duration(seconds: 10),
  animation: ToastAnimationType.bounce,
  variant: ToastVariant.compact,
);
```

### Per-Channel Defaults

Channel defaults override global defaults for toasts on that channel:

```dart
const debugChannel = ToastChannel(
  id: 'debug',
  label: 'Debug',
  defaultPosition: ToastPosition.bottomLeft,
  defaultDuration: Duration(seconds: 10),
  defaultVariant: ToastVariant.debug,
  defaultPriority: ToastPriority.low,
);
```

### Override Precedence

```
Per-toast property > Channel default > Global config default
```

---

## Custom Animations

Use `ToastAnimationType.custom` with a custom animation builder:

```dart
ToastKit.show(ToastEvent.success(
  message: 'Custom animation!',
  animation: ToastAnimationType.custom,
));
```

Built-in animations cover most use cases:

| Animation | Best For |
|-----------|----------|
| `fade` | Subtle, non-distracting |
| `slideFromTop` | Standard top-position toasts |
| `slideFromBottom` | Bottom-position toasts |
| `scale` | Center-position toasts |
| `bounce` | Playful, attention-grabbing |
| `shake` | Error emphasis |
| `spring` | Natural physics feel |

---

## Custom Plugins

Create plugins to extend ToastKit without modifying core behavior:

### Logger Plugin

```dart
class LoggerPlugin extends ToastPlugin {
  @override
  String get name => 'logger';

  @override
  void onToastShown(ToastEvent event) {
    debugPrint('[ToastKit] SHOWN: ${event.type.name} — ${event.message}');
  }

  @override
  void onToastDismissed(ToastEvent event, DismissReason reason) {
    debugPrint('[ToastKit] DISMISSED: ${event.id} — ${reason.name}');
  }

  @override
  void onToastDropped(ToastEvent event, String reason) {
    debugPrint('[ToastKit] DROPPED: ${event.message} — $reason');
  }

  @override
  void onRuleTriggered(String ruleId, String channel) {
    debugPrint('[ToastKit] RULE FIRED: $ruleId on $channel');
  }
}
```

### Haptic Feedback Plugin

```dart
class HapticPlugin extends ToastPlugin {
  @override
  String get name => 'haptics';

  @override
  void onToastShown(ToastEvent event) {
    switch (event.type) {
      case ToastType.error:
        HapticFeedback.heavyImpact();
        break;
      case ToastType.success:
        HapticFeedback.lightImpact();
        break;
      case ToastType.warning:
        HapticFeedback.mediumImpact();
        break;
      default:
        break;
    }
  }
}
```

### Analytics Plugin

```dart
class AnalyticsPlugin extends ToastPlugin {
  final void Function(String name, Map<String, dynamic> params) logEvent;

  AnalyticsPlugin({required this.logEvent});

  @override
  String get name => 'analytics';

  @override
  void onToastShown(ToastEvent event) {
    logEvent('toast_shown', {
      'type': event.type.name,
      'channel': event.channel ?? 'default',
      'variant': event.variant?.name ?? 'auto',
    });
  }

  @override
  void onToastDismissed(ToastEvent event, DismissReason reason) {
    logEvent('toast_dismissed', {
      'type': event.type.name,
      'reason': reason.name,
      'visible_duration_ms': DateTime.now()
          .difference(event.createdAt)
          .inMilliseconds,
    });
  }
}
```

---

[← Configuration](configuration.md) | [Next: Rule Engine →](rule_engine.md)
