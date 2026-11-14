import 'package:test/test.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/contact.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/statement_entry.dart';
import 'package:sales_logistics_system/features/inventory/domain/models/product.dart';
import 'package:sales_logistics_system/features/purchases/presentation/controllers/purchases_controller.dart';

void main() {
  group('PurchasesController State Machine Tests', () {
    late Contact supplier;
    late Contact customerOnly;
    late Product marble;
    late Product sanitary;

    setUp(() {
      supplier = const Contact(
        id: 'supp-10',
        type: ContactType.supplier,
        name: 'سيراميك القدس / חרסינת ירושלים',
        phone: '052-0000000',
        address: 'القدس',
        taxId: '519283741',
        debtWarningLimit: 0,
        currentBalance: 5000.0,
      );

      customerOnly = const Contact(
        id: 'cust-10',
        type: ContactType.customer,
        name: 'زبون خاص',
        phone: '050-1111111',
        address: 'رام الله',
        taxId: '000000000',
        debtWarningLimit: 1000,
        currentBalance: 0.0,
      );

      marble = const Product(
        id: 'p-1',
        name: 'رخام تركي',
        sku: 'MB-002',
        category: ProductCategory.marble,
        unitType: UnitType.meter,
        meterPerBox: 1.44,
        purchaseCost: 80.0,
        sellingPrice: 130.0,
        currentStock: 50.0,
      );

      sanitary = const Product(
        id: 'p-2',
        name: 'حنفية مغسلة',
        sku: 'SN-002',
        category: ProductCategory.sanitary,
        unitType: UnitType.piece,
        purchaseCost: 150.0,
        sellingPrice: 220.0,
        currentStock: 10.0,
      );
    });

    test('initial state has clean default values', () {
      final controller = PurchasesController();
      final state = controller.state;

      expect(state.supplier, isNull);
      expect(state.invoiceNumber, isEmpty);
      expect(state.supplierInvoiceNumber, isNull);
      expect(state.items, isEmpty);
      expect(state.vatRate, equals(0.17));
      expect(state.isPaidImmediately, isFalse);
      expect(state.paidAmount, equals(0.0));
      expect(state.notes, isNull);
      expect(state.subtotal, equals(0.0));
      expect(state.vatAmount, equals(0.0));
      expect(state.totalAmount, equals(0.0));
      expect(state.effectivePaidAmount, equals(0.0));
      expect(state.onAccountAmount, equals(0.0));
      expect(state.projectedSupplierBalance, isNull);
      expect(state.isValid, isFalse);
    });

    test('adds items and dynamically computes subtotals, VAT, and on-account amount', () {
      final controller = PurchasesController();
      controller.setSupplier(supplier);
      controller.setInvoiceNumber('PUR-2026-00010');
      controller.setSupplierInvoiceNumber('INV-990');
      controller.setDate(DateTime(2026, 11, 14, 10, 0));
      controller.setNotes('ملاحظات الشراء');

      controller.addItem(
        product: marble,
        unitType: UnitType.box,
        quantity: 20, // 20 boxes * 1.44 = 28.8 m²
        unitCost: 100.0, // subtotal = 2000.0
      );

      expect(controller.state.items.length, equals(1));
      final item = controller.state.items.first;
      expect(item.product.id, equals('p-1'));
      expect(item.unitType, equals(UnitType.box));
      expect(item.quantity, equals(20.0));
      expect(item.unitCost, equals(100.0));
      expect(item.convertedStock, equals(28.8));
      expect(item.subtotal, equals(2000.0));

      expect(controller.state.subtotal, equals(2000.0));
      expect(controller.state.vatAmount, equals(340.0)); // 2000 * 0.17
      expect(controller.state.totalAmount, equals(2340.0));
      expect(controller.state.effectivePaidAmount, equals(0.0));
      expect(controller.state.onAccountAmount, equals(2340.0));
      expect(controller.state.projectedSupplierBalance, equals(7340.0)); // 5000 + 2340
      expect(controller.state.notes, equals('ملاحظات الشراء'));
      expect(controller.state.isValid, isTrue);

      // Set partial payment
      controller.setPaidAmount(1000.0);
      expect(controller.state.paidAmount, equals(1000.0));
      expect(controller.state.effectivePaidAmount, equals(1000.0));
      expect(controller.state.onAccountAmount, equals(1340.0));
      expect(controller.state.projectedSupplierBalance, equals(6340.0)); // 5000 + 1340

      // Remove item
      controller.removeItem(0);
      expect(controller.state.items.isEmpty, isTrue);
      expect(controller.state.subtotal, equals(0.0));
      expect(controller.state.isValid, isFalse);
    });

    test('addItem and removeItem with multiple items and clearItems', () {
      final controller = PurchasesController();
      controller.setSupplier(supplier);
      controller.setInvoiceNumber('PUR-2026-00020');

      controller.addItem(
        product: marble,
        unitType: UnitType.box,
        quantity: 10,
        unitCost: 100.0, // 1000
      );
      controller.addItem(
        product: sanitary,
        unitType: UnitType.piece,
        quantity: 4,
        unitCost: 150.0, // 600
      );

      expect(controller.state.items.length, equals(2));
      expect(controller.state.subtotal, equals(1600.0));
      expect(controller.state.vatAmount, equals(272.0));
      expect(controller.state.totalAmount, equals(1872.0));

      // Remove second item
      controller.removeItem(1);
      expect(controller.state.items.length, equals(1));
      expect(controller.state.subtotal, equals(1000.0));

      // Removing invalid index is safe no-op
      controller.removeItem(99);
      expect(controller.state.items.length, equals(1));

      // Clear all items
      controller.clearItems();
      expect(controller.state.items.isEmpty, isTrue);
      expect(controller.state.subtotal, equals(0.0));
      expect(controller.state.totalAmount, equals(0.0));
    });

    test('handles isPaidImmediately toggle properly', () {
      final controller = PurchasesController();
      controller.setSupplier(supplier);
      controller.setInvoiceNumber('PUR-2026-00030');
      controller.addItem(
        product: sanitary,
        unitType: UnitType.piece,
        quantity: 10,
        unitCost: 200.0, // subtotal 2000, VAT 340, total 2340
      );

      controller.setPaidAmount(500.0);
      expect(controller.state.paidAmount, equals(500.0));
      expect(controller.state.effectivePaidAmount, equals(500.0));
      expect(controller.state.onAccountAmount, equals(1840.0));
      expect(controller.state.projectedSupplierBalance, equals(6840.0));

      // Turn on immediate full payment
      controller.setPaidImmediately(true);
      expect(controller.state.isPaidImmediately, isTrue);
      expect(controller.state.effectivePaidAmount, equals(2340.0));
      expect(controller.state.onAccountAmount, equals(0.0));
      expect(controller.state.projectedSupplierBalance, equals(5000.0)); // No debt added

      // Turn off immediate payment: reverts back to explicit paidAmount
      controller.setPaidImmediately(false);
      expect(controller.state.isPaidImmediately, isFalse);
      expect(controller.state.effectivePaidAmount, equals(500.0));
      expect(controller.state.onAccountAmount, equals(1840.0));
    });

    test('supports custom VAT rate', () {
      final controller = PurchasesController();
      controller.setSupplier(supplier);
      controller.setInvoiceNumber('PUR-2026-00040');
      controller.setVatRate(0.0); // VAT exempt

      controller.addItem(
        product: sanitary,
        unitType: UnitType.piece,
        quantity: 5,
        unitCost: 100.0, // subtotal 500
      );

      expect(controller.state.subtotal, equals(500.0));
      expect(controller.state.vatAmount, equals(0.0));
      expect(controller.state.totalAmount, equals(500.0));
    });

    test('validates form correctly based on supplier, invoice number, items, and payments', () {
      final controller = PurchasesController();

      // Missing all fields
      expect(controller.state.isValid, isFalse);

      // Supplier only
      controller.setSupplier(supplier);
      expect(controller.state.isValid, isFalse);

      // Customer-only contact is invalid
      controller.setSupplier(customerOnly);
      controller.setInvoiceNumber('PUR-2026-00050');
      controller.addItem(
        product: marble,
        unitType: UnitType.meter,
        quantity: 10,
        unitCost: 80.0,
      );
      expect(controller.state.isValid, isFalse);

      // Fix supplier to valid supplier
      controller.setSupplier(supplier);
      expect(controller.state.isValid, isTrue);

      // Blank invoice number is invalid
      controller.setInvoiceNumber('   ');
      expect(controller.state.isValid, isFalse);
      controller.setInvoiceNumber('PUR-2026-00050');
      expect(controller.state.isValid, isTrue);

      // Overpayment when not paid immediately makes it invalid
      controller.setPaidAmount(2000.0); // total is 800 + 136 = 936
      expect(controller.state.isValid, isFalse);

      // Negative paid amount is invalid
      controller.setPaidAmount(-10.0);
      expect(controller.state.isValid, isFalse);

      // Valid paid amount
      controller.setPaidAmount(500.0);
      expect(controller.state.isValid, isTrue);
    });

    test('submits purchase and resets state after successful processing', () {
      final controller = PurchasesController();
      controller.setSupplier(supplier);
      controller.setInvoiceNumber('PUR-2026-00011');
      controller.setSupplierInvoiceNumber('SUPP-INV-111');
      controller.setNotes('مشتريات معتمدة');
      controller.addItem(
        product: marble,
        unitType: UnitType.meter,
        quantity: 10,
        unitCost: 85.0, // 850 + 144.5 = 994.5
      );

      expect(controller.state.isValid, isTrue);

      final result = controller.submitPurchase(createdBy: 'cashier-01');

      expect(result.purchase.invoiceNumber, equals('PUR-2026-00011'));
      expect(result.purchase.supplierInvoiceNumber, equals('SUPP-INV-111'));
      expect(result.purchase.subtotal, equals(850.0));
      expect(result.purchase.vatAmount, equals(144.50));
      expect(result.purchase.totalAmount, equals(994.50));
      expect(result.updatedSupplier.currentBalance, equals(5000.0 + 994.50));
      expect(result.statementEntry, isNotNull);
      expect(result.statementEntry!.type, equals(StatementEntryType.purchaseInvoice));

      // Controller state is reset
      expect(controller.state.items.isEmpty, isTrue);
      expect(controller.state.supplier, isNull);
      expect(controller.state.supplierInvoiceNumber, isNull);
      expect(controller.state.notes, isNull);
      expect(controller.state.paidAmount, equals(0.0));
      expect(controller.state.subtotal, equals(0.0));
      expect(controller.state.isValid, isFalse);
    });

    test('submitPurchase throws StateError when state is invalid', () {
      final controller = PurchasesController();
      expect(() => controller.submitPurchase(createdBy: 'cashier-01'), throwsStateError);

      controller.setSupplier(supplier);
      controller.setInvoiceNumber('PUR-999');
      // No items added
      expect(() => controller.submitPurchase(createdBy: 'cashier-01'), throwsStateError);
    });

    test('PurchaseItemDraft rejects non-positive quantity and negative unitCost', () {
      expect(
        () => PurchaseItemDraft(
          product: marble,
          unitType: UnitType.box,
          quantity: 0,
          unitCost: 100.0,
        ),
        throwsArgumentError,
      );

      expect(
        () => PurchaseItemDraft(
          product: marble,
          unitType: UnitType.box,
          quantity: 10,
          unitCost: -5.0,
        ),
        throwsArgumentError,
      );
    });
  });
}
