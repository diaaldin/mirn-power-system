import 'package:test/test.dart';
import 'package:sales_logistics_system/features/inventory/domain/models/product.dart';
import 'package:sales_logistics_system/features/purchases/domain/models/purchase_invoice.dart';

void main() {
  group('PurchaseInvoice Domain Model Tests', () {
    test('creates valid purchase invoice with accurate line item subtotals and VAT', () {
      final invoice = PurchaseInvoice(
        id: 'pur-001',
        invoiceNumber: 'PUR-2026-00001',
        supplierInvoiceNumber: 'SUPP-INV-9921',
        date: DateTime(2026, 11, 14, 11, 0),
        supplierId: 'supp-201',
        supplierName: 'מחצבות ירושלים ושיש בע"מ / محاجر القدس للرخام',
        supplierTaxId: '514882109',
        items: [
          PurchaseLineItem(
            productId: 'prod-001',
            productName: 'שיש קררה איטלקי / رخام كرارا إيطالي',
            unitType: UnitType.box,
            quantity: 100,
            unitCost: 110.0,
            subtotal: 11000.0,
            convertedStockQuantity: 144.0,
          ),
          PurchaseLineItem(
            productId: 'prod-003',
            productName: 'كرسي حمام معلق جروهي / אסלה תלויה גרואה',
            unitType: UnitType.piece,
            quantity: 10,
            unitCost: 650.0,
            subtotal: 6500.0,
            convertedStockQuantity: 10.0,
          ),
        ],
        subtotal: 17500.0,
        vatRate: 0.17,
        vatAmount: 2975.0,
        totalAmount: 20475.0,
        paidAmount: 5000.0,
        onAccountAmount: 15475.0,
        notes: 'توريد دفعة رخام وأدوات صحية لمستودع قلنديا',
        createdBy: 'admin-01',
        createdAt: DateTime(2026, 11, 14),
      );

      expect(invoice.invoiceNumber, equals('PUR-2026-00001'));
      expect(invoice.items.length, equals(2));
      expect(invoice.subtotal, equals(17500.0));
      expect(invoice.vatAmount, equals(2975.0));
      expect(invoice.totalAmount, equals(20475.0));
      expect(invoice.onAccountAmount, equals(15475.0));
    });

    test('items list is unmodifiable', () {
      final lineItem = PurchaseLineItem(
        productId: 'prod-001',
        productName: 'שיש קררה',
        unitType: UnitType.box,
        quantity: 10,
        unitCost: 100.0,
        subtotal: 1000.0,
        convertedStockQuantity: 14.4,
      );

      final mutableList = [lineItem];
      final invoice = PurchaseInvoice(
        id: 'pur-001',
        invoiceNumber: 'PUR-2026-00001',
        date: DateTime(2026, 11, 14),
        supplierId: 'supp-201',
        supplierName: 'محاجر القدس',
        supplierTaxId: '514882109',
        items: mutableList,
        subtotal: 1000.0,
        vatRate: 0.17,
        vatAmount: 170.0,
        totalAmount: 1170.0,
        paidAmount: 1170.0,
        onAccountAmount: 0.0,
        createdBy: 'admin-01',
      );

      expect(
        () => invoice.items.add(lineItem),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('rejects invoice with empty line items list', () {
      expect(
        () => PurchaseInvoice(
          id: 'pur-002',
          invoiceNumber: 'PUR-2026-00002',
          date: DateTime(2026, 11, 14),
          supplierId: 'supp-201',
          supplierName: 'محاجر القدس',
          supplierTaxId: '514882109',
          items: [],
          subtotal: 0.0,
          vatRate: 0.17,
          vatAmount: 0.0,
          totalAmount: 0.0,
          paidAmount: 0.0,
          onAccountAmount: 0.0,
          createdBy: 'admin-01',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects line item with non-positive quantity or negative cost', () {
      expect(
        () => PurchaseLineItem(
          productId: 'prod-001',
          productName: 'رخام',
          unitType: UnitType.box,
          quantity: 0,
          unitCost: 100.0,
          subtotal: 0.0,
          convertedStockQuantity: 0.0,
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => PurchaseLineItem(
          productId: 'prod-001',
          productName: 'رخام',
          unitType: UnitType.box,
          quantity: -5,
          unitCost: 100.0,
          subtotal: -500.0,
          convertedStockQuantity: 0.0,
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => PurchaseLineItem(
          productId: 'prod-001',
          productName: 'رخام',
          unitType: UnitType.box,
          quantity: 10,
          unitCost: -50.0,
          subtotal: -500.0,
          convertedStockQuantity: 14.4,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects invoice when paidAmount + onAccountAmount does not equal totalAmount', () {
      expect(
        () => PurchaseInvoice(
          id: 'pur-003',
          invoiceNumber: 'PUR-2026-00003',
          date: DateTime(2026, 11, 14),
          supplierId: 'supp-201',
          supplierName: 'محاجر القدس',
          supplierTaxId: '514882109',
          items: [
            PurchaseLineItem(
              productId: 'prod-001',
              productName: 'رخام',
              unitType: UnitType.box,
              quantity: 10,
              unitCost: 100.0,
              subtotal: 1000.0,
              convertedStockQuantity: 14.4,
            ),
          ],
          subtotal: 1000.0,
          vatRate: 0.17,
          vatAmount: 170.0,
          totalAmount: 1170.0,
          paidAmount: 500.0,
          onAccountAmount: 500.0, // 500 + 500 != 1170
          createdBy: 'admin-01',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects invoice with negative paidAmount or negative onAccountAmount', () {
      expect(
        () => PurchaseInvoice(
          id: 'pur-003',
          invoiceNumber: 'PUR-2026-00003',
          date: DateTime(2026, 11, 14),
          supplierId: 'supp-201',
          supplierName: 'محاجر القدس',
          supplierTaxId: '514882109',
          items: [
            PurchaseLineItem(
              productId: 'prod-001',
              productName: 'رخام',
              unitType: UnitType.box,
              quantity: 10,
              unitCost: 100.0,
              subtotal: 1000.0,
              convertedStockQuantity: 14.4,
            ),
          ],
          subtotal: 1000.0,
          vatRate: 0.17,
          vatAmount: 170.0,
          totalAmount: 1000.0,
          paidAmount: -200.0,
          onAccountAmount: 1200.0,
          createdBy: 'admin-01',
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => PurchaseInvoice(
          id: 'pur-003',
          invoiceNumber: 'PUR-2026-00003',
          date: DateTime(2026, 11, 14),
          supplierId: 'supp-201',
          supplierName: 'محاجر القدس',
          supplierTaxId: '514882109',
          items: [
            PurchaseLineItem(
              productId: 'prod-001',
              productName: 'رخام',
              unitType: UnitType.box,
              quantity: 10,
              unitCost: 100.0,
              subtotal: 1000.0,
              convertedStockQuantity: 14.4,
            ),
          ],
          subtotal: 1000.0,
          vatRate: 0.17,
          vatAmount: 170.0,
          totalAmount: 1000.0,
          paidAmount: 1200.0,
          onAccountAmount: -200.0,
          createdBy: 'admin-01',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('serializes and deserializes to/from JSON cleanly', () {
      final invoice = PurchaseInvoice(
        id: 'pur-004',
        invoiceNumber: 'PUR-2026-00004',
        supplierInvoiceNumber: 'INV-771',
        date: DateTime(2026, 11, 14, 12, 0),
        supplierId: 'supp-202',
        supplierName: 'سيراميك الجليل / חרסינת הגליל',
        supplierTaxId: '515099231',
        items: [
          PurchaseLineItem(
            productId: 'prod-002',
            productName: 'بورسلان اسباني 60*120',
            unitType: UnitType.meter,
            quantity: 50,
            unitCost: 85.0,
            subtotal: 4250.0,
            convertedStockQuantity: 50.0,
          ),
        ],
        subtotal: 4250.0,
        vatRate: 0.17,
        vatAmount: 722.50,
        totalAmount: 4972.50,
        paidAmount: 0.0,
        onAccountAmount: 4972.50,
        notes: 'دفعة على الحساب',
        createdBy: 'admin-01',
        createdAt: DateTime(2026, 11, 14, 12, 0),
      );

      final json = invoice.toJson();
      final revived = PurchaseInvoice.fromJson(json);

      expect(revived.id, equals(invoice.id));
      expect(revived.invoiceNumber, equals(invoice.invoiceNumber));
      expect(revived.supplierInvoiceNumber, equals('INV-771'));
      expect(revived.date, equals(DateTime(2026, 11, 14, 12, 0)));
      expect(revived.supplierId, equals('supp-202'));
      expect(revived.supplierName, equals('سيراميك الجليل / חרסינת הגליל'));
      expect(revived.supplierTaxId, equals('515099231'));
      expect(revived.items.length, equals(1));
      expect(revived.items.first.productId, equals('prod-002'));
      expect(revived.items.first.productName, equals('بورسلان اسباني 60*120'));
      expect(revived.items.first.unitType, equals(UnitType.meter));
      expect(revived.items.first.quantity, equals(50));
      expect(revived.items.first.unitCost, equals(85.0));
      expect(revived.items.first.subtotal, equals(4250.0));
      expect(revived.items.first.convertedStockQuantity, equals(50.0));
      expect(revived.subtotal, equals(4250.0));
      expect(revived.vatRate, equals(0.17));
      expect(revived.vatAmount, equals(722.50));
      expect(revived.totalAmount, equals(4972.50));
      expect(revived.paidAmount, equals(0.0));
      expect(revived.onAccountAmount, equals(4972.50));
      expect(revived.notes, equals('دفعة على الحساب'));
      expect(revived.createdBy, equals('admin-01'));
      expect(revived.createdAt, equals(DateTime(2026, 11, 14, 12, 0)));
    });

    test('PurchaseLineItem and PurchaseInvoice copyWith works correctly', () {
      final item = PurchaseLineItem(
        productId: 'prod-001',
        productName: 'رخام',
        unitType: UnitType.box,
        quantity: 10,
        unitCost: 100.0,
        subtotal: 1000.0,
        convertedStockQuantity: 14.4,
      );

      final updatedItem = item.copyWith(
        quantity: 20,
        subtotal: 2000.0,
        convertedStockQuantity: 28.8,
      );
      expect(updatedItem.quantity, equals(20));
      expect(updatedItem.subtotal, equals(2000.0));
      expect(updatedItem.convertedStockQuantity, equals(28.8));
      expect(updatedItem.unitCost, equals(100.0));

      final invoice = PurchaseInvoice(
        id: 'pur-005',
        invoiceNumber: 'PUR-2026-00005',
        date: DateTime(2026, 11, 14),
        supplierId: 'supp-201',
        supplierName: 'محاجر القدس',
        supplierTaxId: '514882109',
        items: [item],
        subtotal: 1000.0,
        vatRate: 0.17,
        vatAmount: 170.0,
        totalAmount: 1170.0,
        paidAmount: 1170.0,
        onAccountAmount: 0.0,
        createdBy: 'admin-01',
      );

      final updatedInvoice = invoice.copyWith(
        paidAmount: 500.0,
        onAccountAmount: 670.0,
        notes: 'Updated notes',
      );

      expect(updatedInvoice.paidAmount, equals(500.0));
      expect(updatedInvoice.onAccountAmount, equals(670.0));
      expect(updatedInvoice.notes, equals('Updated notes'));
      expect(updatedInvoice.invoiceNumber, equals('PUR-2026-00005'));
    });
  });
}
