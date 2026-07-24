import 'package:cloud_firestore/cloud_firestore.dart';

/// A recorded business expense. Entered on desktop only in V1.
class Expense {
  final String id;
  final String description;
  final double amount;
  final String category;
  final DateTime date;

  const Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
  });

  factory Expense.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final d = data['date'];
    return Expense(
      id: doc.id,
      description: data['description'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] as String? ?? 'General',
      date: d is Timestamp ? d.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'description': description,
        'amount': amount,
        'category': category,
        'date': Timestamp.fromDate(date),
      };
}
