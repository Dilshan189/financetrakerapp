import 'package:flutter/material.dart';

class BudgetProvider extends ChangeNotifier {
  double _monthlyBudget = 1000;
  double _spent = 0;

  double get monthlyBudget => _monthlyBudget;
  double get spent => _spent;
  double get progress =>
      (_monthlyBudget <= 0) ? 0 : (_spent / _monthlyBudget).clamp(0, 1);

  void setBudget(double value) {
    _monthlyBudget = value;
    notifyListeners();
  }

  void setSpent(double value) {
    _spent = value;
    notifyListeners();
  }
}
