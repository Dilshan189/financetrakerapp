import 'package:financetrakerapp/service/budgetservice.dart';
import 'package:flutter/material.dart';


class BudgetProvider extends ChangeNotifier {
  double _monthlyBudget = 1000;
  double _spent = 0;
  final Map<String, double> _budgetsByMonth = {};

  final BudgetDatabaseService _db = BudgetDatabaseService();

  String _keyFor(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  // Getters
  double get monthlyBudget => budgetFor(DateTime.now());
  double get spent => _spent;
  double get progress =>
      (monthlyBudget <= 0) ? 0 : (_spent / monthlyBudget).clamp(0, 1);
  Map<String, double> get monthlyBudgets => Map.unmodifiable(_budgetsByMonth);

  // Business Logic (State Management)
  double budgetFor(DateTime date) {
    return _budgetsByMonth[_keyFor(date)] ?? _monthlyBudget;
  }

  void setBudget(double value) {
    setBudgetFor(DateTime.now(), value);
  }

  void setBudgetFor(DateTime date, double value) {
    _monthlyBudget = value;
    _budgetsByMonth[_keyFor(date)] = value;
    notifyListeners();
    _db.saveBudget(_monthlyBudget, _budgetsByMonth); // Save to DB
  }

  void setAllMonthlyBudgets(Map<String, double> budgetsByMonth) {
    _budgetsByMonth
      ..clear()
      ..addAll(budgetsByMonth);
    notifyListeners();
    _db.saveBudget(_monthlyBudget, _budgetsByMonth);
  }

  void setSpent(double value) {
    _spent = value;
    notifyListeners();
  }

  Future<void> loadFromCloud() async {
    final data = await _db.loadBudget();
    if (data == null) return;

    final goal = (data['budgetGoal'] as num?)?.toDouble();
    if (goal != null) _monthlyBudget = goal;

    final budgets = (data['budgets'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
    );
    if (budgets != null) {
      _budgetsByMonth
        ..clear()
        ..addAll(budgets);
    }
    notifyListeners();
  }
}
