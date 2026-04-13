import 'dart:async';

import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

import '../widgets/cards/feature_card.dart';
import '../widgets/buttons/demo_button.dart';

/// A comprehensive showcase screen that demonstrates every toast type, variant,
/// position, and behavior offered by ToastKit.
class ToastShowcase extends StatefulWidget {
  const ToastShowcase({super.key});

  @override
  State<ToastShowcase> createState() => _ToastShowcaseState();
}

class _ToastShowcaseState extends State<ToastShowcase> {
  // ---------------------------------------------------------------------------
  // Toast Types
  // ---------------------------------------------------------------------------

  void _showSuccess() {
    ToastKit.success(
      'Operation completed successfully!',
      title: 'Success',
    );
  }

  void _showError() {
    ToastKit.error(
      'Something went wrong. Please try again.',
      title: 'Error',
    );
  }

  void _showWarning() {
    ToastKit.warning(
      'Your session will expire in 5 minutes.',
      title: 'Warning',
    );
  }

  void _showInfo() {
    ToastKit.info(
      'A new version is available for download.',
      title: 'Info',
    );
  }

  // ---------------------------------------------------------------------------
  // Toast Variants
  // ---------------------------------------------------------------------------

  void _showVariant(ToastVariant variant, String name) {
    ToastKit.show(ToastEvent(
      type: ToastType.info,
      message: '$name variant toast',
      title: name,
      variant: variant,
    ));
  }

  // ---------------------------------------------------------------------------
  // Toast Positions
  // ---------------------------------------------------------------------------

  void _showAtPosition(ToastPosition position, String label) {
    ToastKit.show(ToastEvent(
      type: ToastType.info,
      message: 'Displayed at $label',
      position: position,
    ));
  }

  // ---------------------------------------------------------------------------
  // Custom Builders
  // ---------------------------------------------------------------------------

