import 'package:flutter/material.dart';

import '../main.dart' show kRestaurantName;
import 'expenses_screen.dart';
import 'menu_screen.dart';
import 'order_screen.dart';
import 'reports_screen.dart';

/// App shell — bottom nav on mobile (narrow), side rail on desktop (wide),
/// per doc §7 (screens: menu, order, reports, expenses).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _destinations = [
    _NavItem('Order', Icons.point_of_sale),
    _NavItem('Menu', Icons.restaurant_menu),
    _NavItem('Reports', Icons.bar_chart),
    _NavItem('Expenses', Icons.receipt_long),
  ];

  static const _pages = [
    OrderScreen(),
    MenuScreen(),
    ReportsScreen(),
    ExpensesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  kRestaurantName,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              destinations: _destinations
                  .map((d) => NavigationRailDestination(
                        icon: Icon(d.icon),
                        label: Text(d.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _pages[_index]),
          ],
        ),
      );
    }

    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _destinations
            .map((d) => NavigationDestination(icon: Icon(d.icon), label: d.label))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}
