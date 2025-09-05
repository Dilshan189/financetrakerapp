import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:financetrakerapp/providers/budget_provider.dart';
import 'package:financetrakerapp/providers/transaction_provider.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late final TextEditingController _budgetController;

  @override
  void initState() {
    super.initState();
    final budget = context.read<BudgetProvider>();
    _budgetController = TextEditingController(
      text: budget.monthlyBudget.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, budget, _) {
        final transactions = context.watch<TransactionProvider>().items;
        final now = DateTime.now();
        final monthSpent = transactions
            .where(
              (t) =>
                  !t.isIncome &&
                  t.date.year == now.year &&
                  t.date.month == now.month,
            )
            .fold<double>(0, (sum, t) => sum + t.amount);

        final double monthlyBudget = budget.monthlyBudget;
        final double progress = monthlyBudget <= 0
            ? 0
            : (monthSpent / monthlyBudget).clamp(0, 1);
        final double usedPercent = (progress * 100);
        final double remainingPercent = (100 - usedPercent).clamp(0, 100);
        final Color barColor = progress >= 0.8
            ? Colors.red
            : Theme.of(context).colorScheme.primary;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget Planning',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _budgetController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Monthly Budget Goal',
                      hintText: 'Enter your monthly budget',
                    ),
                    onSubmitted: (v) {
                      final value = double.tryParse(v.trim());
                      if (value != null && value > 0) {
                        budget.setBudget(value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Used: ${usedPercent.toStringAsFixed(0)}%  (${monthSpent.toStringAsFixed(0)})',
                      ),
                      Text(
                        'Remaining: ${remainingPercent.toStringAsFixed(0)}%  (${(monthlyBudget - monthSpent).clamp(0, double.infinity).toStringAsFixed(0)})',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          final value = double.tryParse(
                            _budgetController.text.trim(),
                          );
                          if (value != null && value > 0) {
                            budget.setBudget(value);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Enter a valid budget amount'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Save Goal'),
                      ),
                      const SizedBox(width: 12),
                      if (progress >= 0.8)
                        Row(
                          children: const [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Warning: Over 80% used',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
