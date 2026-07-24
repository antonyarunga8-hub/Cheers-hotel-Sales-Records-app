import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/order.dart';
import '../services/firestore_service.dart';
import '../services/printer_service.dart';
import '../main.dart' show kRestaurantName;

/// Desktop-only screen showing mobile orders pending receipt printing.
/// The till operator can print individual orders or batch-print all.
class PrintQueueScreen extends StatelessWidget {
  const PrintQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final printer = context.read<PrinterService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Print Queue')),
      body: StreamBuilder<List<Order>>(
        stream: firestore.watchPendingPrintQueue(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.print_disabled,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  const Text('No pending orders to print.'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderPrintCard(
                order: order,
                firestore: firestore,
                printer: printer,
              );
            },
          );
        },
      ),
      floatingActionButton: StreamBuilder<List<Order>>(
        stream: firestore.watchPendingPrintQueue(),
        builder: (context, snapshot) {
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () =>
                _printAll(context, orders, firestore, printer),
            icon: const Icon(Icons.print),
            label: Text('Print All (${orders.length})'),
          );
        },
      ),
    );
  }

  Future<void> _printAll(
    BuildContext context,
    List<Order> orders,
    FirestoreService firestore,
    PrinterService printer,
  ) async {
    int successCount = 0;
    int failCount = 0;

    for (final order in orders) {
      final result = await printer.printReceipt(
        order,
        restaurantName: kRestaurantName,
      );
      if (result == PrintResult.success) {
        await firestore.markReceiptPrinted(order.id);
        successCount++;
      } else {
        failCount++;
      }
    }

    if (context.mounted) {
      final msg = failCount == 0
          ? 'Printed $successCount orders successfully'
          : 'Printed $successCount, failed $failCount';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: failCount == 0 ? null : Colors.orange,
      ));
    }
  }
}

class _OrderPrintCard extends StatelessWidget {
  final Order order;
  final FirestoreService firestore;
  final PrinterService printer;

  const _OrderPrintCard({
    required this.order,
    required this.firestore,
    required this.printer,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('MMM d, HH:mm').format(order.timestamp);
    final itemsSummary =
        order.items.map((e) => '${e.qty}x ${e.name}').join(', ');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Order #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.source == OrderSource.mobile
                        ? 'Mobile'
                        : 'Desktop',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSecondaryContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(timeStr,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey)),
            const SizedBox(height: 10),
            Text(itemsSummary),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'KES ${order.total.toStringAsFixed(0)}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _printSingle(context),
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Print'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printSingle(BuildContext context) async {
    final result = await printer.printReceipt(
      order,
      restaurantName: kRestaurantName,
    );
    if (result == PrintResult.success) {
      await firestore.markReceiptPrinted(order.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order printed successfully')),
        );
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Print failed — check printer connection'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
