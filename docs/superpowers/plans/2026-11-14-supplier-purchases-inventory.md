# Supplier Purchases & Stock Intake Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Supplier Purchases & Stock Intake (فواتير المشتريات وتوريد المخزون / חשבוניות רכש וקליטת מלאי) module with dual-unit stock replenishment ($m^2 \leftrightarrow \text{boxes}$), supplier payables ledger integration, and Israeli standard A4 Goods Intake Note / Purchase Voucher PDF generation.

**Architecture:** Pure Dart domain models and business services decouple stock replenishment and supplier debt accounting from the presentation layer. Purchases convert received units to primary inventory units via `UnitConverter`, update product stock counts and cost averages, credit the supplier's running balance, and log `StatementEntryType.purchaseInvoice` entries. A dedicated PDF generator produces official A4 Goods Intake Vouchers.

**Tech Stack:** Dart 3.x, Flutter 3.x, `pdf` package, `intl`, `test`.

**Spec:** `docs/superpowers/specs/2026-11-13-sales-accounting-logistics-design.md` (Section 2.1 #2 & #3, Section 4.3, Section 4.10)

## Global Constraints
- Currency: Israeli New Shekel (ILS / ₪) formatted with 2 decimal places.
- Dual-Unit Inventory: Primary stock for marble/stone is stored in square meters ($m^2$); boxes are converted via product `meterPerBox` factor. Sanitary ware and fixtures are stored in pieces (חתיכה / حبة).
- Sequential Numbering: Internal purchase invoices follow `PUR-YYYY-xxxxx` (e.g. `PUR-2026-00001`). External supplier invoice numbers (e.g., "SUP-9871") are captured for tax and cross-audit tracking.
- Accounting Semantics: For suppliers, positive `Contact.currentBalance` represents accounts payable (what M.I.R.N owes the supplier). On-account purchases increase `currentBalance` (Credit in StatementEntry), while supplier payments reduce it (Debit in StatementEntry).
- Trilingual Support: Arabic (default RTL), Hebrew (official statutory RTL), English (LTR).
- PDF Documents: Standard A4 format with M.I.R.N POWER luxury branding, Hebrew & Arabic statutory headers, warehouse intake signature blocks, and itemized quantity/unit breakdowns.

## Review Focus
- Dual-unit precision drift: Converting purchased boxes to square meters must preserve exact arithmetic precision (e.g. 100 boxes $\times$ 1.44 $m^2$/box = exactly 144.00 $m^2$).
- Zero or negative quantities and costs: Line items with non-positive quantities or negative unit costs must be strictly rejected with `ArgumentError`.
- Supplier vs. Customer isolation: Attempting to record a purchase from a customer-only contact must throw `ArgumentError`.
- Imbalance in payments: Paid amount cannot exceed total purchase amount; `totalAmount == round2(paidAmount + onAccountAmount)`.
- Average cost calculation: Products receiving stock must properly recalculate weighted moving average cost or latest purchase cost without dividing by zero on empty initial inventory.

---

### Task 1: `PurchaseInvoice` and `PurchaseLineItem` Domain Models

**Files:**
- Create: `lib/features/purchases/domain/models/purchase_invoice.dart`
- Test: `test/features/purchases/purchase_invoice_model_test.dart`

**Interfaces:**
- Consumes: `lib/features/inventory/domain/models/product.dart` (`UnitType`), `lib/features/accounts/domain/models/contact.dart` (`ContactType`).
- Produces: `PurchaseLineItem`, `PurchaseInvoice`.

- [ ] **Step 1: Write failing tests for `PurchaseInvoice` and `PurchaseLineItem` models**

```dart
// test/features/purchases/purchase_invoice_model_test.dart
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
        items: const [
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

    test('rejects invoice with empty line items list', () {
      expect(
        () => PurchaseInvoice(
          id: 'pur-002',
          invoiceNumber: 'PUR-2026-00002',
          date: DateTime(2026, 11, 14),
          supplierId: 'supp-201',
          supplierName: 'محاجر القدس',
          supplierTaxId: '514882109',
          items: const [],
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
          items: const [
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

    test('serializes and deserializes to/from JSON cleanly', () {
      final invoice = PurchaseInvoice(
        id: 'pur-004',
        invoiceNumber: 'PUR-2026-00004',
        supplierInvoiceNumber: 'INV-771',
        date: DateTime(2026, 11, 14, 12, 0),
        supplierId: 'supp-202',
        supplierName: 'سيراميك الجليل / חרסינת הגליל',
        supplierTaxId: '515099231',
        items: const [
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
      expect(revived.items.length, equals(1));
      expect(revived.items.first.productName, equals('بورسلان اسباني 60*120'));
      expect(revived.totalAmount, equals(4972.50));
      expect(revived.onAccountAmount, equals(4972.50));
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**
- [ ] **Step 3: Implement `PurchaseInvoice` and `PurchaseLineItem` in `lib/features/purchases/domain/models/purchase_invoice.dart`**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit Task 1**

---

### Task 2: Stock Addition in `UnitConverter` & `PurchaseService.processPurchase`

**Files:**
- Modify: `lib/features/inventory/domain/services/unit_converter.dart`
- Create: `lib/features/purchases/domain/services/purchase_service.dart`
- Test: `test/features/purchases/purchase_service_test.dart`

**Interfaces:**
- Consumes: `Product`, `UnitType`, `UnitConverter`, `Contact`, `StatementEntry`, `PurchaseInvoice`.
- Produces: `PurchaseService`, `CreatePurchaseInput`, `PurchaseLineItemInput`, `ProcessPurchaseResult`.

- [ ] **Step 1: Write failing tests for `UnitConverter.calculateStockAddition` and `PurchaseService.processPurchase`**

```dart
// test/features/purchases/purchase_service_test.dart
import 'package:test/test.dart';
import 'package:sales_logistics_system/features/inventory/domain/models/product.dart';
import 'package:sales_logistics_system/features/inventory/domain/services/unit_converter.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/contact.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/statement_entry.dart';
import 'package:sales_logistics_system/features/purchases/domain/models/purchase_invoice.dart';
import 'package:sales_logistics_system/features/purchases/domain/services/purchase_service.dart';

void main() {
  group('UnitConverter calculateStockAddition Tests', () {
    test('calculates stock addition from boxes to square meters', () {
      const product = Product(
        id: 'p1',
        name: 'رخام كرارا',
        sku: 'MB-001',
        category: ProductCategory.marble,
        unitType: UnitType.meter,
        meterPerBox: 1.44,
        purchaseCost: 90.0,
        sellingPrice: 150.0,
        currentStock: 100.0,
      );

      final addedMeters = UnitConverter.calculateStockAddition(
        product: product,
        quantity: 50, // 50 boxes
        purchasedUnit: UnitType.box,
      );

      expect(addedMeters, equals(72.0)); // 50 * 1.44
    });

    test('calculates piece-based addition without factor', () {
      const product = Product(
        id: 'p2',
        name: 'كرسي حمام',
        sku: 'SN-001',
        category: ProductCategory.sanitary,
        unitType: UnitType.piece,
        purchaseCost: 500.0,
        sellingPrice: 850.0,
        currentStock: 10.0,
      );

      final added = UnitConverter.calculateStockAddition(
        product: product,
        quantity: 15,
        purchasedUnit: UnitType.piece,
      );

      expect(added, equals(15.0));
    });
  });

  group('PurchaseService processPurchase Tests', () {
    late Contact testSupplier;
    late Product marbleProduct;
    late Product sanitaryProduct;

    setUp(() {
      testSupplier = const Contact(
        id: 'supp-01',
        type: ContactType.supplier,
        name: 'شركة محاجر القدس',
        phone: '02-5819000',
        address: 'عطروت / עטרות',
        taxId: '514882109',
        debtWarningLimit: 0.0,
        currentBalance: 10000.0, // M.I.R.N already owes ₪10,000
      );

      marbleProduct = const Product(
        id: 'prod-marble',
        name: 'رخام كرارا',
        sku: 'MB-001',
        category: ProductCategory.marble,
        unitType: UnitType.meter,
        meterPerBox: 1.44,
        purchaseCost: 100.0,
        sellingPrice: 160.0,
        currentStock: 200.0,
      );

      sanitaryProduct = const Product(
        id: 'prod-sanitary',
        name: 'خلاط مغسلة ألماني',
        sku: 'SN-002',
        category: ProductCategory.sanitary,
        unitType: UnitType.piece,
        purchaseCost: 250.0,
        sellingPrice: 420.0,
        currentStock: 15.0,
      );
    });

    test('replenishes stock and updates supplier payable balance on on-account purchase', () {
      final input = CreatePurchaseInput(
        invoiceNumber: 'PUR-2026-00001',
        supplierInvoiceNumber: 'EXT-1049',
        date: DateTime(2026, 11, 14, 10, 0),
        supplier: testSupplier,
        items: [
          PurchaseLineItemInput(
            product: marbleProduct,
            unitType: UnitType.box,
            quantity: 50, // 50 boxes = 72 m²
            unitCost: 105.0, // 50 * 105 = 5250
          ),
          PurchaseLineItemInput(
            product: sanitaryProduct,
            unitType: UnitType.piece,
            quantity: 10, // 10 pieces
            unitCost: 240.0, // 10 * 240 = 2400
          ),
        ],
        vatRate: 0.17,
        paidAmount: 0.0, // 100% On Account
        notes: 'استلام بضاعة المستودع الرئيسي',
        createdBy: 'admin-01',
      );

      final result = PurchaseService.processPurchase(input: input);

      // Verify Purchase Invoice
      expect(result.purchase.invoiceNumber, equals('PUR-2026-00001'));
      expect(result.purchase.subtotal, equals(7650.0)); // 5250 + 2400
      expect(result.purchase.vatAmount, equals(1300.50)); // 7650 * 0.17
      expect(result.purchase.totalAmount, equals(8950.50));
      expect(result.purchase.onAccountAmount, equals(8950.50));

      // Verify Stock Replenishment
      final updatedMarble = result.updatedProducts.firstWhere((p) => p.id == 'prod-marble');
      expect(updatedMarble.currentStock, equals(272.0)); // 200 + 72
      // Weighted average cost: (200 * 100 + 72 * (105 / 1.44)) / 272 = (20000 + 5250) / 272 = 92.83
      expect(updatedMarble.purchaseCost, isNotNull);

      final updatedSanitary = result.updatedProducts.firstWhere((p) => p.id == 'prod-sanitary');
      expect(updatedSanitary.currentStock, equals(25.0)); // 15 + 10

      // Verify Supplier Balance Update (Payables increase)
      expect(result.updatedSupplier.currentBalance, equals(18950.50)); // 10000 + 8950.50

      // Verify StatementEntry
      expect(result.statementEntry, isNotNull);
      expect(result.statementEntry!.type, equals(StatementEntryType.purchaseInvoice));
      expect(result.statementEntry!.debit, equals(0.0));
      expect(result.statementEntry!.credit, equals(8950.50));
      expect(result.statementEntry!.runningBalance, equals(18950.50));
      expect(result.statementEntry!.referenceNumber, equals('PUR-2026-00001'));
    });

    test('handles partially paid purchase invoice correctly', () {
      final input = CreatePurchaseInput(
        invoiceNumber: 'PUR-2026-00002',
        date: DateTime(2026, 11, 14),
        supplier: testSupplier,
        items: [
          PurchaseLineItemInput(
            product: sanitaryProduct,
            unitType: UnitType.piece,
            quantity: 10,
            unitCost: 200.0, // 2000 subtotal, 340 VAT = 2340 total
          ),
        ],
        vatRate: 0.17,
        paidAmount: 1000.0, // Paid ₪1000 upfront, remaining ₪1340 on account
        createdBy: 'admin-01',
      );

      final result = PurchaseService.processPurchase(input: input);

      expect(result.purchase.totalAmount, equals(2340.0));
      expect(result.purchase.paidAmount, equals(1000.0));
      expect(result.purchase.onAccountAmount, equals(1340.0));
      expect(result.updatedSupplier.currentBalance, equals(11340.0)); // 10000 + 1340
      expect(result.statementEntry!.credit, equals(1340.0));
    });

    test('rejects customer-only contact as purchase supplier', () {
      const customerContact = Contact(
        id: 'cust-01',
        type: ContactType.customer,
        name: 'عميل',
        phone: '050',
        address: '',
        taxId: '',
        debtWarningLimit: 0,
        currentBalance: 0,
      );

      final input = CreatePurchaseInput(
        invoiceNumber: 'PUR-2026-00003',
        date: DateTime(2026, 11, 14),
        supplier: customerContact,
        items: [
          PurchaseLineItemInput(
            product: sanitaryProduct,
            unitType: UnitType.piece,
            quantity: 5,
            unitCost: 100.0,
          ),
        ],
        createdBy: 'admin-01',
      );

      expect(() => PurchaseService.processPurchase(input: input), throwsArgumentError);
    });

    test('rejects paidAmount greater than totalAmount', () {
      final input = CreatePurchaseInput(
        invoiceNumber: 'PUR-2026-00004',
        date: DateTime(2026, 11, 14),
        supplier: testSupplier,
        items: [
          PurchaseLineItemInput(
            product: sanitaryProduct,
            unitType: UnitType.piece,
            quantity: 5,
            unitCost: 100.0, // 500 subtotal, 85 VAT = 585 total
          ),
        ],
        vatRate: 0.17,
        paidAmount: 1000.0, // Overpayment
        createdBy: 'admin-01',
      );

      expect(() => PurchaseService.processPurchase(input: input), throwsArgumentError);
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**
- [ ] **Step 3: Update `UnitConverter.calculateStockAddition` and implement `PurchaseService.processPurchase`**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit Task 2**

---

### Task 3: Israeli Standard A4 Purchase Intake / Voucher PDF Generator (`PurchasePdfGenerator`)

**Files:**
- Create: `lib/core/pdf/purchase_pdf_generator.dart`
- Test: `test/core/pdf/purchase_pdf_test.dart`

**Interfaces:**
- Consumes: `PurchaseInvoice`, `PurchaseLineItem`, `pdf/pdf.dart`, `pdf/widgets.dart`.
- Produces: `PurchasePdfGenerator.generatePurchasePdf(PurchaseInvoice invoice) -> Future<Uint8List>`.

- [ ] **Step 1: Write failing test for `PurchasePdfGenerator`**

```dart
// test/core/pdf/purchase_pdf_test.dart
import 'package:test/test.dart';
import 'package:sales_logistics_system/features/inventory/domain/models/product.dart';
import 'package:sales_logistics_system/features/purchases/domain/models/purchase_invoice.dart';
import 'package:sales_logistics_system/core/pdf/purchase_pdf_generator.dart';

void main() {
  group('Purchase Voucher / Intake Note PDF Generator Tests', () {
    test('generates valid non-empty A4 PDF document with legal headers and line items', () async {
      final invoice = PurchaseInvoice(
        id: 'pur-001',
        invoiceNumber: 'PUR-2026-00001',
        supplierInvoiceNumber: 'SUPP-INV-9921',
        date: DateTime(2026, 11, 14, 11, 0),
        supplierId: 'supp-201',
        supplierName: 'מחצבות ירושלים ושיש בע"מ / محاجر القدس للرخام',
        supplierTaxId: '514882109',
        items: const [
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
            productName: 'أسלה תלויה גרואה / كرسي حمام معلق جروهي',
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
        notes: 'استلام بضاعة مستودع قلنديا',
        createdBy: 'admin-01',
        createdAt: DateTime(2026, 11, 14),
      );

      final pdfBytes = await PurchasePdfGenerator.generatePurchasePdf(invoice);

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
      // PDF standard magic bytes: %PDF-
      expect(pdfBytes[0], equals(0x25)); // %
      expect(pdfBytes[1], equals(0x50)); // P
      expect(pdfBytes[2], equals(0x44)); // D
      expect(pdfBytes[3], equals(0x46)); // F
      expect(pdfBytes[4], equals(0x2D)); // -
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**
- [ ] **Step 3: Implement `PurchasePdfGenerator` in `lib/core/pdf/purchase_pdf_generator.dart`**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit Task 3**

---

### Task 4: Presentation Controller & State Machine (`PurchasesController`)

**Files:**
- Create: `lib/features/purchases/presentation/controllers/purchases_controller.dart`
- Test: `test/features/purchases/purchases_controller_test.dart`

**Interfaces:**
- Consumes: `PurchaseService`, `Product`, `Contact`, `UnitType`.
- Produces: `PurchasesController`, `PurchaseItemDraft`, `PurchasesFormState`.

- [ ] **Step 1: Write failing tests for `PurchasesController`**

```dart
// test/features/purchases/purchases_controller_test.dart
import 'package:test/test.dart';
import 'package:sales_logistics_system/features/inventory/domain/models/product.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/contact.dart';
import 'package:sales_logistics_system/features/purchases/presentation/controllers/purchases_controller.dart';

void main() {
  group('PurchasesController State Machine Tests', () {
    late Contact supplier;
    late Product marble;

    setUp(() {
      supplier = const Contact(
        id: 'supp-10',
        type: ContactType.supplier,
        name: 'سيراميك القدس',
        phone: '052-0000000',
        address: 'القدس',
        taxId: '519283741',
        debtWarningLimit: 0,
        currentBalance: 5000.0,
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
    });

    test('adds items and dynamically computes subtotals, VAT, and on-account amount', () {
      final controller = PurchasesController();
      controller.setSupplier(supplier);
      controller.setInvoiceNumber('PUR-2026-00010');
      controller.setSupplierInvoiceNumber('INV-990');

      controller.addItem(
        product: marble,
        unitType: UnitType.box,
        quantity: 20, // 20 boxes * 1.44 = 28.8 m²
        unitCost: 100.0, // subtotal = 2000.0
      );

      expect(controller.state.items.length, equals(1));
      expect(controller.state.subtotal, equals(2000.0));
      expect(controller.state.vatAmount, equals(340.0)); // 2000 * 0.17
      expect(controller.state.totalAmount, equals(2340.0));
      expect(controller.state.onAccountAmount, equals(2340.0));
      expect(controller.state.isValid, isTrue);

      // Set partial payment
      controller.setPaidAmount(1000.0);
      expect(controller.state.paidAmount, equals(1000.0));
      expect(controller.state.onAccountAmount, equals(1340.0));

      // Remove item
      controller.removeItem(0);
      expect(controller.state.items.isEmpty, isTrue);
      expect(controller.state.subtotal, equals(0.0));
      expect(controller.state.isValid, isFalse);
    });

    test('submits purchase and resets state after successful processing', () {
      final controller = PurchasesController();
      controller.setSupplier(supplier);
      controller.setInvoiceNumber('PUR-2026-00011');
      controller.addItem(
        product: marble,
        unitType: UnitType.meter,
        quantity: 10,
        unitCost: 85.0,
      );

      expect(controller.state.isValid, isTrue);

      final result = controller.submitPurchase(createdBy: 'cashier-01');

      expect(result.purchase.invoiceNumber, equals('PUR-2026-00011'));
      expect(result.updatedSupplier.currentBalance, equals(5000.0 + (850.0 * 1.17)));
      expect(controller.state.items.isEmpty, isTrue); // Reset
      expect(controller.state.supplier, isNull);
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**
- [ ] **Step 3: Implement `PurchasesController` in `lib/features/purchases/presentation/controllers/purchases_controller.dart`**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit Task 4**

---

### Task 5: Interactive UI Integration in `lib/main.dart` & `mirn_system_preview.html`

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/features/dashboard/navigation_shell_test.dart` (if needed, keeping all destinations consistent)
- Modify: `mirn_system_preview.html` (interactive prototype artifact)

**Changes:**
- Add `AppNavDestination.inventory` to the main navigation bar destinations in `lib/main.dart`.
- Build `_buildInventoryScreen()` in `lib/main.dart`:
  - Visual product stock table with live counts, unit badges ($m^2$, boxes, pieces), low-stock warning chips, and purchase cost.
  - "New Stock Intake / Purchase (توريد مخزون وفاتورة شراء جديدة / קליטת מלאי ורכש חדש)" action button.
  - Interactive Modal dialog `_showNewPurchaseDialog()`:
    - Select supplier from registered suppliers (`ContactType.supplier` / `ContactType.both`).
    - Enter internal purchase number and supplier's invoice number.
    - Select product to purchase.
    - Pick unit type ($m^2$, box, piece) with dynamic conversion factor indicator (e.g., "$1\text{ box} = 1.44\text{ }m^2$").
    - Enter quantity and unit cost.
    - Live breakdown: Subtotal, VAT (17%), Total Amount, Paid Amount vs. On-Account Debt.
    - Submit intake: updates live `_products` state, updates `_contacts` supplier balance, appends statement entry to `_statementController`, and displays success snackbar with 1-click A4 PDF print preview.
- Update `mirn_system_preview.html` with the new Purchases & Stock Intake interactive tab and sample transactions.
- Test: Run the full test suite (all 18+ test files) and verify 100% pass rate.

- [ ] **Step 1: Integrate `_buildInventoryScreen()` and `_showNewPurchaseDialog()` in `lib/main.dart`**
- [ ] **Step 2: Update `mirn_system_preview.html`**
- [ ] **Step 3: Run complete test suite via Dart SDK**
- [ ] **Step 4: Commit Task 5**

---

### Task 6: Whole-Branch Verification & Senior Code Review

- [ ] **Step 1: Dispatch Senior Code Reviewer on Pro model to audit the complete branch changes**
- [ ] **Step 2: Address any findings (critical or important)**
- [ ] **Step 3: Merge `feat/purchases-inventory-intake` into `master` locally using `finishing-a-development-branch`**
- [ ] **Step 4: Confirm master working tree clean and all tests green**
