import 'package:flutter/material.dart';

import '../utils/responsive/responsive_helper.dart';

/// A scrollable body wrapper that centers content and constrains width
/// for responsive layouts. Used by feature screens to ensure consistent
/// responsive behavior across mobile, tablet, and desktop.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({
    super.key,
    required this.children,
    this.maxWidth = ResponsiveHelper.maxContentWidth,
  });

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final hPadding = ResponsiveHelper.horizontalPadding(context);
    final vPadding = ResponsiveHelper.verticalPadding(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: hPadding,
            vertical: vPadding,
          ),
          children: children,
        ),
      ),
    );
  }
}
