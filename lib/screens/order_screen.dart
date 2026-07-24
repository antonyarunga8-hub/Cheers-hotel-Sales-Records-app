import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../main.dart' show kRestaurantName;
import '../models/menu_item.dart';
import '../models/order.dart' as model;
import '../models/payment_method.dart';
import '../services/firestore_service.dart';
import '../services/printer_service.dart';
import '../utils/order_number_generator.dart';
import '../widgets/menu_item_card.dart';

/// Order recording flow — works identically on desktop and mobile
/// (doc §7.2). Desktop additionally triggers an immediate print job.
class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final Map<String, int> _cart = {};
  Map<String, MenuItem> _itemsById = {};
  bool _submitting = false;
  PaymentMethod _paymentMethod = PaymentMethod.cash;

  double get _total {
    double sum = 0;
    _cart.forEach((id, qty) {
      final item = _itemsById[id];
      if (item != null) sum += item.price * qty;
    });
    return sum;
  }

  void _addToCart(String itemId) {
    setState(() => _cart[itemId] = (_cart[itemId] ?? 0) + 1);
  }

  void _removeFromCart(String itemId) {
    setState(() {
      final current = _cart[itemId] ?? 0;
      if (current <= 1) {
        _cart.remove(itemId);
      } else {
        _cart[itemId] = current - 1;
      }
    });
  }

  /// Show confirmation dialog before recording the sale.
  Future<void> _confirmAndRecord() async {
    if (_cart.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._cart.entries.map((e) {
              final item = _itemsById[e.key];
              if (item == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${e.value}x ${item.name}')),
                    Text('KES ${(item.price * e.value).toStringAsFixed(0)}'),
                  ],
                ),
              );
            }),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('KES ${_total.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            // Payment method selector
            SegmentedButton<PaymentMethod>(
              segments: const [
                ButtonSegment(
                    value: PaymentMethod.cash,
                    label: Text('Cash'),
                    icon: Icon(Icons.money)),
                ButtonSegment(
                    value: PaymentMethod.mpesa,
                    label: Text('M-Pesa'),
                    icon: Icon(Icons.phone_android)),
              ],
              selected: {_paymentMethod},
              onSelectionChanged: (s) =>
                  setState(() => _paymentMethod = s.first),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Record Sale')),
        ],
      ),
    );

    if (confirmed == true) await _recordSale();
  }

  Future<void> _recordSale() async {
    if (_cart.isEmpty || _submitting) return;
    setState(() => _submitting = true);

    final firestore = context.read<FirestoreService>();
    final printer = context.read<PrinterService>();
    final orderNumGen = context.read<OrderNumberGenerator>();

    // Get sequential order number
    int orderNumber;
    try {
      orderNumber = await orderNumGen.next();
    } catch (_) {
      orderNumber = DateTime.now().millisecondsSinceEpoch % 1000;
    }

    final lines = _cart.entries.map((e) {
      final item = _itemsById[e.key]!;
      return model.OrderLine(
          itemId: item.id, name: item.name, price: item.price, qty: e.value);
    }).toList();

    final order = model.Order(
      id: '',
      items: lines,
      total: model.Order.totalOf(lines),
      timestamp: DateTime.now(),
      recordedBy: 'staff',
      source: printer.isPrintingSupported
          ? model.OrderSource.desktop
          : model.OrderSource.mobile,
      paymentMethod: _paymentMethod,
    );

    final orderId = await firestore.recordOrder(order);

    if (printer.isPrintingSupported) {
      final result = await printer.printReceipt(order,
          restaurantName: kRestaurantName);
      if (result == PrintResult.success) {
        await firestore.markReceiptPrinted(orderId);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Order saved, but printer not connected. Will retry.')),
        );
      }
    }

    setState(() {
      _cart.clear();
      _paymentMethod = PaymentMethod.cash;
      _submitting = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Sale #${OrderNumberGenerator.format(orderNumber)} recorded — '
            'KES ${NumberFormat('#,##0').format(order.total)}'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(title: const Text('New Order')),
      body: StreamBuilder<List<MenuItem>>(
        stream: firestore.watchMenuItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          _itemsById = {for (final i in items) i.id: i};

          if (items.isEmpty) {
            return const Center(
              child: Text('No active menu items. Add some from the Menu tab.'),
            );
          }

          return Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisExtent: 100,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return MenuItemCard(
                      item: item,
                      quantityInCart: _cart[item.id] ?? 0,
                      onTap: () => _addToCart(item.id),
                    );
                  },
                ),
              ),
              if (_cart.isNotEmpty) _buildCartBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _cart.entries.map((e) {
                final item = _itemsById[e.key];
                if (item == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    label: Text('${e.value}x ${item.name}'),
                    onDeleted: () => _removeFromCart(e.key),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Total: KES ${_total.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              FilledButton.icon(
                onPressed: _submitting ? null : _confirmAndRecord,
                icon: const Icon(Icons.check),
                label:
                    Text(_submitting ? 'Recording...' : 'Record Sale'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
