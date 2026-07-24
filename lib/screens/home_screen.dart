import 'package:flutter/material.dart';

import '../main.dart' show kRestaurantName, kIsDesktop;
import '../widgets/connectivity_banner.dart';
import 'expenses_screen.dart';
import 'menu_screen.dart';
import 'order_screen.dart';
import 'print_queue_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

/// App shell — bottom nav on mobile, side rail on desktop.
/// Desktop gets "Print Queue" + "Settings" extra tabs.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  List<_NavItem> get _destinations => [
        const _NavItem('Order', Icons.point_of_sale),
        const _NavItem('Menu', Icons.restaurant_menu),
        if (kIsDesktop) const _NavItem('Print Queue', Icons.print),
        const _NavItem('Reports', Icons.bar_chart),
        const _NavItem('Expenses', Icons.receipt_long),
        const _NavItem('Settings', Icons.settings),
      ];

  List<Widget> get _pages => [
        const OrderScreen(),
        const MenuScreen(),
        if (kIsDesktop) const PrintQueueScreen(),
        const ReportsScreen(),
        const ExpensesScreen(),
        const SettingsScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Column(
      children: [
        const ConnectivityBanner(),
        Expanded(child: isWide ? _buildDesktopLayout() : _buildMobileLayout()),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(Icons.local_bar,
                      color: Theme.of(context).colorScheme.primary, size: 28),
                  const SizedBox(height: 4),
                  const Text(
                    kRestaurantName,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
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

  Widget _buildMobileLayout() {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _destinations
            .map((d) =>
                NavigationDestination(icon: Icon(d.icon), label: d.label))
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
