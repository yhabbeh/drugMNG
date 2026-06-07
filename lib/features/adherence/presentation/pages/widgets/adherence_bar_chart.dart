import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:drug/features/adherence/domain/entities/daily_adherence_point.dart';

final class AdherenceBarChart extends StatelessWidget {
  const AdherenceBarChart({super.key, required this.points});

  final List<DailyAdherencePoint> points;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (points.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'No data',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }

    final maxY = points
        .map((p) => p.taken)
        .fold<int>(0, (m, v) => v > m ? v : m)
        .toDouble();
    final chartMaxY = (maxY < 4 ? 4 : maxY + 1).toDouble();

    final groupWidth = points.length <= 7
        ? 18.0
        : points.length <= 30
            ? 7.0
            : 2.5;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: chartMaxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: chartMaxY / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: cs.outlineVariant.withValues(alpha: 0.4),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: chartMaxY / 4,
                getTitlesWidget: (value, _) => Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= points.length) {
                    return const SizedBox.shrink();
                  }
                  if (points.length > 14 && i % 7 != 0) {
                    return const SizedBox.shrink();
                  }
                  if (points.length > 7 && i % 3 != 0) {
                    return const SizedBox.shrink();
                  }
                  final d = points[i].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('M/d').format(d),
                      style: TextStyle(
                        fontSize: 9,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          barGroups: [
            for (var i = 0; i < points.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: points[i].taken.toDouble(),
                    color: points[i].missed > 0
                        ? cs.error
                        : points[i].taken > 0
                            ? cs.primary
                            : cs.surfaceContainerHighest,
                    width: groupWidth,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
