import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransactionItem {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final bool isIncome;
  final String category;

  TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isIncome,
    this.category = 'Other',
  });
}

class TransactionProvider extends ChangeNotifier {
  final List<TransactionItem> _items = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  List<TransactionItem> get items => List.unmodifiable(_items);

  TransactionItem? getById(String id) {
    try {
      return _items.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  void addTransaction(TransactionItem item) {
    _items.insert(0, item);
    notifyListeners();
  }

  bool updateTransaction(TransactionItem updated) {
    final index = _items.indexWhere((t) => t.id == updated.id);
    if (index == -1) return false;
    _items[index] = updated;
    notifyListeners();
    return true;
  }

  bool deleteTransaction(String id) {
    final index = _items.indexWhere((t) => t.id == id);
    if (index == -1) return false;
    _items.removeAt(index);
    notifyListeners();
    return true;
  }

  void setTransactions(List<TransactionItem> items) {
    _items
      ..clear()
      ..addAll(items);
    notifyListeners();
  }

  void clearAll() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }

  // Firestore integration
  Future<void> startListening() async {
    await stopListening();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .orderBy('date', descending: true);
    _sub = col.snapshots().listen((snap) {
      final list = snap.docs.map((d) {
        final data = d.data();
        return TransactionItem(
          id: d.id,
          title: data['description'] as String? ?? '',
          amount: (data['amount'] as num?)?.toDouble() ?? 0,
          date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isIncome: (data['isIncome'] as bool?) ?? false,
          category: data['category'] as String? ?? 'Other',
        );
      }).toList();
      setTransactions(list);
    });
  }

  Future<void> stopListening() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> refresh() async {
    // Re-attach listener to force pull fresh data
    await startListening();
  }

  Future<void> addToCloud(TransactionItem item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions');
    await col.add({
      'amount': item.amount,
      'category': item.category,
      'date': Timestamp.fromDate(item.date),
      'description': item.title,
      'isIncome': item.isIncome,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateInCloud(TransactionItem item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .doc(item.id);
    await doc.update({
      'amount': item.amount,
      'category': item.category,
      'date': Timestamp.fromDate(item.date),
      'description': item.title,
      'isIncome': item.isIncome,
    });
  }

  Future<void> deleteFromCloud(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .doc(id);
    await doc.delete();
  }
}
