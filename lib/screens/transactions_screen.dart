import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:financetrakerapp/providers/transaction_provider.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        if (provider.items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first transaction.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: provider.items.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (context, index) {
            final item = provider.items[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: item.isIncome
                    ? Colors.green[100]
                    : Colors.red[100],
                child: Icon(
                  item.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: item.isIncome ? Colors.green : Colors.red,
                ),
              ),
              title: Text(item.title),
              subtitle: Text(
                '${item.date.year}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}',
              ),
              trailing: Text(
                (item.isIncome ? '+' : '-') + item.amount.toStringAsFixed(2),
                style: TextStyle(
                  color: item.isIncome ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
