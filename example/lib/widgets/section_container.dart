import 'package:flutter/material.dart';

import '../utils/responsive/responsive_helper.dart';

/// A container that wraps content in a constrained-width, centered layout
/// with responsive padding and optional section title.
class SectionContainer extends StatelessWidget {
  const SectionContainer({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveHelper.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
