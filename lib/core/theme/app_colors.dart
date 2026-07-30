import 'package:flutter/material.dart';

/// LycanOS AI brand palette.
///
/// Primary is an indigo-violet gradient family (premium SaaS feel), with a
/// teal accent for positive/financial states and amber/red for warnings and
/// destructive actions.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryDark = Color(0xFF4834D4);
  static const Color secondary = Color(0xFF00D2B4);
  static const Color accent = Color(0xFFFF6B9D);

  // Gradients
  static const List<Color> primaryGradient = [
    Color(0xFF6C5CE7),
    Color(0xFF4834D4),
  ];
  static const List<Color> successGradient = [
    Color(0xFF00D2B4),
    Color(0xFF00B894),
  ];
  static const List<Color> warningGradient = [
    Color(0xFFFFBE55),
    Color(0xFFFF9F1C),
  ];

  // Semantic
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFFF9F1C);
  static const Color error = Color(0xFFE84855);
  static const Color info = Color(0xFF4A9DFF);

  // Light theme surfaces
  static const Color lightBackground = Color(0xFFF7F7FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEFEFF8);
  static const Color lightOnSurface = Color(0xFF1A1A2E);
  static const Color lightBorder = Color(0xFFE4E4F0);

  // Dark theme surfaces
  static const Color darkBackground = Color(0xFF0F0F1A);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkSurfaceVariant = Color(0xFF232338);
  static const Color darkOnSurface = Color(0xFFF2F2FA);
  static const Color darkBorder = Color(0xFF2E2E45);

  // Glassmorphism helpers
  static Color glassFill(Brightness brightness) => brightness == Brightness.dark
      ? Colors.white.withOpacity(0.06)
      : Colors.white.withOpacity(0.55);

  static Color glassBorder(Brightness brightness) => brightness == Brightness.dark
      ? Colors.white.withOpacity(0.10)
      : Colors.white.withOpacity(0.70);
}
