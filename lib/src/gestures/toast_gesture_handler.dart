import 'package:flutter/material.dart';
import '../core/toast_config.dart';

/// Gesture wrapper for toast widgets.
///
/// Handles tap, long-press, double-tap, swipe dismiss with velocity
/// detection, drag, and hover (web/desktop) with timer pause/resume.
class ToastGestureHandler extends StatefulWidget {
  /// The toast content widget.
  final Widget child;

  /// Tap callback.
  final VoidCallback? onTap;

  /// Long-press callback.
  final VoidCallback? onLongPress;

  /// Double-tap callback.
  final VoidCallback? onDoubleTap;

  /// Called when swipe-dismiss animation completes.
  final VoidCallback? onSwipeDismiss;

  /// Called when user starts interacting (pause the auto-dismiss timer).
  final VoidCallback? onPauseTimer;

  /// Called when interaction ends (resume the auto-dismiss timer).
  final VoidCallback? onResumeTimer;

  /// Allowed swipe-dismiss direction(s).
  final SwipeDismissDirection swipeDismissDirection;

  /// Whether swipe-to-dismiss is enabled.
  final bool enableSwipeDismiss;

  /// Fraction of width/height to trigger a dismiss (0.0–1.0).
  final double swipeThreshold;

  /// Velocity (px/sec) that triggers an instant dismiss.
  final double velocityThreshold;

  /// Whether to pause the timer when the cursor hovers (web/desktop).
  final bool enableHover;

  const ToastGestureHandler({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.onSwipeDismiss,
    this.onPauseTimer,
    this.onResumeTimer,
    this.swipeDismissDirection = SwipeDismissDirection.horizontal,
    this.enableSwipeDismiss = true,
    this.swipeThreshold = 0.4,
    this.velocityThreshold = 700.0,
    this.enableHover = true,
  });

  @override
  State<ToastGestureHandler> createState() => _ToastGestureHandlerState();
}

class _ToastGestureHandlerState extends State<ToastGestureHandler>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  Offset _dragOffset = Offset.zero;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // Drag logic
  // -----------------------------------------------------------------------

  bool _isHorizontal(SwipeDismissDirection d) =>
      d == SwipeDismissDirection.left ||
      d == SwipeDismissDirection.right ||
      d == SwipeDismissDirection.horizontal ||
      d == SwipeDismissDirection.any;

  bool _isVertical(SwipeDismissDirection d) =>
      d == SwipeDismissDirection.up ||
      d == SwipeDismissDirection.down ||
      d == SwipeDismissDirection.vertical ||
      d == SwipeDismissDirection.any;

  void _onPanStart(DragStartDetails _) {
    widget.onPauseTimer?.call();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isDismissing) return;

    double dx = _dragOffset.dx;
    double dy = _dragOffset.dy;

    if (_isHorizontal(widget.swipeDismissDirection)) {
      dx += details.delta.dx;
    }
    if (_isVertical(widget.swipeDismissDirection)) {
      dy += details.delta.dy;
    }
    setState(() => _dragOffset = Offset(dx, dy));
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isDismissing) return;

    final size = context.size ?? const Size(300, 80);
    final velocityX = details.velocity.pixelsPerSecond.dx.abs();
    final velocityY = details.velocity.pixelsPerSecond.dy.abs();

    final fractionX = _dragOffset.dx.abs() / size.width;
    final fractionY = _dragOffset.dy.abs() / size.height;

    final shouldDismiss =
        (velocityX > widget.velocityThreshold ||
            velocityY > widget.velocityThreshold ||
            fractionX > widget.swipeThreshold ||
            fractionY > widget.swipeThreshold);

    if (shouldDismiss) {
      _dismiss();
    } else {
      _snapBack();
    }
  }

  void _dismiss() {
    _isDismissing = true;
    _slideController.forward().then((_) {
      widget.onSwipeDismiss?.call();
    });
  }

  void _snapBack() {
    setState(() => _dragOffset = Offset.zero);
    widget.onResumeTimer?.call();
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    Widget content = Transform.translate(
      offset: _dragOffset,
      child: Opacity(
        opacity: _isDismissing
            ? 0.0
            : (1.0 -
                (_dragOffset.distance /
                        (MediaQuery.of(context).size.width * 0.5))
                    .clamp(0.0, 0.6)),
        child: widget.child,
      ),
    );

    if (widget.enableSwipeDismiss) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onDoubleTap: widget.onDoubleTap,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: content,
      );
    } else {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onDoubleTap: widget.onDoubleTap,
        child: content,
      );
    }

    if (widget.enableHover) {
      content = MouseRegion(
        onEnter: (_) => widget.onPauseTimer?.call(),
        onExit: (_) => widget.onResumeTimer?.call(),
        child: content,
      );
    }

    return content;
  }
}
