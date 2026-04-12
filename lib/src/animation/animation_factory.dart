import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/toast_config.dart';
import 'animation_curves.dart';

/// Abstract base for toast animations.
///
/// Implement this to create fully custom enter / exit animation pairs.
abstract class ToastAnimation {
  /// Wrap [child] with the enter animation driven by [animation].
  Widget buildEnterAnimation(Widget child, Animation<double> animation);

  /// Wrap [child] with the exit animation driven by [animation].
  Widget buildExitAnimation(Widget child, Animation<double> animation);

  /// Suggested duration for this animation.
  Duration get duration;
}

// ---------------------------------------------------------------------------
// Built-in implementations
// ---------------------------------------------------------------------------

class FadeAnimation extends ToastAnimation {
  @override
  Duration get duration => const Duration(milliseconds: 300);

  @override
  Widget buildEnterAnimation(Widget child, Animation<double> animation) {
    return FadeTransition(opacity: animation, child: child);
  }

  @override
  Widget buildExitAnimation(Widget child, Animation<double> animation) {
    return FadeTransition(opacity: animation, child: child);
  }
}

class SlideFromTopAnimation extends ToastAnimation {
  @override
  Duration get duration => const Duration(milliseconds: 350);

  @override
  Widget buildEnterAnimation(Widget child, Animation<double> animation) {
    final offset =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
    return SlideTransition(position: offset, child: child);
  }

  @override
  Widget buildExitAnimation(Widget child, Animation<double> animation) {
    final offset =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1))
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeIn));
    return SlideTransition(position: offset, child: child);
  }
}

class SlideFromBottomAnimation extends ToastAnimation {
  @override
  Duration get duration => const Duration(milliseconds: 350);

  @override
  Widget buildEnterAnimation(Widget child, Animation<double> animation) {
    final offset =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
    return SlideTransition(position: offset, child: child);
  }

  @override
  Widget buildExitAnimation(Widget child, Animation<double> animation) {
    final offset =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, 1))
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeIn));
    return SlideTransition(position: offset, child: child);
  }
}

class SlideFromLeftAnimation extends ToastAnimation {
  @override
  Duration get duration => const Duration(milliseconds: 350);

  @override
  Widget buildEnterAnimation(Widget child, Animation<double> animation) {
    final offset =
        Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
    return SlideTransition(position: offset, child: child);
  }

  @override
  Widget buildExitAnimation(Widget child, Animation<double> animation) {
    final offset =
        Tween<Offset>(begin: Offset.zero, end: const Offset(-1, 0))
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeIn));
    return SlideTransition(position: offset, child: child);
  }
}

class SlideFromRightAnimation extends ToastAnimation {
  @override
  Duration get duration => const Duration(milliseconds: 350);

  @override
  Widget buildEnterAnimation(Widget child, Animation<double> animation) {
    final offset =
        Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
    return SlideTransition(position: offset, child: child);
  }

  @override
  Widget buildExitAnimation(Widget child, Animation<double> animation) {
    final offset =
        Tween<Offset>(begin: Offset.zero, end: const Offset(1, 0))
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeIn));
    return SlideTransition(position: offset, child: child);
  }
}

class ScaleAnimation extends ToastAnimation {
  @override
  Duration get duration => const Duration(milliseconds: 300);

  @override
  Widget buildEnterAnimation(Widget child, Animation<double> animation) {
    final scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
    );
    return ScaleTransition(scale: scale, child: child);
  }

  @override
  Widget buildExitAnimation(Widget child, Animation<double> animation) {
    final scale = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeIn),
    );
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(scale: scale, child: child),
    );
  }
}

class BounceAnimation extends ToastAnimation {
  @override
  Duration get duration => const Duration(milliseconds: 500);

  @override
  Widget buildEnterAnimation(Widget child, Animation<double> animation) {
    final scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animation, curve: const BounceCurve()),
    );
    return ScaleTransition(scale: scale, child: child);
  }

  @override
  Widget buildExitAnimation(Widget child, Animation<double> animation) {
    return FadeTransition(opacity: animation, child: child);
  }
}

class ElasticAnimationImpl extends ToastAnimation {
  @override
  Duration get duration => const Duration(milliseconds: 600);

  @override
  Widget buildEnterAnimation(Widget child, Animation<double> animation) {
    final scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animation, curve: const ElasticCurve()),
    );
    return ScaleTransition(scale: scale, child: child);
  }

  @override
  Widget buildExitAnimation(Widget child, Animation<double> animation) {
    return FadeTransition(opacity: animation, child: child);
  }
}

class SpringAnimationImpl extends ToastAnimation {
  @override
  Duration get duration => const Duration(milliseconds: 500);

  @override
  Widget buildEnterAnimation(Widget child, Animation<double> animation) {
    final offset =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
      CurvedAnimation(parent: animation, curve: const SpringCurve()),
    );
    return SlideTransition(position: offset, child: child);
  }

  @override
  Widget buildExitAnimation(Widget child, Animation<double> animation) {
    final offset =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1)).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeIn),
    );
    return SlideTransition(position: offset, child: child);
  }
}

class ShakeAnimation extends ToastAnimation {
  @override
  Duration get duration => const Duration(milliseconds: 500);

