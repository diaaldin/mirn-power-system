import 'package:test/test.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/contact.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/statement_entry.dart';
import 'package:sales_logistics_system/features/inventory/domain/models/product.dart';
import 'package:sales_logistics_system/features/inventory/domain/services/unit_converter.dart';
import 'package:sales_logistics_system/features/purchases/domain/models/purchase_invoice.dart';
import 'package:sales_logistics_system/features/purchases/domain/services/purchase_service.dart';

void main() {
  group('UnitConverter.calculateStockAddition', () {
    final meterProduct = Product(
      id: 'p-meter',
      name: 'Porcelain Tile 60x120',
      sku: 'POR-60120',
      category: ProductCategory.marble,
      unitType: UnitType.meter,
      meterPerBox: 1.44,
      purchaseCost: 50.0,
      sellingPrice: 85.0,
      currentStock: 100.0,
    );

    final boxProduct = Product(
      id: 'p-box',
      name: 'Ceramic Mosaic',
      sku: 'CER-MOS',
      category: ProductCategory.marble,
      unitType: UnitType.box,
      meterPerBox: 2.0,
      purchaseCost: 40.0,
      sellingPrice: 70.0,
      currentStock: 50.0,
    );

    final pieceProduct = Product(
      id: 'p-piece',
      name: 'Water Tap Mixer',
      sku: 'TAP-01',
      category: ProductCategory.sanitary,
      unitType: UnitType.piece,
      purchaseCost: 120.0,
      sellingPrice: 200.0,
      currentStock: 10.0,
    );

    test('returns exact quantity when purchased unit matches product unitType', () {
      final meterAddition = UnitConverter.calculateStockAddition(
        product: meterProduct,
        quantity: 25.5,
        purchasedUnit: UnitType.meter,
      );
      expect(meterAddition, equals(25.5));

      final boxAddition = UnitConverter.calculateStockAddition(
        product: boxProduct,
        quantity: 15,
        purchasedUnit: UnitType.box,
      );
      expect(boxAddition, equals(15.0));

      final pieceAddition = UnitConverter.calculateStockAddition(
        product: pieceProduct,
        quantity: 5,
        purchasedUnit: UnitType.piece,
      );
      expect(pieceAddition, equals(5.0));
    });

    test('converts boxes to meters when product is meter-based', () {
      // 10 boxes * 1.44 = 14.4 meters
      final addition = UnitConverter.calculateStockAddition(
        product: meterProduct,
        quantity: 10,
        purchasedUnit: UnitType.box,
      );
      expect(addition, closeTo(14.4, 0.0001));
    });

    test('converts meters to boxes when product is box-based', () {
      // 20 meters / 2.0 = 10 boxes
      final addition = UnitConverter.calculateStockAddition(
        product: boxProduct,
        quantity: 20,
        purchasedUnit: UnitType.meter,
      );
      expect(addition, closeTo(10.0, 0.0001));
    });

    test('defaults to meterPerBox = 1.0 if null when converting units', () {
      final nullFactorMeterProduct = Product(
        id: 'p-meter-null',
        name: 'Meter Tile without factor',
        sku: 'POR-NULL',
        category: ProductCategory.marble,
        unitType: UnitType.meter,
        meterPerBox: null,
        purchaseCost: 50.0,
        sellingPrice: 85.0,
        currentStock: 100.0,
      );
      final addition = UnitConverter.calculateStockAddition(
        product: nullFactorMeterProduct,
        quantity: 12,
        purchasedUnit: UnitType.box,
      );
      expect(addition, equals(12.0));
    });
  });

  group('PurchaseService.processPurchase', () {
    late Contact validSupplier;
    late Contact customerOnlyContact;
    late Contact bothTypeContact;
    late Product sampleTileProduct;
    late Product sampleSanitaryProduct;
    final testDate = DateTime(2026, 11, 14, 10, 0, 0);

    setUp(() {
      validSupplier = const Contact(
        id: 'supp-001',
        type: ContactType.supplier,
        name: 'Haifa Ceramics Ltd',
        phone: '04-8123456',
        address: 'Haifa Port Industrial Area',
        taxId: '514987654',
        debtWarningLimit: 50000.0,
        currentBalance: 12000.0,
      );

      customerOnlyContact = const Contact(
        id: 'cust-001',
        type: ContactType.customer,
        name: 'Rami Contractor',
        phone: '050-1234567',
        address: 'Nazareth',
        taxId: '032165498',
        debtWarningLimit: 20000.0,
        currentBalance: 3000.0,
      );

      bothTypeContact = const Contact(
        id: 'both-001',
        type: ContactType.both,
        name: 'Galilee Building Supplies',
        phone: '04-9876543',
        address: 'Karmiel',
        taxId: '512345678',
        debtWarningLimit: 100000.0,
        currentBalance: 0.0,
      );

      sampleTileProduct = const Product(
        id: 'prod-tile',
        name: 'Spanish Porcelain 60x120',
        sku: 'SP-60120',
        category: ProductCategory.marble,
        unitType: UnitType.meter,
        meterPerBox: 1.44,
        purchaseCost: 60.0,
        sellingPrice: 110.0,
        currentStock: 100.0,
      );

      sampleSanitaryProduct = const Product(
        id: 'prod-toilet',
        name: 'Wall-Hung Toilet Set',
        sku: 'WH-TOI-99',
        category: ProductCategory.sanitary,
        unitType: UnitType.piece,
        purchaseCost: 400.0,
        sellingPrice: 750.0,
        currentStock: 10.0,
      );
    });

    group('Validation', () {
      test('throws ArgumentError if supplier is customer-only', () {
        final input = CreatePurchaseInput(
          invoiceNumber: 'PUR-2026-0001',
          date: testDate,
          supplier: customerOnlyContact,
          items: [
            PurchaseLineItemInput(
              product: sampleTileProduct,
              unitType: UnitType.meter,
              quantity: 50,
              unitCost: 55.0,
            ),
          ],
          createdBy: 'admin',
        );

        expect(
          () => PurchaseService.processPurchase(input),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message.toString(),
            'message',
            contains('customer'),
          )),
        );
      });

      test('accepts ContactType.supplier and ContactType.both as suppliers', () {
        final inputSupplier = CreatePurchaseInput(
          invoiceNumber: 'PUR-2026-0001',
          date: testDate,
          supplier: validSupplier,
          items: [
            PurchaseLineItemInput(
              product: sampleTileProduct,
              unitType: UnitType.meter,
              quantity: 10,
              unitCost: 60.0,
            ),
          ],
          createdBy: 'admin',
        );
        expect(() => PurchaseService.processPurchase(inputSupplier), returnsNormally);

        final inputBoth = CreatePurchaseInput(
          invoiceNumber: 'PUR-2026-0002',
          date: testDate,
          supplier: bothTypeContact,
          items: [
            PurchaseLineItemInput(
              product: sampleTileProduct,
              unitType: UnitType.meter,
              quantity: 10,
              unitCost: 60.0,
            ),
          ],
          createdBy: 'admin',
        );
        expect(() => PurchaseService.processPurchase(inputBoth), returnsNormally);
      });

      test('throws ArgumentError when items list is empty', () {
        final input = CreatePurchaseInput(
          invoiceNumber: 'PUR-2026-0001',
          date: testDate,
          supplier: validSupplier,
          items: [],
          createdBy: 'admin',
        );

        expect(
          () => PurchaseService.processPurchase(input),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message.toString(),
            'message',
            contains('empty'),
          )),
        );
      });

      test('throws ArgumentError when line item quantity <= 0', () {
        final inputZero = CreatePurchaseInput(
          invoiceNumber: 'PUR-2026-0001',
          date: testDate,
          supplier: validSupplier,
          items: [
            PurchaseLineItemInput(
              product: sampleTileProduct,
              unitType: UnitType.meter,
              quantity: 0,
              unitCost: 60.0,
            ),
          ],
          createdBy: 'admin',
        );

        expect(() => PurchaseService.processPurchase(inputZero), throwsA(isA<ArgumentError>()));

        final inputNegative = CreatePurchaseInput(
          invoiceNumber: 'PUR-2026-0001',
          date: testDate,
          supplier: validSupplier,
          items: [
            PurchaseLineItemInput(
              product: sampleTileProduct,
              unitType: UnitType.meter,
              quantity: -5,
              unitCost: 60.0,
            ),
          ],
          createdBy: 'admin',
        );

        expect(() => PurchaseService.processPurchase(inputNegative), throwsA(isA<ArgumentError>()));
      });

      test('throws ArgumentError when line item unitCost < 0', () {
        final inputNegativeCost = CreatePurchaseInput(
          invoiceNumber: 'PUR-2026-0001',
          date: testDate,
          supplier: validSupplier,
          items: [
            PurchaseLineItemInput(
              product: sampleTileProduct,
              unitType: UnitType.meter,
              quantity: 10,
              unitCost: -1.0,
            ),
          ],
          createdBy: 'admin',
        );

        expect(() => PurchaseService.processPurchase(inputNegativeCost), throwsA(isA<ArgumentError>()));
      });

      test('throws ArgumentError when paidAmount < 0', () {
        final input = CreatePurchaseInput(
          invoiceNumber: 'PUR-2026-0001',
          date: testDate,
          supplier: validSupplier,
          paidAmount: -500.0,
          items: [
            PurchaseLineItemInput(
              product: sampleTileProduct,
              unitType: UnitType.meter,
              quantity: 10,
              unitCost: 60.0,
            ),
          ],
          createdBy: 'admin',
        );

        expect(() => PurchaseService.processPurchase(input), throwsA(isA<ArgumentError>()));
      });

      test('throws ArgumentError when paidAmount exceeds totalAmount', () {
        // Line subtotal = 10 * 60 = 600, VAT 17% = 102, Total = 702
        final input = CreatePurchaseInput(
          invoiceNumber: 'PUR-2026-0001',
          date: testDate,
          supplier: validSupplier,
          paidAmount: 800.0,
          items: [
            PurchaseLineItemInput(
              product: sampleTileProduct,
              unitType: UnitType.meter,
              quantity: 10,
              unitCost: 60.0,
            ),
          ],
          createdBy: 'admin',
        );

        expect(() => PurchaseService.processPurchase(input), throwsA(isA<ArgumentError>()));
      });
    });

    group('Financial Calculations and Rounding', () {
      test('accurately calculates line subtotal, VAT amount, and total with 17% VAT', () {
        // Item 1: 50 meters * 55 ₪ = 2750.00
        // Item 2: 5 pieces * 350 ₪ = 1750.00
        // Total subtotal = 4500.00
        // VAT (17%) = 4500 * 0.17 = 765.00
        // Total = 5265.00
        // Paid = 2000.00 -> onAccount = 3265.00
        final input = CreatePurchaseInput(
          invoiceNumber: 'PUR-2026-0010',
          supplierInvoiceNumber: 'SUPP-INV-888',
          date: testDate,
          supplier: validSupplier,
          paidAmount: 2000.0,
          items: [
            PurchaseLineItemInput(
              product: sampleTileProduct,
              unitType: UnitType.meter,
              quantity: 50,
              unitCost: 55.0,
            ),
            PurchaseLineItemInput(
              product: sampleSanitaryProduct,
              unitType: UnitType.piece,
              quantity: 5,
              unitCost: 350.0,
            ),
          ],
          createdBy: 'buyer-user',
        );

        final result = PurchaseService.processPurchase(input);

        expect(result.purchase.subtotal, equals(4500.0));
        expect(result.purchase.vatRate, equals(0.17));
        expect(result.purchase.vatAmount, equals(765.0));
        expect(result.purchase.totalAmount, equals(5265.0));
        expect(result.purchase.paidAmount, equals(2000.0));
        expect(result.purchase.onAccountAmount, equals(3265.0));
        expect(result.purchase.supplierInvoiceNumber, equals('SUPP-INV-888'));
        expect(result.purchase.createdBy, equals('buyer-user'));
      });

      test('supports custom VAT rate (e.g. 0% for tax-exempt suppliers/goods)', () {
        final input = CreatePurchaseInput(
          invoiceNumber: 'PUR-2026-0011',
          date: testDate,
          supplier: validSupplier,
          vatRate: 0.0,
          paidAmount: 600.0,
          items: [
            PurchaseLineItemInput(
              product: sampleTileProduct,
              unitType: UnitType.meter,
              quantity: 10,
              unitCost: 60.0,
            ),
          ],
          createdBy: 'buyer-user',
        );

        final result = PurchaseService.processPurchase(input);

        expect(result.purchase.subtotal, equals(600.0));
        expect(result.purchase.vatRate, equals(0.0));
        expect(result.purchase.vatAmount, equals(0.0));
        expect(result.purchase.totalAmount, equals(600.0));
        expect(result.purchase.paidAmount, equals(600.0));
        expect(result.purchase.onAccountAmount, equals(0.0));
      });
    });

    group('Inventory Stock Replenishment & Weighted Moving Average Cost', () {
      test('updates stock and moving average cost when currentStock <= 0', () {
        final outOfStockProduct = sampleTileProduct.copyWith(
          currentStock: 0.0,
          purchaseCost: 50.0,
        );

        final input = CreatePurchaseInput(
          invoiceNumber: 'PUR-2026-0020',
          date: testDate,
          supplier: validSupplier,
          items: [
            PurchaseLineItemInput(
              product: outOfStockProduct,
              unitType: UnitType.meter,
              quantity: 40,
              unitCost: 68.0,
            ),
          ],
          createdBy: 'admin',
        );

        final result = PurchaseService.processPurchase(input);

        expect(result.updatedProducts.length, equals(1));
        final updated = result.updatedProducts.first;
        expect(updated.currentStock, equals(40.0));
        expect(updated.purchaseCost, equals(68.0));
        expect(updated.updatedAt, equals(testDate));
      });

      test('calculates cost per primary unit when purchasing in boxes for meter product at zero stock', () {
        final outOfStockMeterProduct = sampleTileProduct.copyWith(
          currentStock: 0.0,
          meterPerBox: 1.44,
          purchaseCost: 50.0,
        );

        // Buying 10 boxes at 100 ₪/box
        // Converted stock = 10 * 1.44 = 14.4 meters
        // Cost per meter = 100 / 1.44 = 69.4444... -> 69.44
        final input = CreatePurchaseInput(
          invoiceNumber: 'PUR-2026-0021',
          date: testDate,
          supplier: validSupplier,
          items: [
            PurchaseLineItemInput(
              product: outOfStockMeterProduct,
              unitType: UnitType.box,
              quantity: 10,
              unitCost: 100.0,
            ),
          ],
          createdBy: 'admin',
        );

        final result = PurchaseService.processPurchase(input);

        final updated = result.updatedProducts.first;
        expect(updated.currentStock, closeTo(14.4, 0.0001));
        expect(updated.purchaseCost, equals(69.44));
      });

      test('recalculates weighted moving average cost when currentStock > 0', () {
        // Initial: 100 meters @ 50 ₪/m2
        // Purchase: 50 meters @ 80 ₪/m2
        // Total value = (100 * 50) + (50 * 80) = 5000 + 4000 = 9000
        // New stock = 100 + 50 = 150
        // New average cost = 9000 / 150 = 60.00
        final initialProduct = sampleTileProduct.copyWith(
          currentStock: 100.0,
          purchaseCost: 50.0,
        );

        final input = CreatePurchaseInput(
          invoiceNumber: 'PUR-2026-0022',
          date: testDate,
          supplier: validSupplier,
          items: [
            PurchaseLineItemInput(
              product: initialProduct,
              unitType: UnitType.meter,
              quantity: 50,
              unitCost: 80.0,
            ),
          ],
          createdBy: 'admin',
        );

        final result = PurchaseService.processPurchase(input);

        final updated = result.updatedProducts.first;
        expect(updated.currentStock, equals(150.0));
        expect(updated.purchaseCost, equals(60.0));
      });

      test('recalculates weighted moving average cost with box purchases and rounding', () {
        // Initial: 100 meters @ 50 ₪/m2. meterPerBox = 1.44.
        // Purchase: 20 boxes @ 115.20 ₪/box.
        // Converted stock = 20 * 1.44 = 28.8 meters.
        // Cost per meter = 115.20 / 1.44 = 80.00 ₪/m2.
        // Total value = (100 * 50) + (28.8 * 80) = 5000 + 2304 = 7304.
        // New stock = 100 + 28.8 = 128.8 meters.
        // Weighted cost = 7304 / 128.8 = 56.70807... -> 56.71
        final initialProduct = sampleTileProduct.copyWith(
          currentStock: 100.0,
          meterPerBox: 1.44,
          purchaseCost: 50.0,
        );

        final input = CreatePurchaseInput(
          invoiceNumber: 'PUR-2026-0023',
          date: testDate,
          supplier: validSupplier,
          items: [
            PurchaseLineItemInput(
              product: initialProduct,
              unitType: UnitType.box,
              quantity: 20,
              unitCost: 115.20,
            ),
          ],
          createdBy: 'admin',
        );

        final result = PurchaseService.processPurchase(input);

        final updated = result.updatedProducts.first;
        expect(updated.currentStock, closeTo(128.8, 0.0001));
        expect(updated.purchaseCost, equals(56.71));
      });

      test('handles multiple items in the same purchase correctly', () {
        final input = CreatePurchaseInput(
          invoiceNumber: 'PUR-2026-0024',
          date: testDate,
          supplier: validSupplier,
          items: [
            PurchaseLineItemInput(
              product: sampleTileProduct, // 100 stock, 60 cost
              unitType: UnitType.meter,
              quantity: 100, // +100 @ 80 -> (100*60 + 100*80)/200 = 70.0
              unitCost: 80.0,
            ),
            PurchaseLineItemInput(
              product: sampleSanitaryProduct, // 10 stock, 400 cost
              unitType: UnitType.piece,
              quantity: 10, // +10 @ 500 -> (10*400 + 10*500)/20 = 450.0
              unitCost: 500.0,
            ),
          ],
          createdBy: 'admin',
        );

        final result = PurchaseService.processPurchase(input);

        expect(result.updatedProducts.length, equals(2));
        final tile = result.updatedProducts.firstWhere((p) => p.id == sampleTileProduct.id);
        final sanitary = result.updatedProducts.firstWhere((p) => p.id == sampleSanitaryProduct.id);

        expect(tile.currentStock, equals(200.0));
        expect(tile.purchaseCost, equals(70.0));

        expect(sanitary.currentStock, equals(20.0));
        expect(sanitary.purchaseCost, equals(450.0));
      });
    });

    group('Supplier Balance & Statement Entry', () {
      test('records statement entry and increases supplier balance when purchase is on account', () {
        // Initial supplier balance: 12000.0
        // Purchase subtotal: 10 * 100 = 1000.0
        // VAT 17%: 170.0
        // Total: 1170.0
        // Paid: 300.0 -> onAccount: 870.0
        // Expected new balance: 12000.0 + 870.0 = 12870.0
        final input = CreatePurchaseInput(
          invoiceNumber: 'PUR-2026-0030',
          date: testDate,
          supplier: validSupplier,
          paidAmount: 300.0,
          notes: 'Special shipment',
          items: [
            PurchaseLineItemInput(
              product: sampleTileProduct,
              unitType: UnitType.meter,
              quantity: 10,
              unitCost: 100.0,
            ),
          ],
          createdBy: 'finance-clerk',
        );

        final result = PurchaseService.processPurchase(input);

        expect(result.updatedSupplier.currentBalance, equals(12870.0));
        expect(result.updatedSupplier.updatedAt, equals(testDate));

        final stmt = result.statementEntry;
        expect(stmt, isNotNull);
        expect(stmt!.id, equals('stmt-PUR-2026-0030'));
        expect(stmt.contactId, equals(validSupplier.id));
        expect(stmt.contactType, equals(ContactType.supplier));
        expect(stmt.date, equals(testDate));
        expect(stmt.type, equals(StatementEntryType.purchaseInvoice));
        expect(stmt.referenceNumber, equals('PUR-2026-0030'));
        expect(stmt.debit, equals(0.0));
        expect(stmt.credit, equals(870.0));
        expect(stmt.runningBalance, equals(12870.0));
        expect(stmt.description, equals('Special shipment'));
      });

      test('uses default Arabic description when notes is null or empty', () {
        final input = CreatePurchaseInput(
          invoiceNumber: 'PUR-2026-0031',
          date: testDate,
          supplier: validSupplier,
          paidAmount: 0.0,
          notes: '',
          items: [
            PurchaseLineItemInput(
              product: sampleTileProduct,
              unitType: UnitType.meter,
              quantity: 10,
              unitCost: 100.0,
            ),
          ],
          createdBy: 'admin',
        );

        final result = PurchaseService.processPurchase(input);
        expect(
          result.statementEntry?.description,
          equals('فاتورة مشتريات وتوريد مخزون - PUR-2026-0031'),
        );
      });

      test('creates no statement entry and does not mutate supplier balance when fully paid', () {
        // Line subtotal = 1000, VAT = 170, Total = 1170. Paid = 1170.
        final input = CreatePurchaseInput(
          invoiceNumber: 'PUR-2026-0032',
          date: testDate,
          supplier: validSupplier,
          paidAmount: 1170.0,
          items: [
            PurchaseLineItemInput(
              product: sampleTileProduct,
              unitType: UnitType.meter,
              quantity: 10,
              unitCost: 100.0,
            ),
          ],
          createdBy: 'admin',
        );

        final result = PurchaseService.processPurchase(input);

        expect(result.purchase.onAccountAmount, equals(0.0));
        expect(result.updatedSupplier.currentBalance, equals(validSupplier.currentBalance));
        expect(result.statementEntry, isNull);
      });
    });
  });
}
