import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

import '../widgets/see_code_button.dart';

// ---------------------------------------------------------------------------
// Custom UI Scenario
//
// Demonstrates:
// - Custom toast builders with full widget control
// - Using ToastController for state transitions
// - ValueListenableBuilder for reactive toast updates
// - Different custom design approaches
// ---------------------------------------------------------------------------

class CustomUiScenario extends StatelessWidget {
  const CustomUiScenario({super.key});

  /// Show a custom branded toast with company colors.
  void _showBrandedToast() {
    ToastKit.custom(builder: (context, controller) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF3F3D99)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'New Feature!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Dark mode is now available. Try it out!',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white54),
              onPressed: controller.dismiss,
            ),
          ],
        ),
      );
    });
  }

  /// Show a toast with progress tracking using ToastController.
  void _showProgressToast() {
    ToastKit.show(ToastEvent.custom(
      builder: (context, controller) {
        // Simulate progress updates.
        _simulateProgress(controller);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ValueListenableBuilder<ToastState>(
                    valueListenable: controller.stateNotifier,
                    builder: (_, state, __) {
                      final icon = switch (state) {
                        ToastState.success => Icons.check_circle,
                        ToastState.error => Icons.error,
                        _ => Icons.cloud_upload,
                      };
                      final color = switch (state) {
                        ToastState.success => Colors.green,
                        ToastState.error => Colors.red,
                        _ => Colors.blue,
                      };
                      return Icon(icon, color: color, size: 20);
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ValueListenableBuilder<String>(
                      valueListenable: controller.messageNotifier,
                      builder: (_, msg, __) => Text(
                        msg,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<double>(
                valueListenable: controller.progress,
                builder: (_, value, __) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: value,
                      backgroundColor: Colors.grey.shade700,
                      color: Colors.blue,
                      minHeight: 6,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
      duration: const Duration(seconds: 8),
    ));
  }

  Future<void> _simulateProgress(ToastController controller) async {
    for (var i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (controller.isDisposed) return;
      controller.update(
        progressValue: i / 10,
        message: 'Uploading… ${(i * 10)}%',
      );
    }
    if (!controller.isDisposed) {
      controller.success('Upload complete!');
      await Future.delayed(const Duration(seconds: 2));
      if (!controller.isDisposed) controller.dismiss();
    }
  }

  /// Show a minimal notification-style toast.
  void _showNotificationToast() {
    ToastKit.show(ToastEvent.custom(
      builder: (context, controller) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(0xFF6C63FF),
              child: Text('JD', style: TextStyle(color: Colors.white)),
            ),
            title: Text(
              'John Doe',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('Sent you a message: "Hey! Are you free?"'),
            trailing: Text(
              'now',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
          ),
        );
      },
      position: ToastPosition.top,
      duration: const Duration(seconds: 4),
    ));
  }

  /// Show a toast with action buttons using a custom builder.
  void _showActionToast() {
    ToastKit.show(ToastEvent.custom(
      builder: (context, controller) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.delete_forever, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Delete this item?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'This action cannot be undone.',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: controller.dismiss,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      controller.dismiss();
                      ToastKit.success('Item deleted');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      duration: const Duration(seconds: 10),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom UI'),
        actions: const [
          SeeCodeButton(
            title: 'Custom UI Toasts',
            description: 'Custom builders with full widget control, progress tracking, and action buttons.',
            code: _customUiCode,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Custom builders give you full control over toast rendering. '
            'Each example demonstrates a different approach.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _showBrandedToast,
            icon: const Icon(Icons.palette),
            label: const Text('Branded Feature Toast'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _showProgressToast,
            icon: const Icon(Icons.upload),
            label: const Text('Upload Progress Toast'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _showNotificationToast,
            icon: const Icon(Icons.chat_bubble),
            label: const Text('Notification-Style Toast'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _showActionToast,
            icon: const Icon(Icons.delete),
            label: const Text('Confirmation Action Toast'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => ToastKit.dismissAll(),
            child: const Text('Dismiss All'),
          ),
        ],
      ),
    );
  }
}

const _customUiCode = '''// Branded toast with gradient
ToastKit.custom(builder: (context, controller) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF6C63FF), Color(0xFF3F3D99)],
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(children: [
      Icon(Icons.auto_awesome, color: Colors.white),
      Text('New Feature!', style: TextStyle(color: Colors.white)),
      IconButton(
        icon: Icon(Icons.close, color: Colors.white54),
        onPressed: controller.dismiss,
      ),
    ]),
  );
});

// Progress toast with ToastController
ToastKit.show(ToastEvent.custom(
  builder: (context, controller) {
    _simulateProgress(controller);
    return Container(/* progress UI */);
  },
  duration: Duration(seconds: 8),
));

Future<void> _simulateProgress(ToastController ctrl) async {
  for (var i = 1; i <= 10; i++) {
    await Future.delayed(Duration(milliseconds: 400));
    if (ctrl.isDisposed) return;
    ctrl.update(progressValue: i / 10, message: 'Uploading… \${i * 10}%');
  }
  ctrl.success('Upload complete!');
}''';
