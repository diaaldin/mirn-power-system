import '../../../fleet/domain/models/driver.dart';
import '../../../fleet/domain/models/vehicle.dart';
import '../../domain/models/expense.dart';
import '../../domain/services/expense_service.dart';

/// Immutable snapshot representing the reactive presentation state for fleet expenses.
class ExpensesState {
  // Expenses list & filters
  final List<Expense> expenses;
  final List<Expense> filteredExpenses;
  final String? vehicleFilter;
  final String? driverFilter;
  final ExpenseCategory? categoryFilter;
  final DateTime? startDateFilter;
  final DateTime? endDateFilter;

  // Form draft fields
  final ExpenseCategory category;
  final double amount;
  final String description;
  final String? vehicleId;
  final String? vehicleName;
  final String? driverId;
  final String? driverName;
  final int? odometerReading;
  final ExpensePaymentMethod paymentMethod;
  final String? reference;
  final String? createdBy;

  // UI state
  final bool isSubmitting;
  final String? errorMessage;
  final Expense? lastCreatedExpense;

  const ExpensesState({
    this.expenses = const [],
    this.filteredExpenses = const [],
    this.vehicleFilter,
    this.driverFilter,
    this.categoryFilter,
    this.startDateFilter,
    this.endDateFilter,
    this.category = ExpenseCategory.fuel,
    this.amount = 0.0,
    this.description = '',
    this.vehicleId,
    this.vehicleName,
    this.driverId,
    this.driverName,
    this.odometerReading,
    this.paymentMethod = ExpensePaymentMethod.cash,
    this.reference,
    this.createdBy,
    this.isSubmitting = false,
    this.errorMessage,
    this.lastCreatedExpense,
  });

  ExpensesState copyWith({
    List<Expense>? expenses,
    List<Expense>? filteredExpenses,
    String? vehicleFilter,
    bool clearVehicleFilter = false,
    String? driverFilter,
    bool clearDriverFilter = false,
    ExpenseCategory? categoryFilter,
    bool clearCategoryFilter = false,
    DateTime? startDateFilter,
    bool clearStartDateFilter = false,
    DateTime? endDateFilter,
    bool clearEndDateFilter = false,
    bool clearDateFilter = false,
    ExpenseCategory? category,
    double? amount,
    String? description,
    String? vehicleId,
    bool clearVehicleId = false,
    String? vehicleName,
    bool clearVehicleName = false,
    bool clearVehicle = false,
    String? driverId,
    bool clearDriverId = false,
    String? driverName,
    bool clearDriverName = false,
    bool clearDriver = false,
    int? odometerReading,
    bool clearOdometerReading = false,
    bool clearOdometer = false,
    ExpensePaymentMethod? paymentMethod,
    String? reference,
    bool clearReference = false,
    String? createdBy,
    bool clearCreatedBy = false,
    bool? isSubmitting,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool clearError = false,
    Expense? lastCreatedExpense,
    bool clearLastCreatedExpense = false,
  }) {
    return ExpensesState(
      expenses: expenses ?? this.expenses,
      filteredExpenses: filteredExpenses ?? this.filteredExpenses,
      vehicleFilter: clearVehicleFilter ? null : (vehicleFilter ?? this.vehicleFilter),
      driverFilter: clearDriverFilter ? null : (driverFilter ?? this.driverFilter),
      categoryFilter: clearCategoryFilter ? null : (categoryFilter ?? this.categoryFilter),
      startDateFilter:
          (clearDateFilter || clearStartDateFilter) ? null : (startDateFilter ?? this.startDateFilter),
      endDateFilter:
          (clearDateFilter || clearEndDateFilter) ? null : (endDateFilter ?? this.endDateFilter),
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      vehicleId: (clearVehicle || clearVehicleId) ? null : (vehicleId ?? this.vehicleId),
      vehicleName: (clearVehicle || clearVehicleName) ? null : (vehicleName ?? this.vehicleName),
      driverId: (clearDriver || clearDriverId) ? null : (driverId ?? this.driverId),
      driverName: (clearDriver || clearDriverName) ? null : (driverName ?? this.driverName),
      odometerReading:
          (clearOdometer || clearOdometerReading) ? null : (odometerReading ?? this.odometerReading),
      paymentMethod: paymentMethod ?? this.paymentMethod,
      reference: clearReference ? null : (reference ?? this.reference),
      createdBy: clearCreatedBy ? null : (createdBy ?? this.createdBy),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: (clearError || clearErrorMessage) ? null : (errorMessage ?? this.errorMessage),
      lastCreatedExpense:
          clearLastCreatedExpense ? null : (lastCreatedExpense ?? this.lastCreatedExpense),
    );
  }
}

