import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';

class KpiTile extends StatelessWidget {
  const KpiTile({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.primary;

    return GlassCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: tint.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: tint, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: AppTextStyles.numericLarge.copyWith(color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.bodySmall),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: theme.textTheme.labelSmall),
          ],
        ],
      ),
    );
  }
}
