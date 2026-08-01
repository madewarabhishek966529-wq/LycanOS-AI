import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/dashboard_summary_entity.dart';
import '../../../../shared/widgets/glass_card.dart';

class RevenueChart extends StatelessWidget {
  const RevenueChart({required this.points, super.key});
  final List<RevenuePointEntity> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxRevenue = points.map((p) => p.revenue).fold<double>(0, (a, b) => a > b ? a : b);
    final safeMax = maxRevenue <= 0 ? 10.0 : maxRevenue * 1.2;

    return GlassCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Revenue — last 7 days', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: safeMax,
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= points.length) return const SizedBox.shrink();
                        final day = points[index].day;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('${day.day}/${day.month}', style: theme.textTheme.labelSmall),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots.map((spot) {
                      return LineTooltipItem('₹${spot.y.toStringAsFixed(0)}', theme.textTheme.bodySmall!);
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].revenue)],
                    isCurved: true,
                    color: theme.colorScheme.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: theme.colorScheme.primary.withOpacity(0.12)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
