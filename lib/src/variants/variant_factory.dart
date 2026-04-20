import 'package:flutter/material.dart';
import '../core/toast_config.dart';
import '../events/toast_event.dart';
import 'custom_variant_builder.dart';
import 'custom_variant_registry.dart';
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

/// Maps [ToastVariant] enums to concrete widget implementations and resolves
/// custom variants from the [CustomVariantRegistry].
///
/// ## Rendering Precedence
///
/// The [resolveAndBuild] method implements the full precedence chain:
///
/// 1. **Explicit `customBuilder`** on the event — always wins.
/// 2. **`customVariantName`** on the event — looked up in the registry.
/// 3. **Channel's `customVariantName`** — inherited from the channel config.
/// 4. **`variant`** (enum) on the event — resolved via [build].
/// 5. **Channel's `defaultVariant`** — inherited from the channel config.
/// 6. **Default for the event's `type`** — via [defaultVariantForType].
class VariantFactory {
  VariantFactory._();

  /// Build the widget for the given built-in [variant].
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
      // ignore: deprecated_member_use_from_same_package
      case ToastType.custom:
        return ToastVariant.customBuilder;
      default:
        return ToastVariant.material;
    }
  }

  /// Resolve the correct widget for a toast event using the full precedence
  /// chain, including custom variant registry lookups and channel fallbacks.
  ///
  /// Returns a [Widget] wrapped in a [Builder] so the build context is
  /// available at render time.
  ///
  /// The [channelCustomVariantName] and [channelDefaultVariant] parameters
  /// are optional overrides inherited from the event's channel.
  static Widget resolveAndBuild({
    required ToastEvent event,
    required ToastController controller,
    required CustomVariantRegistry registry,
    String? channelCustomVariantName,
    ToastVariant? channelDefaultVariant,
  }) {
    // 1. Explicit customBuilder always wins.
    if (event.customBuilder != null) {
      return Builder(
        builder: (ctx) => event.customBuilder!(ctx, controller),
      );
    }

    // 2. Event-level customVariantName.
    if (event.customVariantName != null) {
      final customVariant = registry[event.customVariantName!];
      if (customVariant != null) {
        return Builder(
          builder: (ctx) => customVariant.build(ctx, event, controller),
        );
      }
      // If the name is not found, fall through to next level.
    }

    // 3. Channel-level customVariantName.
    if (channelCustomVariantName != null) {
      final customVariant = registry[channelCustomVariantName];
      if (customVariant != null) {
        return Builder(
          builder: (ctx) => customVariant.build(ctx, event, controller),
        );
      }
    }

    // 4. Event-level built-in variant enum.
    if (event.variant != null) {
      return Builder(
        builder: (ctx) => build(event.variant!, event, controller),
      );
    }

    // 5. Channel-level default variant enum.
    if (channelDefaultVariant != null) {
      return Builder(
        builder: (ctx) => build(channelDefaultVariant, event, controller),
      );
    }

    // 6. Default for the event type.
    final defaultVariant = defaultVariantForType(event.type);
    return Builder(
      builder: (ctx) => build(defaultVariant, event, controller),
    );
  }
}
