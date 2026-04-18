import 'package:flutter/material.dart';

import '../utils/responsive/responsive_helper.dart';

/// Applies responsive padding based on the current screen size.
///
/// On desktop, content is centered with a max width of [maxWidth].
class AdaptivePadding extends StatelessWidget {
  const AdaptivePadding({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveHelper.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final hPadding = ResponsiveHelper.horizontalPadding(context);
    final vPadding = ResponsiveHelper.verticalPadding(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: hPadding,
            vertical: vPadding,
          ),
          child: child,
        ),
      ),
    );
  }
}
