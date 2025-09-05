import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:financetrakerapp/providers/budget_provider.dart';
import 'package:financetrakerapp/providers/transaction_provider.dart';
import 'package:financetrakerapp/theme/app_theme.dart';

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
    final theme = Theme.of(context);

    return Consumer<BudgetProvider>(
      builder: (context, budget, _) {
        final transactions = context.watch<TransactionProvider>().items;
        final now = DateTime.now();

        // Calculate monthly spending
        final monthSpent = transactions
            .where(
              (t) =>
                  !t.isIncome &&
                  t.date.year == now.year &&
                  t.date.month == now.month,
            )
            .fold<double>(0, (sum, t) => sum + t.amount);

        // Calculate category spending
        final Map<String, double> categorySpending = {};
        for (final t in transactions.where(
          (t) =>
              !t.isIncome &&
              t.date.year == now.year &&
              t.date.month == now.month,
        )) {
          categorySpending.update(
            t.category,
            (value) => value + t.amount,
            ifAbsent: () => t.amount,
          );
        }

        final double monthlyBudget = budget.monthlyBudget;
        final double remaining = (monthlyBudget - monthSpent).clamp(
          0.0,
          double.infinity,
        );
        final double progress = monthlyBudget <= 0
            ? 0
            : (monthSpent / monthlyBudget).clamp(0, 1);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Budget Overview Card
              _BudgetOverviewCard(
                monthlyBudget: monthlyBudget,
                monthSpent: monthSpent,
                remaining: remaining,
                progress: progress,
                onBudgetUpdate: (value) {
                  budget.setBudget(value);
                },
              ),

              const SizedBox(height: 24),

              // Quick Stats
              _BudgetStatsSection(
                monthlyBudget: monthlyBudget,
                monthSpent: monthSpent,
                remaining: remaining,
                progress: progress,
              ),

              const SizedBox(height: 24),

              // Category Breakdown
              _CategoryBreakdownSection(
                categorySpending: categorySpending,
                totalSpent: monthSpent,
                monthlyBudget: monthlyBudget,
              ),

              const SizedBox(height: 24),

              // Budget Tips
              _BudgetTipsSection(progress: progress),

              const SizedBox(height: 100), // Space for navigation
            ],
          ),
        );
      },
    );
  }
}

class _BudgetOverviewCard extends StatefulWidget {
  final double monthlyBudget;
  final double monthSpent;
  final double remaining;
  final double progress;
  final ValueChanged<double> onBudgetUpdate;

  const _BudgetOverviewCard({
    required this.monthlyBudget,
    required this.monthSpent,
    required this.remaining,
    required this.progress,
    required this.onBudgetUpdate,
  });

  @override
  State<_BudgetOverviewCard> createState() => _BudgetOverviewCardState();
}

