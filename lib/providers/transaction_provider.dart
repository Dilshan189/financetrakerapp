import 'package:flutter/material.dart';

class TransactionItem {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final bool isIncome;

  TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isIncome,
  });
}

class TransactionProvider extends ChangeNotifier {
  final List<TransactionItem> _items = [];

  List<TransactionItem> get items => List.unmodifiable(_items);

  void addTransaction(TransactionItem item) {
    _items.insert(0, item);
    notifyListeners();
  }
}
