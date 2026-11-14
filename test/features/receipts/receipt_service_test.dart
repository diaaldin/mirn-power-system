import 'package:test/test.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/contact.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/statement_entry.dart';
import 'package:sales_logistics_system/features/checks/domain/models/check_record.dart';
import 'package:sales_logistics_system/features/receipts/domain/models/payment_receipt.dart';
import 'package:sales_logistics_system/features/sales/domain/models/payment_split.dart';
import 'package:sales_logistics_system/features/receipts/domain/services/receipt_service.dart';

void main() {
  group('ReceiptService.processCustomerReceipt Tests', () {
    late Contact testCustomer;
    final testDate = DateTime(2026, 11, 14, 10, 30);

    setUp(() {
      testCustomer = const Contact(
        id: 'cust-101',
        type: ContactType.customer,
        name: 'شركة البراق للمقاولات',
        phone: '0599123456',
        address: 'رام الله - شارع الإرسال',
        taxId: '567890123',
        debtWarningLimit: 50000.0,
        currentBalance: 38200.0,
      );
    });

    test('Case 1: Customer debt deduction reduces balance from 38,200 to 23,200 on 15,000 receipt', () {
      final input = CreateReceiptInput(
        receiptNumber: 'REC-2026-00001',
        date: testDate,
        amount: 15000.0,
        payments: [
          ReceiptPaymentItem(
            method: PaymentMethod.cash,
            amount: 15000.0,
          ),
        ],
        createdBy: 'diaaldin',
      );

      final result = ReceiptService.processCustomerReceipt(
        contact: testCustomer,
        input: input,
      );

      expect(result.updatedContact.currentBalance, equals(23200.0));
      expect(result.receipt.receiptNumber, equals('REC-2026-00001'));
      expect(result.receipt.totalAmount, equals(15000.0));
      expect(result.receipt.partyType, equals(ContactType.customer));
      expect(result.receipt.contactId, equals(testCustomer.id));
      expect(result.receipt.contactName, equals(testCustomer.name));
      expect(result.createdChecks, isEmpty);
    });

    test('Case 2: StatementEntry generation creates correct paymentReceipt credit entry', () {
      final input = CreateReceiptInput(
        receiptNumber: 'REC-2026-00001',
        date: testDate,
        amount: 15000.0,
        payments: [
          ReceiptPaymentItem(
            method: PaymentMethod.cash,
            amount: 15000.0,
          ),
        ],
        createdBy: 'diaaldin',
      );

      final result = ReceiptService.processCustomerReceipt(
        contact: testCustomer,
        input: input,
      );

      final entry = result.statementEntry;
      expect(entry.id, equals('stmt-REC-2026-00001'));
      expect(entry.contactId, equals(testCustomer.id));
      expect(entry.contactType, equals(ContactType.customer));
      expect(entry.date, equals(testDate));
      expect(entry.type, equals(StatementEntryType.paymentReceipt));
      expect(entry.referenceNumber, equals('REC-2026-00001'));
      expect(entry.debit, equals(0.0));
      expect(entry.credit, equals(15000.0));
      expect(entry.runningBalance, equals(23200.0));
      expect(entry.description, equals('سند قبض دفعات على الحساب'));
    });

    test('StatementEntry uses custom notes if provided', () {
      final input = CreateReceiptInput(
        receiptNumber: 'REC-2026-00002',
        date: testDate,
        amount: 5000.0,
        notes: 'دفعة نقدية تحت الحساب عن مشروع البرج التجاري',
        payments: [
          ReceiptPaymentItem(
            method: PaymentMethod.cash,
            amount: 5000.0,
          ),
        ],
        createdBy: 'diaaldin',
      );

      final result = ReceiptService.processCustomerReceipt(
        contact: testCustomer,
        input: input,
      );

      expect(
        result.statementEntry.description,
        equals('دفعة نقدية تحت الحساب عن مشروع البرج التجاري'),
      );
    });

    test('Case 3: Check ingestion registers pending received check with audit history', () {
      final checkDueDate = DateTime(2026, 12, 1);
      final input = CreateReceiptInput(
        receiptNumber: 'REC-2026-00003',
        date: testDate,
        amount: 12500.0,
        payments: [
          ReceiptPaymentItem(
            method: PaymentMethod.check,
            amount: 12500.0,
            checkNumber: 'CHK-998877',
            bankName: 'بنك فلسطين / Bank of Palestine',
            branchNumber: '450',
            accountNumber: '1234567',
            dueDate: checkDueDate,
            drawerName: 'شركة البراق',
          ),
        ],
        createdBy: 'diaaldin',
      );

      final result = ReceiptService.processCustomerReceipt(
        contact: testCustomer,
        input: input,
      );

      expect(result.createdChecks.length, equals(1));
      final check = result.createdChecks.first;
      expect(check.checkNumber, equals('CHK-998877'));
      expect(check.bankName, equals('بنك فلسطين / Bank of Palestine'));
      expect(check.branchNumber, equals('450'));
      expect(check.accountNumber, equals('1234567'));
      expect(check.amount, equals(12500.0));
      expect(check.dueDate, equals(checkDueDate));
      expect(check.type, equals(CheckType.received));
      expect(check.partyId, equals(testCustomer.id));
      expect(check.partyName, equals(testCustomer.name));
      expect(check.relatedTransactionId, equals(result.receipt.id));
      expect(check.status, equals(CheckStatus.pending));
      expect(check.createdAt, equals(testDate));

      expect(check.history.length, equals(1));
      final historyEntry = check.history.first;
      expect(historyEntry.status, equals(CheckStatus.pending));
      expect(historyEntry.changedAt, equals(testDate));
      expect(historyEntry.notes, equals('Ingested from receipt REC-2026-00003'));
      expect(historyEntry.changedBy, equals('diaaldin'));
    });

    test('Check ingestion uses input.date when check dueDate is null', () {
      final input = CreateReceiptInput(
        receiptNumber: 'REC-2026-00004',
        date: testDate,
        amount: 3000.0,
        payments: [
          ReceiptPaymentItem(
            method: PaymentMethod.check,
            amount: 3000.0,
            checkNumber: 'CHK-112233',
            bankName: 'البنك العربي / Arab Bank',
          ),
        ],
        createdBy: 'diaaldin',
      );

      final result = ReceiptService.processCustomerReceipt(
        contact: testCustomer,
        input: input,
      );

      expect(result.createdChecks.first.dueDate, equals(testDate));
      expect(result.createdChecks.first.branchNumber, equals(''));
      expect(result.createdChecks.first.accountNumber, equals(''));
    });

    test('Case 4: Overpayment / credit balance allows customer to pay more than debt into negative balance', () {
      const customerWithSmallDebt = Contact(
        id: 'cust-102',
        type: ContactType.customer,
        name: 'مؤسسة القدس',
        phone: '0599000000',
        address: 'القدس',
        taxId: '123456789',
        debtWarningLimit: 10000.0,
        currentBalance: 5000.0,
      );

      final input = CreateReceiptInput(
        receiptNumber: 'REC-2026-00005',
        date: testDate,
        amount: 8000.0,
        payments: [
          ReceiptPaymentItem(
            method: PaymentMethod.cash,
            amount: 8000.0,
          ),
        ],
        createdBy: 'diaaldin',
      );

      final result = ReceiptService.processCustomerReceipt(
        contact: customerWithSmallDebt,
        input: input,
      );

      expect(result.updatedContact.currentBalance, equals(-3000.0));
      expect(result.updatedContact.isCreditor, isTrue);
      expect(result.updatedContact.isDebtor, isFalse);
      expect(result.statementEntry.runningBalance, equals(-3000.0));
    });

    test('Case 5: Rejection of supplier-only contacts on customer receipts', () {
      const supplierContact = Contact(
        id: 'supp-201',
        type: ContactType.supplier,
        name: 'شركة الإسمنت الوطنية',
        phone: '0599111222',
        address: 'حيفا',
        taxId: '987654321',
        debtWarningLimit: 0.0,
        currentBalance: -50000.0,
      );

      final input = CreateReceiptInput(
        receiptNumber: 'REC-2026-00006',
        date: testDate,
        amount: 10000.0,
        payments: [
          ReceiptPaymentItem(
            method: PaymentMethod.cash,
            amount: 10000.0,
          ),
        ],
        createdBy: 'diaaldin',
      );

      expect(
        () => ReceiptService.processCustomerReceipt(
          contact: supplierContact,
          input: input,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('supplier'),
        )),
      );
    });

    test('Allows receipt processing for contact with ContactType.both', () {
      const dualContact = Contact(
        id: 'cust-supp-301',
        type: ContactType.both,
        name: 'مجموعة النور التجارية (عميل ومورد)',
        phone: '0599333444',
        address: 'نابلس',
        taxId: '333444555',
        debtWarningLimit: 20000.0,
        currentBalance: 15000.0,
      );

      final input = CreateReceiptInput(
        receiptNumber: 'REC-2026-00007',
        date: testDate,
        amount: 5000.0,
        payments: [
          ReceiptPaymentItem(
            method: PaymentMethod.cash,
            amount: 5000.0,
          ),
        ],
        createdBy: 'diaaldin',
      );

      final result = ReceiptService.processCustomerReceipt(
        contact: dualContact,
        input: input,
      );

      expect(result.updatedContact.currentBalance, equals(10000.0));
      expect(result.receipt.partyType, equals(ContactType.customer));
    });

    test('Case 6: Rejection of check payments lacking check number or bank name', () {
      // Missing checkNumber
      final inputMissingCheckNumber = CreateReceiptInput(
        receiptNumber: 'REC-2026-00008',
        date: testDate,
        amount: 4000.0,
        payments: [
          ReceiptPaymentItem(
            method: PaymentMethod.check,
            amount: 4000.0,
            checkNumber: '',
            bankName: 'بنك فلسطين',
          ),
        ],
        createdBy: 'diaaldin',
      );

      expect(
        () => ReceiptService.processCustomerReceipt(
          contact: testCustomer,
          input: inputMissingCheckNumber,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('checkNumber'),
        )),
      );

      // Null checkNumber
      final inputNullCheckNumber = CreateReceiptInput(
        receiptNumber: 'REC-2026-00009',
        date: testDate,
        amount: 4000.0,
        payments: [
          ReceiptPaymentItem(
            method: PaymentMethod.check,
            amount: 4000.0,
            bankName: 'بنك فلسطين',
          ),
        ],
        createdBy: 'diaaldin',
      );

      expect(
        () => ReceiptService.processCustomerReceipt(
          contact: testCustomer,
          input: inputNullCheckNumber,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('checkNumber'),
        )),
      );

      // Missing bankName
      final inputMissingBankName = CreateReceiptInput(
        receiptNumber: 'REC-2026-00010',
        date: testDate,
        amount: 4000.0,
        payments: [
          ReceiptPaymentItem(
            method: PaymentMethod.check,
            amount: 4000.0,
            checkNumber: 'CHK-1234',
            bankName: '   ',
          ),
        ],
        createdBy: 'diaaldin',
      );

      expect(
        () => ReceiptService.processCustomerReceipt(
          contact: testCustomer,
          input: inputMissingBankName,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('bankName'),
        )),
      );

      // Null bankName
      final inputNullBankName = CreateReceiptInput(
        receiptNumber: 'REC-2026-00011',
        date: testDate,
        amount: 4000.0,
        payments: [
          ReceiptPaymentItem(
            method: PaymentMethod.check,
            amount: 4000.0,
            checkNumber: 'CHK-1234',
          ),
        ],
        createdBy: 'diaaldin',
      );

      expect(
        () => ReceiptService.processCustomerReceipt(
          contact: testCustomer,
          input: inputNullBankName,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('bankName'),
        )),
      );
    });

    test('Rejection of zero or negative receipt amount', () {
      final inputZero = CreateReceiptInput(
        receiptNumber: 'REC-2026-00012',
        date: testDate,
        amount: 0.0,
        payments: [],
        createdBy: 'diaaldin',
      );

      expect(
        () => ReceiptService.processCustomerReceipt(
          contact: testCustomer,
          input: inputZero,
        ),
        throwsA(isA<ArgumentError>()),
      );

      final inputNegative = CreateReceiptInput(
        receiptNumber: 'REC-2026-00013',
        date: testDate,
        amount: -500.0,
        payments: [],
        createdBy: 'diaaldin',
      );

      expect(
        () => ReceiptService.processCustomerReceipt(
          contact: testCustomer,
          input: inputNegative,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Rejection of unbalanced payment items', () {
      final inputUnbalanced = CreateReceiptInput(
        receiptNumber: 'REC-2026-00014',
        date: testDate,
        amount: 10000.0,
        payments: [
          ReceiptPaymentItem(
            method: PaymentMethod.cash,
            amount: 7000.0,
          ),
        ],
        createdBy: 'diaaldin',
      );

      expect(
        () => ReceiptService.processCustomerReceipt(
          contact: testCustomer,
          input: inputUnbalanced,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Handles multiple check items and mixed payment methods', () {
      final inputMixed = CreateReceiptInput(
        receiptNumber: 'REC-2026-00015',
        date: testDate,
        amount: 25000.0,
        payments: [
          ReceiptPaymentItem(
            method: PaymentMethod.cash,
            amount: 5000.0,
          ),
          ReceiptPaymentItem(
            method: PaymentMethod.bankTransfer,
            amount: 5000.0,
            reference: 'TRF-BANK-001',
          ),
          ReceiptPaymentItem(
            method: PaymentMethod.check,
            amount: 8000.0,
            checkNumber: 'CHK-SPLIT-1',
            bankName: 'بنك القدس',
          ),
          ReceiptPaymentItem(
            method: PaymentMethod.check,
            amount: 7000.0,
            checkNumber: 'CHK-SPLIT-2',
            bankName: 'بنك القاهرة عمان',
          ),
        ],
        createdBy: 'diaaldin',
      );

      final result = ReceiptService.processCustomerReceipt(
        contact: testCustomer,
        input: inputMixed,
      );

      expect(result.updatedContact.currentBalance, equals(13200.0));
      expect(result.createdChecks.length, equals(2));
      expect(result.createdChecks[0].id, equals('chk-REC-2026-00015-1'));
      expect(result.createdChecks[0].checkNumber, equals('CHK-SPLIT-1'));
      expect(result.createdChecks[0].amount, equals(8000.0));
      expect(result.createdChecks[1].id, equals('chk-REC-2026-00015-2'));
      expect(result.createdChecks[1].checkNumber, equals('CHK-SPLIT-2'));
      expect(result.createdChecks[1].amount, equals(7000.0));
    });

    test('Preserves custom receipt ID if provided, otherwise generates rec- receipt ID', () {
      final inputWithCustomId = CreateReceiptInput(
        id: 'custom-receipt-999',
        receiptNumber: 'REC-2026-00016',
        date: testDate,
        amount: 1000.0,
        payments: [
          ReceiptPaymentItem(
            method: PaymentMethod.cash,
            amount: 1000.0,
          ),
        ],
        createdBy: 'diaaldin',
      );

      final resultCustom = ReceiptService.processCustomerReceipt(
        contact: testCustomer,
        input: inputWithCustomId,
      );

      expect(resultCustom.receipt.id, equals('custom-receipt-999'));

      final inputWithoutId = CreateReceiptInput(
        receiptNumber: 'REC-2026-00017',
        date: testDate,
        amount: 1000.0,
        payments: [
          ReceiptPaymentItem(
            method: PaymentMethod.cash,
            amount: 1000.0,
          ),
        ],
        createdBy: 'diaaldin',
      );

      final resultDefault = ReceiptService.processCustomerReceipt(
        contact: testCustomer,
        input: inputWithoutId,
      );

      expect(resultDefault.receipt.id, equals('rec-REC-2026-00017'));
    });
  });
}
