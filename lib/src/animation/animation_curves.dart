import 'dart:math' as math;
import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

/// Bouncy overshoot curve.
class BounceCurve extends Curve {
  const BounceCurve();

  @override
  double transformInternal(double t) {
    if (t < 0.5) {
      return 8.0 * t * t * t * t;
    } else {
      final f = (t - 1.0);
      return 1.0 - 8.0 * f * f * f * f;
    }
  }
}

/// Elastic overshoot curve.
class ElasticCurve extends Curve {
  final double period;
  const ElasticCurve({this.period = 0.4});

  @override
  double transformInternal(double t) {
    final s = period / 4.0;
    final postFix = math.pow(2.0, -10.0 * t);
    return (postFix * math.sin((t - s) * (2.0 * math.pi) / period) + 1.0)
        .toDouble();
  }
}

/// Physics-based spring curve.
class SpringCurve extends Curve {
  final double damping;
  final double stiffness;
  final double mass;

  const SpringCurve({
    this.damping = 12.0,
    this.stiffness = 180.0,
    this.mass = 1.0,
  });

  @override
  double transformInternal(double t) {
    final spring = SpringDescription(
      mass: mass,
      stiffness: stiffness,
      damping: damping,
    );
    final sim = SpringSimulation(spring, 0.0, 1.0, 0.0);
    return sim.x(t);
  }
}

/// Slight overshoot then settle.
class OvershootCurve extends Curve {
  final double tension;
  const OvershootCurve({this.tension = 2.0});

  @override
  double transformInternal(double t) {
    final s = t - 1.0;
    return s * s * ((tension + 1.0) * s + tension) + 1.0;
  }
}