  @override
  Widget buildEnterAnimation(Widget child, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final shake = math.sin(animation.value * math.pi * 4) *
            (1 - animation.value) *
            10.0;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: Opacity(opacity: animation.value, child: child),
        );
      },
      child: child,
    );
  }

  @override
  Widget buildExitAnimation(Widget child, Animation<double> animation) {
    return FadeTransition(opacity: animation, child: child);
  }
}

class BlurAnimation extends ToastAnimation {
  @override
  Duration get duration => const Duration(milliseconds: 400);

  @override
  Widget buildEnterAnimation(Widget child, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final sigma = (1 - animation.value) * 8.0;
        return ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: Opacity(opacity: animation.value, child: child),
        );
      },
      child: child,
    );
  }

  @override
  Widget buildExitAnimation(Widget child, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final sigma = (1 - animation.value) * 8.0;
        return ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: Opacity(opacity: animation.value, child: child),
        );
      },
      child: child,
    );
  }
}

class GlowAnimation extends ToastAnimation {
  @override
  Duration get duration => const Duration(milliseconds: 500);

  @override
  Widget buildEnterAnimation(Widget child, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final glow = animation.value * 12.0;
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.white.withAlpha((animation.value * 80).toInt()),
                blurRadius: glow,
                spreadRadius: glow / 3,
              ),
            ],
          ),
          child: Opacity(opacity: animation.value, child: child),
        );
      },
      child: child,
    );
  }

  @override
  Widget buildExitAnimation(Widget child, Animation<double> animation) {
    return FadeTransition(opacity: animation, child: child);
  }
}

// ---------------------------------------------------------------------------
// Helper — AnimatedBuilder that accepts an explicit animation & builder.
// ---------------------------------------------------------------------------

class AnimatedBuilder extends StatelessWidget {
  final Listenable animation;
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder._internal(
      animation: animation,
      builder: builder,
      child: child,
    );
  }

  /// Internal redirect to Flutter's [AnimatedBuilder].
  static Widget _internal({
    required Listenable animation,
    required Widget Function(BuildContext, Widget?) builder,
    Widget? child,
  }) {
    // Use Flutter's built-in AnimatedBuilder via its super (ListenableBuilder).
    return _RebuildOnChange(
      listenable: animation,
      builder: builder,
      child: child,
    );
  }
}

class _RebuildOnChange extends StatefulWidget {
  final Listenable listenable;
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const _RebuildOnChange({
    required this.listenable,
    required this.builder,
    this.child,
  });

  @override
  State<_RebuildOnChange> createState() => _RebuildOnChangeState();
}

class _RebuildOnChangeState extends State<_RebuildOnChange> {
  @override
  void initState() {
    super.initState();
    widget.listenable.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(_RebuildOnChange old) {
    super.didUpdateWidget(old);
    if (old.listenable != widget.listenable) {
      old.listenable.removeListener(_onChanged);
      widget.listenable.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.child);
  }
}

// ---------------------------------------------------------------------------
// Factory
// ---------------------------------------------------------------------------

/// Creates [ToastAnimation] instances from [ToastAnimationType] enums.
class AnimationFactory {
  AnimationFactory._();

  /// Return the built-in animation for the given [type].
  static ToastAnimation fromType(ToastAnimationType type) {
    switch (type) {
      case ToastAnimationType.fade:
        return FadeAnimation();
      case ToastAnimationType.slideFromTop:
        return SlideFromTopAnimation();
      case ToastAnimationType.slideFromBottom:
        return SlideFromBottomAnimation();
      case ToastAnimationType.slideFromLeft:
        return SlideFromLeftAnimation();
      case ToastAnimationType.slideFromRight:
        return SlideFromRightAnimation();
      case ToastAnimationType.scale:
        return ScaleAnimation();
      case ToastAnimationType.bounce:
        return BounceAnimation();
      case ToastAnimationType.elastic:
        return ElasticAnimationImpl();
      case ToastAnimationType.spring:
        return SpringAnimationImpl();
      case ToastAnimationType.shake:
        return ShakeAnimation();
      case ToastAnimationType.blur:
        return BlurAnimation();
      case ToastAnimationType.glow:
        return GlowAnimation();
      case ToastAnimationType.custom:
        return FadeAnimation(); // fallback
    }
  }

  /// Create a fully custom animation from enter / exit builder callbacks.
  static ToastAnimation custom({
    required Widget Function(Widget, Animation<double>) enterBuilder,
    required Widget Function(Widget, Animation<double>) exitBuilder,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return _CustomAnimation(
      enterBuilder: enterBuilder,
      exitBuilder: exitBuilder,
      animDuration: duration,
    );
  }
}

class _CustomAnimation extends ToastAnimation {
  final Widget Function(Widget, Animation<double>) enterBuilder;
  final Widget Function(Widget, Animation<double>) exitBuilder;
  final Duration animDuration;

  _CustomAnimation({
    required this.enterBuilder,
    required this.exitBuilder,
    required this.animDuration,
  });

  @override
  Duration get duration => animDuration;

  @override
  Widget buildEnterAnimation(Widget child, Animation<double> animation) {
    return enterBuilder(child, animation);
  }

  @override
  Widget buildExitAnimation(Widget child, Animation<double> animation) {
    return exitBuilder(child, animation);
  }
}
