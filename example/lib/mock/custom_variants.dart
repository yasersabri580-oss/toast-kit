import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

// =============================================================================
// Custom Toast Variants
//
// Reusable, named toast variant builders that can be registered once and
// referenced by name across the app. These demonstrate the extensible
// variant system introduced in ToastKit 2.0.
//
// Rendering Precedence (highest → lowest):
//   1. customBuilder on event
//   2. customVariantName on event
//   3. Channel's customVariantName
//   4. variant (enum) on event
//   5. Channel's defaultVariant
//   6. Default for ToastType
// =============================================================================

/// A custom variant for payment success notifications.
///
/// Features a green-themed card with a payment icon, title, message,
/// and a dismiss button. Assigned to the payment channel by default.
class PaymentSuccessVariant extends CustomToastVariantBuilder {
  @override
  String get name => 'payment_success';

  @override
  Widget build(
    BuildContext context,
    ToastEvent event,
    ToastController controller,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              event.icon ?? Icons.payment_rounded,
              color: Colors.green.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (event.title != null)
                  Text(
                    event.title!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                      fontSize: 14,
                    ),
                  ),
                if (event.title != null) const SizedBox(height: 2),
                Text(
                  event.message ?? '',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.green.shade400, size: 20),
            onPressed: controller.dismiss,
          ),
        ],
      ),
    );
  }
}

/// A custom variant for system error notifications.
///
/// Features a dark-themed card with a red accent, suitable for critical
/// errors that require user attention. Assigned to the system channel.
class SystemErrorVariant extends CustomToastVariantBuilder {
  @override
  String get name => 'system_error';

  @override
  Widget build(
    BuildContext context,
    ToastEvent event,
    ToastController controller,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withAlpha(30),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(
              event.icon ?? Icons.error_outline_rounded,
              color: Colors.red.shade300,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (event.title != null)
                  Text(
                    event.title!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                if (event.title != null) const SizedBox(height: 2),
                Text(
                  event.message ?? '',
                  style: TextStyle(
                    color: Colors.red.shade100,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (event.dismissible)
            IconButton(
              icon: Icon(Icons.close, color: Colors.red.shade300, size: 20),
              onPressed: controller.dismiss,
            ),
        ],
      ),
    );
  }
}

/// A notification-banner style variant for general notifications.
///
/// Features a subtle card with a left accent bar, suitable for
/// informational messages across any channel.
class NotificationBannerVariant extends CustomToastVariantBuilder {
  @override
  String get name => 'notification_banner';

  @override
  Widget build(
    BuildContext context,
    ToastEvent event,
    ToastController controller,
  ) {
    final accentColor = switch (event.type) {
      ToastType.success => Colors.green,
      ToastType.error => Colors.red,
      ToastType.warning => Colors.orange,
      _ => const Color(0xFF6366F1),
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              event.icon ?? Icons.notifications_active_rounded,
              color: accentColor,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (event.title != null)
                    Text(
                      event.title!,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                      ),
                    ),
                  Text(
                    event.message ?? '',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(180),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                size: 18,
                color: Theme.of(context).colorScheme.outline,
              ),
              onPressed: controller.dismiss,
            ),
          ],
        ),
      ),
    );
  }
}
