import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single item on the restaurant menu.
class MenuItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final bool active;

  const MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.active = true,
  });

  factory MenuItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return MenuItem(
      id: doc.id,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? 'Other',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      active: data['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'price': price,
        'active': active,
      };

  MenuItem copyWith({
    String? name,
    String? category,
    double? price,
    bool? active,
  }) {
    return MenuItem(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      active: active ?? this.active,
    );
  }
}
