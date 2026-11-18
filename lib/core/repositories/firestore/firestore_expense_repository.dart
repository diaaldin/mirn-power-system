import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../features/expenses/domain/models/expense.dart';
import '../../firebase/firestore_schema.dart';
import '../expense_repository.dart';

class FirestoreExpenseRepository implements ExpenseRepository {
  final FirebaseFirestore _firestore;

  FirestoreExpenseRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _expensesRef =>
      _firestore.collection(FirestoreCollections.expenses);

  @override
  Stream<List<Expense>> watchExpenses() {
    return _expensesRef
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Expense.fromJson(doc.data())).toList();
    });
  }

  @override
  Future<List<Expense>> getExpenses() async {
    final snapshot = await _expensesRef.orderBy('date', descending: true).get();
    return snapshot.docs.map((doc) => Expense.fromJson(doc.data())).toList();
  }

  @override
  Future<Expense?> getExpenseById(String id) async {
    final doc = await _expensesRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return Expense.fromJson(doc.data()!);
  }

  @override
  Future<void> saveExpense(Expense expense) async {
    // Expense vouchers are statutory financial records
    await _expensesRef.doc(expense.id).set(expense.toJson());
  }
}
