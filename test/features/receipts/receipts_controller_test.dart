import 'package:test/test.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/contact.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/statement_entry.dart';
import 'package:sales_logistics_system/features/checks/domain/models/check_record.dart';
import 'package:sales_logistics_system/features/receipts/domain/models/payment_receipt.dart';
import 'package:sales_logistics_system/features/sales/domain/models/payment_split.dart';
import 'package:sales_logistics_system/features/receipts/presentation/controllers/receipts_controller.dart';

void main() {
  group('ReceiptsController & ReceiptFormState Tests', () {
    late Contact testCustomer;
    late Contact testSupplier;
    final testDate = DateTime(2026, 11, 14, 11, 0);

    setUp(() {
      testCustomer = const Contact(
        id: 'cust-201',
        type: ContactType.customer,
        name: 'معرض الأندلس للرخام',
        phone: '0599000111',
        address: 'نابلس - رفيديا',
        taxId: '590001112',
        debtWarningLimit: 40000.0,
        currentBalance: 25000.0,
      );

      testSupplier = const Contact(
        id: 'supp-301',
        type: ContactType.supplier,
        name: 'مصنع الشرق للأدوات الصحية',
        phone: '0599000222',
        address: 'الخليل - المنطقة الصناعية',
        taxId: '590002223',
        debtWarningLimit: 60000.0,
        currentBalance: 30000.0,
      );
    });

    group('Initial State & Parameter Initialization', () {
      test('defaults without parameters initialize correctly', () {
        final controller = ReceiptsController();
        final state = controller.state;

        expect(state.contact, isNull);
        expect(state.receiptType, equals(ReceiptType.customerReceipt));
        expect(state.receiptNumber, isEmpty);
        expect(state.totalAmount, equals(0.0));
        expect(state.payments, isEmpty);
        expect(state.notes, isNull);
        expect(state.allocatedAmount, equals(0.0));
        expect(state.remainingToAllocate, equals(0.0));
        expect(state.projectedBalance, isNull);
        expect(state.isComplete, isFalse);
      });

      test('initializes with custom parameters', () {
        final controller = ReceiptsController(
          initialContact: testCustomer,
          initialType: ReceiptType.supplierPayment,
          initialReceiptNumber: 'VOUCH-2026-001',
          initialDate: testDate,
        );
        final state = controller.state;

        expect(state.contact, equals(testCustomer));
        expect(state.receiptType, equals(ReceiptType.supplierPayment));
        expect(state.receiptNumber, equals('VOUCH-2026-001'));
        expect(state.date, equals(testDate));
        expect(state.projectedBalance, equals(25000.0));
        expect(state.isComplete, isFalse);
      });
    });

    group('State Computation & Dynamic Recalculation', () {
      test('remainingToAllocate and projectedBalance recalculate dynamically on payment line addition and removal', () {
        final controller = ReceiptsController(
          initialContact: testCustomer,
          initialReceiptNumber: 'REC-2026-101',
          initialDate: testDate,
        );
        controller.setTotalAmount(10000.0);

        var state = controller.state;
        expect(state.totalAmount, equals(10000.0));
        expect(state.allocatedAmount, equals(0.0));
        expect(state.remainingToAllocate, equals(10000.0));
        expect(state.projectedBalance, equals(25000.0)); // 25000 - 0
        expect(state.isComplete, isFalse);

        // Add first payment line: Cash 4,000
        controller.addPaymentLine(
          method: PaymentMethod.cash,
          amount: 4000.0,
          reference: 'CASH-REC-1',
        );

        state = controller.state;
        expect(state.payments.length, equals(1));
        expect(state.allocatedAmount, equals(4000.0));
        expect(state.remainingToAllocate, equals(6000.0));
        expect(state.projectedBalance, equals(21000.0)); // 25000 - 4000
        expect(state.isComplete, isFalse);

        // Add second payment line: Check 6,000
        controller.addPaymentLine(
          method: PaymentMethod.check,
          amount: 6000.0,
          checkNumber: 'CHK-9988',
          bankName: 'بنك فلسطين',
          branchNumber: '450',
          accountNumber: '123456',
          dueDate: DateTime(2026, 12, 31),
          drawerName: 'أحمد التميمي',
        );

        state = controller.state;
        expect(state.payments.length, equals(2));
        expect(state.allocatedAmount, equals(10000.0));
        expect(state.remainingToAllocate, equals(0.0));
        expect(state.projectedBalance, equals(15000.0)); // 25000 - 10000
        expect(state.isComplete, isTrue);

        // Remove the first payment line (Cash 4,000)
        controller.removePaymentLine(0);

        state = controller.state;
        expect(state.payments.length, equals(1));
        expect(state.payments.first.method, equals(PaymentMethod.check));
        expect(state.allocatedAmount, equals(6000.0));
        expect(state.remainingToAllocate, equals(4000.0));
        expect(state.projectedBalance, equals(19000.0)); // 25000 - 6000
        expect(state.isComplete, isFalse);

        // Clear all payments
        controller.clearPayments();

        state = controller.state;
        expect(state.payments, isEmpty);
        expect(state.allocatedAmount, equals(0.0));
        expect(state.remainingToAllocate, equals(10000.0));
        expect(state.projectedBalance, equals(25000.0));
        expect(state.isComplete, isFalse);
      });

      test('supplier payment projected balance recalculates dynamically', () {
        final controller = ReceiptsController(
          initialContact: testSupplier,
          initialType: ReceiptType.supplierPayment,
          initialReceiptNumber: 'PAY-2026-201',
          initialDate: testDate,
        );
        controller.setTotalAmount(12000.0);

        expect(controller.state.projectedBalance, equals(30000.0));

        controller.addPaymentLine(
          method: PaymentMethod.check,
          amount: 7000.0,
          checkNumber: 'CHK-7700',
          bankName: 'بنك القدس',
        );

        expect(controller.state.allocatedAmount, equals(7000.0));
        expect(controller.state.remainingToAllocate, equals(5000.0));
        expect(controller.state.projectedBalance, equals(23000.0)); // 30000 - 7000

        controller.addPaymentLine(
          method: PaymentMethod.bankTransfer,
          amount: 5000.0,
          reference: 'TRF-5544',
        );

        expect(controller.state.allocatedAmount, equals(12000.0));
        expect(controller.state.remainingToAllocate, equals(0.0));
        expect(controller.state.projectedBalance, equals(18000.0)); // 30000 - 12000
        expect(controller.state.isComplete, isTrue);
      });

      test('handles fractional cents rounding accurately', () {
        final controller = ReceiptsController(
          initialContact: testCustomer,
          initialReceiptNumber: 'REC-FRAC',
        );
        controller.setTotalAmount(100.55);

        controller.addPaymentLine(
          method: PaymentMethod.cash,
          amount: 50.25,
        );
        controller.addPaymentLine(
          method: PaymentMethod.cash,
          amount: 50.30,
        );

        final state = controller.state;
        expect(state.allocatedAmount, equals(100.55));
        expect(state.remainingToAllocate, equals(0.0));
        expect(state.isComplete, isTrue);
        expect(state.projectedBalance, equals(24899.45));
      });
    });

    group('isComplete Flag Verification', () {
      test('isComplete is false when totalAmount is zero even if remainingToAllocate is zero', () {
        final controller = ReceiptsController(initialContact: testCustomer);
        controller.setTotalAmount(0.0);

        expect(controller.state.remainingToAllocate, equals(0.0));
        expect(controller.state.isComplete, isFalse);
      });

      test('isComplete is true within 0.01 tolerance', () {
        final controller = ReceiptsController(initialContact: testCustomer);
        controller.setTotalAmount(100.0);

        controller.addPaymentLine(
          method: PaymentMethod.cash,
          amount: 99.995,
        );

        // remaining = 100.0 - 100.0 = 0.0
        expect(controller.state.isComplete, isTrue);
      });

      test('isComplete is false when overallocated or underallocated', () {
        final controller = ReceiptsController(initialContact: testCustomer);
        controller.setTotalAmount(500.0);

        // Underallocated
        controller.addPaymentLine(
          method: PaymentMethod.cash,
          amount: 499.0,
        );
        expect(controller.state.remainingToAllocate, equals(1.0));
        expect(controller.state.isComplete, isFalse);

        // Overallocated
        controller.addPaymentLine(
          method: PaymentMethod.cash,
          amount: 2.0,
        );
        expect(controller.state.allocatedAmount, equals(501.0));
        expect(controller.state.remainingToAllocate, equals(-1.0));
        expect(controller.state.isComplete, isFalse);
      });
    });

    group('submitCustomerReceipt Workflow', () {
      test('submits valid customer receipt and returns ProcessCustomerReceiptResult', () {
        final controller = ReceiptsController(
          initialContact: testCustomer,
          initialReceiptNumber: 'REC-2026-900',
          initialDate: testDate,
        );
        controller.setTotalAmount(15000.0);
        controller.setNotes('دفعة نقدية وشيك على حساب مواد البناء');

        controller.addPaymentLine(
          method: PaymentMethod.cash,
          amount: 5000.0,
          reference: 'CSH-01',
        );
        controller.addPaymentLine(
          method: PaymentMethod.check,
          amount: 10000.0,
          checkNumber: 'CHK-12345',
          bankName: 'بنك فلسطين',
          branchNumber: '450',
          accountNumber: '987654',
          dueDate: DateTime(2026, 12, 1),
          drawerName: 'شركة الأندلس',
        );

        expect(controller.state.isComplete, isTrue);

        final result = controller.submitCustomerReceipt(createdBy: 'diaaldin');

        // Verify receipt
        expect(result.receipt.receiptNumber, equals('REC-2026-900'));
        expect(result.receipt.partyType, equals(ContactType.customer));
        expect(result.receipt.contactId, equals(testCustomer.id));
        expect(result.receipt.contactName, equals(testCustomer.name));
        expect(result.receipt.totalAmount, equals(15000.0));
        expect(result.receipt.payments.length, equals(2));
        expect(result.receipt.notes, equals('دفعة نقدية وشيك على حساب مواد البناء'));
        expect(result.receipt.createdBy, equals('diaaldin'));

        // Verify contact debt reduction (25,000 - 15,000 = 10,000)
        expect(result.updatedContact.currentBalance, equals(10000.0));
        expect(result.updatedContact.updatedAt, equals(testDate));

        // Verify statement entry
        expect(result.statementEntry.contactId, equals(testCustomer.id));
        expect(result.statementEntry.type, equals(StatementEntryType.paymentReceipt));
        expect(result.statementEntry.credit, equals(15000.0));
        expect(result.statementEntry.debit, equals(0.0));
        expect(result.statementEntry.runningBalance, equals(10000.0));

        // Verify check ingestion
        expect(result.createdChecks.length, equals(1));
        final chk = result.createdChecks.first;
        expect(chk.checkNumber, equals('CHK-12345'));
        expect(chk.bankName, equals('بنك فلسطين'));
        expect(chk.amount, equals(10000.0));
        expect(chk.type, equals(CheckType.received));
        expect(chk.status, equals(CheckStatus.pending));
      });
    });

    group('submitSupplierPayment Workflow', () {
      test('submits valid supplier payment and returns ProcessSupplierPaymentResult', () {
        final controller = ReceiptsController(
          initialContact: testSupplier,
          initialType: ReceiptType.supplierPayment,
          initialReceiptNumber: 'PAY-2026-800',
          initialDate: testDate,
        );
        controller.setTotalAmount(20000.0);
        controller.setNotes('صرف دفعة بموجب شيك للمورد');

        controller.addPaymentLine(
          method: PaymentMethod.check,
          amount: 20000.0,
          checkNumber: 'CHK-9999',
          bankName: 'بنك القدس',
          branchNumber: '110',
          accountNumber: '555111',
          dueDate: DateTime(2026, 12, 15),
          drawerName: 'M.I.R.N POWER',
        );

        expect(controller.state.isComplete, isTrue);

        final result = controller.submitSupplierPayment(createdBy: 'diaaldin');

        // Verify voucher
        expect(result.paymentVoucher.receiptNumber, equals('PAY-2026-800'));
        expect(result.paymentVoucher.partyType, equals(ContactType.supplier));
        expect(result.paymentVoucher.contactId, equals(testSupplier.id));
        expect(result.paymentVoucher.totalAmount, equals(20000.0));
        expect(result.paymentVoucher.createdBy, equals('diaaldin'));

        // Verify supplier payable reduction (30,000 - 20,000 = 10,000)
        expect(result.updatedSupplier.currentBalance, equals(10000.0));

        // Verify statement entry
        expect(result.statementEntry.contactId, equals(testSupplier.id));
        expect(result.statementEntry.type, equals(StatementEntryType.supplierPayment));
        expect(result.statementEntry.debit, equals(20000.0));
        expect(result.statementEntry.credit, equals(0.0));
        expect(result.statementEntry.runningBalance, equals(10000.0));

        // Verify issued check
        expect(result.issuedChecks.length, equals(1));
        final chk = result.issuedChecks.first;
        expect(chk.checkNumber, equals('CHK-9999'));
        expect(chk.bankName, equals('بنك القدس'));
        expect(chk.amount, equals(20000.0));
        expect(chk.type, equals(CheckType.issued));
        expect(chk.status, equals(CheckStatus.pending));
      });
    });

    group('Incomplete State & Invalid Submission Rejections', () {
      test('submitting customer receipt with null contact throws StateError', () {
        final controller = ReceiptsController();
        controller.setReceiptNumber('REC-FAIL-1');
        controller.setTotalAmount(1000.0);
        controller.addPaymentLine(method: PaymentMethod.cash, amount: 1000.0);

        expect(controller.state.contact, isNull);
        expect(controller.state.isComplete, isTrue);

        expect(
          () => controller.submitCustomerReceipt(createdBy: 'diaaldin'),
          throwsA(isA<StateError>()),
        );
      });

      test('submitting customer receipt when isComplete is false throws StateError', () {
        final controller = ReceiptsController(
          initialContact: testCustomer,
          initialReceiptNumber: 'REC-FAIL-2',
        );
        controller.setTotalAmount(1000.0);
        controller.addPaymentLine(method: PaymentMethod.cash, amount: 500.0);

        expect(controller.state.isComplete, isFalse);

        expect(
          () => controller.submitCustomerReceipt(createdBy: 'diaaldin'),
          throwsA(isA<StateError>()),
        );
      });

      test('submitting customer receipt with zero total amount throws StateError', () {
        final controller = ReceiptsController(
          initialContact: testCustomer,
          initialReceiptNumber: 'REC-FAIL-3',
        );

        expect(controller.state.totalAmount, equals(0.0));
        expect(controller.state.isComplete, isFalse);

        expect(
          () => controller.submitCustomerReceipt(createdBy: 'diaaldin'),
          throwsA(isA<StateError>()),
        );
      });

      test('submitting supplier payment with null contact throws StateError', () {
        final controller = ReceiptsController(
          initialType: ReceiptType.supplierPayment,
          initialReceiptNumber: 'PAY-FAIL-1',
        );
        controller.setTotalAmount(2000.0);
        controller.addPaymentLine(method: PaymentMethod.cash, amount: 2000.0);

        expect(controller.state.contact, isNull);
        expect(controller.state.isComplete, isTrue);

        expect(
          () => controller.submitSupplierPayment(createdBy: 'diaaldin'),
          throwsA(isA<StateError>()),
        );
      });

      test('submitting supplier payment when isComplete is false throws StateError', () {
        final controller = ReceiptsController(
          initialContact: testSupplier,
          initialType: ReceiptType.supplierPayment,
          initialReceiptNumber: 'PAY-FAIL-2',
        );
        controller.setTotalAmount(2000.0);
        controller.addPaymentLine(method: PaymentMethod.cash, amount: 1500.0);

        expect(controller.state.isComplete, isFalse);

        expect(
          () => controller.submitSupplierPayment(createdBy: 'diaaldin'),
          throwsA(isA<StateError>()),
        );
      });

      test('submitting customer receipt for supplier contact delegates to service and throws ArgumentError', () {
        final controller = ReceiptsController(
          initialContact: testSupplier, // Supplier contact
          initialReceiptNumber: 'REC-FAIL-MISMATCH',
        );
        controller.setTotalAmount(5000.0);
        controller.addPaymentLine(method: PaymentMethod.cash, amount: 5000.0);

        expect(controller.state.isComplete, isTrue);

        expect(
          () => controller.submitCustomerReceipt(createdBy: 'diaaldin'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('submitting supplier payment for customer contact delegates to service and throws ArgumentError', () {
        final controller = ReceiptsController(
          initialContact: testCustomer, // Customer contact
          initialType: ReceiptType.supplierPayment,
          initialReceiptNumber: 'PAY-FAIL-MISMATCH',
        );
        controller.setTotalAmount(5000.0);
        controller.addPaymentLine(method: PaymentMethod.cash, amount: 5000.0);

        expect(controller.state.isComplete, isTrue);

        expect(
          () => controller.submitSupplierPayment(createdBy: 'diaaldin'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Edge Cases & State Modifiers', () {
      test('setContact, setReceiptType, setDate, setReceiptNumber, setNotes mutate state correctly', () {
        final controller = ReceiptsController();

        expect(controller.state.contact, isNull);
        controller.setContact(testCustomer);
        expect(controller.state.contact, equals(testCustomer));

        controller.setReceiptType(ReceiptType.supplierPayment);
        expect(controller.state.receiptType, equals(ReceiptType.supplierPayment));

        final customDate = DateTime(2026, 12, 25);
        controller.setDate(customDate);
        expect(controller.state.date, equals(customDate));

        controller.setReceiptNumber('CUSTOM-NUM-99');
        expect(controller.state.receiptNumber, equals('CUSTOM-NUM-99'));

        controller.setNotes('ملاحظات خاصة');
        expect(controller.state.notes, equals('ملاحظات خاصة'));
      });

      test('removePaymentLine with out-of-bounds index is safely ignored', () {
        final controller = ReceiptsController();
        controller.addPaymentLine(method: PaymentMethod.cash, amount: 100.0);

        expect(controller.state.payments.length, equals(1));
        controller.removePaymentLine(-1);
        expect(controller.state.payments.length, equals(1));
        controller.removePaymentLine(5);
        expect(controller.state.payments.length, equals(1));
      });

      test('adding payment line with zero or negative amount throws ArgumentError', () {
        final controller = ReceiptsController();

        expect(
          () => controller.addPaymentLine(method: PaymentMethod.cash, amount: 0.0),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => controller.addPaymentLine(method: PaymentMethod.cash, amount: -50.0),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
