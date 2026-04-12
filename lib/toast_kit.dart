/// ToastKit SDK — A production-grade Flutter notification framework.
///
/// ## Quick Start
///
/// ```dart
/// final navigatorKey = GlobalKey<NavigatorState>();
///
/// MaterialApp(navigatorKey: navigatorKey, home: MyApp());
///
/// ToastKit.init(navigatorKey: navigatorKey);
///
/// ToastKit.success('Done!');
/// ToastKit.error('Oops!');
///
/// // Stateful loading → success/error
/// final ctrl = ToastKit.showLoading('Saving…');
/// try {
///   await saveData();
///   ctrl.success('Saved!');
/// } catch (_) {
///   ctrl.error('Save failed');
/// }
/// ```
library toast_kit;

// Core
export 'src/core/toast_config.dart';
export 'src/core/toast_kit.dart';

// Events
export 'src/events/toast_event.dart';
export 'src/events/event_bus.dart';

// Queue
export 'src/queue/queue_manager.dart';

// Router
export 'src/router/notification_router.dart';
export 'src/router/router_config.dart';

// Overlay
export 'src/overlay/overlay_engine.dart';

// Animation
export 'src/animation/animation_curves.dart';
export 'src/animation/animation_factory.dart';

// Gestures
export 'src/gestures/toast_gesture_handler.dart';

// Theme
export 'src/theme/toast_theme.dart';

// Layout
export 'src/layout/toast_position_calculator.dart';

// Channels
export 'src/channels/toast_channel.dart';

// Persistence
export 'src/persistence/toast_persistence.dart';

// Stacking
export 'src/stacking/group_collapser.dart';

// Accessibility
export 'src/accessibility/toast_accessibility.dart';

// Variants
export 'src/variants/toast_variant_helpers.dart';
export 'src/variants/variant_factory.dart';
export 'src/variants/minimal_toast.dart';
export 'src/variants/material_toast.dart';
export 'src/variants/ios_toast.dart';
export 'src/variants/glassmorphism_toast.dart';
export 'src/variants/gradient_toast.dart';
export 'src/variants/floating_card_toast.dart';
export 'src/variants/compact_toast.dart';
export 'src/variants/full_width_toast.dart';
export 'src/variants/loading_toast.dart';
export 'src/variants/progress_toast.dart';
export 'src/variants/action_toast.dart';
export 'src/variants/debug_toast.dart';