/// Presentation controller managing the state machine for fleet expenses:
/// expense listing, filtering, drafting form entries, monotonic odometer updates,
/// sequential expense numbers, and fleet cost-per-km metrics delegation.
class ExpensesController {
  ExpensesState _state;
  final List<Vehicle> _vehicles;
  final List<Driver> _drivers;
  int _nextExpenseSeq;

  ExpensesController({
    List<Expense> initialExpenses = const [],
    List<Vehicle> vehicles = const [],
    List<Driver> drivers = const [],
    int? nextExpenseSeq,
  })  : _vehicles = List<Vehicle>.from(vehicles),
        _drivers = List<Driver>.from(drivers),
        _nextExpenseSeq = nextExpenseSeq ?? _calculateNextSeq(initialExpenses),
        _state = ExpensesState(
          expenses: List.unmodifiable(initialExpenses),
          filteredExpenses: List.unmodifiable(initialExpenses),
        );

  ExpensesState get state => _state;
  List<Vehicle> get vehicles => List.unmodifiable(_vehicles);
  List<Driver> get drivers => List.unmodifiable(_drivers);
  int get nextExpenseSeq => _nextExpenseSeq;

  static int _calculateNextSeq(List<Expense> expenses) {
    int maxSeq = 0;
    final regex = RegExp(r'EXP-\d{4}-(\d+)');
    for (final exp in expenses) {
      final match = regex.firstMatch(exp.expenseNumber);
      if (match != null) {
        final seq = int.tryParse(match.group(1)!);
        if (seq != null && seq > maxSeq) {
          maxSeq = seq;
        }
      }
    }
    return maxSeq + 1;
  }

  // ── Form Setters ─────────────────────────────────────────────────────────────

  void setCategory(ExpenseCategory category) {
    _state = _state.copyWith(category: category);
  }

  void setAmount(double amount) {
    _state = _state.copyWith(amount: amount);
  }

  void setDescription(String description) {
    _state = _state.copyWith(description: description);
  }

  void setVehicle(Vehicle? vehicle) {
    if (vehicle == null) {
      _state = _state.copyWith(clearVehicle: true);
    } else {
      _state = _state.copyWith(
        vehicleId: vehicle.id,
        vehicleName: vehicle.name,
      );
    }
  }

  void setVehicleId(String? vehicleId, {String? vehicleName}) {
    if (vehicleId == null) {
      _state = _state.copyWith(clearVehicle: true);
    } else {
      final resolvedName = vehicleName ??
          _vehicles
              .cast<Vehicle?>()
              .firstWhere(
                (v) => v?.id == vehicleId,
                orElse: () => null,
              )
              ?.name;
      _state = _state.copyWith(
        vehicleId: vehicleId,
        vehicleName: resolvedName,
        clearVehicleName: resolvedName == null,
      );
    }
  }

  void setDriver(Driver? driver) {
    if (driver == null) {
      _state = _state.copyWith(clearDriver: true);
    } else {
      _state = _state.copyWith(
        driverId: driver.id,
        driverName: driver.fullName,
      );
    }
  }

  void setDriverId(String? driverId, {String? driverName}) {
    if (driverId == null) {
      _state = _state.copyWith(clearDriver: true);
    } else {
      final resolvedName = driverName ??
          _drivers
              .cast<Driver?>()
              .firstWhere(
                (d) => d?.id == driverId,
                orElse: () => null,
              )
              ?.fullName;
      _state = _state.copyWith(
        driverId: driverId,
        driverName: resolvedName,
        clearDriverName: resolvedName == null,
      );
    }
  }

