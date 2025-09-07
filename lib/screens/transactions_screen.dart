import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:financetrakerapp/providers/transaction_provider.dart';
import 'package:financetrakerapp/theme/app_theme.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  DateTimeRange? _range;
  String _category = 'All';
  bool _tableView = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// date range calculation

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
      /// Category filter
      final inCategory = _category == 'All' || t.category == _category;

      /// Date range filter
      final inRange = _range == null
          ? true
          : (t.date.isAfter(_range!.start.subtract(const Duration(days: 1))) &&
                t.date.isBefore(_range!.end.add(const Duration(days: 1))));

      /// Search filter
      final matchesSearch =
          _searchQuery.isEmpty ||
          t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.amount.toString().contains(_searchQuery);

      return inCategory && inRange && matchesSearch;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final items = provider.items;
        final categories = <String>{
          'All',
          ...items.map((e) => e.category),
        }.toList()..sort();

        if (items.isEmpty) {
          return _EmptyTransactionsView();
        }

        final filtered = _applyFilters(items).toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        return Column(
          children: [
            /// Search and Filter Header
            Container(
              color: theme.colorScheme.surface,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  /// Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search transactions...',
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// Filter Controls
                  Row(
                    children: [
                      Expanded(
                        child: _FilterChip(
                          icon: Icons.date_range_rounded,
                          label: _range == null
                              ? 'All time'
                              : '${_formatDateShort(_range!.start)} - ${_formatDateShort(_range!.end)}',
                          onTap: _pickRange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FilterChip(
                          icon: Icons.category_rounded,
                          label: _category,
                          onTap: () => _showCategoryPicker(categories),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Container(
                        decoration: BoxDecoration(
                          color: _tableView
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _tableView
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: IconButton(
                          onPressed: () =>
                              setState(() => _tableView = !_tableView),
                          icon: Icon(
                            _tableView
                                ? Icons.view_list_rounded
                                : Icons.table_chart_rounded,
                            color: _tableView
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// Results Summary
            if (filtered.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                child: Text(
                  '${filtered.length} transaction${filtered.length != 1 ? 's' : ''} found',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

            /// Transactions List
            Expanded(
              child: filtered.isEmpty
                  ? _NoResultsView(searchQuery: _searchQuery)
                  : _tableView
                  ? _TransactionsTable(rows: filtered)
                  : _TransactionsList(transactions: filtered),
            ),
          ],
        );
      },
    );
  }

  String _formatDateShort(DateTime date) {
    return '${date.day}/${date.month}/${date.year.toString().substring(2)}';
  }



  /// category  picker bottom sheet
  void _showCategoryPicker(List<String> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {

        return DraggableScrollableSheet(
          initialChildSize: 0.3,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Category',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((category) {
                          final isSelected = category == _category;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _category = category;
                              });
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primaryContainer
                                    : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                category,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

}


/// FilterChip class

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty transaction view Class

class _EmptyTransactionsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No transactions yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start tracking your finances by adding your first transaction.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

          ],
        ),
      ),
    );
  }
}

/// No resultView Class

class _NoResultsView extends StatelessWidget {
  final String searchQuery;

  const _NoResultsView({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'No results found',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            if (searchQuery.isNotEmpty) ...[
              Text(
                'No transactions match "$searchQuery"',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Text(
                'Try adjusting your filters',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}


/// transaction list

class _TransactionsList extends StatelessWidget {
  final List<TransactionItem> transactions;

  const _TransactionsList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _ModernTransactionCard(transaction: transaction);
      },
    );
  }
}

/// decentralisation card

class _ModernTransactionCard extends StatelessWidget {
  final TransactionItem transaction;

  const _ModernTransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = transaction.isIncome;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isIncome
                  ? AppTheme.incomeBackgroundColor
                  : AppTheme.expenseBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(transaction.category, isIncome),
              color: isIncome ? AppTheme.incomeColor : AppTheme.expenseColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title.isEmpty
                      ? transaction.category
                      : transaction.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        transaction.category,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(transaction.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: isIncome
                      ? AppTheme.incomeColor
                      : AppTheme.expenseColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// category

  IconData _getCategoryIcon(String category, bool isIncome) {
    if (isIncome) {
      switch (category.toLowerCase()) {
        case 'salary':
          return Icons.work_rounded;
        default:
          return Icons.trending_up_rounded;
      }
    } else {
      switch (category.toLowerCase()) {
        case 'food':
          return Icons.restaurant_rounded;
        case 'transport':
          return Icons.directions_car_rounded;
        case 'bills':
          return Icons.receipt_rounded;
        case 'shopping':
          return Icons.shopping_bag_rounded;
        case 'health':
          return Icons.local_hospital_rounded;
        case 'entertainment':
          return Icons.movie_rounded;
        default:
          return Icons.trending_down_rounded;
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '${difference}d ago';

    return '${date.day}/${date.month}/${date.year}';
  }
}

/// transaction table class

class _TransactionsTable extends StatelessWidget {
  final List<TransactionItem> rows;
  const _TransactionsTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          headingTextStyle: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
          dataTextStyle: theme.textTheme.bodyMedium,
          columns: const [
            DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Category')),
            DataColumn(label: Text('Description')),
            DataColumn(label: Text('Date')),
          ],
          rows: rows.map((t) {
            final dateStr = '${t.date.day}/${t.date.month}/${t.date.year}';
            final amountStr =
                '${t.isIncome ? '+' : '-'}\$${t.amount.toStringAsFixed(2)}';
            final amountStyle = TextStyle(
              color: t.isIncome ? AppTheme.incomeColor : AppTheme.expenseColor,
              fontWeight: FontWeight.w600,
            );
            return DataRow(
              cells: [
                DataCell(Text(amountStr, style: amountStyle)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(t.category),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Text(
                      t.title.isEmpty ? '-' : t.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(dateStr)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
