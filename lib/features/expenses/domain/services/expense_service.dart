import '../../../fleet/domain/models/vehicle.dart';
import '../models/expense.dart';

/// Input object for creating a new expense record with validation.
class CreateExpenseInput {
  final String? id;
  final String expenseNumber; // EXP-YYYY-xxxxx
  final DateTime date;
  final ExpenseCategory category;
  final double amount;
  final String description;
  final String? vehicleId;
  final String? driverId;
  final int? odometerReading;
  final ExpensePaymentMethod paymentMethod;
  final String? reference;
  final String? createdBy;
  final DateTime? createdAt;

  const CreateExpenseInput({
    this.id,
    required this.expenseNumber,
    required this.date,
    required this.category,
    required this.amount,
    required this.description,
    this.vehicleId,
    this.driverId,
    this.odometerReading,
    required this.paymentMethod,
    this.reference,
    this.createdBy,
    this.createdAt,
  });
}

/// Operational metrics aggregated for a specific fleet vehicle.
class VehicleExpenseMetrics {
  final String vehicleId;
  final String vehicleName;
  final double totalExpenses;
  final double fuelExpenses;
  final double maintenanceExpenses;
  final double otherExpenses;
  final int totalDistanceKm;
  final double costPerKm;
  final double fuelCostPerKm;
  final double maintenanceCostPerKm;
  final int expenseCount;

  const VehicleExpenseMetrics({
    required this.vehicleId,
    required this.vehicleName,
    required this.totalExpenses,
    required this.fuelExpenses,
    required this.maintenanceExpenses,
    required this.otherExpenses,
    required this.totalDistanceKm,
    required this.costPerKm,
    required this.fuelCostPerKm,
    required this.maintenanceCostPerKm,
    required this.expenseCount,
  });
}

/// Overall fleet operational summary aggregating vehicle and general company expenses.
class FleetOperationalSummary {
  final double totalExpenses;
  final double totalFuel;
  final double totalMaintenance;
  final int totalDistanceKm;
  final double overallCostPerKm;
  final Map<String, VehicleExpenseMetrics> vehicleMetrics;

  const FleetOperationalSummary({
    required this.totalExpenses,
    required this.totalFuel,
    required this.totalMaintenance,
    required this.totalDistanceKm,
    required this.overallCostPerKm,
    required this.vehicleMetrics,
  });
}

/// Domain service managing expense creation, validation, filtering,
/// and vehicle/fleet operational cost-per-kilometer calculations.
class ExpenseService {
  ExpenseService._();

  static double _round2(double val) => ((val * 100).round()) / 100.0;

  /// Validates business invariants and creates a new [Expense].
  ///
  /// Throws [ArgumentError] if:
  /// - `input.amount <= 0` ('Expense amount must be strictly positive')
  /// - `input.description.trim().isEmpty` ('Description cannot be empty')
  /// - `input.expenseNumber.trim().isEmpty` ('Expense number cannot be empty')
  /// - `vehicle != null && input.odometerReading != null && input.odometerReading! < vehicle.currentOdometer`
  ///   ('Odometer reading cannot be lower than current vehicle odometer')
  static Expense createExpense(CreateExpenseInput input, {Vehicle? vehicle}) {
    if (input.amount <= 0) {
      throw ArgumentError.value(
        input.amount,
        'amount',
        'Expense amount must be strictly positive',
      );
    }

    final trimmedDescription = input.description.trim();
    if (trimmedDescription.isEmpty) {
      throw ArgumentError.value(
        input.description,
        'description',
        'Description cannot be empty',
      );
    }

    final trimmedExpenseNumber = input.expenseNumber.trim();
    if (trimmedExpenseNumber.isEmpty) {
      throw ArgumentError.value(
        input.expenseNumber,
        'expenseNumber',
        'Expense number cannot be empty',
      );
    }

    if (vehicle != null && input.odometerReading != null) {
      if (input.odometerReading! < vehicle.currentOdometer) {
        throw ArgumentError.value(
          input.odometerReading,
          'odometerReading',
          'Odometer reading cannot be lower than current vehicle odometer',
        );
      }
    }

    final assignedVehicleId = input.vehicleId ?? vehicle?.id;

    return Expense(
      id: input.id ?? trimmedExpenseNumber,
      expenseNumber: trimmedExpenseNumber,
      date: input.date,
      category: input.category,
      amount: input.amount,
      description: trimmedDescription,
      vehicleId: assignedVehicleId,
      driverId: input.driverId,
      odometerReading: input.odometerReading,
      paymentMethod: input.paymentMethod,
      reference: input.reference?.trim().isEmpty == true ? null : input.reference?.trim(),
      createdBy: input.createdBy?.trim().isEmpty == true ? null : input.createdBy?.trim(),
      createdAt: input.createdAt ?? input.date,
    );
  }

