import 'package:flutter/material.dart';
import '../events/toast_event.dart';

/// Base class for user-defined toast variant builders.
///
/// Extend this class to create reusable, named toast variants that can be
/// registered once and assigned to channels or individual toast events.
///
/// ## Example
///
/// ```dart
/// class PaymentSuccessVariant extends CustomToastVariantBuilder {
///   @override
///   String get name => 'payment_success';
///
///   @override
///   Widget build(BuildContext context, ToastEvent event, ToastController controller) {
///     return Container(
///       padding: const EdgeInsets.all(16),
///       decoration: BoxDecoration(
///         color: Colors.green.shade50,
///         borderRadius: BorderRadius.circular(12),
///         border: Border.all(color: Colors.green),
///       ),
///       child: Row(
///         children: [
///           const Icon(Icons.payment, color: Colors.green),
///           const SizedBox(width: 12),
///           Expanded(child: Text(event.message ?? '')),
///         ],
///       ),
///     );
///   }
/// }
/// ```
///
/// Register the variant with ToastKit:
///
/// ```dart
/// ToastKit.registerVariant(PaymentSuccessVariant());
/// ```
///
/// Then use it by name:
///
/// ```dart
/// ToastKit.success('Payment received!', customVariantName: 'payment_success');
/// ```
///
/// Or assign it to a channel:
///
/// ```dart
/// ToastKit.registerChannel(
///   const ToastChannel(
///     id: 'payment',
///     label: 'Payment',
///     customVariantName: 'payment_success',
///   ),
/// );
/// ```
///
/// ## Precedence Rules
///
/// When multiple rendering strategies are specified, ToastKit resolves them
/// in the following order (highest priority first):
///
/// 1. **Explicit `customBuilder`** — a one-off builder passed directly on the
///    event always wins. Use this for truly unique, single-use toast UIs.
/// 2. **Custom variant (by name)** — a registered [CustomToastVariantBuilder]
///    referenced via `customVariantName` on the event or its channel.
/// 3. **Built-in variant (enum)** — a [ToastVariant] enum value resolved by
///    [VariantFactory].
///
/// This means an explicit builder is a per-event escape hatch that overrides
/// everything, while custom variants are the recommended way to centralise
/// reusable toast styling across the app.
abstract class CustomToastVariantBuilder {
  /// Unique name for this variant.
  ///
  /// Must be non-empty and unique across all registered variants. Names are
  /// case-sensitive. By convention, use `snake_case` (e.g. `'payment_success'`).
  String get name;

  /// Build the widget for this variant.
  ///
  /// Called by the rendering pipeline when this variant is resolved for a
  /// toast event. The [controller] allows the widget to dismiss, pause, or
  /// update the toast.
  Widget build(
    BuildContext context,
    ToastEvent event,
    ToastController controller,
  );
}
