import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BudgetDatabaseService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Save budget data to Firestore
  Future<void> saveBudget(double monthlyBudget, Map<String, double> budgets) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = _firestore.collection('users').doc(user.uid);
    await doc.set({
      'budgetGoal': monthlyBudget,
      'budgets': budgets,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Load budget data from Firestore
  Future<Map<String, dynamic>?> loadBudget() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }
}
