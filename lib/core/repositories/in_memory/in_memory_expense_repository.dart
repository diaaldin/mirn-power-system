import 'dart:async';
import '../../../features/expenses/domain/models/expense.dart';
import '../expense_repository.dart';

class InMemoryExpenseRepository implements ExpenseRepository {
  final Map<String, Expense> _expenses = {};
  late final StreamController<List<Expense>> _controller;

  InMemoryExpenseRepository({List<Expense>? initialExpenses}) {
    if (initialExpenses != null) {
      for (final e in initialExpenses) {
        _expenses[e.id] = e;
      }
    }
    _controller = StreamController<List<Expense>>.broadcast(
      onListen: () => _controller.add(_currentList),
    );
  }

  List<Expense> get _currentList => List.unmodifiable(_expenses.values);

  @override
  Stream<List<Expense>> watchExpenses() => _controller.stream;

  @override
  Future<List<Expense>> getExpenses() async => _currentList;

  @override
  Future<Expense?> getExpenseById(String id) async => _expenses[id];

  @override
  Future<void> saveExpense(Expense expense) async {
    _expenses[expense.id] = expense;
    _controller.add(_currentList);
  }

  void dispose() {
    _controller.close();
  }
}
