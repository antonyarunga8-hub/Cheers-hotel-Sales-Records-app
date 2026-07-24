import 'package:cloud_firestore/cloud_firestore.dart';

/// Where an order originated. Desktop is the only device wired to the
/// printer; mobile-originated orders get confirmed/printed from desktop.
enum OrderSource { desktop, mobile }

OrderSource orderSourceFromString(String? value) {
  return value == 'mobile' ? OrderSource.mobile : OrderSource.desktop;
}

String orderSourceToString(OrderSource source) =>
    source == OrderSource.mobile ? 'mobile' : 'desktop';

/// A single line item within an order. Price is captured at time-of-sale
/// so later menu price changes never retroactively alter historical totals.
class OrderLine {
  final String itemId;
  final String name;
  final double price;
  final int qty;

  const OrderLine({
    required this.itemId,
    required this.name,
    required this.price,
    required this.qty,
  });

  double get lineTotal => price * qty;

  Map<String, dynamic> toMap() => {
        'itemId': itemId,
        'name': name,
        'price': price,
        'qty': qty,
      };

  factory OrderLine.fromMap(Map<String, dynamic> map) => OrderLine(
        itemId: map['itemId'] as String? ?? '',
        name: map['name'] as String? ?? '',
        price: (map['price'] as num?)?.toDouble() ?? 0.0,
        qty: (map['qty'] as num?)?.toInt() ?? 1,
      );
}

/// A recorded sale. Written by either the desktop till or the mobile app;
/// only the desktop ever marks [receiptPrinted] true.
class Order {
  final String id;
  final List<OrderLine> items;
  final double total;
  final DateTime timestamp;
  final String recordedBy;
  final OrderSource source;
  final bool synced;
  final bool receiptPrinted;

  const Order({
    required this.id,
    required this.items,
    required this.total,
    required this.timestamp,
    required this.recordedBy,
    required this.source,
    this.synced = true,
    this.receiptPrinted = false,
  });

  factory Order.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawItems = (data['items'] as List<dynamic>? ?? [])
        .map((e) => OrderLine.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    final ts = data['timestamp'];
    return Order(
      id: doc.id,
      items: rawItems,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      timestamp: ts is Timestamp ? ts.toDate() : DateTime.now(),
      recordedBy: data['recordedBy'] as String? ?? 'unknown',
      source: orderSourceFromString(data['source'] as String?),
      synced: data['synced'] as bool? ?? true,
      receiptPrinted: data['receiptPrinted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'items': items.map((e) => e.toMap()).toList(),
        'total': total,
        'timestamp': Timestamp.fromDate(timestamp),
        'recordedBy': recordedBy,
        'source': orderSourceToString(source),
        'synced': synced,
        'receiptPrinted': receiptPrinted,
      };

  static double totalOf(List<OrderLine> lines) =>
      lines.fold(0.0, (sum, l) => sum + l.lineTotal);
}