class _BudgetOverviewCardState extends State<_BudgetOverviewCard> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.monthlyBudget.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverBudget = widget.progress > 1.0;
    final isNearLimit = widget.progress >= 0.8;

    Color progressColor = AppTheme.primaryColor;
    if (isOverBudget) {
      progressColor = AppTheme.errorColor;
    } else if (isNearLimit) {
      progressColor = AppTheme.warningColor;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [progressColor, progressColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: progressColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Monthly Budget',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isEditing = !_isEditing;
                  });
                },
                icon: Icon(
                  _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (_isEditing) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  prefixStyle: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                  border: InputBorder.none,
                  hintText: '0.00',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                ),
                onSubmitted: (value) {
                  final parsed = double.tryParse(value);
                  if (parsed != null && parsed > 0) {
                    widget.onBudgetUpdate(parsed);
                    setState(() {
                      _isEditing = false;
                    });
                  }
                },
              ),
            ),
          ] else ...[
            Text(
              '\$${widget.monthlyBudget.toStringAsFixed(2)}',
              style: theme.textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Progress Bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: widget.progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spent',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${widget.monthSpent.toStringAsFixed(2)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isOverBudget ? 'Over Budget' : 'Remaining',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isOverBudget
                          ? '\$${(widget.monthSpent - widget.monthlyBudget).toStringAsFixed(2)}'
                          : '\$${widget.remaining.toStringAsFixed(2)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetStatsSection extends StatelessWidget {
  final double monthlyBudget;
  final double monthSpent;
  final double remaining;
  final double progress;

  const _BudgetStatsSection({
    required this.monthlyBudget,
    required this.monthSpent,
    required this.remaining,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysInMonth = DateTime(
      DateTime.now().year,
      DateTime.now().month + 1,
      0,
    ).day;
    final currentDay = DateTime.now().day;
    final daysRemaining = daysInMonth - currentDay;
    final avgDailySpent = currentDay > 0 ? monthSpent / currentDay : 0;
    final suggestedDailySpend = daysRemaining > 0
        ? remaining / daysRemaining
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Budget Insights', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Daily Average',
                value: '\$${avgDailySpent.toStringAsFixed(2)}',
                icon: Icons.today_rounded,
                color: AppTheme.primaryColor,
                subtitle: 'Spent per day',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: 'Suggested Daily',
                value: suggestedDailySpend > 0
                    ? '\$${suggestedDailySpend.toStringAsFixed(2)}'
                    : '\$0.00',
                icon: Icons.trending_down_rounded,
                color: remaining > 0
                    ? AppTheme.successColor
                    : AppTheme.errorColor,
                subtitle: 'To stay on budget',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Progress',
                value: '${(progress * 100).toStringAsFixed(1)}%',
                icon: Icons.track_changes_rounded,
                color: progress >= 0.8
                    ? AppTheme.warningColor
                    : AppTheme.primaryColor,
                subtitle: 'of budget used',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: 'Days Left',
                value: '$daysRemaining',
                icon: Icons.calendar_today_rounded,
                color: AppTheme.primaryColor,
                subtitle: 'until month end',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBreakdownSection extends StatelessWidget {
  final Map<String, double> categorySpending;
  final double totalSpent;
  final double monthlyBudget;

  const _CategoryBreakdownSection({
    required this.categorySpending,
    required this.totalSpent,
    required this.monthlyBudget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.pie_chart_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('Spending by Category', style: theme.textTheme.headlineSmall),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: categorySpending.isEmpty
              ? Column(
                  children: [
                    Icon(
                      Icons.category_rounded,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No spending this month',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: sortedCategories.take(5).map((entry) {
                    final percent = totalSpent > 0
                        ? (entry.value / totalSpent)
                        : 0.0;
                    final budgetPercent = monthlyBudget > 0
                        ? (entry.value / monthlyBudget)
                        : 0.0;
                    final colorIndex = sortedCategories.indexOf(entry);
                    final color =
                        AppTheme.categoryColors[colorIndex %
                            AppTheme.categoryColors.length];

                    return _CategoryBreakdownItem(
                      category: entry.key,
                      amount: entry.value,
                      percent: percent,
                      budgetPercent: budgetPercent,
                      color: color,
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _CategoryBreakdownItem extends StatelessWidget {
  final String category;
  final double amount;
  final double percent;
  final double budgetPercent;
  final Color color;

  const _CategoryBreakdownItem({
    required this.category,
    required this.amount,
    required this.percent,
    required this.budgetPercent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percent.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(percent * 100).toStringAsFixed(1)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetTipsSection extends StatelessWidget {
  final double progress;

  const _BudgetTipsSection({required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String tip;
    IconData tipIcon;
    Color tipColor;

    if (progress >= 1.0) {
      tip =
          "You've exceeded your budget this month. Consider reviewing your expenses and adjusting your spending habits.";
      tipIcon = Icons.warning_rounded;
      tipColor = AppTheme.errorColor;
    } else if (progress >= 0.8) {
      tip =
          "You're approaching your budget limit. Keep an eye on your remaining expenses for this month.";
      tipIcon = Icons.info_rounded;
      tipColor = AppTheme.warningColor;
    } else if (progress >= 0.5) {
      tip =
          "Great job! You're on track with your budget. Keep maintaining your current spending pace.";
      tipIcon = Icons.thumb_up_rounded;
      tipColor = AppTheme.successColor;
    } else {
      tip =
          "Excellent budget management! You have plenty of room for planned expenses this month.";
      tipIcon = Icons.celebration_rounded;
      tipColor = AppTheme.successColor;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tipColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tipColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(tipIcon, color: tipColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budget Tip',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: tipColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
