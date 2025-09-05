import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:financetrakerapp/providers/budget_provider.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, budget, _) {
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
                    'Monthly Budget',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: budget.progress,
                    minHeight: 10,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Spent: ${budget.spent.toStringAsFixed(0)} / ${budget.monthlyBudget.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final controller = TextEditingController(
                            text: budget.monthlyBudget.toStringAsFixed(0),
                          );
                          final value = await showDialog<double>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Edit Monthly Budget'),
                              content: TextField(
                                controller: controller,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Amount',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(
                                    context,
                                    double.tryParse(controller.text.trim()),
                                  ),
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          );
                          if (value != null && value > 0) {
                            budget.setBudget(value);
                          }
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Budget'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.history),
                        label: const Text('View History'),
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
