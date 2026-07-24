import 'package:flutter/material.dart';

import '../models/menu_item.dart';

/// Tappable card for a single menu item, used in the order grid on both
/// desktop and mobile (doc §7.2 — large tap/click targets, under 10 taps).
class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final int quantityInCart;
  final VoidCallback onTap;

  const MenuItemCard({
    super.key,
    required this.item,
    required this.quantityInCart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = quantityInCart > 0;
    return Card(
      elevation: selected ? 4 : 1,
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text('KES ${item.price.toStringAsFixed(0)}'),
                ],
              ),
              if (selected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      '$quantityInCart',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
