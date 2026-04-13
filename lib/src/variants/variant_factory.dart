import 'package:flutter/material.dart';
import '../core/toast_config.dart';
import '../events/toast_event.dart';
import 'minimal_toast.dart';
import 'material_toast.dart';
import 'ios_toast.dart';
import 'glassmorphism_toast.dart';
import 'gradient_toast.dart';
import 'floating_card_toast.dart';
import 'compact_toast.dart';
import 'full_width_toast.dart';
import 'loading_toast.dart';
import 'progress_toast.dart';
import 'action_toast.dart';
import 'debug_toast.dart';

/// Maps [ToastVariant] enums to concrete widget implementations.
class VariantFactory {
  VariantFactory._();

  /// Build the widget for the given [variant].
  static Widget build(
    ToastVariant variant,
    ToastEvent event,
    ToastController controller,
  ) {
    switch (variant) {
      case ToastVariant.minimal:
        return MinimalToast(event: event, controller: controller);
      case ToastVariant.material:
        return MaterialToast(event: event, controller: controller);
      case ToastVariant.ios:
        return IosToast(event: event, controller: controller);
      case ToastVariant.glassmorphism:
        return GlassmorphismToast(event: event, controller: controller);
      case ToastVariant.gradient:
        return GradientToast(event: event, controller: controller);
      case ToastVariant.floatingCard:
        return FloatingCardToast(event: event, controller: controller);
      case ToastVariant.compact:
        return CompactToast(event: event, controller: controller);
      case ToastVariant.fullWidth:
        return FullWidthToast(event: event, controller: controller);
      case ToastVariant.loading:
        return LoadingToast(event: event, controller: controller);
      case ToastVariant.progress:
        return ProgressToast(event: event, controller: controller);
      case ToastVariant.action:
      case ToastVariant.retry:
      case ToastVariant.undo:
        return ActionToast(event: event, controller: controller);
      case ToastVariant.debug:
        return DebugToast(event: event, controller: controller);
      // Variants that don't yet have a dedicated widget fall back to Material.
      case ToastVariant.neumorphism:
      case ToastVariant.blurredBackground:
      case ToastVariant.topBanner:
      case ToastVariant.bottomSheet:
      case ToastVariant.inline:
      case ToastVariant.iconBased:
      case ToastVariant.textOnly:
      case ToastVariant.richContent:
      case ToastVariant.persistent:
      case ToastVariant.expandable:
      case ToastVariant.chatBubble:
      case ToastVariant.customBuilder:
        return MaterialToast(event: event, controller: controller);
    }
  }

  /// Return a sensible default variant for the given toast type.
  static ToastVariant defaultVariantForType(ToastType type) {
    switch (type) {
      case ToastType.loading:
        return ToastVariant.loading;
      case ToastType.custom:
        return ToastVariant.customBuilder;
      default:
        return ToastVariant.material;
    }
  }
}