  void setOdometerReading(int? reading) {
    if (reading == null) {
      _state = _state.copyWith(clearOdometer: true);
    } else {
      _state = _state.copyWith(odometerReading: reading);
    }
  }

  void setPaymentMethod(ExpensePaymentMethod paymentMethod) {
    _state = _state.copyWith(paymentMethod: paymentMethod);
  }

  void setReference(String? reference) {
    if (reference == null) {
      _state = _state.copyWith(clearReference: true);
    } else {
      _state = _state.copyWith(reference: reference);
    }
  }

  void setCreatedBy(String? createdBy) {
    if (createdBy == null) {
      _state = _state.copyWith(clearCreatedBy: true);
    } else {
      _state = _state.copyWith(createdBy: createdBy);
    }
  }

  void resetForm() {
    _state = _state.copyWith(
      category: ExpenseCategory.fuel,
      amount: 0.0,
      description: '',
      clearVehicle: true,
      clearDriver: true,
      clearOdometer: true,
      paymentMethod: ExpensePaymentMethod.cash,
      clearReference: true,
      clearCreatedBy: true,
      clearError: true,
    );
  }

  // ── Filters ──────────────────────────────────────────────────────────────────

  void setVehicleFilter(String? vehicleId) {
    _state = _state.copyWith(
      vehicleFilter: vehicleId,
      clearVehicleFilter: vehicleId == null,
    );
    _applyFilters();
  }

  void setDriverFilter(String? driverId) {
    _state = _state.copyWith(
      driverFilter: driverId,
      clearDriverFilter: driverId == null,
    );
    _applyFilters();
  }

  void setCategoryFilter(ExpenseCategory? category) {
    _state = _state.copyWith(
      categoryFilter: category,
      clearCategoryFilter: category == null,
    );
    _applyFilters();
  }

  void setDateFilter({DateTime? startDate, DateTime? endDate}) {
    _state = _state.copyWith(
      startDateFilter: startDate,
      clearStartDateFilter: startDate == null,
      endDateFilter: endDate,
      clearEndDateFilter: endDate == null,
    );
    _applyFilters();
  }

  void clearFilters() {
    _state = _state.copyWith(
      clearVehicleFilter: true,
      clearDriverFilter: true,
      clearCategoryFilter: true,
      clearDateFilter: true,
    );
    _applyFilters();
  }

