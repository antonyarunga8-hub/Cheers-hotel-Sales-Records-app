import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/order.dart';

/// Bar chart showing daily sales totals for the past 7 days.
/// Must be given a constrained height by the parent (e.g., SizedBox).
class SalesChart extends StatelessWidget {
  final List<Order> orders;

  const SalesChart({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final chartData = _generateChartData(context, now);

    double maxY = 0;
    for (var group in chartData) {
      if (group.barRods.first.toY > maxY) {
        maxY = group.barRods.first.toY;
      }
    }
    maxY = maxY > 0 ? maxY * 1.2 : 1000;

    return SizedBox(
      height: 250,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Weekly Sales',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => Colors.black87,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            'KES ${NumberFormat('#,##0').format(rod.toY)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            final idx = value.toInt();
                            if (idx < 0 || idx > 6) {
                              return const SizedBox.shrink();
                            }
                            final date =
                                now.subtract(Duration(days: 6 - idx));
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                DateFormat('E').format(date),
                                style: const TextStyle(fontSize: 11),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          getTitlesWidget: (value, _) {
                            if (value == 0) return const SizedBox.shrink();
                            return Text(
                              NumberFormat.compact().format(value),
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY > 0 ? maxY / 4 : 250,
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: chartData,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _generateChartData(
      BuildContext context, DateTime now) {
    final color = Theme.of(context).colorScheme.primary;
    final groups = <BarChartGroupData>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayTotal = orders
          .where((o) =>
              o.timestamp.year == date.year &&
              o.timestamp.month == date.month &&
              o.timestamp.day == date.day)
          .fold(0.0, (sum, o) => sum + o.total);

      groups.add(BarChartGroupData(
        x: 6 - i,
        barRods: [
          BarChartRodData(
            toY: dayTotal,
            color: color,
            width: 14,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      ));
    }
    return groups;
  }
}
