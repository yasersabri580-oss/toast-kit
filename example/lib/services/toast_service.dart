import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

import '../mock/custom_variants.dart';

// =============================================================================
// ToastService — Production-Quality, Multi-Channel ToastKit Integration
//
// This service demonstrates:
//   • Multi-channel initialization (default, payment, system, notification)
//   • Custom variant registration and per-channel assignment
//   • Config-based and custom rules with stats-driven conditions
//   • Progress/loading toast lifecycle (start → update → complete/fail)
//   • Fluent channel API usage
//   • Runtime rule management (add/remove/reset)
//
// Usage:
//   1. Call `ToastService.instance.init(navigatorKey)` once after the first
//      frame is rendered.
//   2. Call any `show*` method from anywhere — no BuildContext needed.
//   3. Call `ToastService.instance.dispose()` when the app shuts down.
// =============================================================================

/// A centralized service that configures ToastKit with channels, variants,
/// rules, and plugins, and exposes typed methods for every notification
/// scenario in the app.
class ToastService {
  ToastService._();

  /// Singleton instance.
  static final ToastService instance = ToastService._();

  // ---------------------------------------------------------------------------
  // Channel IDs — constants for type-safe channel references
  // ---------------------------------------------------------------------------

  /// Default channel for general-purpose toasts.
  static const String channelDefault = 'default';

  /// Payment-specific channel (max 1 visible, urgent priority).
  static const String channelPayment = 'payment';

  /// System/error channel for critical alerts.
  static const String channelSystem = 'system';

  /// Notification channel for informational banners.
  static const String channelNotification = 'notification';

  // ---------------------------------------------------------------------------
  // Channel definitions
  // ---------------------------------------------------------------------------

  /// Default channel — uses Material variant, allows 2 visible toasts.
  static const defaultChannel = ToastChannel(
    id: channelDefault,
    label: 'Default Channel',
    defaultVariant: ToastVariant.material,
    maxVisible: 2,
    defaultDuration: Duration(seconds: 3),
    defaultPosition: ToastPosition.top,
    defaultAnimation: ToastAnimationType.fade,
    defaultPriority: ToastPriority.normal,
    enabled: true,
  );

  /// Payment channel — uses the custom `payment_success` variant, max 1
  /// visible toast, urgent priority for immediate attention.
  static const paymentChannel = ToastChannel(
    id: channelPayment,
    label: 'Payment Channel',
    customVariantName: 'payment_success',
    maxVisible: 1,
    defaultPriority: ToastPriority.urgent,
    defaultDuration: Duration(seconds: 5),
    defaultPosition: ToastPosition.top,
    defaultAnimation: ToastAnimationType.slideFromTop,
    enabled: true,
  );

  /// System channel — uses the custom `system_error` variant for critical
  /// error presentation with high priority.
  static const systemChannel = ToastChannel(
    id: channelSystem,
    label: 'System Channel',
    customVariantName: 'system_error',
    maxVisible: 2,
    defaultPriority: ToastPriority.high,
    defaultDuration: Duration(seconds: 6),
    defaultPosition: ToastPosition.top,
    defaultAnimation: ToastAnimationType.slideFromTop,
    enabled: true,
  );

  /// Notification channel — uses the custom `notification_banner` variant
  /// for informational content.
  static const notificationChannel = ToastChannel(
    id: channelNotification,
    label: 'Notification Channel',
    customVariantName: 'notification_banner',
    maxVisible: 3,
    defaultPriority: ToastPriority.normal,
    defaultDuration: Duration(seconds: 4),
    defaultPosition: ToastPosition.top,
    defaultAnimation: ToastAnimationType.fade,
    enabled: true,
  );

  // ---------------------------------------------------------------------------
  // Custom variant instances
  // ---------------------------------------------------------------------------

