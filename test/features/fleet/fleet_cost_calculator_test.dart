import 'package:test/test.dart';
import 'package:sales_logistics_system/features/fleet/domain/models/vehicle.dart';
import 'package:sales_logistics_system/features/fleet/domain/models/driver.dart';
import 'package:sales_logistics_system/features/logistics/domain/models/dispatch.dart';
import 'package:sales_logistics_system/features/expenses/domain/models/expense.dart';
import 'package:sales_logistics_system/features/fleet/domain/services/fleet_cost_calculator.dart';

void main() {
  group('Fleet Costing & Logistics Dispatch Engine', () {
    final truck = Vehicle(
      id: 'veh-001',
      name: 'Volvo FH 500 Heavy Hauler',
      plateNumber: '12-345-67',
      modelYear: 2023,
      currentOdometer: 105400,
      status: VehicleStatus.active,
    );

    final driver = Driver(
      id: 'drv-001',
      fullName: 'Ahmad Al-Mansour',
      phone: '050-7654321',
      licenseNumber: 'LIC-998877',
      status: DriverStatus.active,
    );

    final expenses = [
      Expense(
        id: 'exp-001',
        expenseNumber: 'EXP-2026-00001',
        date: DateTime(2026, 11, 10),
        category: ExpenseCategory.fuel,
        amount: 500.0,
        description: 'Diesel fuel refill (100L)',
        vehicleId: truck.id,
        driverId: driver.id,
        odometerReading: 105000,
        paymentMethod: ExpensePaymentMethod.cash,
        createdAt: DateTime(2026, 11, 10),
      ),
      Expense(
        id: 'exp-002',
        expenseNumber: 'EXP-2026-00002',
        date: DateTime(2026, 11, 12),
        category: ExpenseCategory.maintenance,
        amount: 300.0,
        description: 'Engine oil filter replacement',
        vehicleId: truck.id,
        driverId: driver.id,
        odometerReading: 105200,
        paymentMethod: ExpensePaymentMethod.bankTransfer,
        createdAt: DateTime(2026, 11, 12),
      ),
    ];

    test('calculates operational cost per kilometer accurately', () {
      final costPerKm = FleetCostCalculator.calculateCostPerKm(
        expenses: expenses,
        startOdometer: 105000,
        endOdometer: 105400, // 400 km traveled
      );

      // Total expense = 500 + 300 = 800. Distance = 400 km. Cost/km = 800 / 400 = 2.00
      expect(costPerKm, equals(2.0));
    });

    test('prevents division by zero on identical odometer readings', () {
      final costPerKm = FleetCostCalculator.calculateCostPerKm(
        expenses: expenses,
        startOdometer: 105000,
        endOdometer: 105000,
      );
      expect(costPerKm, equals(0.0));
    });

    test('aggregates total expenses by category', () {
      final totals = FleetCostCalculator.aggregateByCategory(expenses);
      expect(totals[ExpenseCategory.fuel], equals(500.0));
      expect(totals[ExpenseCategory.maintenance], equals(300.0));
    });

    test('verifies dispatch status progression and data model', () {
      final dispatch = Dispatch(
        id: 'dsp-001',
        dispatchNumber: 'DSP-2026-00001',
        date: DateTime(2026, 11, 14),
        customerId: 'cust-10',
        customerName: 'Al-Quds Contracting',
        customerPhone: '050-1234567',
        deliveryAddress: 'Beit Hanina, Jerusalem',
        cargoDescription: '150 m² Marble + 4 Toilets',
        vehicleId: truck.id,
        vehicleName: truck.name,
        plateNumber: truck.plateNumber,
        driverId: driver.id,
        driverName: driver.fullName,
        status: DispatchStatus.pending,
        updatedAt: DateTime(2026, 11, 14),
      );

      expect(dispatch.dispatchNumber, equals('DSP-2026-00001'));
      expect(dispatch.status, equals(DispatchStatus.pending));

      final updated = dispatch.copyWith(status: DispatchStatus.delivered);
      expect(updated.status, equals(DispatchStatus.delivered));
    });
  });
}