  /// Filters a list of expenses by optional vehicle, driver, category, and date range criteria.
  static List<Expense> filterExpenses({
    required List<Expense> expenses,
    String? vehicleId,
    String? driverId,
    ExpenseCategory? category,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final normalizedEndDate = endDate != null
        ? (endDate.hour == 0 && endDate.minute == 0 && endDate.second == 0 && endDate.millisecond == 0
            ? DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999)
            : endDate)
        : null;

    return expenses.where((e) {
      if (vehicleId != null && e.vehicleId != vehicleId) return false;
      if (driverId != null && e.driverId != driverId) return false;
      if (category != null && e.category != category) return false;
      if (startDate != null && e.date.isBefore(startDate)) return false;
      if (normalizedEndDate != null && e.date.isAfter(normalizedEndDate)) return false;
      return true;
    }).toList();
  }

  /// Calculates operational expense metrics and cost/km breakdown for a specific [vehicle].
  ///
  /// Prevents division by zero when traveled distance is `<= 0`.
  static VehicleExpenseMetrics calculateVehicleMetrics({
    required Vehicle vehicle,
    required List<Expense> expenses,
    int? overrideDistanceKm,
  }) {
    final vehicleExpenses = expenses.where((e) => e.vehicleId == vehicle.id).toList();

    final totalExpenses = _round2(
      vehicleExpenses.fold<double>(0.0, (sum, e) => sum + e.amount),
    );
    final fuelExpenses = _round2(
      vehicleExpenses
          .where((e) => e.category == ExpenseCategory.fuel)
          .fold<double>(0.0, (sum, e) => sum + e.amount),
    );
    final maintenanceExpenses = _round2(
      vehicleExpenses
          .where((e) => e.category == ExpenseCategory.maintenance || e.category == ExpenseCategory.tires)
          .fold<double>(0.0, (sum, e) => sum + e.amount),
    );
    final otherExpenses = _round2(
      vehicleExpenses
          .where((e) =>
              e.category != ExpenseCategory.fuel &&
              e.category != ExpenseCategory.maintenance &&
              e.category != ExpenseCategory.tires)
          .fold<double>(0.0, (sum, e) => sum + e.amount),
    );

    final rawDistance = overrideDistanceKm ?? vehicle.currentOdometer;
    final int distance = rawDistance > 0 ? rawDistance : 0;

    final double costPerKm = distance > 0 ? _round2(totalExpenses / distance) : 0.0;
    final double fuelCostPerKm = distance > 0 ? _round2(fuelExpenses / distance) : 0.0;
    final double maintenanceCostPerKm = distance > 0 ? _round2(maintenanceExpenses / distance) : 0.0;

    return VehicleExpenseMetrics(
      vehicleId: vehicle.id,
      vehicleName: vehicle.name,
      totalExpenses: totalExpenses,
      fuelExpenses: fuelExpenses,
      maintenanceExpenses: maintenanceExpenses,
      otherExpenses: otherExpenses,
      totalDistanceKm: distance,
      costPerKm: costPerKm,
      fuelCostPerKm: fuelCostPerKm,
      maintenanceCostPerKm: maintenanceCostPerKm,
      expenseCount: vehicleExpenses.length,
    );
  }

  /// Aggregates fleet-wide operational summary across all vehicles and general unassigned expenses.
  static FleetOperationalSummary calculateFleetSummary({
    required List<Vehicle> vehicles,
    required List<Expense> expenses,
  }) {
    final totalExpenses = _round2(
      expenses.fold<double>(0.0, (sum, e) => sum + e.amount),
    );
    final totalFuel = _round2(
      expenses
          .where((e) => e.category == ExpenseCategory.fuel)
          .fold<double>(0.0, (sum, e) => sum + e.amount),
    );
    final totalMaintenance = _round2(
      expenses
          .where((e) => e.category == ExpenseCategory.maintenance || e.category == ExpenseCategory.tires)
          .fold<double>(0.0, (sum, e) => sum + e.amount),
    );

    final totalDistanceKm = vehicles.fold<int>(
      0,
      (sum, v) => sum + (v.currentOdometer > 0 ? v.currentOdometer : 0),
    );

    final double overallCostPerKm =
        totalDistanceKm > 0 ? _round2(totalExpenses / totalDistanceKm) : 0.0;

    final Map<String, VehicleExpenseMetrics> vehicleMetrics = {};
    for (final vehicle in vehicles) {
      vehicleMetrics[vehicle.id] = calculateVehicleMetrics(
        vehicle: vehicle,
        expenses: expenses,
      );
    }

    return FleetOperationalSummary(
      totalExpenses: totalExpenses,
      totalFuel: totalFuel,
      totalMaintenance: totalMaintenance,
      totalDistanceKm: totalDistanceKm,
      overallCostPerKm: overallCostPerKm,
      vehicleMetrics: vehicleMetrics,
    );
  }
}
