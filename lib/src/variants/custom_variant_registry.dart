
import 'custom_variant_builder.dart';

/// Global registry for user-defined custom toast variants.
///
/// Stores [CustomToastVariantBuilder] instances keyed by their [name].
/// Registered variants can be referenced by name from [ToastEvent],
/// [ToastChannel], or per-call overrides without modifying ToastKit's core.
///
/// ## Example
///
/// ```dart
/// final registry = CustomVariantRegistry();
/// registry.register(PaymentSuccessVariant());
/// registry.register(NotificationBannerVariant());
///
/// // Look up by name
/// final variant = registry['payment_success'];
/// ```
///
/// The registry is safe to use from any isolate and does not hold widget
/// references — only builder instances that produce widgets on demand.
class CustomVariantRegistry {
  final Map<String, CustomToastVariantBuilder> _variants = {};

  /// Register a custom variant. Replaces any existing variant with the same
  /// name (idempotent override).
  ///
  /// Throws [ArgumentError] if [variant.name] is empty.
  void register(CustomToastVariantBuilder variant) {
    if (variant.name.isEmpty) {
      throw ArgumentError.value(
        variant.name,
        'variant.name',
        'Custom variant name must not be empty.',
      );
    }
    _variants[variant.name] = variant;
  }

  /// Unregister a variant by name.
  void unregister(String name) {
    _variants.remove(name);
  }

  /// Look up a variant by name. Returns `null` if not registered.
  CustomToastVariantBuilder? operator [](String name) => _variants[name];

  /// Whether a variant with the given name is registered.
  bool isRegistered(String name) => _variants.containsKey(name);

  /// All registered variant names.
  Iterable<String> get variantNames => _variants.keys;

  /// Number of registered variants.
  int get count => _variants.length;

  /// Clear all registrations.
  void clear() {
    _variants.clear();
  }

  /// Returns a debug description of all registered variants.
  @override
  String toString() {
    return 'CustomVariantRegistry(${_variants.keys.join(', ')})';
  }
}
