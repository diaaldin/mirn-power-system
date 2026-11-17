import '../../features/expenses/domain/models/expense.dart';

abstract class ExpenseRepository {
  Stream<List<Expense>> watchExpenses();
  Future<List<Expense>> getExpenses();
  Future<Expense?> getExpenseById(String id);
  Future<void> saveExpense(Expense expense);
}
