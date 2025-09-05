import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BudgetProvider extends ChangeNotifier {
  // Legacy single-value backing field for backward compatibility
  double _monthlyBudget = 1000;
  double _spent = 0;

  // New: budgets per month (key format: YYYY-MM)
  final Map<String, double> _budgetsByMonth = {};

  String _keyFor(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  // Current-month budget (prefers per-month value if set)
  double get monthlyBudget => budgetFor(DateTime.now());

  // Legacy getters maintained
  double get spent => _spent;
  double get progress =>
      (monthlyBudget <= 0) ? 0 : (_spent / monthlyBudget).clamp(0, 1);

  // Get budget for a specific month
  double budgetFor(DateTime date) {
    return _budgetsByMonth[_keyFor(date)] ?? _monthlyBudget;
  }

  double budgetForMonth(int year, int month) {
    return budgetFor(DateTime(year, month));
  }

  // Set budget for current month (and legacy field)
  void setBudget(double value) {
    setBudgetFor(DateTime.now(), value);
  }


  // Set budget for a specific month
  void setBudgetFor(DateTime date, double value) {
    _monthlyBudget = value; // keep legacy field in sync with most-recent set
    _budgetsByMonth[_keyFor(date)] = value;
    notifyListeners();
    _saveToCloud();
  }


  void setBudgetForMonth(int year, int month, double value) {
    setBudgetFor(DateTime(year, month), value);
  }

  // Optional: replace all monthly budgets
  void setAllMonthlyBudgets(Map<String, double> budgetsByMonth) {
    _budgetsByMonth
      ..clear()
      ..addAll(budgetsByMonth);
    notifyListeners();
    _saveToCloud();
  }

  Map<String, double> get monthlyBudgets => Map.unmodifiable(_budgetsByMonth);

  // Legacy: manual spent setter (most UIs compute from transactions instead)
  void setSpent(double value) {
    _spent = value;
    notifyListeners();
  }

  // Firestore persistence: store current month budget as 'budgetGoal' and optional map as 'budgets'
  Future<void> _saveToCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await doc.set({
      'budgetGoal': monthlyBudget,
      'budgets': _budgetsByMonth,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> loadFromCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    if (data == null) return;
    final goal = (data['budgetGoal'] as num?)?.toDouble();
    if (goal != null) {
      _monthlyBudget = goal;
    }
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
