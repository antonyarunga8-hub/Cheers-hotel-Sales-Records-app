import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';

class SalesChart extends StatelessWidget {
  final List<Order> orders;

  const SalesChart({Key? key, required this.orders}) : super(key: key);

  List<BarChartGroupData> _generateChartData(BuildContext context, DateTime now) {
    final List<BarChartGroupData> barGroups = [];
    final primaryColor = Theme.of(context).colorScheme.primary;

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayOrders = orders.where((o) =>
          o.timestamp.year == date.year &&
          o.timestamp.month == date.month &&
          o.timestamp.day == date.day);
      
      final dailyTotal = dayOrders.fold(0.0, (sum, o) => sum + o.total);

      barGroups.add(
        BarChartGroupData(
          x: 6 - i, // 0 to 6
          barRods: [
            BarChartRodData(
              toY: dailyTotal,
              color: primaryColor,
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }
    return barGroups;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final chartData = _generateChartData(context, now);
    
    // Calculate max Y for scaling
    double maxY = 0;
    for (var group in chartData) {
      if (group.barRods.first.toY > maxY) {
        maxY = group.barRods.first.toY;
      }
    }
    // Add some padding to top, fallback to 100 if no sales
    maxY = maxY > 0 ? maxY * 1.2 : 100;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Weekly Sales',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.black87,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final formattedValue = NumberFormat.currency(
                          symbol: 'KES ',
                          decimalDigits: 0,
                        ).format(rod.toY);
                        return BarTooltipItem(
                          formattedValue,
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final int index = value.toInt();
                          if (index < 0 || index > 6) return const SizedBox.shrink();
                          final date = now.subtract(Duration(days: 6 - index));
                          final dayLabel = DateFormat('E').format(date);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              dayLabel,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const Text('');
                          return Text(
                            NumberFormat.compact().format(value),
                            style: const TextStyle(fontSize: 10),
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
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY / 4) > 0 ? (maxY / 4) : 25,
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
