import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PieChartWidget extends StatelessWidget {
  final Map<String, double> totals;

  const PieChartWidget({super.key, required this.totals});

  @override
  Widget build(BuildContext context) {
    if (totals.isEmpty) {
      return const Center(child: Text('No Data'));
    }

    final totalAmount = totals.values.fold(0.0, (a, b) => a + b);
    final entries = totals.entries.toList();

    return SizedBox(
      height: 300,
      child: PieChart(
        PieChartData(
          centerSpaceRadius: 50,
          sectionsSpace: 3,
          sections: entries.map((entry) {
            final percent = entry.value / totalAmount * 100;
            return PieChartSectionData(
              value: entry.value,
              radius: 90,
              title: '${percent.toStringAsFixed(0)}%',
              titleStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14),
            );
          }).toList(),
        ),
      ),
    );
  }
}