  final _paymentSuccessVariant = PaymentSuccessVariant();
  final _systemErrorVariant = SystemErrorVariant();
  final _notificationBannerVariant = NotificationBannerVariant();

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initialize the ToastService and underlying ToastKit SDK.
  ///
  /// Must be called once, after the first frame is rendered
  /// (e.g. inside `addPostFrameCallback`).
  ///
  /// ```dart
  /// WidgetsBinding.instance.addPostFrameCallback((_) {
  ///   ToastService.instance.init(navigatorKey);
  /// });
  /// ```
  void init(GlobalKey<NavigatorState> navigatorKey) {
    // 1. Initialize ToastKit with global config and channels.
    ToastKit.init(
      navigatorKey: navigatorKey,
      config: const ToastConfig(
        defaultPosition: ToastPosition.top,
        maxVisibleToasts: 3,
        enableQueue: true,
        queueMode: QueueMode.fifo,
        maxQueueSize: 50,
      ),
      routerConfig: const RouterConfig(
        enableDeduplication: true,
        deduplicationWindow: Duration(seconds: 2),
        enableThrottling: true,
        throttleInterval: Duration(milliseconds: 300),
      ),
      channels: [
        defaultChannel,
        paymentChannel,
        systemChannel,
        notificationChannel,
      ],
    );

    // 2. Register custom variants so they can be referenced by name.
    ToastKit.configure(variants: [
      _paymentSuccessVariant,
      _systemErrorVariant,
      _notificationBannerVariant,
    ]);

    // 3. Set up rules for each channel.
    _configureRules();

    if (kDebugMode) {
      print('[ToastService] Initialized with channels: '
          '[$channelDefault, $channelPayment, $channelSystem, $channelNotification]');
      print('[ToastService] Custom variants registered: '
          '[${_paymentSuccessVariant.name}, '
          '${_systemErrorVariant.name}, '
          '${_notificationBannerVariant.name}]');
    }
  }

  // ---------------------------------------------------------------------------
  // Rules Configuration
  // ---------------------------------------------------------------------------

