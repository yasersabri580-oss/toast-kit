# Example: Custom Toast UI

Build a fully custom toast widget using `ToastEvent.custom`.

## What This Example Demonstrates

- `customBuilder` for full widget control
- Accessing `ToastController` inside a custom builder
- Progress tracking in a custom toast
- Interactive elements (buttons, sliders) inside toasts

---

## Simple Custom Toast

```dart
ToastKit.show(ToastEvent.custom(
  builder: (context, controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.rocket_launch, color: Colors.white),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'New feature unlocked!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: controller.dismiss,
            child: const Text('Got it', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  },
  duration: const Duration(seconds: 5),
));
```

## Custom Toast with Progress

```dart
Future<void> uploadFile(File file) async {
  final event = ToastEvent.custom(
    builder: (context, controller) {
      return _UploadProgressToast(controller: controller);
    },
    persistent: true,
    dismissible: false,
  );

  final ctrl = ToastKit.showWithController(event);

  try {
    await api.uploadFile(
      file,
      onProgress: (sent, total) {
        final progress = sent / total;
        ctrl.update(
          progressValue: progress,
          message: '${(progress * 100).toInt()}% uploaded',
        );
      },
    );

    ctrl.success('Upload complete!');
  } catch (e) {
    ctrl.error('Upload failed: $e');
  }
}

class _UploadProgressToast extends StatelessWidget {
  const _UploadProgressToast({required this.controller});

  final ToastController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_upload),
              const SizedBox(width: 8),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: controller.messageNotifier,
                  builder: (_, message, __) => Text(
                    message.isEmpty ? 'Uploading…' : message,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<double>(
            valueListenable: controller.progress,
            builder: (_, value, __) => LinearProgressIndicator(
              value: value,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
```

## Custom Toast with State Transitions

A custom toast that visually reacts to state changes:

```dart
class _StatefulCustomToast extends StatelessWidget {
  const _StatefulCustomToast({required this.controller});

  final ToastController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ToastState>(
      valueListenable: controller.stateNotifier,
      builder: (_, state, __) {
        final (color, icon) = switch (state) {
          ToastState.loading => (Colors.blue, Icons.hourglass_empty),
          ToastState.success => (Colors.green, Icons.check_circle),
          ToastState.error => (Colors.red, Icons.error),
          ToastState.warning => (Colors.orange, Icons.warning),
          _ => (Colors.grey, Icons.info),
        };

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: controller.messageNotifier,
                  builder: (_, message, __) => Text(message),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

---

[← Form Validation](form_validation.md) | [Next: Loading State Flow →](loading_state_flow.md)
