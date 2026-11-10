import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/journal_symptome_model.dart';
import '../services/journal_symptome_service.dart';
import '../theme/app_colors.dart';

/// Histogramme du nombre d'entrées du journal par jour.
class JournalBarChart extends StatelessWidget {
  final List<JourJournal> serie;
  final double height;

  const JournalBarChart({
    super.key,
    required this.serie,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    final maxCount = serie.fold<int>(
      0,
      (max, j) => j.nbEntrees > max ? j.nbEntrees : max,
    );
    final maxY = (maxCount == 0 ? 1 : maxCount).toDouble() + 0.5;

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: Colors.white10, strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 9),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= serie.length) {
                    return const SizedBox.shrink();
                  }
                  final labelEvery = serie.length > 14 ? 5 : 1;
                  if (index % labelEvery != 0 && index != serie.length - 1) {
                    return const SizedBox.shrink();
                  }
                  final d = serie[index].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${d.day}/${d.month}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 8),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (item) => const Color(0xFF0D2D5E),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final jour = serie[group.x];
                return BarTooltipItem(
                  '${jour.date.day}/${jour.date.month} : ${jour.nbEntrees} entrée(s)',
                  const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                );
              },
            ),
          ),
          barGroups: serie.asMap().entries.map((entry) {
            final i = entry.key;
            final jour = entry.value;
            final color = jour.fievre
                ? AppColors.danger
                : jour.nbEntrees > 0
                    ? const Color(0xFF4DAAFF)
                    : const Color(0x22FFFFFF);
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: jour.nbEntrees.toDouble(),
                  color: color,
                  width: serie.length > 14 ? 6 : 12,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Courbe de la température mesurée dans le journal.
class TemperatureLineChart extends StatelessWidget {
  final List<JournalSymptomeModel> entrees;
  final double height;

  const TemperatureLineChart({
    super.key,
    required this.entrees,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    final points = entrees
        .where((e) => e.temperature != null)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'Aucune température mesurée',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ),
      );
    }

    final spots = points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.temperature!))
        .toList();

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (spots.length - 1).toDouble().clamp(1.0, 999.0).toDouble(),
          minY: 35,
          maxY: 41,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: Colors.white10, strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 38,
                color: const Color(0xFFE67E22).withValues(alpha: 0.55),
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
              HorizontalLine(
                y: 39,
                color: AppColors.danger.withValues(alpha: 0.55),
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
            ],
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}°',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 9),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  final labelEvery = points.length > 8 ? 3 : 1;
                  if (index % labelEvery != 0 && index != points.length - 1) {
                    return const SizedBox.shrink();
                  }
                  final d = points[index].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${d.day}/${d.month}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 8),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => const Color(0xFF0D2D5E),
              getTooltipItems: (touched) => touched.map((spot) {
                final e = points[spot.x.toInt()];
                return LineTooltipItem(
                  '${e.temperature!.toStringAsFixed(1)} °C\n'
                  '${e.date.day}/${e.date.month} · ${e.date.hour.toString().padLeft(2, '0')}h${e.date.minute.toString().padLeft(2, '0')}',
                  const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.2,
              color: const Color(0xFF4DAAFF),
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, _, _) {
                  final color = spot.y >= 39
                      ? AppColors.danger
                      : spot.y >= 38
                          ? const Color(0xFFE67E22)
                          : const Color(0xFF00C9A7);
                  return FlDotCirclePainter(
                    radius: 4,
                    color: color,
                    strokeColor: Colors.white,
                    strokeWidth: 1.4,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF4DAAFF).withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
