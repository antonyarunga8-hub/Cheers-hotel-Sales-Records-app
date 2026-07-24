import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../services/firestore_service.dart';

/// Expense entry + automatic profit/loss (doc §7.5, §7.6). Desktop-only
/// for V1 — expenses are typically entered by the admin, not tableside.
class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  double? _profitLoss;

  @override
  void initState() {
    super.initState();
    _refreshProfitLoss();
  }

  Future<void> _refreshProfitLoss() async {
    final firestore = context.read<FirestoreService>();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final pl = await firestore.profitOrLoss(start, end);
    if (mounted) setState(() => _profitLoss = pl);
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add expense',
            onPressed: () => _showAddExpenseDialog(context, firestore),
          ),
        ],
      ),
      body: Column(
        children: [
          _ProfitLossBanner(value: _profitLoss),
          Expanded(
            child: StreamBuilder<List<Expense>>(
              stream: firestore.watchExpensesBetween(start, end),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final expenses = snapshot.data ?? [];
                if (expenses.isEmpty) {
                  return const Center(child: Text('No expenses recorded today.'));
                }
                return ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, i) {
                    final e = expenses[i];
                    return ListTile(
                      title: Text(e.description),
                      subtitle: Text(e.category),
                      trailing: Text('KES ${NumberFormat('#,##0').format(e.amount)}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, FirestoreService firestore) {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: amountCtrl,
              decoration: const InputDecoration(labelText: 'Amount (KES)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: categoryCtrl,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
              if (descCtrl.text.trim().isNotEmpty && amount > 0) {
                await firestore.addExpense(Expense(
                  id: '',
                  description: descCtrl.text.trim(),
                  amount: amount,
                  category: categoryCtrl.text.trim().isEmpty
                      ? 'General'
                      : categoryCtrl.text.trim(),
                  date: DateTime.now(),
                ));
                _refreshProfitLoss();
              }
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _ProfitLossBanner extends StatelessWidget {
  final double? value;
  const _ProfitLossBanner({required this.value});

  @override
  Widget build(BuildContext context) {
    final loading = value == null;
    final isProfit = (value ?? 0) >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: loading
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : (isProfit ? Colors.green.shade50 : Colors.red.shade50),
      child: Text(
        loading
            ? "Calculating today's profit/loss..."
            : "Today's P/L: ${isProfit ? '+' : ''}KES ${NumberFormat('#,##0').format(value)}",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: loading ? null : (isProfit ? Colors.green.shade800 : Colors.red.shade800),
        ),
      ),
    );
  }
}