  void _showBrandedToast() {
    ToastKit.custom(
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
                color: const Color(0xFF6366F1).withAlpha(80),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Branded Toast',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Custom gradient background with shadow',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                onPressed: controller.dismiss,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationToast() {
    ToastKit.custom(
      duration: const Duration(seconds: 5),
      builder: (context, controller) {
        final theme = Theme.of(context);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withAlpha(80),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFF10B981),
                child: Text('JD', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'John Doe',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sent you a new message 📩',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'now',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Action Toasts
  // ---------------------------------------------------------------------------

  void _showUndoToast() {
    ToastKit.show(ToastEvent(
      type: ToastType.info,
      message: 'Item deleted',
      duration: const Duration(seconds: 5),
      actions: [
        ToastAction(
          label: 'Undo',
          onPressed: () {
            ToastKit.success('Item restored');
          },
        ),
      ],
    ));
  }

  void _showConfirmCancelToast() {
    ToastKit.show(ToastEvent(
      type: ToastType.warning,
      message: 'Discard unsaved changes?',
      title: 'Confirm',
      persistent: true,
      dismissible: false,
      actions: [
        ToastAction(
          label: 'Cancel',
          onPressed: () {
            ToastKit.info('Cancelled');
          },
        ),
        ToastAction(
          label: 'Discard',
          color: Colors.red,
          onPressed: () {
            ToastKit.error('Changes discarded');
          },
        ),
      ],
    ));
  }

  // ---------------------------------------------------------------------------
  // Loading & Progress
  // ---------------------------------------------------------------------------

  void _showLoadingToSuccess() {
    final ctrl = ToastKit.showLoading('Loading data…');
    Future.delayed(const Duration(seconds: 2), () {
      ctrl.success('Data loaded successfully!');
    });
  }

  void _showLoadingToError() {
    final ctrl = ToastKit.showLoading('Connecting to server…');
    Future.delayed(const Duration(seconds: 2), () {
      ctrl.error('Connection timed out');
    });
  }

  void _showProgressUpdates() {
    final ctrl = ToastKit.showLoading('Uploading… 0%');
    const steps = [0.2, 0.45, 0.7, 0.9, 1.0];
    const labels = ['20%', '45%', '70%', '90%', '100%'];
    var tick = 0;

    Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (tick < steps.length) {
        ctrl.update(
          message: 'Uploading… ${labels[tick]}',
          progressValue: steps[tick],
        );
        tick++;
      } else {
        timer.cancel();
        ctrl.success('Upload complete!');
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Toast Showcase'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTypesSection(),
          const SizedBox(height: 12),
          _buildVariantsSection(),
          const SizedBox(height: 12),
          _buildPositionsSection(),
          const SizedBox(height: 12),
          _buildCustomBuildersSection(),
          const SizedBox(height: 12),
          _buildActionToastsSection(),
          const SizedBox(height: 12),
          _buildLoadingProgressSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section Builders
  // ---------------------------------------------------------------------------

  Widget _buildTypesSection() {
    return FeatureCard(
      title: 'Toast Types',
      subtitle: 'Standard semantic toast types',
      icon: Icons.category_outlined,
      iconColor: Colors.deepPurple,
      children: [
        DemoButton(
          label: 'Success',
          icon: Icons.check_circle_outline,
          color: Colors.green,
          onPressed: _showSuccess,
        ),
        DemoButton(
          label: 'Error',
          icon: Icons.error_outline,
          color: Colors.red,
          onPressed: _showError,
        ),
        DemoButton(
          label: 'Warning',
          icon: Icons.warning_amber_rounded,
          color: Colors.amber,
          onPressed: _showWarning,
        ),
        DemoButton(
          label: 'Info',
          icon: Icons.info_outline,
          color: Colors.blue,
          onPressed: _showInfo,
        ),
      ],
    );
  }

  Widget _buildVariantsSection() {
    return FeatureCard(
      title: 'Toast Variants',
      subtitle: 'Visual style presets',
      icon: Icons.style_outlined,
      iconColor: Colors.teal,
      children: [
        DemoButton(
          label: 'Minimal',
          icon: Icons.minimize,
          onPressed: () => _showVariant(ToastVariant.minimal, 'Minimal'),
        ),
        DemoButton(
          label: 'Material',
          icon: Icons.widgets_outlined,
          onPressed: () => _showVariant(ToastVariant.material, 'Material'),
        ),
        DemoButton(
          label: 'iOS',
          icon: Icons.phone_iphone,
          onPressed: () => _showVariant(ToastVariant.ios, 'iOS'),
        ),
        DemoButton(
          label: 'Glassmorphism',
          icon: Icons.blur_on,
          onPressed: () =>
              _showVariant(ToastVariant.glassmorphism, 'Glassmorphism'),
        ),
        DemoButton(
          label: 'Gradient',
          icon: Icons.gradient,
          onPressed: () => _showVariant(ToastVariant.gradient, 'Gradient'),
        ),
        DemoButton(
          label: 'Floating Card',
          icon: Icons.credit_card,
          onPressed: () =>
              _showVariant(ToastVariant.floatingCard, 'Floating Card'),
        ),
        DemoButton(
          label: 'Compact',
          icon: Icons.compress,
          onPressed: () => _showVariant(ToastVariant.compact, 'Compact'),
        ),
        DemoButton(
          label: 'Full Width',
          icon: Icons.width_full,
          onPressed: () => _showVariant(ToastVariant.fullWidth, 'Full Width'),
        ),
      ],
    );
  }

  Widget _buildPositionsSection() {
    return FeatureCard(
      title: 'Toast Positions',
      subtitle: 'Control where toasts appear',
      icon: Icons.open_with_rounded,
      iconColor: Colors.indigo,
      children: [
        DemoButton(
          label: 'Top',
          icon: Icons.vertical_align_top,
          onPressed: () => _showAtPosition(ToastPosition.top, 'Top'),
        ),
        DemoButton(
          label: 'Bottom',
          icon: Icons.vertical_align_bottom,
          onPressed: () => _showAtPosition(ToastPosition.bottom, 'Bottom'),
        ),
        DemoButton(
          label: 'Top Left',
          icon: Icons.north_west,
          onPressed: () =>
              _showAtPosition(ToastPosition.topLeft, 'Top Left'),
        ),
        DemoButton(
          label: 'Top Right',
          icon: Icons.north_east,
          onPressed: () =>
              _showAtPosition(ToastPosition.topRight, 'Top Right'),
        ),
        DemoButton(
          label: 'Bottom Left',
          icon: Icons.south_west,
          onPressed: () =>
              _showAtPosition(ToastPosition.bottomLeft, 'Bottom Left'),
        ),
        DemoButton(
          label: 'Bottom Right',
          icon: Icons.south_east,
          onPressed: () =>
              _showAtPosition(ToastPosition.bottomRight, 'Bottom Right'),
        ),
        DemoButton(
          label: 'Center',
          icon: Icons.center_focus_strong,
          onPressed: () => _showAtPosition(ToastPosition.center, 'Center'),
        ),
      ],
    );
  }

  Widget _buildCustomBuildersSection() {
    return FeatureCard(
      title: 'Custom Builders',
      subtitle: 'Fully custom toast UI',
      icon: Icons.brush_outlined,
      iconColor: Colors.orange,
      children: [
        DemoButton(
          label: 'Branded Toast',
          icon: Icons.auto_awesome,
          color: const Color(0xFF6366F1),
          onPressed: _showBrandedToast,
        ),
        DemoButton(
          label: 'Notification Style',
          icon: Icons.notifications_active_outlined,
          color: const Color(0xFF10B981),
          onPressed: _showNotificationToast,
        ),
      ],
    );
  }

  Widget _buildActionToastsSection() {
    return FeatureCard(
      title: 'Action Toasts',
      subtitle: 'Toasts with interactive buttons',
      icon: Icons.touch_app_outlined,
      iconColor: Colors.pink,
      children: [
        DemoButton(
          label: 'Undo Action',
          icon: Icons.undo,
          onPressed: _showUndoToast,
        ),
        DemoButton(
          label: 'Confirm / Cancel',
          icon: Icons.help_outline,
          onPressed: _showConfirmCancelToast,
        ),
      ],
    );
  }

  Widget _buildLoadingProgressSection() {
    return FeatureCard(
      title: 'Loading & Progress',
      subtitle: 'Stateful toast transitions',
      icon: Icons.hourglass_bottom_rounded,
      iconColor: Colors.cyan,
      children: [
        DemoButton(
          label: 'Loading → Success',
          icon: Icons.check,
          color: Colors.green,
          onPressed: _showLoadingToSuccess,
        ),
        DemoButton(
          label: 'Loading → Error',
          icon: Icons.close,
          color: Colors.red,
          onPressed: _showLoadingToError,
        ),
        DemoButton(
          label: 'Progress with Updates',
          icon: Icons.trending_up,
          color: Colors.cyan,
          onPressed: _showProgressUpdates,
        ),
      ],
    );
  }
}
