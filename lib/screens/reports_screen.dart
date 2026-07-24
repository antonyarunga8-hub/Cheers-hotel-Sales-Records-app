import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../services/firestore_service.dart';
import '../widgets/sales_chart.dart';
import 'order_history_screen.dart';

enum _Period { today, week, month }

/// Reporting dashboard — today/week/month sales, top items, combined
/// across desktop and mobile-sourced orders (doc §7.4).
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  _Period _period = _Period.today;

  (DateTime, DateTime) _range() {
    final now = DateTime.now();
    switch (_period) {
      case _Period.today:
        final start = DateTime(now.year, now.month, now.day);
        return (start, start.add(const Duration(days: 1)));
      case _Period.week:
        final start = now.subtract(Duration(days: now.weekday - 1));
        final startDay = DateTime(start.year, start.month, start.day);
        return (startDay, startDay.add(const Duration(days: 7)));
      case _Period.month:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1);
        return (start, end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final (start, end) = _range();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Order History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<_Period>(
              segments: const [
                ButtonSegment(value: _Period.today, label: Text('Today')),
                ButtonSegment(value: _Period.week, label: Text('This Week')),
                ButtonSegment(value: _Period.month, label: Text('This Month')),
              ],
              selected: {_period},
              onSelectionChanged: (s) => setState(() => _period = s.first),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Order>>(
              stream: firestore.watchOrdersBetween(start, end),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final orders = snapshot.data ?? [];
                final totalSales =
                    orders.fold<double>(0, (sum, o) => sum + o.total);
                final desktopCount =
                    orders.where((o) => o.source == OrderSource.desktop).length;
                final mobileCount = orders.length - desktopCount;

                final topItems = <String, int>{};
                for (final o in orders) {
                  for (final line in o.items) {
                    topItems[line.name] = (topItems[line.name] ?? 0) + line.qty;
                  }
                }
                final sortedTop = topItems.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Sales chart — only show for week/month when there's data
                    if (_period != _Period.today && orders.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SalesChart(orders: orders),
                      ),

                    _StatCard(
                      icon: Icons.attach_money,
                      label: 'Total Sales',
                      value: 'KES ${NumberFormat('#,##0').format(totalSales)}',
                    ),
                    _StatCard(
                      icon: Icons.receipt,
                      label: 'Orders',
                      value: '${orders.length}',
                    ),
                    _StatCard(
                      icon: Icons.devices,
                      label: 'By Source',
                      value:
                          'Desktop: $desktopCount  •  Mobile: $mobileCount',
                    ),
                    const SizedBox(height: 16),
                    const Text('Top Items',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ...sortedTop.take(5).map(
                          (e) => ListTile(
                            leading:
                                const Icon(Icons.star, color: Colors.amber),
                            title: Text(e.key),
                            trailing: Text('${e.value} sold'),
                          ),
                        ),
                    if (sortedTop.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child:
                            Text('No sales recorded for this period yet.'),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(label),
        trailing:
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
