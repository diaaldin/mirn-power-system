import 'package:test/test.dart';
import 'package:sales_logistics_system/core/firebase/firestore_schema.dart';
import 'package:sales_logistics_system/core/di/service_locator.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/contact.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/statement_entry.dart';
import 'package:sales_logistics_system/features/checks/domain/models/check_record.dart';
import 'package:sales_logistics_system/features/inventory/domain/models/product.dart';
import 'package:sales_logistics_system/features/sales/domain/models/payment_split.dart';
import 'package:sales_logistics_system/features/sales/domain/models/sale_invoice.dart';

void main() {
  group('Firestore Schema & Payload Serialization Tests', () {
    test('verifies Firestore collection path mappings in schema constants', () {
      expect(FirestoreCollections.products, equals('products'));
      expect(FirestoreCollections.contacts, equals('contacts'));
      expect(FirestoreCollections.sales, equals('sales'));
      expect(FirestoreCollections.creditNotes, equals('credit_notes'));
      expect(FirestoreCollections.checks, equals('checks'));
      expect(FirestoreCollections.purchases, equals('purchases'));
      expect(FirestoreCollections.dispatches, equals('dispatches'));
      expect(FirestoreCollections.expenses, equals('expenses'));
      expect(FirestoreCollections.statementEntries, equals('statement_entries'));
      expect(FirestoreCollections.counters, equals('counters'));
      expect(FirestoreCollections.users, equals('users'));

      expect(FirestoreCollections.productPath('p1'), equals('products/p1'));
      expect(FirestoreCollections.salePath('s1'), equals('sales/s1'));
      expect(FirestoreCollections.checkPath('chk1'), equals('checks/chk1'));
      expect(FirestoreCollections.statementEntryPath('st1'), equals('statement_entries/st1'));
    });

    test('verifies ServiceLocator supports custom repository dependency injection', () {
      if (ServiceLocator.instance.isInitialized) {
        ServiceLocator.instance.dispose();
      }

      ServiceLocator.instance.initialize(
        initialProducts: [
          const Product(
            id: 'p-custom-01',
            name: 'رخام القدس / שיש ירושלים',
            sku: 'SKU-JLM',
            category: ProductCategory.marble,
            unitType: UnitType.meter,
            purchaseCost: 150.0,
            sellingPrice: 220.0,
            currentStock: 100.0,
          ),
        ],
      );

      expect(ServiceLocator.instance.isInitialized, isTrue);
      expect(ServiceLocator.instance.saleOrchestrator, isNotNull);
      expect(ServiceLocator.instance.purchaseOrchestrator, isNotNull);
      expect(ServiceLocator.instance.creditNoteOrchestrator, isNotNull);
      expect(ServiceLocator.instance.checkLifecycleOrchestrator, isNotNull);

      ServiceLocator.instance.dispose();
      expect(ServiceLocator.instance.isInitialized, isFalse);
    });

    test('verifies bidirectional JSON round-trip for Firestore document payloads', () {
      // 1. Product payload
      const originalProduct = Product(
        id: 'prod-fire-01',
        name: 'رخام إيطالي كلكتا / שיש איטלקי',
        sku: 'MRB-001',
        category: ProductCategory.marble,
        unitType: UnitType.meter,
        meterPerBox: 1.44,
        purchaseCost: 200.0,
        sellingPrice: 280.0,
        currentStock: 450.0,
      );
      final productJson = originalProduct.toJson();
      final roundTripProduct = Product.fromJson(productJson);
      expect(roundTripProduct.id, equals(originalProduct.id));
      expect(roundTripProduct.sellingPrice, equals(280.0));
      expect(roundTripProduct.meterPerBox, equals(1.44));

      // 2. Sale invoice payload
      final originalSale = SaleInvoice(
        id: 'sale-fire-01',
        invoiceNumber: 'INV-2026-00055',
        date: DateTime(2026, 11, 18),
        customerId: 'cust-101',
        customerName: 'شركة البراق / אל-בוראק',
        customerTaxId: '515892104',
        isTaxInclusiveInput: true,
        items: const [
          SaleLineItem(
            productId: 'prod-fire-01',
            productName: 'رخام إيطالي كلكتا',
            unitType: UnitType.meter,
            quantity: 20.0,
            unitPrice: 280.0,
            subtotal: 5600.0,
          ),
        ],
        subtotal: 4786.32,
        vatRate: 0.17,
        vatAmount: 813.68,
        totalAmount: 5600.0,
        payments: const [
          PaymentSplit(method: PaymentMethod.cash, amount: 2000.0),
          PaymentSplit(method: PaymentMethod.debt, amount: 3600.0),
        ],
        createdAt: DateTime(2026, 11, 18),
      );
      final saleJson = originalSale.toJson();
      final roundTripSale = SaleInvoice.fromJson(saleJson);
      expect(roundTripSale.invoiceNumber, equals('INV-2026-00055'));
      expect(roundTripSale.totalAmount, equals(5600.0));
      expect(roundTripSale.payments.length, equals(2));

      // 3. Statement entry payload
      final originalEntry = StatementEntry(
        id: 'stmt-001',
        contactId: 'cust-101',
        contactType: ContactType.customer,
        date: DateTime(2026, 11, 18),
        type: StatementEntryType.saleInvoice,
        referenceNumber: 'INV-2026-00055',
        debit: 3600.0,
        credit: 0.0,
        runningBalance: 3600.0,
        description: 'فاتورة ضريبية / חשבונית מס INV-2026-00055',
      );
      final entryJson = originalEntry.toJson();
      final roundTripEntry = StatementEntry.fromJson(entryJson);
      expect(roundTripEntry.referenceNumber, equals('INV-2026-00055'));
      expect(roundTripEntry.runningBalance, equals(3600.0));

      // 4. Check payload with lifecycle history
      final originalCheck = CheckRecord(
        id: 'chk-001',
        checkNumber: 'CHK-998811',
        bankName: 'بنك القدس / בנק ירושלים',
        branchNumber: '001',
        accountNumber: 'ACC-112233',
        amount: 5000.0,
        dueDate: DateTime(2026, 12, 1),
        type: CheckType.received,
        partyId: 'cust-101',
        partyName: 'شركة البراق',
        relatedTransactionId: 'sale-fire-01',
        status: CheckStatus.bounced,
        createdAt: DateTime(2026, 11, 1),
        history: [
          CheckHistoryEntry(
            status: CheckStatus.pending,
            changedAt: DateTime(2026, 11, 1),
            notes: 'استلام الشيك',
          ),
          CheckHistoryEntry(
            status: CheckStatus.bounced,
            changedAt: DateTime(2026, 11, 18),
            notes: 'عدم كفاية الرصيد',
          ),
        ],
      );
      final checkJson = originalCheck.toJson();
      final roundTripCheck = CheckRecord.fromJson(checkJson);
      expect(roundTripCheck.checkNumber, equals('CHK-998811'));
      expect(roundTripCheck.status, equals(CheckStatus.bounced));
      expect(roundTripCheck.history.length, equals(2));
      expect(roundTripCheck.history.last.notes, equals('عدم كفاية الرصيد'));
    });
  });
}
