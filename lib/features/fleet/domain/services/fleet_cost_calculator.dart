import '../../../expenses/domain/models/expense.dart';

class FleetCostCalculator {
  FleetCostCalculator._();

  /// Calculates net operational expense per kilometer for a fleet vehicle.
  ///
  /// Prevents division by zero when `endOdometer <= startOdometer`.
  static double calculateCostPerKm({
    required List<Expense> expenses,
    required int startOdometer,
    required int endOdometer,
  }) {
    final int distance = endOdometer - startOdometer;
    if (distance <= 0) {
      return 0.0;
    }

    final double total = expenses.fold(0.0, (sum, e) => sum + e.amount);
    return ((total / distance) * 100).roundToDouble() / 100.0;
  }

  /// Aggregates a list of expenses by their operational category.
  static Map<ExpenseCategory, double> aggregateByCategory(List<Expense> expenses) {
    final Map<ExpenseCategory, double> result = {};
    for (final e in expenses) {
      result[e.category] = (result[e.category] ?? 0.0) + e.amount;
    }
    return result;
  }
}
