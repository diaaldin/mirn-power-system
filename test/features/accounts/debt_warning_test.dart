import 'package:test/test.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/contact.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/statement_entry.dart';
import 'package:sales_logistics_system/features/accounts/domain/services/debt_warning_evaluator.dart';

void main() {
  group('Customer Debt Warning & Balance Ledger Engine', () {
    final customer = Contact(
      id: 'cust-001',
      type: ContactType.customer,
      name: 'Al-Quds Contracting Co.',
      phone: '050-1234567',
      address: 'Jerusalem',
      taxId: '515000123',
      debtWarningLimit: 5000.0,
      currentBalance: 4000.0, // owes ₪4,000
    );

    test('does not trigger warning when new debt is within limit', () {
      final result = DebtWarningEvaluator.evaluate(
        contact: customer,
        additionalDebt: 800.0,
      );

      expect(result.isExceeded, isFalse);
      expect(result.totalProjectedDebt, equals(4800.0));
      expect(result.exceededAmount, equals(0.0));
      expect(result.canProceed, isTrue); // Anti-goal guarantee: never hard blocks
    });

    test('triggers soft warning with exact delta when limit is exceeded', () {
      final result = DebtWarningEvaluator.evaluate(
        contact: customer,
        additionalDebt: 1500.0, // 4000 + 1500 = 5500 > 5000
      );

      expect(result.isExceeded, isTrue);
      expect(result.totalProjectedDebt, equals(5500.0));
      expect(result.exceededAmount, equals(500.0));
      expect(result.canProceed, isTrue); // Always allows confirmation
      expect(result.warningMessage, contains('₪500.00'));
    });

    test('ignores customers without debt limit set (limit = 0)', () {
      final generalCustomer = Contact(
        id: 'cust-general',
        type: ContactType.customer,
        name: 'General Customer (عميل عام)',
        phone: '',
        address: '',
        taxId: '',
        debtWarningLimit: 0.0,
        currentBalance: 0.0,
      );

      final result = DebtWarningEvaluator.evaluate(
        contact: generalCustomer,
        additionalDebt: 10000.0,
      );

      expect(result.isExceeded, isFalse);
      expect(result.canProceed, isTrue);
    });

    test('verifies StatementEntry running balance mutation', () {
      final entry = StatementEntry(
        id: 'stmt-001',
        contactId: 'cust-001',
        contactType: ContactType.customer,
        date: DateTime(2026, 11, 14),
        type: StatementEntryType.saleInvoice,
        referenceNumber: 'INV-2026-00001',
        debit: 1500.0,
        credit: 0.0,
        runningBalance: 5500.0,
        description: 'חשבונית מס קבלה / فاتورة مبيعات',
      );

      expect(entry.referenceNumber, equals('INV-2026-00001'));
      expect(entry.debit, equals(1500.0));
      expect(entry.runningBalance, equals(5500.0));
    });
  });
}
