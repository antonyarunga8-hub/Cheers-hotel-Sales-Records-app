import 'package:cloud_firestore/cloud_firestore.dart';

/// Generates sequential daily order numbers (e.g., #001, #002).
/// Resets to 1 at the start of each calendar day.
/// Uses a Firestore counter doc for cross-device consistency.
class OrderNumberGenerator {
  final FirebaseFirestore _db;
  final String restaurantId;

  OrderNumberGenerator({required this.restaurantId, FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  /// Get the next order number for today. Thread-safe via Firestore transaction.
  Future<int> next() async {
    final today = _todayKey();
    final counterRef = _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('counters')
        .doc('order_$today');

    return _db.runTransaction<int>((txn) async {
      final snap = await txn.get(counterRef);
      final current = snap.exists ? (snap.data()?['value'] as int? ?? 0) : 0;
      final next = current + 1;
      txn.set(counterRef, {'value': next, 'date': today});
      return next;
    });
  }

  /// Format as zero-padded string, e.g., "007".
  static String format(int number) => number.toString().padLeft(3, '0');

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
