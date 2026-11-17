import 'package:test/test.dart';
import 'package:sales_logistics_system/features/expenses/domain/models/expense.dart';
import 'package:sales_logistics_system/features/fleet/domain/models/vehicle.dart';
import 'package:sales_logistics_system/features/fleet/domain/models/driver.dart';
import 'package:sales_logistics_system/features/expenses/domain/services/expense_service.dart';

void main() {
  group('ExpenseService Domain Service & Cost/KM Engine', () {
    final testTruck1 = Vehicle(
      id: 'veh-001',
      name: 'Volvo FH 500 Heavy Hauler',
      plateNumber: '12-345-67',
      modelYear: 2023,
      currentOdometer: 100000,
      status: VehicleStatus.active,
    );

    final testTruck2 = Vehicle(
      id: 'veh-002',
      name: 'Mercedes Actros 1845',
      plateNumber: '78-901-23',
      modelYear: 2022,
      currentOdometer: 50000,
      status: VehicleStatus.active,
    );

    final testDriver = Driver(
      id: 'drv-001',
      fullName: 'Ahmad Al-Mansour',
      phone: '050-7654321',
      licenseNumber: 'LIC-998877',
      status: DriverStatus.active,
    );

    group('createExpense validation & creation', () {
      test('creates valid expense with all specified fields', () {
        final date = DateTime(2026, 11, 15);
        final input = CreateExpenseInput(
          id: 'exp-test-01',
          expenseNumber: 'EXP-2026-00001',
          date: date,
          category: ExpenseCategory.fuel,
          amount: 450.50,
          description: 'Full tank diesel refill',
          vehicleId: testTruck1.id,
          driverId: testDriver.id,
          odometerReading: 100500,
          paymentMethod: ExpensePaymentMethod.cash,
          reference: 'INVOICE-9982',
          createdBy: 'admin',
        );

        final expense = ExpenseService.createExpense(input, vehicle: testTruck1);

        expect(expense.id, equals('exp-test-01'));
        expect(expense.expenseNumber, equals('EXP-2026-00001'));
        expect(expense.date, equals(date));
        expect(expense.category, equals(ExpenseCategory.fuel));
        expect(expense.amount, equals(450.50));
        expect(expense.description, equals('Full tank diesel refill'));
        expect(expense.vehicleId, equals(testTruck1.id));
        expect(expense.driverId, equals(testDriver.id));
        expect(expense.odometerReading, equals(100500));
        expect(expense.paymentMethod, equals(ExpensePaymentMethod.cash));
        expect(expense.reference, equals('INVOICE-9982'));
        expect(expense.createdBy, equals('admin'));
        expect(expense.createdAt, isNotNull);
      });

      test('auto-generates id when input.id is null', () {
        final input = CreateExpenseInput(
          expenseNumber: 'EXP-2026-00002',
          date: DateTime(2026, 11, 15),
          category: ExpenseCategory.maintenance,
          amount: 250.0,
          description: 'Oil change',
          paymentMethod: ExpensePaymentMethod.bankTransfer,
        );

        final expense = ExpenseService.createExpense(input);
        expect(expense.id, isNotEmpty);
        expect(expense.expenseNumber, equals('EXP-2026-00002'));
      });

      test('rejects zero or negative amounts with ArgumentError', () {
        final baseInputZero = CreateExpenseInput(
          expenseNumber: 'EXP-2026-00003',
          date: DateTime(2026, 11, 15),
          category: ExpenseCategory.fuel,
          amount: 0.0,
          description: 'Zero fuel',
          paymentMethod: ExpensePaymentMethod.cash,
        );

        expect(
          () => ExpenseService.createExpense(baseInputZero),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Expense amount must be strictly positive'),
            ),
          ),
        );

        final baseInputNegative = CreateExpenseInput(
          expenseNumber: 'EXP-2026-00004',
          date: DateTime(2026, 11, 15),
          category: ExpenseCategory.fuel,
          amount: -100.0,
          description: 'Negative fuel',
          paymentMethod: ExpensePaymentMethod.cash,
        );

        expect(
          () => ExpenseService.createExpense(baseInputNegative),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Expense amount must be strictly positive'),
            ),
          ),
        );
      });

      test('rejects blank or whitespace description with ArgumentError', () {
        final emptyDesc = CreateExpenseInput(
          expenseNumber: 'EXP-2026-00005',
          date: DateTime(2026, 11, 15),
          category: ExpenseCategory.other,
          amount: 150.0,
          description: '   ',
          paymentMethod: ExpensePaymentMethod.cash,
        );

        expect(
          () => ExpenseService.createExpense(emptyDesc),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Description cannot be empty'),
            ),
          ),
        );
      });

      test('rejects blank or whitespace expense number with ArgumentError', () {
        final emptyNumber = CreateExpenseInput(
          expenseNumber: '   ',
          date: DateTime(2026, 11, 15),
          category: ExpenseCategory.other,
          amount: 150.0,
          description: 'Valid description',
          paymentMethod: ExpensePaymentMethod.cash,
        );

        expect(
          () => ExpenseService.createExpense(emptyNumber),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Expense number cannot be empty'),
            ),
          ),
        );
      });

      test('rejects backward odometer reading against vehicle current odometer', () {
        // testTruck1 has currentOdometer: 100000
        final backwardInput = CreateExpenseInput(
          expenseNumber: 'EXP-2026-00006',
          date: DateTime(2026, 11, 15),
          category: ExpenseCategory.fuel,
          amount: 300.0,
          description: 'Diesel fuel',
          vehicleId: testTruck1.id,
          odometerReading: 99999, // Lower than 100000
          paymentMethod: ExpensePaymentMethod.cash,
        );

        expect(
          () => ExpenseService.createExpense(backwardInput, vehicle: testTruck1),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Odometer reading cannot be lower than current vehicle odometer'),
            ),
          ),
        );
      });

      test('allows equal or higher odometer reading against vehicle', () {
        final equalInput = CreateExpenseInput(
          expenseNumber: 'EXP-2026-00007',
          date: DateTime(2026, 11, 15),
          category: ExpenseCategory.fuel,
          amount: 300.0,
          description: 'Diesel fuel at depot',
          vehicleId: testTruck1.id,
          odometerReading: 100000, // Equal
          paymentMethod: ExpensePaymentMethod.cash,
        );

        final exp1 = ExpenseService.createExpense(equalInput, vehicle: testTruck1);
        expect(exp1.odometerReading, equals(100000));

        final higherInput = CreateExpenseInput(
          expenseNumber: 'EXP-2026-00008',
          date: DateTime(2026, 11, 15),
          category: ExpenseCategory.fuel,
          amount: 300.0,
          description: 'Diesel fuel on highway',
          vehicleId: testTruck1.id,
          odometerReading: 100450, // Higher
          paymentMethod: ExpensePaymentMethod.cash,
        );

        final exp2 = ExpenseService.createExpense(higherInput, vehicle: testTruck1);
        expect(exp2.odometerReading, equals(100450));
      });

      test('infers vehicleId from vehicle parameter if vehicleId is not specified in input', () {
        final input = CreateExpenseInput(
          expenseNumber: 'EXP-2026-00009',
          date: DateTime(2026, 11, 15),
          category: ExpenseCategory.fuel,
          amount: 200.0,
          description: 'Fuel with inferred vehicle',
          paymentMethod: ExpensePaymentMethod.cash,
        );

        final exp = ExpenseService.createExpense(input, vehicle: testTruck1);
        expect(exp.vehicleId, equals(testTruck1.id));
      });
    });

    group('filterExpenses', () {
      final sampleExpenses = [
        Expense(
          id: 'exp-1',
          expenseNumber: 'EXP-2026-00001',
          date: DateTime(2026, 11, 1),
          category: ExpenseCategory.fuel,
          amount: 500.0,
          description: 'Fuel Truck 1',
          vehicleId: testTruck1.id,
          driverId: testDriver.id,
          paymentMethod: ExpensePaymentMethod.cash,
          createdAt: DateTime(2026, 11, 1),
        ),
        Expense(
          id: 'exp-2',
          expenseNumber: 'EXP-2026-00002',
          date: DateTime(2026, 11, 5),
          category: ExpenseCategory.maintenance,
          amount: 350.0,
          description: 'Brake pads Truck 1',
          vehicleId: testTruck1.id,
          driverId: testDriver.id,
          paymentMethod: ExpensePaymentMethod.bankTransfer,
          createdAt: DateTime(2026, 11, 5),
        ),
        Expense(
          id: 'exp-3',
          expenseNumber: 'EXP-2026-00003',
          date: DateTime(2026, 11, 10),
          category: ExpenseCategory.fuel,
          amount: 600.0,
          description: 'Fuel Truck 2',
          vehicleId: testTruck2.id,
          driverId: 'drv-002',
          paymentMethod: ExpensePaymentMethod.cash,
          createdAt: DateTime(2026, 11, 10),
        ),
        Expense(
          id: 'exp-4',
          expenseNumber: 'EXP-2026-00004',
          date: DateTime(2026, 11, 15),
          category: ExpenseCategory.rent,
          amount: 2000.0,
          description: 'Warehouse rent',
          paymentMethod: ExpensePaymentMethod.check,
          createdAt: DateTime(2026, 11, 15),
        ),
      ];

      test('returns all expenses when no filters are set', () {
        final result = ExpenseService.filterExpenses(expenses: sampleExpenses);
        expect(result.length, equals(4));
      });

      test('filters by vehicleId', () {
        final result = ExpenseService.filterExpenses(
          expenses: sampleExpenses,
          vehicleId: testTruck1.id,
        );
        expect(result.length, equals(2));
        expect(result.every((e) => e.vehicleId == testTruck1.id), isTrue);
      });

      test('filters by driverId', () {
        final result = ExpenseService.filterExpenses(
          expenses: sampleExpenses,
          driverId: testDriver.id,
        );
        expect(result.length, equals(2));
        expect(result.every((e) => e.driverId == testDriver.id), isTrue);
      });

      test('filters by category', () {
        final result = ExpenseService.filterExpenses(
          expenses: sampleExpenses,
          category: ExpenseCategory.fuel,
        );
        expect(result.length, equals(2));
        expect(result.every((e) => e.category == ExpenseCategory.fuel), isTrue);
      });

      test('filters by date range', () {
        final result = ExpenseService.filterExpenses(
          expenses: sampleExpenses,
          startDate: DateTime(2026, 11, 4),
          endDate: DateTime(2026, 11, 12),
        );
        expect(result.length, equals(2));
        expect(result.map((e) => e.id), containsAll(['exp-2', 'exp-3']));
      });

      test('combines multiple filters simultaneously', () {
        final result = ExpenseService.filterExpenses(
          expenses: sampleExpenses,
          vehicleId: testTruck1.id,
          category: ExpenseCategory.fuel,
        );
        expect(result.length, equals(1));
        expect(result.first.id, equals('exp-1'));
      });
    });

    group('calculateVehicleMetrics', () {
      test('calculates costPerKm, fuelCostPerKm, and maintenanceCostPerKm correctly', () {
        final truckExpenses = [
          Expense(
            id: 'exp-1',
            expenseNumber: 'EXP-2026-00001',
            date: DateTime(2026, 11, 1),
            category: ExpenseCategory.fuel,
            amount: 500.0,
            description: 'Fuel refill',
            vehicleId: testTruck1.id,
            paymentMethod: ExpensePaymentMethod.cash,
            createdAt: DateTime(2026, 11, 1),
          ),
          Expense(
            id: 'exp-2',
            expenseNumber: 'EXP-2026-00002',
            date: DateTime(2026, 11, 3),
            category: ExpenseCategory.maintenance,
            amount: 300.0,
            description: 'Brake service',
            vehicleId: testTruck1.id,
            paymentMethod: ExpensePaymentMethod.cash,
            createdAt: DateTime(2026, 11, 3),
          ),
          Expense(
            id: 'exp-3',
            expenseNumber: 'EXP-2026-00003',
            date: DateTime(2026, 11, 5),
            category: ExpenseCategory.tires,
            amount: 200.0,
            description: 'Front tire replacement',
            vehicleId: testTruck1.id,
            paymentMethod: ExpensePaymentMethod.cash,
            createdAt: DateTime(2026, 11, 5),
          ),
          Expense(
            id: 'exp-4',
            expenseNumber: 'EXP-2026-00004',
            date: DateTime(2026, 11, 8),
            category: ExpenseCategory.licensingInsurance,
            amount: 150.0,
            description: 'Annual test sticker',
            vehicleId: testTruck1.id,
            paymentMethod: ExpensePaymentMethod.cash,
            createdAt: DateTime(2026, 11, 8),
          ),
          // Expense for a different vehicle - must be ignored
          Expense(
            id: 'exp-other',
            expenseNumber: 'EXP-2026-00005',
            date: DateTime(2026, 11, 9),
            category: ExpenseCategory.fuel,
            amount: 999.0,
            description: 'Different truck fuel',
            vehicleId: testTruck2.id,
            paymentMethod: ExpensePaymentMethod.cash,
            createdAt: DateTime(2026, 11, 9),
          ),
        ];

        // testTruck1 has currentOdometer = 100000, let's test with overrideDistanceKm: 1000
        final metrics = ExpenseService.calculateVehicleMetrics(
          vehicle: testTruck1,
          expenses: truckExpenses,
          overrideDistanceKm: 1000,
        );

        expect(metrics.vehicleId, equals(testTruck1.id));
        expect(metrics.vehicleName, equals(testTruck1.name));
        expect(metrics.totalExpenses, equals(1150.0));
        expect(metrics.fuelExpenses, equals(500.0));
        expect(metrics.maintenanceExpenses, equals(500.0)); // 300 + 200
        expect(metrics.otherExpenses, equals(150.0));
        expect(metrics.totalDistanceKm, equals(1000));
        expect(metrics.costPerKm, equals(1.15)); // 1150 / 1000
        expect(metrics.fuelCostPerKm, equals(0.50)); // 500 / 1000
        expect(metrics.maintenanceCostPerKm, equals(0.50)); // 500 / 1000
        expect(metrics.expenseCount, equals(4));
      });

      test('rounds costPerKm to two decimal places', () {
        final truckExpenses = [
          Expense(
            id: 'exp-r',
            expenseNumber: 'EXP-2026-00010',
            date: DateTime(2026, 11, 1),
            category: ExpenseCategory.fuel,
            amount: 100.0,
            description: 'Fuel',
            vehicleId: testTruck1.id,
            paymentMethod: ExpensePaymentMethod.cash,
            createdAt: DateTime(2026, 11, 1),
          ),
        ];

        // 100 / 300 = 0.333333... -> 0.33
        final metrics = ExpenseService.calculateVehicleMetrics(
          vehicle: testTruck1,
          expenses: truckExpenses,
          overrideDistanceKm: 300,
        );

        expect(metrics.costPerKm, equals(0.33));
        expect(metrics.fuelCostPerKm, equals(0.33));
        expect(metrics.maintenanceCostPerKm, equals(0.0));
      });

      test('guards against zero or negative distance (returns 0.0 for cost per km)', () {
        final zeroOdometerVehicle = Vehicle(
          id: 'veh-zero',
          name: 'Zero Km Vehicle',
          plateNumber: '00-000-00',
          currentOdometer: 0,
          status: VehicleStatus.active,
        );

        final expenses = [
          Expense(
            id: 'exp-z',
            expenseNumber: 'EXP-2026-00011',
            date: DateTime(2026, 11, 1),
            category: ExpenseCategory.fuel,
            amount: 500.0,
            description: 'Fuel',
            vehicleId: zeroOdometerVehicle.id,
            paymentMethod: ExpensePaymentMethod.cash,
            createdAt: DateTime(2026, 11, 1),
          ),
        ];

        final metricsDefault = ExpenseService.calculateVehicleMetrics(
          vehicle: zeroOdometerVehicle,
          expenses: expenses,
        );

        expect(metricsDefault.totalDistanceKm, equals(0));
        expect(metricsDefault.costPerKm, equals(0.0));
        expect(metricsDefault.fuelCostPerKm, equals(0.0));
        expect(metricsDefault.maintenanceCostPerKm, equals(0.0));

        final metricsNegative = ExpenseService.calculateVehicleMetrics(
          vehicle: testTruck1,
          expenses: expenses,
          overrideDistanceKm: -50,
        );

        expect(metricsNegative.costPerKm, equals(0.0));
        expect(metricsNegative.fuelCostPerKm, equals(0.0));
        expect(metricsNegative.maintenanceCostPerKm, equals(0.0));
      });
    });

    group('calculateFleetSummary', () {
      test('aggregates metrics across all vehicles and unassigned general expenses', () {
        final vehicles = [testTruck1, testTruck2];
        final allExpenses = [
          // Truck 1: Fuel 600, Maintenance 400
          Expense(
            id: 'e-1',
            expenseNumber: 'EXP-2026-00001',
            date: DateTime(2026, 11, 1),
            category: ExpenseCategory.fuel,
            amount: 600.0,
            description: 'Fuel Truck 1',
            vehicleId: testTruck1.id,
            paymentMethod: ExpensePaymentMethod.cash,
            createdAt: DateTime(2026, 11, 1),
          ),
          Expense(
            id: 'e-2',
            expenseNumber: 'EXP-2026-00002',
            date: DateTime(2026, 11, 2),
            category: ExpenseCategory.maintenance,
            amount: 400.0,
            description: 'Maintenance Truck 1',
            vehicleId: testTruck1.id,
            paymentMethod: ExpensePaymentMethod.cash,
            createdAt: DateTime(2026, 11, 2),
          ),
          // Truck 2: Fuel 500, Tires 300
          Expense(
            id: 'e-3',
            expenseNumber: 'EXP-2026-00003',
            date: DateTime(2026, 11, 3),
            category: ExpenseCategory.fuel,
            amount: 500.0,
            description: 'Fuel Truck 2',
            vehicleId: testTruck2.id,
            paymentMethod: ExpensePaymentMethod.cash,
            createdAt: DateTime(2026, 11, 3),
          ),
          Expense(
            id: 'e-4',
            expenseNumber: 'EXP-2026-00004',
            date: DateTime(2026, 11, 4),
            category: ExpenseCategory.tires,
            amount: 300.0,
            description: 'Tires Truck 2',
            vehicleId: testTruck2.id,
            paymentMethod: ExpensePaymentMethod.cash,
            createdAt: DateTime(2026, 11, 4),
          ),
          // General overhead (no vehicleId): Rent 2000, Electricity 500
          Expense(
            id: 'e-5',
            expenseNumber: 'EXP-2026-00005',
            date: DateTime(2026, 11, 5),
            category: ExpenseCategory.rent,
            amount: 2000.0,
            description: 'Depot Rent',
            paymentMethod: ExpensePaymentMethod.bankTransfer,
            createdAt: DateTime(2026, 11, 5),
          ),
          Expense(
            id: 'e-6',
            expenseNumber: 'EXP-2026-00006',
            date: DateTime(2026, 11, 6),
            category: ExpenseCategory.utilities,
            amount: 500.0,
            description: 'Electricity bill',
            paymentMethod: ExpensePaymentMethod.bankTransfer,
            createdAt: DateTime(2026, 11, 6),
          ),
        ];

        // testTruck1 odometer = 100000, testTruck2 odometer = 50000 -> total = 150000
        // totalExpenses = 600 + 400 + 500 + 300 + 2000 + 500 = 4300.0
        // totalFuel = 600 + 500 = 1100.0
        // totalMaintenance = 400 + 300 = 700.0
        // overallCostPerKm = 4300 / 150000 = 0.028666... -> 0.03
        final summary = ExpenseService.calculateFleetSummary(
          vehicles: vehicles,
          expenses: allExpenses,
        );

        expect(summary.totalExpenses, equals(4300.0));
        expect(summary.totalFuel, equals(1100.0));
        expect(summary.totalMaintenance, equals(700.0));
        expect(summary.totalDistanceKm, equals(150000));
        expect(summary.overallCostPerKm, equals(0.03));
        expect(summary.vehicleMetrics.containsKey(testTruck1.id), isTrue);
        expect(summary.vehicleMetrics.containsKey(testTruck2.id), isTrue);

        final m1 = summary.vehicleMetrics[testTruck1.id]!;
        expect(m1.totalExpenses, equals(1000.0));
        expect(m1.fuelExpenses, equals(600.0));
        expect(m1.maintenanceExpenses, equals(400.0));

        final m2 = summary.vehicleMetrics[testTruck2.id]!;
        expect(m2.totalExpenses, equals(800.0));
        expect(m2.fuelExpenses, equals(500.0));
        expect(m2.maintenanceExpenses, equals(300.0));
      });

      test('guards against empty fleet or zero distance', () {
        final summary = ExpenseService.calculateFleetSummary(
          vehicles: [],
          expenses: [],
        );

        expect(summary.totalExpenses, equals(0.0));
        expect(summary.totalFuel, equals(0.0));
        expect(summary.totalMaintenance, equals(0.0));
        expect(summary.totalDistanceKm, equals(0));
        expect(summary.overallCostPerKm, equals(0.0));
        expect(summary.vehicleMetrics, isEmpty);
      });
    });
  });
}
