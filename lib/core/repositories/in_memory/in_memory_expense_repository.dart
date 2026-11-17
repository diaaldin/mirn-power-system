import 'dart:async';
import '../../../features/expenses/domain/models/expense.dart';
import '../expense_repository.dart';

class InMemoryExpenseRepository implements ExpenseRepository {
  final Map<String, Expense> _expenses = {};
  final StreamController<List<Expense>> _controller = StreamController<List<Expense>>.broadcast();

  InMemoryExpenseRepository({List<Expense>? initialExpenses}) {
    if (initialExpenses != null) {
      for (final e in initialExpenses) {
        _expenses[e.id] = e;
      }
    }
  }

  List<Expense> get _currentList => List.unmodifiable(_expenses.values);

  void _notify() {
    if (!_controller.isClosed) {
      _controller.add(_currentList);
    }
  }

  @override
  Stream<List<Expense>> watchExpenses() {
    late StreamController<List<Expense>> subCtrl;
    StreamSubscription<List<Expense>>? subscription;
    subCtrl = StreamController<List<Expense>>.broadcast(
      onListen: () {
        subCtrl.add(_currentList);
        subscription = _controller.stream.listen(
          (data) {
            if (!subCtrl.isClosed) subCtrl.add(data);
          },
          onError: subCtrl.addError,
          onDone: subCtrl.close,
        );
      },
      onCancel: () => subscription?.cancel(),
    );
    return subCtrl.stream;
  }

  @override
  Future<List<Expense>> getExpenses() async => _currentList;

  @override
  Future<Expense?> getExpenseById(String id) async => _expenses[id];

  @override
  Future<void> saveExpense(Expense expense) async {
    _expenses[expense.id] = expense;
    _notify();
  }

  void dispose() {
    _controller.close();
  }
}