  void _applyFilters() {
    final filtered = ExpenseService.filterExpenses(
      expenses: _state.expenses,
      vehicleId: _state.vehicleFilter,
      driverId: _state.driverFilter,
      category: _state.categoryFilter,
      startDate: _state.startDateFilter,
      endDate: _state.endDateFilter,
    );
    _state = _state.copyWith(filteredExpenses: List.unmodifiable(filtered));
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  String _generateExpenseNumber(DateTime date) {
    final seq = _nextExpenseSeq.toString().padLeft(5, '0');
    return 'EXP-${date.year}-$seq';
  }

  /// Validates form inputs, creates the expense via [ExpenseService], increments sequence,
  /// updates vehicle odometer monotonically if provided, appends to expense lists,
  /// and resets draft form fields.
  ///
  /// Throws [ArgumentError] if amount <= 0, description is blank, or odometer is lower
  /// than vehicle's current odometer reading.
  Expense submitNewExpense({DateTime? date, String? customExpenseNumber}) {
    if (_state.amount <= 0) {
      const error = 'Expense amount must be strictly positive';
      _state = _state.copyWith(errorMessage: error);
      throw ArgumentError(error);
    }

    if (_state.description.trim().isEmpty) {
      const error = 'Description cannot be empty';
      _state = _state.copyWith(errorMessage: error);
      throw ArgumentError(error);
    }

    Vehicle? matchedVehicle;
    if (_state.vehicleId != null) {
      matchedVehicle = _vehicles.cast<Vehicle?>().firstWhere(
            (v) => v?.id == _state.vehicleId,
            orElse: () => null,
          );
    }

    final effectiveDate = date ?? DateTime.now();
    final expenseNumber = (customExpenseNumber != null && customExpenseNumber.trim().isNotEmpty)
        ? customExpenseNumber.trim()
        : _generateExpenseNumber(effectiveDate);

    final input = CreateExpenseInput(
      expenseNumber: expenseNumber,
      date: effectiveDate,
      category: _state.category,
      amount: _state.amount,
      description: _state.description,
      vehicleId: _state.vehicleId,
      driverId: _state.driverId,
      odometerReading: _state.odometerReading,
      paymentMethod: _state.paymentMethod,
      reference: _state.reference,
      createdBy: _state.createdBy,
      createdAt: effectiveDate,
    );

    final Expense expense;
    try {
      expense = ExpenseService.createExpense(input, vehicle: matchedVehicle);
    } catch (e) {
      final errorMsg =
          e is ArgumentError ? (e.message?.toString() ?? e.toString()) : e.toString();
      _state = _state.copyWith(errorMessage: errorMsg);
      rethrow;
    }

    // Monotonic vehicle odometer update
    if (matchedVehicle != null &&
        _state.odometerReading != null &&
        _state.odometerReading! > matchedVehicle.currentOdometer) {
      final index = _vehicles.indexWhere((v) => v.id == matchedVehicle!.id);
      if (index != -1) {
        _vehicles[index] = matchedVehicle.copyWith(currentOdometer: _state.odometerReading!);
      }
    }

    _nextExpenseSeq++;

    final updatedExpenses = List<Expense>.unmodifiable([
      ..._state.expenses,
      expense,
    ]);

    _state = _state.copyWith(
      expenses: updatedExpenses,
      lastCreatedExpense: expense,
      clearError: true,
      // Reset form draft:
      category: ExpenseCategory.fuel,
      amount: 0.0,
      description: '',
      clearVehicle: true,
      clearDriver: true,
      clearOdometer: true,
      paymentMethod: ExpensePaymentMethod.cash,
      clearReference: true,
      clearCreatedBy: true,
      isSubmitting: false,
    );
    _applyFilters();

    return expense;
  }

  /// Appends an existing [Expense] to state, refreshes filtered view,
  /// and advances sequential counter if necessary.
  void addExpense(Expense expense) {
    final match = RegExp(r'EXP-\d{4}-(\d+)').firstMatch(expense.expenseNumber);
    if (match != null) {
      final seq = int.tryParse(match.group(1)!);
      if (seq != null && seq >= _nextExpenseSeq) {
        _nextExpenseSeq = seq + 1;
      }
    }

    final updatedExpenses = List<Expense>.unmodifiable([
      ..._state.expenses,
      expense,
    ]);

    _state = _state.copyWith(
      expenses: updatedExpenses,
      lastCreatedExpense: expense,
      clearError: true,
    );
    _applyFilters();
  }

  /// Calculates cost-per-kilometer metrics for a specific [vehicle].
  VehicleExpenseMetrics getVehicleMetrics(Vehicle vehicle, {int? overrideDistanceKm}) {
    return ExpenseService.calculateVehicleMetrics(
      vehicle: vehicle,
      expenses: _state.expenses,
      overrideDistanceKm: overrideDistanceKm,
    );
  }

  /// Calculates aggregated fleet operational metrics across all managed vehicles.
  FleetOperationalSummary getFleetSummary() {
    return ExpenseService.calculateFleetSummary(
      vehicles: _vehicles,
      expenses: _state.expenses,
    );
  }

  void clearError() {
    _state = _state.copyWith(clearError: true);
  }

  void addVehicle(Vehicle vehicle) {
    final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
    if (index != -1) {
      _vehicles[index] = vehicle;
    } else {
      _vehicles.add(vehicle);
    }
  }

  void addDriver(Driver driver) {
    final index = _drivers.indexWhere((d) => d.id == driver.id);
    if (index != -1) {
      _drivers[index] = driver;
    } else {
      _drivers.add(driver);
    }
  }
}
