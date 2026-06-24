import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';

class BarChartWidget extends StatelessWidget {
  final Map<int, double> totals;

  const BarChartWidget({super.key, required this.totals});

  @override
  Widget build(BuildContext context) {
    if (totals.isEmpty) {
      return Center(child: Text('No data yet', style: GoogleFonts.inter(color: AC.textLight)));
    }

    final days = totals.keys.toList()..sort();
    final maxY = totals.values.reduce((a, b) => a > b ? a : b) * 1.3;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AC.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AC.primary.withValues(alpha: 0.5), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(color: AC.accent.withValues(alpha: 0.15), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, _) => Text(
                  '${value.toInt()}',
                  style: GoogleFonts.dmSans(fontSize: 10, color: AC.textLight),
                ),
              ),
            ),
          ),
          barGroups: days.map((day) => BarChartGroupData(
            x: day,
            barRods: [
              BarChartRodData(
                toY: totals[day]!,
                width: 10,
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  colors: [AC.accent, AC.primary],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ],
          )).toList(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AC.text,
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                '₹${rod.toY.toStringAsFixed(0)}',
                GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
