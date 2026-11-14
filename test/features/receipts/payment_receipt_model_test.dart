import 'package:test/test.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/contact.dart';
import 'package:sales_logistics_system/features/sales/domain/models/payment_split.dart';
import 'package:sales_logistics_system/features/receipts/domain/models/payment_receipt.dart';

void main() {
  group('PaymentReceipt Model Tests', () {
    test('creates valid customer receipt and validates total match', () {
      final receipt = PaymentReceipt(
        id: 'rec-001',
        receiptNumber: 'REC-2026-00001',
        date: DateTime(2026, 11, 14, 10, 30),
        partyType: ContactType.customer,
        contactId: 'cust-101',
        contactName: 'شركة البراق للمقاولات',
        totalAmount: 15000.0,
        payments: [
          ReceiptPaymentItem(
            method: PaymentMethod.cash,
            amount: 5000.0,
          ),
          ReceiptPaymentItem(
            method: PaymentMethod.check,
            amount: 10000.0,
            checkNumber: '10495',
            bankName: 'בנק הפועלים (12)',
            branchNumber: '680',
            accountNumber: '445910',
            dueDate: DateTime(2026, 12, 1),
            drawerName: 'شركة البراق',
          ),
        ],
        notes: 'دفعة على الحساب',
        createdBy: 'admin-01',
        createdAt: DateTime(2026, 11, 14),
      );

      expect(receipt.id, equals('rec-001'));
      expect(receipt.receiptNumber, equals('REC-2026-00001'));
      expect(receipt.partyType, equals(ContactType.customer));
      expect(receipt.contactId, equals('cust-101'));
      expect(receipt.contactName, equals('شركة البراق للمقاولات'));
      expect(receipt.totalAmount, equals(15000.0));
      expect(receipt.payments.length, equals(2));
      expect(receipt.isPaymentBalanced, isTrue);
      expect(receipt.notes, equals('دفعة على الحساب'));
      expect(receipt.createdBy, equals('admin-01'));
    });

    test('creates valid supplier payment voucher', () {
      final voucher = PaymentReceipt(
        id: 'pay-001',
        receiptNumber: 'PAY-2026-00001',
        date: DateTime(2026, 11, 14, 11, 0),
        partyType: ContactType.supplier,
        contactId: 'supp-201',
        contactName: 'مورد مواد البناء العربي',
        totalAmount: 8500.0,
        payments: [
          ReceiptPaymentItem(
            method: PaymentMethod.bankTransfer,
            amount: 8500.0,
            reference: 'TR-998822',
          ),
        ],
        notes: 'تسديد دفعة توريد حديد',
        createdBy: 'accountant-02',
        createdAt: DateTime(2026, 11, 14, 11, 0),
      );

      expect(voucher.partyType, equals(ContactType.supplier));
      expect(voucher.totalAmount, equals(8500.0));
      expect(voucher.isPaymentBalanced, isTrue);
    });

    test('rejects receipt where payments do not equal total amount (underpaid or overpaid)', () {
      // Underpaid
      expect(
        () => PaymentReceipt(
          id: 'rec-002',
          receiptNumber: 'REC-2026-00002',
          date: DateTime(2026, 11, 14),
          partyType: ContactType.customer,
          contactId: 'cust-101',
          contactName: 'شركة البراق',
          totalAmount: 10000.0,
          payments: [
            ReceiptPaymentItem(
              method: PaymentMethod.cash,
              amount: 8000.0,
            ),
          ],
          createdBy: 'admin-01',
          createdAt: DateTime(2026, 11, 14),
        ),
        throwsArgumentError,
      );

      // Overpaid
      expect(
        () => PaymentReceipt(
          id: 'rec-002b',
          receiptNumber: 'REC-2026-00002',
          date: DateTime(2026, 11, 14),
          partyType: ContactType.customer,
          contactId: 'cust-101',
          contactName: 'شركة البراق',
          totalAmount: 10000.0,
          payments: [
            ReceiptPaymentItem(
              method: PaymentMethod.cash,
              amount: 12000.0,
            ),
          ],
          createdBy: 'admin-01',
          createdAt: DateTime(2026, 11, 14),
        ),
        throwsArgumentError,
      );
    });

    test('rejects receipt with negative or zero total amount', () {
      // Zero amount
      expect(
        () => PaymentReceipt(
          id: 'rec-003',
          receiptNumber: 'REC-2026-00003',
          date: DateTime(2026, 11, 14),
          partyType: ContactType.customer,
          contactId: 'cust-101',
          contactName: 'شركة البراق',
          totalAmount: 0.0,
          payments: [],
          createdBy: 'admin-01',
          createdAt: DateTime(2026, 11, 14),
        ),
        throwsArgumentError,
      );

      // Negative amount
      expect(
        () => PaymentReceipt(
          id: 'rec-004',
          receiptNumber: 'REC-2026-00004',
          date: DateTime(2026, 11, 14),
          partyType: ContactType.customer,
          contactId: 'cust-101',
          contactName: 'شركة البراق',
          totalAmount: -500.0,
          payments: [],
          createdBy: 'admin-01',
          createdAt: DateTime(2026, 11, 14),
        ),
        throwsArgumentError,
      );
    });

    test('rejects ReceiptPaymentItem constructor with non-positive amount directly', () {
      expect(
        () => ReceiptPaymentItem(
          method: PaymentMethod.cash,
          amount: 0.0,
        ),
        throwsArgumentError,
      );

      expect(
        () => ReceiptPaymentItem(
          method: PaymentMethod.cash,
          amount: -50.0,
        ),
        throwsArgumentError,
      );
    });

    test('enforces defensive immutability on payments list', () {
      final receipt = PaymentReceipt(
        id: 'rec-008',
        receiptNumber: 'REC-2026-00008',
        date: DateTime.now(),
        partyType: ContactType.customer,
        contactId: 'cust-101',
        contactName: 'شركة البراق',
        totalAmount: 100.0,
        payments: [
          ReceiptPaymentItem(
            method: PaymentMethod.cash,
            amount: 100.0,
          ),
        ],
        createdBy: 'admin-01',
        createdAt: DateTime.now(),
      );

      expect(
        () => receipt.payments.add(
          ReceiptPaymentItem(
            method: PaymentMethod.cash,
            amount: 50.0,
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('validates exact 0.01 tolerance boundary (100.01 passes, 100.02 rejects)', () {
      // 100.01 difference is 0.01: PASSES
      final upperBoundaryReceipt = PaymentReceipt(
        id: 'rec-bound-1',
        receiptNumber: 'REC-2026-B001',
        date: DateTime(2026, 11, 14),
        partyType: ContactType.customer,
        contactId: 'cust-101',
        contactName: 'شركة البراق',
        totalAmount: 100.00,
        payments: [
          ReceiptPaymentItem(
            method: PaymentMethod.cash,
            amount: 100.01,
          ),
        ],
        createdBy: 'admin-01',
        createdAt: DateTime(2026, 11, 14),
      );
      expect(upperBoundaryReceipt.isPaymentBalanced, isTrue);

      // 99.99 difference is 0.01: PASSES
      final lowerBoundaryReceipt = PaymentReceipt(
        id: 'rec-bound-2',
        receiptNumber: 'REC-2026-B002',
        date: DateTime(2026, 11, 14),
        partyType: ContactType.customer,
        contactId: 'cust-101',
        contactName: 'شركة البراق',
        totalAmount: 100.00,
        payments: [
          ReceiptPaymentItem(
            method: PaymentMethod.cash,
            amount: 99.99,
          ),
        ],
        createdBy: 'admin-01',
        createdAt: DateTime(2026, 11, 14),
      );
      expect(lowerBoundaryReceipt.isPaymentBalanced, isTrue);

      // 100.02 difference is 0.02: THROWS ArgumentError
      expect(
        () => PaymentReceipt(
          id: 'rec-bound-3',
          receiptNumber: 'REC-2026-B003',
          date: DateTime(2026, 11, 14),
          partyType: ContactType.customer,
          contactId: 'cust-101',
          contactName: 'شركة البراق',
          totalAmount: 100.00,
          payments: [
            ReceiptPaymentItem(
              method: PaymentMethod.cash,
              amount: 100.02,
            ),
          ],
          createdBy: 'admin-01',
          createdAt: DateTime(2026, 11, 14),
        ),
        throwsArgumentError,
      );

      // 99.98 difference is 0.02: THROWS ArgumentError
      expect(
        () => PaymentReceipt(
          id: 'rec-bound-4',
          receiptNumber: 'REC-2026-B004',
          date: DateTime(2026, 11, 14),
          partyType: ContactType.customer,
          contactId: 'cust-101',
          contactName: 'شركة البراق',
          totalAmount: 100.00,
          payments: [
            ReceiptPaymentItem(
              method: PaymentMethod.cash,
              amount: 99.98,
            ),
          ],
          createdBy: 'admin-01',
          createdAt: DateTime(2026, 11, 14),
        ),
        throwsArgumentError,
      );
    });

    test('verifies ReceiptType trilingual titles and display names', () {
      expect(ReceiptType.customerReceipt.arabicTitle, equals('سند قبض'));
      expect(ReceiptType.customerReceipt.hebrewTitle, equals('קבלה'));
      expect(ReceiptType.customerReceipt.englishTitle, equals('Payment Receipt'));
      expect(ReceiptType.customerReceipt.displayName, equals('سند قبض / קבלה'));

      expect(ReceiptType.supplierPayment.arabicTitle, equals('سند صرف'));
      expect(ReceiptType.supplierPayment.hebrewTitle, equals('תשלום ספק'));
      expect(ReceiptType.supplierPayment.englishTitle, equals('Supplier Payment Voucher'));
      expect(ReceiptType.supplierPayment.displayName, equals('سند صرف / תשלום ספק'));
    });

    test('accepts receipt with slight floating point variance across multiple items', () {
      // 33.33 + 33.33 + 33.34 = 100.00
      final receipt = PaymentReceipt(
        id: 'rec-006',
        receiptNumber: 'REC-2026-00006',
        date: DateTime(2026, 11, 14),
        partyType: ContactType.customer,
        contactId: 'cust-101',
        contactName: 'شركة البراق',
        totalAmount: 100.0,
        payments: [
          ReceiptPaymentItem(
            method: PaymentMethod.cash,
            amount: 33.33,
          ),
          ReceiptPaymentItem(
            method: PaymentMethod.cash,
            amount: 33.33,
          ),
          ReceiptPaymentItem(
            method: PaymentMethod.cash,
            amount: 33.34,
          ),
        ],
        createdBy: 'admin-01',
        createdAt: DateTime(2026, 11, 14),
      );

      expect(receipt.isPaymentBalanced, isTrue);
    });

    test('JSON serialization roundtrip preserves all fields with defensive map decoding', () {
      final receipt = PaymentReceipt(
        id: 'rec-007',
        receiptNumber: 'REC-2026-00007',
        date: DateTime(2026, 11, 14, 15, 45, 0),
        partyType: ContactType.customer,
        contactId: 'cust-202',
        contactName: 'خالد مصطفى',
        totalAmount: 7500.50,
        payments: [
          ReceiptPaymentItem(
            method: PaymentMethod.cash,
            amount: 2500.50,
            reference: 'REF-CASH-1',
          ),
          ReceiptPaymentItem(
            method: PaymentMethod.check,
            amount: 5000.0,
            checkNumber: '55667',
            bankName: 'בנק לאומי (10)',
            branchNumber: '800',
            accountNumber: '123456',
            dueDate: DateTime(2026, 12, 15),
            drawerName: 'خالد مصطفى',
          ),
        ],
        notes: 'دفعة نقدية مع شيك مؤجل',
        createdBy: 'cashier-01',
        createdAt: DateTime(2026, 11, 14, 15, 45, 30),
      );

      final json = receipt.toJson();
      // Test defensive deserialization with Map<dynamic, dynamic>
      final dynamicJson = Map<dynamic, dynamic>.from(json);
      final roundtripped = PaymentReceipt.fromJson(Map<String, dynamic>.from(dynamicJson));

      expect(roundtripped.id, equals(receipt.id));
      expect(roundtripped.receiptNumber, equals(receipt.receiptNumber));
      expect(roundtripped.date, equals(receipt.date));
      expect(roundtripped.partyType, equals(receipt.partyType));
      expect(roundtripped.contactId, equals(receipt.contactId));
      expect(roundtripped.contactName, equals(receipt.contactName));
      expect(roundtripped.totalAmount, equals(receipt.totalAmount));
      expect(roundtripped.notes, equals(receipt.notes));
      expect(roundtripped.createdBy, equals(receipt.createdBy));
      expect(roundtripped.createdAt, equals(receipt.createdAt));
      expect(roundtripped.isPaymentBalanced, isTrue);

      expect(roundtripped.payments.length, equals(2));
      final p1 = roundtripped.payments[0];
      expect(p1.method, equals(PaymentMethod.cash));
      expect(p1.amount, equals(2500.50));
      expect(p1.reference, equals('REF-CASH-1'));
      expect(p1.checkNumber, isNull);

      final p2 = roundtripped.payments[1];
      expect(p2.method, equals(PaymentMethod.check));
      expect(p2.amount, equals(5000.0));
      expect(p2.checkNumber, equals('55667'));
      expect(p2.bankName, equals('בנק לאומי (10)'));
      expect(p2.branchNumber, equals('800'));
      expect(p2.accountNumber, equals('123456'));
      expect(p2.dueDate, equals(DateTime(2026, 12, 15)));
      expect(p2.drawerName, equals('خالد مصطفى'));
    });

    test('ReceiptPaymentItem JSON serialization roundtrip with null optional fields', () {
      final item = ReceiptPaymentItem(
        method: PaymentMethod.bankTransfer,
        amount: 3200.0,
      );

      final json = item.toJson();
      final roundtripped = ReceiptPaymentItem.fromJson(json);

      expect(roundtripped.method, equals(PaymentMethod.bankTransfer));
      expect(roundtripped.amount, equals(3200.0));
      expect(roundtripped.reference, isNull);
      expect(roundtripped.checkNumber, isNull);
      expect(roundtripped.bankName, isNull);
      expect(roundtripped.branchNumber, isNull);
      expect(roundtripped.accountNumber, isNull);
      expect(roundtripped.dueDate, isNull);
      expect(roundtripped.drawerName, isNull);
    });
  });
}