  /// Configure both config-based and custom rules for each channel.
  void _configureRules() {
    // ── Payment channel: config-based rule ──
    // Trigger after 3 payment errors within a 60-second window, max once.
    ToastKit.configureRule(
      channelPayment,
      const RuleConfig(
        errorThreshold: 3,
        deduplicateWindow: Duration(seconds: 60),
        maxTriggers: 1,
      ),
    );

    // ── Payment channel: custom rule — suggest alternative after 2 errors ──
    ToastKit.addRule(ToastRule(
      id: 'payment-suggest-alternative',
      channel: channelPayment,
      maxTriggers: 1,
      condition: (stats, event) => stats.errorCount >= 2,
      action: (context) {
        ToastKit.show(ToastEvent.info(
          message: 'Having trouble? Try a different payment method.',
          title: 'Payment Help',
          variant: ToastVariant.action,
          deduplicationKey: 'payment-help-suggestion',
          actions: [
            ToastAction(
              label: 'Switch Method',
              onPressed: () {
                ToastKit.success(
                  'Payment method updated',
                  channel: channelPayment,
                );
              },
            ),
          ],
          channel: channelPayment,
        ));
      },
    ));

    // ── System channel: error burst detection ──
    // Detect 5+ errors within 30 seconds.
    ToastKit.addRule(ToastRule(
      id: 'system-error-burst',
      channel: channelSystem,
      deduplicateWindow: const Duration(seconds: 60),
      condition: (stats, event) {
        return stats.errorsInWindow(const Duration(seconds: 30)) >= 5;
      },
      action: (context) {
        ToastKit.show(ToastEvent.error(
          message: 'Multiple system errors detected. '
              '${context.stats.errorCount} errors recorded.',
          title: 'Error Burst',
          persistent: true,
          dismissible: true,
          deduplicationKey: 'system-error-burst',
          channel: channelSystem,
        ));
      },
    ));

    // ── System channel: config-based threshold ──
    ToastKit.configureRule(
      channelSystem,
      const RuleConfig(
        errorThreshold: 5,
        deduplicateWindow: Duration(seconds: 30),
        maxTriggers: 2,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Toast Display Methods — Default Channel
  // ---------------------------------------------------------------------------

  /// Show a simple info toast on the default channel.
  void showInfoToast(String message, {String? title}) {
    ToastKit.info(
      message,
      title: title,
      channel: channelDefault,
      variant: ToastVariant.material,
    );
  }

  /// Show a success toast on the default channel.
  void showSuccessToast(String message, {String? title}) {
    ToastKit.success(
      message,
      title: title,
      channel: channelDefault,
    );
  }

  /// Show a warning toast on the default channel.
  void showWarningToast(String message, {String? title}) {
    ToastKit.warning(
      message,
      title: title,
      channel: channelDefault,
    );
  }

  /// Show an error toast on the default channel.
  void showErrorToast(String message, {String? title}) {
    ToastKit.error(
      message,
      title: title,
      channel: channelDefault,
    );
  }

  // ---------------------------------------------------------------------------
  // Toast Display Methods — Payment Channel
  // ---------------------------------------------------------------------------

  /// Show a payment success toast using the custom [PaymentSuccessVariant].
  ///
  /// The payment channel is configured with `customVariantName: 'payment_success'`,
  /// so all toasts on this channel automatically use that variant unless
  /// explicitly overridden.
  void showPaymentSuccess(String message) {
    ToastKit.channel(channelPayment).success(
      message,
      title: 'Payment Successful',
    );
  }

  /// Show a payment error toast on the payment channel.
  ///
  /// After 2 errors, the `payment-suggest-alternative` rule triggers
  /// automatically to show a help toast.
  void showPaymentError(String message) {
    ToastKit.channel(channelPayment).error(
      message,
      title: 'Payment Failed',
    );
  }

  // ---------------------------------------------------------------------------
  // Toast Display Methods — System Channel
  // ---------------------------------------------------------------------------

  /// Show a system error toast using the custom [SystemErrorVariant].
  void showSystemError(String message, {String? title}) {
    ToastKit.error(
      message,
      title: title ?? 'System Error',
      channel: channelSystem,
    );
  }

  /// Show a critical system error that cannot be dismissed by tap.
  void showCriticalError(String message) {
    ToastKit.show(ToastEvent(
      type: ToastType.error,
      message: message,
      title: 'Critical Error',
      icon: Icons.dangerous_rounded,
      persistent: true,
      dismissible: false,
      priority: ToastPriority.urgent,
      channel: channelSystem,
      actions: [
        ToastAction(
          label: 'Acknowledge',
          onPressed: () => ToastKit.dismissAll(),
        ),
      ],
    ));
  }

  // ---------------------------------------------------------------------------
  // Toast Display Methods — Notification Channel
  // ---------------------------------------------------------------------------

  /// Show a notification banner using the custom [NotificationBannerVariant].
  void showNotification(String message, {String? title}) {
    ToastKit.info(
      message,
      title: title,
      channel: channelNotification,
    );
  }

  // ---------------------------------------------------------------------------
  // Progress / Loading Toasts
  // ---------------------------------------------------------------------------

  /// Start a loading toast and return its controller for progress updates.
  ///
  /// ```dart
  /// final ctrl = ToastService.instance.showLoading('Processing…');
  /// try {
  ///   await doWork();
  ///   ctrl.success('Done!');
  /// } catch (e) {
  ///   ctrl.error('Failed: $e');
  /// }
  /// ```
  ToastController showLoading(String message, {String? channel}) {
    return ToastKit.showLoading(
      message,
      channel: channel ?? channelDefault,
    );
  }

  /// Simulate a file upload with progress updates.
  ///
  /// Returns the [ToastController] for external cancellation.
  ToastController simulateUpload({
    String fileName = 'document.pdf',
    int durationMs = 3000,
    bool shouldFail = false,
    int failAtPercent = 60,
  }) {
    final ctrl = ToastKit.showLoading('Uploading $fileName…');
    final stepMs = durationMs ~/ 20;

    Timer.periodic(Duration(milliseconds: stepMs), (timer) {
      final elapsed = timer.tick * stepMs;
      final pct = ((elapsed / durationMs) * 100).clamp(0, 100).round();

      if (ctrl.isDisposed) {
        timer.cancel();
        return;
      }

      if (shouldFail && pct >= failAtPercent) {
        timer.cancel();
        ctrl.error('Upload failed at $pct%');
        return;
      }

      ctrl.update(message: 'Uploading $fileName… $pct%');
      ctrl.progress.value = pct / 100;

      if (pct >= 100) {
        timer.cancel();
        ctrl.success('$fileName uploaded successfully!');
      }
    });

    return ctrl;
  }

  // ---------------------------------------------------------------------------
  // Rule Management
  // ---------------------------------------------------------------------------

  /// Add a custom rule at runtime.
  void addCustomRule(ToastRule rule) {
    ToastKit.addRule(rule);
    if (kDebugMode) {
      print('[ToastService] Rule added: ${rule.id} on ${rule.channel}');
    }
  }

  /// Remove a custom rule at runtime.
  void removeCustomRule(String ruleId) {
    ToastKit.removeRule(ruleId);
    if (kDebugMode) {
      print('[ToastService] Rule removed: $ruleId');
    }
  }

  /// Reset all rule stats while keeping rule definitions intact.
  void resetRuleStats() {
    ToastKit.ruleEngine.resetStats();
    if (kDebugMode) {
      print('[ToastService] Rule stats reset');
    }
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Release all resources. Call when the app shuts down.
  void dispose() {
    ToastKit.dispose();
  }
}
