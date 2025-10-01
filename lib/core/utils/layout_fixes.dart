import 'package:flutter/material.dart';
import 'package:calendario_familiar/core/utils/responsive_layout.dart';

class LayoutFixes {
  /// Corrige dropdowns que pueden causar overflow
  static Widget safeDropdown({
    required BuildContext context,
    required Widget child,
    double? maxWidth,
  }) => ResponsiveLayout.buildResponsiveDropdown(
      context: context,
      child: child,
      maxWidth: maxWidth,
    );

  /// Crea un Row seguro que se convierte en Wrap en pantallas pequeñas
  static Widget safeRow({
    required BuildContext context,
    required List<Widget> children,
    double spacing = 8.0,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) => ResponsiveLayout.buildResponsiveRow(
      context: context,
      children: children,
      spacing: spacing,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
    );

  /// Crea botones responsivos que se adaptan al tamaño de pantalla
  static Widget responsiveButton({
    required BuildContext context,
    required VoidCallback onPressed,
    required String text,
    Color? backgroundColor,
    Color? foregroundColor,
    Color? borderColor,
    double? width,
    double? height,
  }) => SizedBox(
      width: width ?? ResponsiveLayout.getResponsiveWidth(context, small: 0.4, medium: 0.3, large: 0.25),
      height: height ?? 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.white,
          foregroundColor: foregroundColor ?? Colors.black87,
          side: borderColor != null ? BorderSide(color: borderColor) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: ResponsiveLayout.getResponsiveFontSize(context, small: 12, medium: 14, large: 16),
          ),
        ),
      ),
    );

  /// Crea un contenedor con padding responsivo
  static Widget responsiveContainer({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? color,
    double? borderRadius,
  }) => Container(
      padding: padding ?? ResponsiveLayout.getResponsivePadding(context),
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius != null ? BorderRadius.circular(borderRadius) : null,
      ),
      child: child,
    );

  /// Crea un texto con tamaño responsivo
  static Widget responsiveText({
    required BuildContext context,
    required String text,
    double? smallSize,
    double? mediumSize,
    double? largeSize,
    Color? color,
    FontWeight? fontWeight,
    TextAlign? textAlign,
  }) => Text(
      text,
      style: TextStyle(
        fontSize: ResponsiveLayout.getResponsiveFontSize(
          context,
          small: smallSize ?? 12,
          medium: mediumSize ?? 14,
          large: largeSize ?? 16,
        ),
        color: color,
        fontWeight: fontWeight,
      ),
      textAlign: textAlign,
    );

  /// Crea un campo de texto responsivo
  static Widget responsiveTextField({
    required BuildContext context,
    required TextEditingController controller,
    String? hintText,
    String? labelText,
    int? maxLines,
    TextInputType? keyboardType,
    bool? enabled,
  }) => TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: ResponsiveLayout.getResponsivePadding(context),
      ),
      maxLines: maxLines ?? 1,
      keyboardType: keyboardType,
      enabled: enabled,
      style: TextStyle(
        fontSize: ResponsiveLayout.getResponsiveFontSize(context, small: 12, medium: 14, large: 16),
      ),
    );
}



