import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:sales_logistics_system/core/pdf/expense_pdf_generator.dart';
import 'package:sales_logistics_system/core/pdf/invoice_pdf_generator.dart';
import 'package:sales_logistics_system/features/expenses/domain/models/expense.dart';
import 'package:sales_logistics_system/features/fleet/domain/models/driver.dart';
import 'package:sales_logistics_system/features/fleet/domain/models/vehicle.dart';

void main() {
  group('ExpensePdfGenerator Tests', () {
    const testCompany = CompanyInfo(
      name: 'M.I.R.N POWER',
      nameHebrew: 'מ.י.ר.נ. פאוור',
      nameArabic: 'م.ي.ر.ن. باور',
      subtitleHebrew: 'כלים סניטריים, שיש, אבן והובלה',
      subtitleArabic: 'أدوات صحية، رخام، حجر، ونقل وشحن',
      taxId: '515123456',
      phone: '02-123-4567',
      address: 'ירושלים / القدس',
    );

    const testVehicle = Vehicle(
      id: 'veh-001',
      name: 'Volvo FH 500',
      plateNumber: '12-345-67',
      modelYear: 2023,
      currentOdometer: 145200,
      status: VehicleStatus.active,
    );

    const testDriver = Driver(
      id: 'drv-001',
      fullName: 'Yousef Hamdan / يوسف حمدان',
      phone: '052-123-4567',
      licenseNumber: 'DL-987654',
      status: DriverStatus.active,
    );

    final testExpense = Expense(
      id: 'exp-001',
      expenseNumber: 'EXP-2026-00001',
      date: DateTime(2026, 11, 16),
      category: ExpenseCategory.fuel,
      amount: 850.50,
      description: 'Diesel refueling 120 Liters / تعبئة وقود ديزل 120 لتر',
      vehicleId: 'veh-001',
      driverId: 'drv-001',
      odometerReading: 145200,
      paymentMethod: ExpensePaymentMethod.cash,
      reference: 'REC-99412',
      createdBy: 'Admin / מנהל',
      createdAt: DateTime(2026, 11, 16, 14, 30),
    );

    test('generates non-empty PDF bytes', () async {
      final Uint8List bytes = await ExpensePdfGenerator.generate(
        expense: testExpense,
        company: testCompany,
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('generates PDF with vehicle and driver attribution', () async {
      final Uint8List bytes = await ExpensePdfGenerator.generate(
        expense: testExpense,
        company: testCompany,
        vehicle: testVehicle,
        driver: testDriver,
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('generates PDF without vehicle or driver (general operational overhead)', () async {
      final overheadExpense = Expense(
        id: 'exp-002',
        expenseNumber: 'EXP-2026-00002',
        date: DateTime(2026, 11, 16),
        category: ExpenseCategory.rent,
        amount: 12000.00,
        description: 'Office and warehouse monthly rent / إيجار المكتب والمستودع الشهري',
        paymentMethod: ExpensePaymentMethod.bankTransfer,
        reference: 'TRX-778899',
        createdBy: 'Accountant',
        createdAt: DateTime(2026, 11, 16, 10, 0),
      );

      final Uint8List bytes = await ExpensePdfGenerator.generate(
        expense: overheadExpense,
        company: testCompany,
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('handles all expense categories', () async {
      for (final category in ExpenseCategory.values) {
        final expense = Expense(
          id: 'exp-${category.name}',
          expenseNumber: 'EXP-2026-${category.index}',
          date: DateTime(2026, 11, 16),
          category: category,
          amount: 500.00,
          description: 'Testing category ${category.name}',
          paymentMethod: ExpensePaymentMethod.cash,
          createdAt: DateTime(2026, 11, 16),
        );

        final bytes = await ExpensePdfGenerator.generate(
          expense: expense,
          company: testCompany,
        );

        expect(bytes, isNotEmpty);
        expect(bytes.length, greaterThan(100));
      }
    });

    test('handles all payment methods', () async {
      for (final method in ExpensePaymentMethod.values) {
        final expense = Expense(
          id: 'exp-${method.name}',
          expenseNumber: 'EXP-2026-${method.index}',
          date: DateTime(2026, 11, 16),
          category: ExpenseCategory.other,
          amount: 250.00,
          description: 'Testing payment method ${method.name}',
          paymentMethod: method,
          createdAt: DateTime(2026, 11, 16),
        );

        final bytes = await ExpensePdfGenerator.generate(
          expense: expense,
          company: testCompany,
        );

        expect(bytes, isNotEmpty);
        expect(bytes.length, greaterThan(100));
      }
    });
  });
}
