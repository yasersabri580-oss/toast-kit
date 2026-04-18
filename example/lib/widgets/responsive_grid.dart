import 'package:flutter/material.dart';

import '../utils/responsive/responsive_helper.dart';

/// A responsive grid that adapts columns based on screen size.
///
/// Mobile: single column, Tablet: 2 columns, Desktop: 3 columns.
/// Uses [LayoutBuilder] for accurate sizing.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.mainAxisSpacing = 12,
    this.crossAxisSpacing = 12,
    this.childAspectRatio,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  });

  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  /// If null, uses [SliverGridDelegateWithMaxCrossAxisExtent] for auto-sizing.
  final double? childAspectRatio;

  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsFor(context);
        final effectiveAspectRatio = childAspectRatio ?? _autoAspectRatio(constraints.maxWidth, columns);

        return GridView.builder(
          shrinkWrap: shrinkWrap,
          physics: physics,
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            childAspectRatio: effectiveAspectRatio,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }

  int _columnsFor(BuildContext context) {
    return switch (ResponsiveHelper.screenSize(context)) {
      ScreenSize.mobile => mobileColumns,
      ScreenSize.tablet => tabletColumns,
      ScreenSize.desktop => desktopColumns,
    };
  }

  double _autoAspectRatio(double maxWidth, int columns) {
    final cardWidth = (maxWidth - (crossAxisSpacing * (columns - 1))) / columns;
    // Target a reasonable card height based on width
    return cardWidth / (cardWidth < 200 ? 160 : 140);
  }
}
