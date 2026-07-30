import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Frosted-glass container: the signature surface for dashboard KPI tiles,
/// AI insight cards, and POS side panels.
///
/// Uses a real backdrop blur (not just a translucent color) so it reads as
/// glassmorphism over gradients/images, and falls back gracefully to a
/// plain tinted card on surfaces where blur would be wasted (e.g. flat
/// list rows) — pass [blur: false] there.
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20,
    this.blur = true,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final radius = BorderRadius.circular(borderRadius);

    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.glassFill(brightness),
        borderRadius: radius,
        border: Border.all(color: AppColors.glassBorder(brightness)),
      ),
      child: child,
    );

    if (!blur) return content;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: content,
      ),
    );
  }
}
