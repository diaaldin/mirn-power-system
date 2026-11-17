import 'package:test/test.dart';
import 'package:sales_logistics_system/features/expenses/domain/models/expense.dart';
import 'package:sales_logistics_system/features/expenses/presentation/controllers/expenses_controller.dart';
import 'package:sales_logistics_system/features/fleet/domain/models/driver.dart';
import 'package:sales_logistics_system/features/fleet/domain/models/vehicle.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Test Fixtures
  // ---------------------------------------------------------------------------
  final testVehicle1 = Vehicle(
    id: 'veh-01',
    name: 'Volvo FH 500',
    plateNumber: '12-345-67',
    currentOdometer: 50000,
    status: VehicleStatus.active,
  );

  final testVehicle2 = Vehicle(
    id: 'veh-02',
    name: 'Scania R450',
    plateNumber: '98-765-43',
    currentOdometer: 80000,
    status: VehicleStatus.active,
  );

  final testDriver1 = Driver(
    id: 'drv-01',
    fullName: 'Ahmed Salem',
    phone: '050-1111111',
    licenseNumber: 'LIC-12345',
    status: DriverStatus.active,
  );

  final testDriver2 = Driver(
    id: 'drv-02',
    fullName: 'Yousef Mansour',
    phone: '052-2222222',
    licenseNumber: 'LIC-67890',
    status: DriverStatus.active,
  );

  Expense createSampleExpense({
    required String id,
    required String number,
    required DateTime date,
    required ExpenseCategory category,
    required double amount,
    String description = 'Test expense',
    String? vehicleId,
    String? driverId,
    int? odometerReading,
    ExpensePaymentMethod paymentMethod = ExpensePaymentMethod.cash,
    String? reference,
    String? createdBy,
  }) {
    return Expense(
      id: id,
      expenseNumber: number,
      date: date,
      category: category,
      amount: amount,
      description: description,
      vehicleId: vehicleId,
      driverId: driverId,
      odometerReading: odometerReading,
      paymentMethod: paymentMethod,
      reference: reference,
      createdBy: createdBy,
      createdAt: date,
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Initial State & Defaults
  // ---------------------------------------------------------------------------
  group('ExpensesController - Initial State & Defaults', () {
    test('default constructor initializes with empty lists and default form draft', () {
      final ctrl = ExpensesController();
      final state = ctrl.state;

      expect(state.expenses, isEmpty);
      expect(state.filteredExpenses, isEmpty);
      expect(state.vehicleFilter, isNull);
      expect(state.driverFilter, isNull);
      expect(state.categoryFilter, isNull);
      expect(state.startDateFilter, isNull);
      expect(state.endDateFilter, isNull);

      // Form draft defaults
      expect(state.category, equals(ExpenseCategory.fuel));
      expect(state.amount, equals(0.0));
      expect(state.description, equals(''));
      expect(state.vehicleId, isNull);
      expect(state.vehicleName, isNull);
      expect(state.driverId, isNull);
      expect(state.driverName, isNull);
      expect(state.odometerReading, isNull);
      expect(state.paymentMethod, equals(ExpensePaymentMethod.cash));
      expect(state.reference, isNull);
      expect(state.createdBy, isNull);

      // UI state
      expect(state.isSubmitting, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.lastCreatedExpense, isNull);

      // Sequence
      expect(ctrl.nextExpenseSeq, equals(1));
    });

    test('preserves initial expenses, vehicles, and drivers passed to constructor', () {
      final initialExpenses = [
        createSampleExpense(
          id: 'exp-1',
          number: 'EXP-2026-00005',
          date: DateTime(2026, 11, 1),
          category: ExpenseCategory.fuel,
          amount: 450.0,
          vehicleId: testVehicle1.id,
        ),
      ];

      final ctrl = ExpensesController(
        initialExpenses: initialExpenses,
        vehicles: [testVehicle1, testVehicle2],
        drivers: [testDriver1],
      );

      expect(ctrl.state.expenses, hasLength(1));
      expect(ctrl.state.filteredExpenses, hasLength(1));
      expect(ctrl.vehicles, hasLength(2));
      expect(ctrl.drivers, hasLength(1));
    });

    test('auto-calculates next sequence from initial expenses if not explicitly given', () {
      final initialExpenses = [
        createSampleExpense(
          id: 'exp-1',
          number: 'EXP-2026-00003',
          date: DateTime(2026, 11, 1),
          category: ExpenseCategory.fuel,
          amount: 300.0,
        ),
        createSampleExpense(
          id: 'exp-2',
          number: 'EXP-2026-00015',
          date: DateTime(2026, 11, 2),
          category: ExpenseCategory.maintenance,
          amount: 1200.0,
        ),
      ];

      final ctrl = ExpensesController(initialExpenses: initialExpenses);
      expect(ctrl.nextExpenseSeq, equals(16));
    });

    test('respects explicitly provided nextExpenseSeq over parsed sequence', () {
      final initialExpenses = [
        createSampleExpense(
          id: 'exp-1',
          number: 'EXP-2026-00010',
          date: DateTime(2026, 11, 1),
          category: ExpenseCategory.fuel,
          amount: 300.0,
        ),
      ];

      final ctrl = ExpensesController(
        initialExpenses: initialExpenses,
        nextExpenseSeq: 100,
      );
      expect(ctrl.nextExpenseSeq, equals(100));
    });
  });

  // ---------------------------------------------------------------------------
  // 2. Form Drafting & Setters
  // ---------------------------------------------------------------------------
  group('ExpensesController - Form Drafting & Setters', () {
    late ExpensesController ctrl;

    setUp(() {
      ctrl = ExpensesController(
        vehicles: [testVehicle1, testVehicle2],
        drivers: [testDriver1, testDriver2],
      );
    });

    test('setCategory updates draft category', () {
      ctrl.setCategory(ExpenseCategory.maintenance);
      expect(ctrl.state.category, equals(ExpenseCategory.maintenance));
    });

    test('setAmount updates draft amount', () {
      ctrl.setAmount(1250.50);
      expect(ctrl.state.amount, equals(1250.50));
    });

    test('setDescription updates draft description', () {
      ctrl.setDescription('Replaced front brake pads');
      expect(ctrl.state.description, equals('Replaced front brake pads'));
    });

    test('setVehicle sets vehicleId and vehicleName from Vehicle object, or clears when null', () {
      ctrl.setVehicle(testVehicle1);
      expect(ctrl.state.vehicleId, equals('veh-01'));
      expect(ctrl.state.vehicleName, equals('Volvo FH 500'));

      ctrl.setVehicle(null);
      expect(ctrl.state.vehicleId, isNull);
      expect(ctrl.state.vehicleName, isNull);
    });

    test('setVehicleId resolves vehicle name from controller vehicles list', () {
      ctrl.setVehicleId('veh-02');
      expect(ctrl.state.vehicleId, equals('veh-02'));
      expect(ctrl.state.vehicleName, equals('Scania R450'));

      // If explicit custom name provided, it takes precedence
      ctrl.setVehicleId('veh-01', vehicleName: 'Custom Volvo Name');
      expect(ctrl.state.vehicleId, equals('veh-01'));
      expect(ctrl.state.vehicleName, equals('Custom Volvo Name'));

      // Passing null clears vehicle
      ctrl.setVehicleId(null);
      expect(ctrl.state.vehicleId, isNull);
      expect(ctrl.state.vehicleName, isNull);
    });

    test('setDriver sets driverId and driverName from Driver object, or clears when null', () {
      ctrl.setDriver(testDriver1);
      expect(ctrl.state.driverId, equals('drv-01'));
      expect(ctrl.state.driverName, equals('Ahmed Salem'));

      ctrl.setDriver(null);
      expect(ctrl.state.driverId, isNull);
      expect(ctrl.state.driverName, isNull);
    });

    test('setDriverId resolves driver name from controller drivers list', () {
      ctrl.setDriverId('drv-02');
      expect(ctrl.state.driverId, equals('drv-02'));
      expect(ctrl.state.driverName, equals('Yousef Mansour'));

      // Explicit name
      ctrl.setDriverId('drv-01', driverName: 'Custom Driver Name');
      expect(ctrl.state.driverId, equals('drv-01'));
      expect(ctrl.state.driverName, equals('Custom Driver Name'));

      // Passing null clears driver
      ctrl.setDriverId(null);
      expect(ctrl.state.driverId, isNull);
      expect(ctrl.state.driverName, isNull);
    });

    test('setOdometerReading updates and clears odometer reading', () {
      ctrl.setOdometerReading(52000);
      expect(ctrl.state.odometerReading, equals(52000));

      ctrl.setOdometerReading(null);
      expect(ctrl.state.odometerReading, isNull);
    });

    test('setPaymentMethod updates draft payment method', () {
      ctrl.setPaymentMethod(ExpensePaymentMethod.bankTransfer);
      expect(ctrl.state.paymentMethod, equals(ExpensePaymentMethod.bankTransfer));
    });

    test('setReference updates and clears reference', () {
      ctrl.setReference('INV-9988');
      expect(ctrl.state.reference, equals('INV-9988'));

      ctrl.setReference(null);
      expect(ctrl.state.reference, isNull);
    });

    test('setCreatedBy updates and clears createdBy', () {
      ctrl.setCreatedBy('Manager Dan');
      expect(ctrl.state.createdBy, equals('Manager Dan'));

      ctrl.setCreatedBy(null);
      expect(ctrl.state.createdBy, isNull);
    });

    test('resetForm restores form draft defaults while preserving expenses and filters', () {
      ctrl.setCategoryFilter(ExpenseCategory.fuel);
      ctrl.setCategory(ExpenseCategory.tires);
      ctrl.setAmount(900.0);
      ctrl.setDescription('4 new Michelin tires');
      ctrl.setVehicle(testVehicle1);
      ctrl.setDriver(testDriver1);
      ctrl.setOdometerReading(51000);
      ctrl.setPaymentMethod(ExpensePaymentMethod.check);
      ctrl.setReference('CHK-1002');
      ctrl.setCreatedBy('Admin');

      ctrl.resetForm();

      final s = ctrl.state;
      expect(s.category, equals(ExpenseCategory.fuel));
      expect(s.amount, equals(0.0));
      expect(s.description, equals(''));
      expect(s.vehicleId, isNull);
      expect(s.vehicleName, isNull);
      expect(s.driverId, isNull);
      expect(s.driverName, isNull);
      expect(s.odometerReading, isNull);
      expect(s.paymentMethod, equals(ExpensePaymentMethod.cash));
      expect(s.reference, isNull);
      expect(s.createdBy, isNull);

      // Filter is preserved
      expect(s.categoryFilter, equals(ExpenseCategory.fuel));
    });
  });

  // ---------------------------------------------------------------------------
  // 3. Filtering
  // ---------------------------------------------------------------------------
  group('ExpensesController - Filtering', () {
    late ExpensesController ctrl;
    final exp1 = createSampleExpense(
      id: 'e1',
      number: 'EXP-2026-00001',
      date: DateTime(2026, 11, 10),
      category: ExpenseCategory.fuel,
      amount: 500.0,
      vehicleId: testVehicle1.id,
      driverId: testDriver1.id,
    );
    final exp2 = createSampleExpense(
      id: 'e2',
      number: 'EXP-2026-00002',
      date: DateTime(2026, 11, 12),
      category: ExpenseCategory.maintenance,
      amount: 1500.0,
      vehicleId: testVehicle1.id,
      driverId: testDriver2.id,
    );
    final exp3 = createSampleExpense(
      id: 'e3',
      number: 'EXP-2026-00003',
      date: DateTime(2026, 11, 15),
      category: ExpenseCategory.fuel,
      amount: 600.0,
      vehicleId: testVehicle2.id,
      driverId: testDriver1.id,
    );
    final exp4 = createSampleExpense(
      id: 'e4',
      number: 'EXP-2026-00004',
      date: DateTime(2026, 11, 20),
      category: ExpenseCategory.rent,
      amount: 4000.0, // general company expense
    );

    setUp(() {
      ctrl = ExpensesController(
        initialExpenses: [exp1, exp2, exp3, exp4],
        vehicles: [testVehicle1, testVehicle2],
        drivers: [testDriver1, testDriver2],
      );
    });

    test('initial filteredExpenses contains all initial expenses', () {
      expect(ctrl.state.filteredExpenses, hasLength(4));
    });

    test('setVehicleFilter filters by vehicleId and clearing restores all', () {
      ctrl.setVehicleFilter(testVehicle1.id);
      expect(ctrl.state.vehicleFilter, equals(testVehicle1.id));
      expect(ctrl.state.filteredExpenses, hasLength(2));
      expect(ctrl.state.filteredExpenses.map((e) => e.id), containsAll(['e1', 'e2']));

      ctrl.setVehicleFilter(null);
      expect(ctrl.state.vehicleFilter, isNull);
      expect(ctrl.state.filteredExpenses, hasLength(4));
    });

    test('setDriverFilter filters by driverId', () {
      ctrl.setDriverFilter(testDriver2.id);
      expect(ctrl.state.driverFilter, equals(testDriver2.id));
      expect(ctrl.state.filteredExpenses, hasLength(1));
      expect(ctrl.state.filteredExpenses.first.id, equals('e2'));
    });

    test('setCategoryFilter filters by category', () {
      ctrl.setCategoryFilter(ExpenseCategory.fuel);
      expect(ctrl.state.categoryFilter, equals(ExpenseCategory.fuel));
      expect(ctrl.state.filteredExpenses, hasLength(2));
      expect(ctrl.state.filteredExpenses.map((e) => e.id), containsAll(['e1', 'e3']));
    });

    test('setDateFilter filters by date range', () {
      ctrl.setDateFilter(
        startDate: DateTime(2026, 11, 11),
        endDate: DateTime(2026, 11, 16),
      );
      expect(ctrl.state.filteredExpenses, hasLength(2));
      expect(ctrl.state.filteredExpenses.map((e) => e.id), containsAll(['e2', 'e3']));
    });

    test('combines multiple filters simultaneously', () {
      ctrl.setVehicleFilter(testVehicle1.id);
      ctrl.setCategoryFilter(ExpenseCategory.fuel);
      expect(ctrl.state.filteredExpenses, hasLength(1));
      expect(ctrl.state.filteredExpenses.first.id, equals('e1'));
    });

    test('clearFilters clears all filters and restores full expense list', () {
      ctrl.setVehicleFilter(testVehicle1.id);
      ctrl.setDriverFilter(testDriver1.id);
      ctrl.setCategoryFilter(ExpenseCategory.fuel);
      ctrl.setDateFilter(startDate: DateTime(2026, 11, 1), endDate: DateTime(2026, 11, 30));

      expect(ctrl.state.filteredExpenses, hasLength(1));

      ctrl.clearFilters();
      expect(ctrl.state.vehicleFilter, isNull);
      expect(ctrl.state.driverFilter, isNull);
      expect(ctrl.state.categoryFilter, isNull);
      expect(ctrl.state.startDateFilter, isNull);
      expect(ctrl.state.endDateFilter, isNull);
      expect(ctrl.state.filteredExpenses, hasLength(4));
    });
  });

  // ---------------------------------------------------------------------------
  // 4. Expense Creation & Sequential Numbering
  // ---------------------------------------------------------------------------
  group('ExpensesController - Expense Creation & Sequential Numbering', () {
    late ExpensesController ctrl;

    setUp(() {
      ctrl = ExpensesController(
        vehicles: [testVehicle1, testVehicle2],
        drivers: [testDriver1, testDriver2],
      );
    });

    test('submitNewExpense generates EXP-YYYY-xxxxx sequentially and increments counter', () {
      ctrl.setCategory(ExpenseCategory.fuel);
      ctrl.setAmount(350.0);
      ctrl.setDescription('Full diesel tank');
      ctrl.setVehicle(testVehicle1);
      ctrl.setDriver(testDriver1);

      final fixedDate = DateTime(2026, 11, 17, 10, 0);
      final expense1 = ctrl.submitNewExpense(date: fixedDate);

      expect(expense1.expenseNumber, equals('EXP-2026-00001'));
      expect(expense1.amount, equals(350.0));
      expect(expense1.description, equals('Full diesel tank'));
      expect(expense1.vehicleId, equals('veh-01'));
      expect(expense1.driverId, equals('drv-01'));
      expect(ctrl.nextExpenseSeq, equals(2));

      expect(ctrl.state.expenses, hasLength(1));
      expect(ctrl.state.filteredExpenses, hasLength(1));
      expect(ctrl.state.lastCreatedExpense, equals(expense1));

      // Second expense auto-increments
      ctrl.setCategory(ExpenseCategory.maintenance);
      ctrl.setAmount(700.0);
      ctrl.setDescription('Oil change');
      final expense2 = ctrl.submitNewExpense(date: fixedDate);

      expect(expense2.expenseNumber, equals('EXP-2026-00002'));
      expect(ctrl.nextExpenseSeq, equals(3));
      expect(ctrl.state.expenses, hasLength(2));
      expect(ctrl.state.lastCreatedExpense, equals(expense2));
    });

    test('submitNewExpense respects customExpenseNumber if provided', () {
      ctrl.setAmount(100.0);
      ctrl.setDescription('Car wash');
      final expense = ctrl.submitNewExpense(
        date: DateTime(2026, 11, 17),
        customExpenseNumber: 'EXP-CUSTOM-001',
      );

      expect(expense.expenseNumber, equals('EXP-CUSTOM-001'));
      expect(ctrl.state.expenses.first.expenseNumber, equals('EXP-CUSTOM-001'));
    });

    test('submitNewExpense resets draft form fields while keeping expense list', () {
      ctrl.setAmount(500.0);
      ctrl.setDescription('Tire replacement');
      ctrl.setVehicle(testVehicle1);
      ctrl.setDriver(testDriver1);
      ctrl.setOdometerReading(50500);
      ctrl.setReference('REF-001');
      ctrl.setCreatedBy('Dispatcher');

      ctrl.submitNewExpense(date: DateTime(2026, 11, 17));

      final s = ctrl.state;
      expect(s.amount, equals(0.0));
      expect(s.description, equals(''));
      expect(s.vehicleId, isNull);
      expect(s.vehicleName, isNull);
      expect(s.driverId, isNull);
      expect(s.driverName, isNull);
      expect(s.odometerReading, isNull);
      expect(s.reference, isNull);
      expect(s.createdBy, isNull);
      expect(s.errorMessage, isNull);
      expect(s.isSubmitting, isFalse);
    });

    test('addExpense appends expense, refreshes filters, and updates next sequence if higher', () {
      final extExpense = createSampleExpense(
        id: 'ext-1',
        number: 'EXP-2026-00050',
        date: DateTime(2026, 11, 17),
        category: ExpenseCategory.licensingInsurance,
        amount: 3200.0,
      );

      ctrl.addExpense(extExpense);

      expect(ctrl.state.expenses, hasLength(1));
      expect(ctrl.state.filteredExpenses, hasLength(1));
      expect(ctrl.state.lastCreatedExpense, equals(extExpense));
      expect(ctrl.nextExpenseSeq, equals(51));
    });
  });

  // ---------------------------------------------------------------------------
  // 5. Error Handling & Validation
  // ---------------------------------------------------------------------------
  group('ExpensesController - Error Handling & Validation', () {
    late ExpensesController ctrl;

    setUp(() {
      ctrl = ExpensesController(
        vehicles: [testVehicle1],
      );
    });

    test('rejects zero or negative amount, sets errorMessage and throws ArgumentError', () {
      ctrl.setAmount(0.0);
      ctrl.setDescription('Valid description');

      expect(
        () => ctrl.submitNewExpense(),
        throwsA(isA<ArgumentError>()),
      );
      expect(ctrl.state.errorMessage, contains('strictly positive'));

      ctrl.setAmount(-50.0);
      expect(
        () => ctrl.submitNewExpense(),
        throwsA(isA<ArgumentError>()),
      );
      expect(ctrl.state.errorMessage, contains('strictly positive'));
    });

    test('rejects blank description, sets errorMessage and throws ArgumentError', () {
      ctrl.setAmount(100.0);
      ctrl.setDescription('   ');

      expect(
        () => ctrl.submitNewExpense(),
        throwsA(isA<ArgumentError>()),
      );
      expect(ctrl.state.errorMessage, contains('Description cannot be empty'));
    });

    test('rejects backward odometer reading against vehicle current odometer', () {
      // testVehicle1 current odometer is 50,000
      ctrl.setVehicle(testVehicle1);
      ctrl.setAmount(200.0);
      ctrl.setDescription('Diesel');
      ctrl.setOdometerReading(49900); // backwards!

      expect(
        () => ctrl.submitNewExpense(),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        ctrl.state.errorMessage,
        contains('Odometer reading cannot be lower than current vehicle odometer'),
      );
    });

    test('clearError resets errorMessage in state', () {
      ctrl.setAmount(-10.0);
      try {
        ctrl.submitNewExpense();
      } catch (_) {}

      expect(ctrl.state.errorMessage, isNotNull);
      ctrl.clearError();
      expect(ctrl.state.errorMessage, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // 6. Updating Vehicle Odometer on Higher Reading
  // ---------------------------------------------------------------------------
  group('ExpensesController - Vehicle Odometer Updates', () {
    late ExpensesController ctrl;

    setUp(() {
      ctrl = ExpensesController(
        vehicles: [testVehicle1], // currentOdometer = 50,000
      );
    });

    test('updates vehicle current odometer when higher odometer reading is submitted', () {
      ctrl.setVehicle(testVehicle1);
      ctrl.setAmount(400.0);
      ctrl.setDescription('Fuel refill at station');
      ctrl.setOdometerReading(52450);

      ctrl.submitNewExpense();

      final updatedVehicle = ctrl.vehicles.firstWhere((v) => v.id == testVehicle1.id);
      expect(updatedVehicle.currentOdometer, equals(52450));
    });

    test('does not decrease vehicle odometer if reading equals current', () {
      ctrl.setVehicle(testVehicle1);
      ctrl.setAmount(400.0);
      ctrl.setDescription('Fuel refill at station');
      ctrl.setOdometerReading(50000); // equal to current

      ctrl.submitNewExpense();

      final updatedVehicle = ctrl.vehicles.firstWhere((v) => v.id == testVehicle1.id);
      expect(updatedVehicle.currentOdometer, equals(50000));
    });
  });

  // ---------------------------------------------------------------------------
  // 7. Operational Metrics & Fleet Summary Delegation
  // ---------------------------------------------------------------------------
  group('ExpensesController - Operational Metrics & Fleet Summary Delegation', () {
    test('getVehicleMetrics delegates to ExpenseService and calculates costPerKm', () {
      final ctrl = ExpensesController(
        vehicles: [testVehicle1], // 50,000 km
      );

      ctrl.setVehicle(testVehicle1);
      ctrl.setCategory(ExpenseCategory.fuel);
      ctrl.setAmount(2000.0);
      ctrl.setDescription('Fuel month total');
      ctrl.submitNewExpense();

      ctrl.setVehicle(testVehicle1);
      ctrl.setCategory(ExpenseCategory.maintenance);
      ctrl.setAmount(1000.0);
      ctrl.setDescription('Brake inspection');
      ctrl.submitNewExpense();

      final metrics = ctrl.getVehicleMetrics(testVehicle1);
      expect(metrics.vehicleId, equals(testVehicle1.id));
      expect(metrics.totalExpenses, equals(3000.0));
      expect(metrics.fuelExpenses, equals(2000.0));
      expect(metrics.maintenanceExpenses, equals(1000.0));
      expect(metrics.costPerKm, equals(0.06)); // 3000 / 50000 = 0.06
    });

    test('getFleetSummary aggregates fleet expenses and distance', () {
      final v1 = Vehicle(
        id: 'v1',
        name: 'Truck 1',
        plateNumber: '111',
        currentOdometer: 10000,
        status: VehicleStatus.active,
      );
      final v2 = Vehicle(
        id: 'v2',
        name: 'Truck 2',
        plateNumber: '222',
        currentOdometer: 20000,
        status: VehicleStatus.active,
      );

      final ctrl = ExpensesController(vehicles: [v1, v2]);

      ctrl.setVehicle(v1);
      ctrl.setCategory(ExpenseCategory.fuel);
      ctrl.setAmount(1500.0);
      ctrl.setDescription('Fuel truck 1');
      ctrl.submitNewExpense();

      ctrl.setVehicle(v2);
      ctrl.setCategory(ExpenseCategory.maintenance);
      ctrl.setAmount(1500.0);
      ctrl.setDescription('Maintenance truck 2');
      ctrl.submitNewExpense();

      final summary = ctrl.getFleetSummary();
      expect(summary.totalExpenses, equals(3000.0));
      expect(summary.totalFuel, equals(1500.0));
      expect(summary.totalMaintenance, equals(1500.0));
      expect(summary.totalDistanceKm, equals(30000));
      expect(summary.overallCostPerKm, equals(0.10)); // 3000 / 30000 = 0.10
      expect(summary.vehicleMetrics.containsKey('v1'), isTrue);
      expect(summary.vehicleMetrics.containsKey('v2'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // 8. ExpensesState copyWith flags
  // ---------------------------------------------------------------------------
  group('ExpensesState - copyWith flags', () {
    test('all clear flags work as intended', () {
      final date = DateTime(2026, 11, 1);
      final state = ExpensesState(
        vehicleFilter: 'v1',
        driverFilter: 'd1',
        categoryFilter: ExpenseCategory.fuel,
        startDateFilter: date,
        endDateFilter: date,
        vehicleId: 'v1',
        vehicleName: 'Vehicle 1',
        driverId: 'd1',
        driverName: 'Driver 1',
        odometerReading: 50000,
        reference: 'REF',
        createdBy: 'Admin',
        errorMessage: 'Some error',
      );

      final cleared = state.copyWith(
        clearVehicleFilter: true,
        clearDriverFilter: true,
        clearCategoryFilter: true,
        clearDateFilter: true,
        clearVehicle: true,
        clearDriver: true,
        clearOdometer: true,
        clearReference: true,
        clearCreatedBy: true,
        clearError: true,
      );

      expect(cleared.vehicleFilter, isNull);
      expect(cleared.driverFilter, isNull);
      expect(cleared.categoryFilter, isNull);
      expect(cleared.startDateFilter, isNull);
      expect(cleared.endDateFilter, isNull);
      expect(cleared.vehicleId, isNull);
      expect(cleared.vehicleName, isNull);
      expect(cleared.driverId, isNull);
      expect(cleared.driverName, isNull);
      expect(cleared.odometerReading, isNull);
      expect(cleared.reference, isNull);
      expect(cleared.createdBy, isNull);
      expect(cleared.errorMessage, isNull);
    });
  });
}
