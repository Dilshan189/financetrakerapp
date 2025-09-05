import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:financetrakerapp/providers/transaction_provider.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = context.watch<TransactionProvider>().items;
    final theme = Theme.of(context);

    // Current month filter
    final now = DateTime.now();
    final currentMonthTx = transactions
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();

    // Spending by category (expenses only)
    final Map<String, double> categoryTotals = {};
    for (final t in currentMonthTx.where((t) => !t.isIncome)) {
      categoryTotals.update(
        t.category,
        (v) => v + t.amount,
        ifAbsent: () => t.amount,
      );
    }
    final double totalSpending = categoryTotals.values.fold(
      0.0,
      (s, v) => s + v,
    );

    // Monthly income vs expenses for last 6 months (including current)
    final List<_MonthPoint> months = [];
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final income = transactions
          .where(
            (t) =>
                t.date.year == date.year &&
                t.date.month == date.month &&
                t.isIncome,
          )
          .fold<double>(0, (s, t) => s + t.amount);
      final expense = transactions
          .where(
            (t) =>
                t.date.year == date.year &&
                t.date.month == date.month &&
                !t.isIncome,
          )
          .fold<double>(0, (s, t) => s + t.amount);
      months.add(
        _MonthPoint('${date.month}/${date.year % 100}', income, expense),
      );
    }
    final double maxBar = [
      ...months.map((m) => m.income),
      ...months.map((m) => m.expense),
    ].fold<double>(0, (max, v) => v > max ? v : max);

    final List<Color> palette = [
      Colors.indigo,
      Colors.blue,
      Colors.teal,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.purple,
      Colors.brown,
      Colors.cyan,
      Colors.red,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.pie_chart_outline),
              SizedBox(width: 8),
              Text('Spending by Category (This Month)'),
            ],
          ),
          const SizedBox(height: 12),
          if (totalSpending == 0)
            Text(
              'No expense data for this month',
              style: theme.textTheme.bodyMedium,
            )
          else
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    SizedBox(
                      height: 180,
                      width: 180,
                      child: CustomPaint(
                        painter: _PieChartPainter(
                          slices: [
                            for (int i = 0; i < categoryTotals.length; i++)
                              _PieSlice(
                                value: categoryTotals.values.elementAt(i),
                                color: palette[i % palette.length],
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (int i = 0; i < categoryTotals.length; i++)
                            _LegendTile(
                              color: palette[i % palette.length],
                              label: categoryTotals.keys.elementAt(i),
                              percent:
                                  (categoryTotals.values.elementAt(i) /
                                      totalSpending) *
                                  100,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),
          Row(
            children: const [
              Icon(Icons.bar_chart),
              SizedBox(width: 8),
              Text('Monthly Income vs Expenses (Last 6 months)'),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 220,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final m in months)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, c) {
                                  final double maxHeight =
                                      c.maxHeight - 36; // reserve for labels
                                  final double incomeH = maxBar == 0
                                      ? 0
                                      : (m.income / maxBar) * maxHeight;
                                  final double expenseH = maxBar == 0
                                      ? 0
                                      : (m.expense / maxBar) * maxHeight;
                                  return Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 10,
                                          height: incomeH,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 10,
                                          height: expenseH,
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(m.label, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              _LegendDot(color: Colors.green),
              SizedBox(width: 6),
              Text('Income'),
              SizedBox(width: 16),
              _LegendDot(color: Colors.red),
              SizedBox(width: 6),
              Text('Expenses'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendTile extends StatelessWidget {
  final Color color;
  final String label;
  final double percent;
  const _LegendTile({
    required this.color,
    required this.label,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendDot(color: color),
          const SizedBox(width: 8),
          Text(label),
          const SizedBox(width: 8),
          Text('${percent.toStringAsFixed(0)}%'),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _PieSlice {
  final double value;
  final Color color;
  _PieSlice({required this.value, required this.color});
}

class _PieChartPainter extends CustomPainter {
  final List<_PieSlice> slices;
  _PieChartPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (s, e) => s + e.value);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 4;

    final backgroundPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, backgroundPaint);

    if (total <= 0) return;

    double startRadian = -90 * 3.1415926535 / 180;
    for (final s in slices) {
      final sweep = (s.value / total) * 2 * 3.1415926535;
      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startRadian,
        sweep,
        true,
        paint,
      );
      startRadian += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.slices != slices;
  }
}

class _MonthPoint {
  final String label;
  final double income;
  final double expense;
  _MonthPoint(this.label, this.income, this.expense);
}
