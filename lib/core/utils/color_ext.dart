import 'package:flutter/material.dart';

extension ColorExtension on Color {
  String toHex() => '#${red.toRadixString(16).padLeft(2, '0')}'
        '${green.toRadixString(16).padLeft(2, '0')}'
        '${blue.toRadixString(16).padLeft(2, '0')}';

  String toHexWithAlpha() => '#${alpha.toRadixString(16).padLeft(2, '0')}'
        '${red.toRadixString(16).padLeft(2, '0')}'
        '${green.toRadixString(16).padLeft(2, '0')}'
        '${blue.toRadixString(16).padLeft(2, '0')}';
}

extension StringColorExtension on String {
  Color toColor() {
    String hex = this;
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }
    
    if (hex.length == 6) {
      hex = 'FF$hex'; // Add alpha channel
    }
    
    if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
    
    throw FormatException('Invalid hex color: $this');
  }

  bool isValidHexColor() {
    try {
      toColor();
      return true;
    } catch (e) {
      return false;
    }
  }
}

class AppColors {
  static const List<Color> eventColors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFFEF4444), // Red
    Color(0xFF10B981), // Green
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFF84CC16), // Lime
    Color(0xFFF97316), // Orange
    Color(0xFF6B7280), // Gray
  ];

  static const Color primary = Color(0xFF3B82F6);
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color accent = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF1E293B);
  static const Color onSurface = Color(0xFF1E293B);
}



