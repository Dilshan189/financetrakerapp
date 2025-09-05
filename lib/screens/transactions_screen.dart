import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:financetrakerapp/providers/transaction_provider.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  DateTimeRange? _range;
  String _category = 'All';
  bool _tableView = false;

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5);
    final lastDate = DateTime(now.year + 5);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange:
          _range ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );
    if (picked != null) {
      setState(() => _range = picked);
    }
  }

  Iterable<TransactionItem> _applyFilters(List<TransactionItem> items) {
    return items.where((t) {
      final inCategory = _category == 'All' || t.category == _category;
      final inRange = _range == null
          ? true
          : (t.date.isAfter(_range!.start.subtract(const Duration(days: 1))) &&
                t.date.isBefore(_range!.end.add(const Duration(days: 1))));
      return inCategory && inRange;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final items = provider.items;
        final categories = <String>{
          'All',
          ...items.map((e) => e.category),
        }.toList()..sort();

        if (items.isEmpty) {
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

        final filtered = _applyFilters(items).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickRange,
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        _range == null
                            ? 'All time'
                            : '${_range!.start.year}-${_range!.start.month.toString().padLeft(2, '0')}-${_range!.start.day.toString().padLeft(2, '0')}  to  '
                                  '${_range!.end.year}-${_range!.end.month.toString().padLeft(2, '0')}-${_range!.end.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: categories.contains(_category) ? _category : 'All',
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _category = v ?? 'All'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: _tableView ? 'List view' : 'Table view',
                    onPressed: () => setState(() => _tableView = !_tableView),
                    icon: Icon(
                      _tableView ? Icons.view_list : Icons.table_chart,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _tableView
                  ? _TransactionsTable(rows: filtered)
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 0),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final dateStr =
                            '${item.date.year}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}';
                        final amountStr =
                            (item.isIncome ? '+' : '-') +
                            item.amount.toStringAsFixed(2);
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: item.isIncome
                                  ? Colors.green[100]
                                  : Colors.red[100],
                              child: Icon(
                                item.isIncome
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: item.isIncome
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    amountStr,
                                    style: TextStyle(
                                      color: item.isIncome
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  dateStr,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.label_rounded, size: 16),
                                    const SizedBox(width: 4),
                                    Text(item.category),
                                  ],
                                ),
                                if (item.title.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    item.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _TransactionsTable extends StatelessWidget {
  final List<TransactionItem> rows;
  const _TransactionsTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Amount')),
          DataColumn(label: Text('Category')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Note')),
        ],
        rows: rows.map((t) {
          final dateStr =
              '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
          final amountStr =
              (t.isIncome ? '+' : '-') + t.amount.toStringAsFixed(2);
          final amountStyle = TextStyle(
            color: t.isIncome ? Colors.green : Colors.red,
            fontWeight: FontWeight.w600,
          );
          return DataRow(
            cells: [
              DataCell(Text(amountStr, style: amountStyle)),
              DataCell(Text(t.category)),
              DataCell(Text(dateStr)),
              DataCell(Text(t.title)),
            ],
          );
        }).toList(),
      ),
    );
  }
}
