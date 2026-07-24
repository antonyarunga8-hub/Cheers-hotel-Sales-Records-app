import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense.dart';
import '../models/menu_item.dart';
import '../models/order.dart';

/// Single point of contact with Firestore. Kept intentionally simple for
/// V1 — client-side queries and aggregation, no Cloud Functions yet.
///
/// Collections (see doc §6):
///   restaurants/{restaurantId}/menuItems/{itemId}
///   restaurants/{restaurantId}/orders/{orderId}
///   restaurants/{restaurantId}/expenses/{expenseId}
class FirestoreService {
  FirestoreService({required this.restaurantId, FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance {
    // Firestore offline persistence — covers V1's offline needs on both
    // desktop and mobile without a custom local DB.
    _db.settings = const Settings(persistenceEnabled: true);
  }

  final String restaurantId;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get _restaurantDoc =>
      _db.collection('restaurants').doc(restaurantId);

  CollectionReference<Map<String, dynamic>> get _menuItems =>
      _restaurantDoc.collection('menuItems');

  CollectionReference<Map<String, dynamic>> get _orders =>
      _restaurantDoc.collection('orders');

  CollectionReference<Map<String, dynamic>> get _expenses =>
      _restaurantDoc.collection('expenses');

  // ---------------- Menu ----------------

  Stream<List<MenuItem>> watchMenuItems({bool activeOnly = true}) {
    Query<Map<String, dynamic>> q = _menuItems.orderBy('category');
    if (activeOnly) q = q.where('active', isEqualTo: true);
    return q.snapshots().map(
        (snap) => snap.docs.map((d) => MenuItem.fromFirestore(d)).toList());
  }

  Future<void> upsertMenuItem(MenuItem item) async {
    if (item.id.isEmpty) {
      await _menuItems.add(item.toMap());
    } else {
      await _menuItems.doc(item.id).set(item.toMap(), SetOptions(merge: true));
    }
  }

  Future<void> setMenuItemActive(String itemId, bool active) =>
      _menuItems.doc(itemId).update({'active': active});

  // ---------------- Orders ----------------

  /// Records a sale. Price-at-time-of-sale is captured on each [OrderLine]
  /// by the caller before this is invoked (see order_screen.dart).
  Future<String> recordOrder(Order order) async {
    final ref = await _orders.add(order.toMap());
    return ref.id;
  }

  Future<void> markReceiptPrinted(String orderId) =>
      _orders.doc(orderId).update({'receiptPrinted': true});

  /// Orders recorded on mobile that the desktop till hasn't printed yet.
  Stream<List<Order>> watchPendingPrintQueue() {
    return _orders
        .where('receiptPrinted', isEqualTo: false)
        .orderBy('timestamp')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Order.fromFirestore(d)).toList());
  }

  Stream<List<Order>> watchOrdersBetween(DateTime start, DateTime end) {
    return _orders
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Order.fromFirestore(d)).toList());
  }

  // ---------------- Expenses ----------------

  Future<void> addExpense(Expense expense) => _expenses.add(expense.toMap());

  Stream<List<Expense>> watchExpensesBetween(DateTime start, DateTime end) {
    return _expenses
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Expense.fromFirestore(d)).toList());
  }

  // ---------------- Reporting helpers ----------------

  /// Profit/Loss for [start, end). Combines both desktop- and
  /// mobile-sourced orders — the P/L formula is source-agnostic (doc §7.6).
  Future<double> profitOrLoss(DateTime start, DateTime end) async {
    final ordersSnap = await _orders
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end))
        .get();
    final expensesSnap = await _expenses
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();

    final salesTotal = ordersSnap.docs.fold<double>(
        0.0, (sum, d) => sum + ((d.data()['total'] as num?)?.toDouble() ?? 0));
    final expenseTotal = expensesSnap.docs.fold<double>(
        0.0, (sum, d) => sum + ((d.data()['amount'] as num?)?.toDouble() ?? 0));

    return salesTotal - expenseTotal;
  }
}
