import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/menu_item.dart';
import '../services/firestore_service.dart';

/// Admin screen to add/edit/deactivate menu items (doc §7.1). Changes
/// reflect on both desktop and mobile immediately via Firestore streams.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add menu item',
            onPressed: () => _showEditDialog(context, firestore),
          ),
        ],
      ),
      body: StreamBuilder<List<MenuItem>>(
        stream: firestore.watchMenuItems(activeOnly: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No menu items yet. Tap + to add one.'));
          }

          final byCategory = <String, List<MenuItem>>{};
          for (final item in items) {
            byCategory.putIfAbsent(item.category, () => []).add(item);
          }

          return ListView(
            children: byCategory.entries.map((entry) {
              return ExpansionTile(
                title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                initiallyExpanded: true,
                children: entry.value.map((item) {
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text('KES ${item.price.toStringAsFixed(0)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: item.active,
                          onChanged: (v) =>
                              firestore.setMenuItemActive(item.id, v),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () =>
                              _showEditDialog(context, firestore, existing: item),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, FirestoreService firestore,
      {MenuItem? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final categoryCtrl = TextEditingController(text: existing?.category ?? '');
    final priceCtrl =
        TextEditingController(text: existing?.price.toStringAsFixed(0) ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Menu Item' : 'Edit Menu Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: categoryCtrl,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: 'Price (KES)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final item = MenuItem(
                id: existing?.id ?? '',
                name: nameCtrl.text.trim(),
                category: categoryCtrl.text.trim().isEmpty
                    ? 'Other'
                    : categoryCtrl.text.trim(),
                price: double.tryParse(priceCtrl.text.trim()) ?? 0.0,
                active: existing?.active ?? true,
              );
              if (item.name.isNotEmpty) {
                firestore.upsertMenuItem(item);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
