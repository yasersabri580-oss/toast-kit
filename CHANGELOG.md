# Changelog

## [2.1.0] - Comprehensive Builder Demo & ToastService Example

### Added
- **`example/lib/mock/custom_variants.dart`** — Three production-quality `CustomToastVariantBuilder` implementations (`PaymentSuccessVariant`, `SystemErrorVariant`, `NotificationBannerVariant`) demonstrating the extensible variant system.
- **`example/lib/services/toast_service.dart`** — A centralized `ToastService` singleton showing best practices for multi-channel initialization, custom variant registration, per-channel variant assignment, config-based and custom rules, progress/loading toast lifecycle, and runtime rule management.
- **`example/lib/toast_demo/toast_builder_demo.dart`** — An interactive demo screen covering:
  - Multi-channel toasts (default, payment, system, notification)
  - Custom variant registration and per-channel assignment
  - Per-event variant override (e.g., glassmorphism on payment channel)
  - Config-based and custom rules with real-time feedback
  - Progress/loading toast lifecycle (start → update → success/fail)
  - Runtime rule management (add, remove, reset stats)
  - "See Code" modals with copy-paste-ready snippets for every feature

### Changed
- **README.md** — Replaced the minimal example app section with a comprehensive, multi-step guide covering custom variants, channel definitions, initialization with rules, and usage patterns. Updated folder structure to reflect new files.
- **Dashboard** — Added "Builder Demo" entry linking to the new `ToastBuilderDemo` screen.
- **Router** — Added `/toast/builder` route for the new demo.

## [2.0.0] - Extensible Custom Toast Variants

### Added
- **`CustomToastVariantBuilder`** — abstract base class for creating reusable, named toast variants. Define a variant once, register it, and use it across the entire app without code duplication.
- **`CustomVariantRegistry`** — central registry for storing and looking up custom variants by name. Supports registration, unregistration, and idempotent overrides.
- **`ToastKit.registerVariant(variant)`** — register a `CustomToastVariantBuilder` instance so it can be referenced by name.
- **`ToastKit.unregisterVariant(name)`** — remove a registered custom variant.
- **`ToastKit.isVariantRegistered(name)`** — check whether a custom variant is registered.
- **`ToastKit.variantRegistry`** — access the underlying `CustomVariantRegistry`.
- **`ToastKit.configure(variants: [...])`** — batch-register custom variants (alongside plugins).
- **`customVariantName`** parameter on `ToastEvent`, `ToastEvent.success()`, `ToastEvent.error()`, `ToastEvent.warning()`, `ToastEvent.info()`, `ToastEvent.loading()` — reference a registered custom variant by name.
- **`customVariantName`** field on `ToastChannel` — assign a custom variant to an entire channel so all toasts on that channel use it automatically.
- **`customVariantName`** parameter on `ChannelHandle.success()`, `.error()`, `.warning()`, `.info()` — per-call custom variant override on the fluent channel API.
- **`VariantFactory.resolveAndBuild()`** — new method implementing the full rendering precedence chain (customBuilder > customVariantName > channel customVariantName > variant enum > channel defaultVariant > type default).
- Full rendering precedence documentation in code comments and README.

### Deprecated
- **`ToastType.custom`** — with the extensible variant system, there is no longer a need for a catch-all "custom" type. Use any standard `ToastType` with `customVariantName` instead. Will be removed in a future release.
- **`ToastState.custom`** — same rationale as `ToastType.custom`. Use standard states instead.

### Migration Guide
1. **Replace `ToastEvent.custom(builder: myBuilder)`** with either:
   - A registered `CustomToastVariantBuilder` (recommended for reusable styling):
     ```dart
     ToastKit.registerVariant(MyVariant());
     ToastKit.success('Done!', customVariantName: 'my_variant');
     ```
   - A standard `ToastEvent` with `customBuilder` (for one-off cases):
     ```dart
     ToastKit.show(ToastEvent(type: ToastType.success, customBuilder: myBuilder));
     ```
2. **Replace `ToastType.custom`** references with the appropriate standard type (`success`, `error`, `warning`, `info`).
3. **Replace `ToastState.custom`** references with the appropriate standard state.
4. **Assign custom variants to channels** by setting `customVariantName` on `ToastChannel` instead of building custom UIs in each screen.

### No Breaking Changes
- All existing APIs continue to work. The `ToastType.custom` and `ToastState.custom` values are deprecated but not removed.
- The `customBuilder` parameter on `ToastEvent` continues to work and takes the highest rendering priority.

## [1.0.0] - Initial Stable Release
