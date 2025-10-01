import 'package:flutter/material.dart';

class ResponsiveLayout {
  static bool isSmallScreen(BuildContext context) => MediaQuery.of(context).size.width < 600;

  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }

  static bool isLargeScreen(BuildContext context) => MediaQuery.of(context).size.width >= 1200;

  static double getResponsiveWidth(BuildContext context, {double small = 0.9, double medium = 0.8, double large = 0.7}) {
    if (isSmallScreen(context)) {
      return MediaQuery.of(context).size.width * small;
    } else if (isMediumScreen(context)) {
      return MediaQuery.of(context).size.width * medium;
    } else {
      return MediaQuery.of(context).size.width * large;
    }
  }

  static Widget buildResponsiveRow({
    required BuildContext context,
    required List<Widget> children,
    double spacing = 8.0,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    if (isSmallScreen(context)) {
      // En pantallas pequeñas, usar Wrap para evitar overflow
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: children,
      );
    } else {
      // En pantallas más grandes, usar Row
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      );
    }
  }

  static Widget buildResponsiveDropdown({
    required BuildContext context,
    required Widget child,
    double? maxWidth,
  }) => ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? getResponsiveWidth(context, small: 0.28, medium: 0.25, large: 0.2),
      ),
      child: child,
    );

  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isSmallScreen(context)) {
      return const EdgeInsets.all(8.0);
    } else if (isMediumScreen(context)) {
      return const EdgeInsets.all(12.0);
    } else {
      return const EdgeInsets.all(16.0);
    }
  }

  static double getResponsiveFontSize(BuildContext context, {double small = 12, double medium = 14, double large = 16}) {
    if (isSmallScreen(context)) {
      return small;
    } else if (isMediumScreen(context)) {
      return medium;
    } else {
      return large;
    }
  }
}



