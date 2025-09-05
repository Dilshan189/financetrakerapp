import 'package:financetrakerapp/providers/auth_provider.dart';
import 'package:financetrakerapp/screens/transactions_screen.dart';
import 'package:financetrakerapp/screens/budget_screen.dart';
import 'package:financetrakerapp/screens/reports_screen.dart';
import 'package:financetrakerapp/screens/add_transaction_screen.dart';
import 'package:financetrakerapp/providers/transaction_provider.dart';
import 'package:financetrakerapp/providers/budget_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Start cloud sync after login
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    transactionProvider.startListening();
    budgetProvider.loadFromCloud();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final pages = <Widget>[
      _DashboardWelcome(userEmail: authProvider.user?.email ?? ''),
      const TransactionsScreen(),
      const BudgetScreen(),
      const ReportsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForIndex(_currentIndex)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),

      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            label: 'Reports',
          ),
        ],
      ),

      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddTransactionScreen(),
                  ),
                );
                setState(() {});
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Transaction'),
            )
          : null,
    );
  }

  String _titleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Transactions';
      case 2:
        return 'Budget';
      case 3:
        return 'Reports';
      default:
        return 'Finance Tracker';
    }
  }
}


class _DashboardWelcome extends StatelessWidget {
  final String userEmail;
  const _DashboardWelcome({required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return _HomeDashboard(userEmail: userEmail);
  }
}



class _HomeDashboard extends StatelessWidget {
  final String userEmail;
  const _HomeDashboard({required this.userEmail});

  @override
  Widget build(BuildContext context) {
    final transactions = Provider.of<TransactionProvider>(context).items;
    final budget = Provider.of<BudgetProvider>(context);

    final totalIncome = transactions
        .where((t) => t.isIncome)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final totalExpenses = transactions
        .where((t) => !t.isIncome)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final remaining = (budget.monthlyBudget - totalExpenses).clamp(
      0.0,
      double.infinity,
    );

    final Map<String, double> categoryTotals = {};
    for (final t in transactions.where((t) => !t.isIncome)) {
      categoryTotals.update(
        t.category,
        (v) => v + t.amount,
        ifAbsent: () => t.amount,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome${userEmail.isNotEmpty ? ', ' : ''}$userEmail',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const double spacing = 12;
              final int columns = constraints.maxWidth >= 900
                  ? 3
                  : (constraints.maxWidth >= 600 ? 2 : 1);
              final double cardWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _SummaryCard(
                      label: 'Total Income',
                      value: totalIncome,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _SummaryCard(
                      label: 'Total Expenses',
                      value: totalExpenses,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _SummaryCard(
                      label: 'Remaining Budget',
                      value: remaining,
                      color: Colors.indigo,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.pie_chart_outline),
                      SizedBox(width: 8),
                      Text('Monthly spending by category'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (categoryTotals.isEmpty)
                    Text(
                      'No expenses yet',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double maxChipWidth = constraints.maxWidth;
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categoryTotals.entries.map((e) {
                            final percent = totalExpenses == 0
                                ? 0.0
                                : (e.value / totalExpenses);
                            return ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: maxChipWidth,
                              ),
                              child: _CategoryChip(
                                label: e.key,
                                amount: e.value,
                                percent: percent,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }
}





class _SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.circle, color: color, size: 12),
                const SizedBox(width: 8),
                Text(
                  value.toStringAsFixed(2),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}





class _CategoryChip extends StatelessWidget {
  final String label;
  final double amount;
  final double percent;
  const _CategoryChip({
    required this.label,
    required this.amount,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentText = (percent * 100).toStringAsFixed(0) + '%';
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 6),
          Text(amount.toStringAsFixed(0), style: theme.textTheme.bodySmall),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              percentText,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
