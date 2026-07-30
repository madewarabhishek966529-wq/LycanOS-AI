import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized typography scale.
///
/// Uses Inter for UI text (clean, highly legible at small sizes on dense
/// dashboard screens) — swap the base font here if you add a licensed
/// display font under assets/fonts.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base({
    required double size,
    required FontWeight weight,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static final TextStyle displayLarge = _base(size: 40, weight: FontWeight.w700, letterSpacing: -0.5);
  static final TextStyle displayMedium = _base(size: 32, weight: FontWeight.w700, letterSpacing: -0.4);
  static final TextStyle headlineLarge = _base(size: 26, weight: FontWeight.w700);
  static final TextStyle headlineMedium = _base(size: 22, weight: FontWeight.w600);
  static final TextStyle titleLarge = _base(size: 18, weight: FontWeight.w600);
  static final TextStyle titleMedium = _base(size: 16, weight: FontWeight.w600);
  static final TextStyle bodyLarge = _base(size: 16, weight: FontWeight.w400, height: 1.5);
  static final TextStyle bodyMedium = _base(size: 14, weight: FontWeight.w400, height: 1.5);
  static final TextStyle bodySmall = _base(size: 12, weight: FontWeight.w400, height: 1.4);
  static final TextStyle labelLarge = _base(size: 14, weight: FontWeight.w600, letterSpacing: 0.2);
  static final TextStyle labelSmall = _base(size: 11, weight: FontWeight.w500, letterSpacing: 0.3);
  static final TextStyle numericLarge = _base(size: 30, weight: FontWeight.w700, letterSpacing: -0.5);
}
