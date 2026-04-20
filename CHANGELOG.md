# Changelog

## [2.2.0] - Full-Featured Toast Builder UI

### Added
- **Channels Tab** (`example/lib/toast_demo/builder/channel_builder_tab.dart`) — Interactive channel management with full CRUD operations:
  - Add, edit, and remove toast channels
  - Configure all `ToastChannel` properties: id, label, maxVisible, defaultPriority, defaultPosition, defaultDuration, defaultAnimation, defaultVariant, customVariantName, enabled
  - Per-channel `ChannelConfig` policies: deduplication, throttling, interrupt behavior, queue limits
- **Variants Tab** (`example/lib/toast_demo/builder/variant_builder_tab.dart`) — Variant management and assignment:
  - Register custom variant names with quick-add for common examples
  - Assign built-in or custom variants to any channel
  - Visual gallery of all 12 built-in variant types
  - Variant precedence documentation in tooltips
- **Rules Tab** (`example/lib/toast_demo/builder/rules_builder_tab.dart`) — Rule configuration:
  - Config-based rules (RuleConfig): error threshold, deduplication window, max triggers per channel
  - Custom rules (ToastRule): condition types (error count, total count, window-based, warnings), action types (info/warning/error/action toasts), persistence and dismiss settings
- **Full Code Generator** (`example/lib/toast_demo/builder/full_code_generator.dart`) — Complete, production-ready Dart code generation:
  - Channel definitions as `const ToastChannel(...)` declarations
  - Initialization function with `ToastKit.init(...)` and channel registration
  - Custom variant registration scaffolding with class stubs
  - Config-based and custom rule setup in `_configureRules()`
  - Usage examples with both direct and fluent channel API
- **Builder Data Models** (`example/lib/toast_demo/builder/builder_models.dart`) — Type-safe models for all builder state:
  - `ChannelModel`, `ChannelConfigModel`, `RuleConfigModel`, `CustomRuleModel`
  - `BuilderConfiguration` with `toJson()`/`fromJson()` for serialization
  - Enum types for rule conditions and actions
- **Import/Export** — Export builder configuration as JSON to clipboard; import previously exported configurations to restore state
- **Full Setup Code Section** in Preview tab — generates complete initialization code alongside the single-toast code

### Changed
- **Toast Configurator Screen** — Expanded from 5 tabs to 8 tabs (Content, Style, Animation, Behavior, Channels, Variants, Rules, Preview)
- **App Bar** — Added import/export action buttons alongside randomize and reset
- **Preview Tab** — Now includes "Full Setup Code" section that generates complete channel/variant/rule initialization code

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
