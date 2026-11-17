import 'package:test/test.dart';
import 'package:sales_logistics_system/features/inventory/domain/models/product.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/contact.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/statement_entry.dart';
import 'package:sales_logistics_system/features/checks/domain/models/check_record.dart';
import 'package:sales_logistics_system/features/sales/domain/models/payment_split.dart';
import 'package:sales_logistics_system/features/sales/domain/models/sale_invoice.dart';
import 'package:sales_logistics_system/features/purchases/domain/models/purchase_invoice.dart';
import 'package:sales_logistics_system/features/returns/domain/models/credit_note.dart';
import 'package:sales_logistics_system/core/repositories/in_memory/in_memory_product_repository.dart';
import 'package:sales_logistics_system/core/repositories/in_memory/in_memory_contact_repository.dart';
import 'package:sales_logistics_system/core/repositories/in_memory/in_memory_sale_repository.dart';
import 'package:sales_logistics_system/core/repositories/in_memory/in_memory_check_repository.dart';
import 'package:sales_logistics_system/core/repositories/in_memory/in_memory_purchase_repository.dart';
import 'package:sales_logistics_system/features/sales/domain/services/sale_transaction_orchestrator.dart';
import 'package:sales_logistics_system/features/checks/domain/services/check_lifecycle_orchestrator.dart';
import 'package:sales_logistics_system/features/purchases/domain/services/purchase_transaction_orchestrator.dart';
import 'package:sales_logistics_system/features/returns/domain/services/credit_note_transaction_orchestrator.dart';

void main() {
  group('SaleTransactionOrchestrator', () {
    late InMemoryProductRepository productRepo;
    late InMemoryContactRepository contactRepo;
    late InMemorySaleRepository saleRepo;
    late InMemoryCheckRepository checkRepo;
    late SaleTransactionOrchestrator orchestrator;

    final sampleProduct = const Product(
      id: 'prod-01',
      name: 'Spanish Porcelain 60x120',
      sku: 'POR-001',
      category: ProductCategory.sanitary,
      unitType: UnitType.meter,
      purchaseCost: 80.0,
      sellingPrice: 120.0,
      currentStock: 50.0,
    );

    final sampleCustomer = const Contact(
      id: 'cust-01',
      name: 'Tariq Mansoor',
      phone: '052-1111111',
      address: 'Jerusalem',
      taxId: '515892104',
      debtWarningLimit: 10000.0,
      type: ContactType.customer,
      currentBalance: 1000.0,
    );

    setUp(() {
      productRepo = InMemoryProductRepository(initialProducts: [sampleProduct]);
      contactRepo = InMemoryContactRepository(initialContacts: [sampleCustomer]);
      saleRepo = InMemorySaleRepository();
      checkRepo = InMemoryCheckRepository();
      orchestrator = SaleTransactionOrchestrator(
        productRepository: productRepo,
        contactRepository: contactRepo,
        saleRepository: saleRepo,
        checkRepository: checkRepo,
      );
    });

    tearDown(() {
      productRepo.dispose();
      contactRepo.dispose();
      saleRepo.dispose();
      checkRepo.dispose();
    });

    test('successfully processes sale: decrements stock, records debt, and saves sale', () async {
      final sale = SaleInvoice(
        id: 'inv-01',
        invoiceNumber: 'INV-2026-00001',
        date: DateTime(2026, 11, 17),
        customerId: sampleCustomer.id,
        customerName: sampleCustomer.name,
        customerTaxId: sampleCustomer.taxId,
        isTaxInclusiveInput: false,
        items: const [
          SaleLineItem(
            productId: 'prod-01',
            productName: 'Spanish Porcelain 60x120',
            unitType: UnitType.meter,
            quantity: 20.0,
            unitPrice: 100.0,
            subtotal: 2000.0,
          ),
        ],
        subtotal: 2000.0,
        vatRate: 0.17,
        vatAmount: 340.0,
        totalAmount: 2340.0,
        payments: const [
          PaymentSplit(method: PaymentMethod.cash, amount: 340.0),
          PaymentSplit(method: PaymentMethod.debt, amount: 2000.0),
        ],
        createdAt: DateTime(2026, 11, 17),
      );

      await orchestrator.processSaleTransaction(sale: sale, customer: sampleCustomer);

      // Verify stock decremented
      final updatedProduct = await productRepo.getProductById('prod-01');
      expect(updatedProduct!.currentStock, equals(30.0));

      // Verify customer debt incremented
      final updatedCustomer = await contactRepo.getContactById('cust-01');
      expect(updatedCustomer!.currentBalance, equals(3000.0));

      // Verify ledger entry
      final ledger = await contactRepo.getStatementEntries('cust-01');
      expect(ledger, hasLength(1));
      expect(ledger.first.debit, equals(2000.0));

      // Verify sale recorded
      final savedSale = await saleRepo.getSaleById('inv-01');
      expect(savedSale, isNotNull);
      expect(savedSale!.totalAmount, equals(2340.0));
    });

    test('rejects sale and aborts when stock is insufficient', () async {
      final excessiveSale = SaleInvoice(
        id: 'inv-02',
        invoiceNumber: 'INV-2026-00002',
        date: DateTime(2026, 11, 17),
        customerId: sampleCustomer.id,
        customerName: sampleCustomer.name,
        customerTaxId: sampleCustomer.taxId,
        isTaxInclusiveInput: false,
        items: const [
          SaleLineItem(
            productId: 'prod-01',
            productName: 'Spanish Porcelain 60x120',
            unitType: UnitType.meter,
            quantity: 999.0, // Available: 50.0
            unitPrice: 100.0,
            subtotal: 99900.0,
          ),
        ],
        subtotal: 99900.0,
        vatRate: 0.17,
        vatAmount: 16983.0,
        totalAmount: 116883.0,
        payments: const [
          PaymentSplit(method: PaymentMethod.cash, amount: 116883.0),
        ],
        createdAt: DateTime(2026, 11, 17),
      );

      expect(
        () => orchestrator.processSaleTransaction(sale: excessiveSale, customer: sampleCustomer),
        throwsA(isA<StateError>()),
      );

      // Stock should remain unchanged (no partial deduction)
      final product = await productRepo.getProductById('prod-01');
      expect(product!.currentStock, equals(50.0));
    });

    test('aggregates quantities for duplicate products in sale and rejects if total exceeds stock', () async {
      // prod-01 has 50.0 available. Two items requesting 30.0 each = 60.0 total
      final duplicateItemsSale = SaleInvoice(
        id: 'inv-dup-01',
        invoiceNumber: 'INV-2026-00003',
        date: DateTime(2026, 11, 17),
        customerId: sampleCustomer.id,
        customerName: sampleCustomer.name,
        customerTaxId: sampleCustomer.taxId,
        isTaxInclusiveInput: false,
        items: const [
          SaleLineItem(
            productId: 'prod-01',
            productName: 'Spanish Porcelain 60x120',
            unitType: UnitType.meter,
            quantity: 30.0,
            unitPrice: 100.0,
            subtotal: 3000.0,
          ),
          SaleLineItem(
            productId: 'prod-01',
            productName: 'Spanish Porcelain 60x120',
            unitType: UnitType.meter,
            quantity: 30.0,
            unitPrice: 90.0,
            subtotal: 2700.0,
          ),
        ],
        subtotal: 5700.0,
        vatRate: 0.17,
        vatAmount: 969.0,
        totalAmount: 6669.0,
        payments: const [
          PaymentSplit(method: PaymentMethod.cash, amount: 6669.0),
        ],
        createdAt: DateTime(2026, 11, 17),
      );

      expect(
        () => orchestrator.processSaleTransaction(sale: duplicateItemsSale, customer: sampleCustomer),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('requested 60.0'),
        )),
      );

      // Stock remains completely untouched at 50.0
      final product = await productRepo.getProductById('prod-01');
      expect(product!.currentStock, equals(50.0));
    });
  });

  group('CheckLifecycleOrchestrator', () {
    late InMemoryCheckRepository checkRepo;
    late InMemoryContactRepository contactRepo;
    late CheckLifecycleOrchestrator orchestrator;

    final sampleCustomer = const Contact(
      id: 'cust-01',
      name: 'Tariq Mansoor',
      phone: '052-1111111',
      address: 'Jerusalem',
      taxId: '515892104',
      debtWarningLimit: 10000.0,
      type: ContactType.customer,
      currentBalance: 0.0,
    );

    final check = CheckRecord(
      id: 'chk-99',
      checkNumber: '882211',
      bankName: 'Bank Hapoalim',
      branchNumber: '512',
      accountNumber: '998822',
      amount: 4500.0,
      dueDate: DateTime(2026, 11, 15),
      type: CheckType.received,
      partyId: 'cust-01',
      partyName: 'Tariq Mansoor',
      relatedTransactionId: 'inv-01',
      status: CheckStatus.deposited,
      history: const [],
      createdAt: DateTime(2026, 11, 10),
    );

    setUp(() {
      checkRepo = InMemoryCheckRepository(initialChecks: [check]);
      contactRepo = InMemoryContactRepository(initialContacts: [sampleCustomer]);
      orchestrator = CheckLifecycleOrchestrator(
        checkRepository: checkRepo,
        contactRepository: contactRepo,
      );
    });

    tearDown(() {
      checkRepo.dispose();
      contactRepo.dispose();
    });

    test('bounced check restores customer debt and appends ledger statement', () async {
      await orchestrator.processCheckBounce(
        checkId: 'chk-99',
        party: sampleCustomer,
        reason: 'Insufficient funds (אין כיסוי)',
      );

      // Check status updated
      final updatedCheck = await checkRepo.getCheckById('chk-99');
      expect(updatedCheck!.status, equals(CheckStatus.bounced));

      // Customer debt re-applied
      final updatedCustomer = await contactRepo.getContactById('cust-01');
      expect(updatedCustomer!.currentBalance, equals(4500.0));

      // Ledger statement added
      final statements = await contactRepo.getStatementEntries('cust-01');
      expect(statements, hasLength(1));
      expect(statements.first.type, equals(StatementEntryType.checkBounced));
      expect(statements.first.debit, equals(4500.0));
      expect(statements.first.runningBalance, equals(4500.0));
    });

    test('rejects bounce if check is already marked as bounced', () async {
      await orchestrator.processCheckBounce(
        checkId: 'chk-99',
        party: sampleCustomer,
      );

      // Attempt second bounce
      expect(
        () => orchestrator.processCheckBounce(
          checkId: 'chk-99',
          party: sampleCustomer,
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('already marked as bounced'),
        )),
      );

      // Debt balance not doubled
      final customer = await contactRepo.getContactById('cust-01');
      expect(customer!.currentBalance, equals(4500.0));
    });

    test('rejects bounce if partyId does not match check partyId', () async {
      final wrongCustomer = const Contact(
        id: 'cust-wrong',
        name: 'Wrong Customer',
        phone: '050-0000000',
        address: 'Unknown',
        taxId: '515892104',
        debtWarningLimit: 10000.0,
        type: ContactType.customer,
        currentBalance: 0.0,
      );

      expect(
        () => orchestrator.processCheckBounce(
          checkId: 'chk-99',
          party: wrongCustomer,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Party ID mismatch'),
        )),
      );
    });
  });

  group('PurchaseTransactionOrchestrator', () {
    late InMemoryProductRepository productRepo;
    late InMemoryContactRepository contactRepo;
    late InMemoryPurchaseRepository purchaseRepo;
    late PurchaseTransactionOrchestrator orchestrator;

    final sampleProduct = const Product(
      id: 'prod-01',
      name: 'Spanish Porcelain 60x120',
      sku: 'POR-001',
      category: ProductCategory.sanitary,
      unitType: UnitType.meter,
      purchaseCost: 80.0,
      sellingPrice: 120.0,
      currentStock: 20.0,
    );

    final sampleSupplier = const Contact(
      id: 'sup-01',
      name: 'Castellon Tiles Spain',
      phone: '054-9988776',
      address: 'Valencia, Spain',
      taxId: '515892104',
      debtWarningLimit: 50000.0,
      type: ContactType.supplier,
      currentBalance: 10000.0,
    );

    setUp(() {
      productRepo = InMemoryProductRepository(initialProducts: [sampleProduct]);
      contactRepo = InMemoryContactRepository(initialContacts: [sampleSupplier]);
      purchaseRepo = InMemoryPurchaseRepository();
      orchestrator = PurchaseTransactionOrchestrator(
        productRepository: productRepo,
        contactRepository: contactRepo,
        purchaseRepository: purchaseRepo,
      );
    });

    tearDown(() {
      productRepo.dispose();
      contactRepo.dispose();
      purchaseRepo.dispose();
    });

    test('processes purchase intake: increments stock, computes moving average cost, and increases supplier AP', () async {
      final purchase = PurchaseInvoice(
        id: 'pur-01',
        invoiceNumber: 'PUR-2026-00001',
        supplierId: 'sup-01',
        supplierName: 'Castellon Tiles Spain',
        supplierTaxId: '515892104',
        supplierInvoiceNumber: 'INV-ES-99',
        date: DateTime(2026, 11, 17),
        items: [
          PurchaseLineItem(
            productId: 'prod-01',
            productName: 'Spanish Porcelain 60x120',
            unitType: UnitType.meter,
            quantity: 30.0,
            unitCost: 100.0,
            subtotal: 3000.0,
            convertedStockQuantity: 30.0,
          ),
        ],
        subtotal: 3000.0,
        vatRate: 0.17,
        vatAmount: 510.0,
        totalAmount: 3510.0,
        onAccountAmount: 3510.0,
        createdBy: 'admin',
      );

      await orchestrator.processPurchaseTransaction(
        purchase: purchase,
        supplier: sampleSupplier,
      );

      // Stock was 20 @ 80 = 1600. Added 30 @ 100 = 3000. Total = 4600 / 50 = 92.0
      final updatedProduct = await productRepo.getProductById('prod-01');
      expect(updatedProduct!.currentStock, equals(50.0));
      expect(updatedProduct.purchaseCost, equals(92.0));

      // Supplier AP balance updated: 10000 + 3510 = 13510
      final updatedSupplier = await contactRepo.getContactById('sup-01');
      expect(updatedSupplier!.currentBalance, equals(13510.0));

      // Statement ledger credited
      final statements = await contactRepo.getStatementEntries('sup-01');
      expect(statements, hasLength(1));
      expect(statements.first.credit, equals(3510.0));
      expect(statements.first.runningBalance, equals(13510.0));
    });

    test('aborts and rejects purchase intake if any product is not found in repository', () async {
      final invalidPurchase = PurchaseInvoice(
        id: 'pur-invalid-01',
        invoiceNumber: 'PUR-2026-00002',
        supplierId: 'sup-01',
        supplierName: 'Castellon Tiles Spain',
        supplierTaxId: '515892104',
        date: DateTime(2026, 11, 17),
        items: [
          PurchaseLineItem(
            productId: 'non-existent-product',
            productName: 'Unknown Product',
            unitType: UnitType.meter,
            quantity: 10.0,
            unitCost: 50.0,
            subtotal: 500.0,
            convertedStockQuantity: 10.0,
          ),
        ],
        subtotal: 500.0,
        vatRate: 0.17,
        vatAmount: 85.0,
        totalAmount: 585.0,
        onAccountAmount: 585.0,
        createdBy: 'admin',
      );

      expect(
        () => orchestrator.processPurchaseTransaction(
          purchase: invalidPurchase,
          supplier: sampleSupplier,
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('not found'),
        )),
      );

      // Supplier AP remains untouched at 10000.0 (no phantom debt)
      final supplier = await contactRepo.getContactById('sup-01');
      expect(supplier!.currentBalance, equals(10000.0));
    });
  });

  group('CreditNoteTransactionOrchestrator', () {
    late InMemoryProductRepository productRepo;
    late InMemoryContactRepository contactRepo;
    late InMemorySaleRepository saleRepo;
    late CreditNoteTransactionOrchestrator orchestrator;

    final sampleProduct = const Product(
      id: 'prod-01',
      name: 'Spanish Porcelain 60x120',
      sku: 'POR-001',
      category: ProductCategory.sanitary,
      unitType: UnitType.meter,
      purchaseCost: 80.0,
      sellingPrice: 120.0,
      currentStock: 20.0,
    );

    final sampleCustomer = const Contact(
      id: 'cust-01',
      name: 'Tariq Mansoor',
      phone: '052-1111111',
      address: 'Jerusalem',
      taxId: '515892104',
      debtWarningLimit: 10000.0,
      type: ContactType.customer,
      currentBalance: 5000.0,
    );

    setUp(() {
      productRepo = InMemoryProductRepository(initialProducts: [sampleProduct]);
      contactRepo = InMemoryContactRepository(initialContacts: [sampleCustomer]);
      saleRepo = InMemorySaleRepository();
      orchestrator = CreditNoteTransactionOrchestrator(
        productRepository: productRepo,
        contactRepository: contactRepo,
        saleRepository: saleRepo,
      );
    });

    tearDown(() {
      productRepo.dispose();
      contactRepo.dispose();
      saleRepo.dispose();
    });

    test('restores inventory stock, reduces customer debt, and posts credit ledger entry', () async {
      final creditNote = CreditNote(
        id: 'crn-01',
        creditNoteNumber: 'CRN-2026-00001',
        originalInvoiceNumber: 'INV-2026-00001',
        date: DateTime(2026, 11, 17),
        customerId: sampleCustomer.id,
        customerName: sampleCustomer.name,
        customerTaxId: sampleCustomer.taxId,
        items: const [
          CreditNoteLineItem(
            productId: 'prod-01',
            productName: 'Spanish Porcelain 60x120',
            unitType: UnitType.meter,
            quantity: 5.0,
            unitPrice: 100.0,
            subtotal: 500.0,
          ),
        ],
        subtotal: 500.0,
        vatRate: 0.17,
        vatAmount: 85.0,
        totalAmount: 585.0,
        refundMethod: RefundMethod.debtCredit,
        reason: 'Broken tile return',
        createdAt: DateTime(2026, 11, 17),
      );

      await orchestrator.processCreditNoteTransaction(
        creditNote: creditNote,
        customer: sampleCustomer,
      );

      // Inventory restored: 20 + 5 = 25
      final product = await productRepo.getProductById('prod-01');
      expect(product!.currentStock, equals(25.0));

      // Customer debt reduced: 5000 - 585 = 4415.0
      final customer = await contactRepo.getContactById('cust-01');
      expect(customer!.currentBalance, equals(4415.0));

      // Ledger statement recorded
      final statements = await contactRepo.getStatementEntries('cust-01');
      expect(statements, hasLength(1));
      expect(statements.first.credit, equals(585.0));
      expect(statements.first.runningBalance, equals(4415.0));
    });

    test('cash refund restores stock but does not deduct customer on-account debt', () async {
      final cashCreditNote = CreditNote(
        id: 'crn-cash-01',
        creditNoteNumber: 'CRN-2026-00002',
        originalInvoiceNumber: 'INV-2026-00001',
        date: DateTime(2026, 11, 17),
        customerId: sampleCustomer.id,
        customerName: sampleCustomer.name,
        customerTaxId: sampleCustomer.taxId,
        items: const [
          CreditNoteLineItem(
            productId: 'prod-01',
            productName: 'Spanish Porcelain 60x120',
            unitType: UnitType.meter,
            quantity: 4.0,
            unitPrice: 100.0,
            subtotal: 400.0,
          ),
        ],
        subtotal: 400.0,
        vatRate: 0.17,
        vatAmount: 68.0,
        totalAmount: 468.0,
        refundMethod: RefundMethod.cashRefund, // Cash paid out directly
        reason: 'Surplus tiles returned for cash',
        createdAt: DateTime(2026, 11, 17),
      );

      await orchestrator.processCreditNoteTransaction(
        creditNote: cashCreditNote,
        customer: sampleCustomer,
      );

      // Inventory restored: 20 + 4 = 24
      final product = await productRepo.getProductById('prod-01');
      expect(product!.currentStock, equals(24.0));

      // Customer on-account debt remains unchanged (no double refund)
      final customer = await contactRepo.getContactById('cust-01');
      expect(customer!.currentBalance, equals(5000.0));

      // No ledger entry created
      final statements = await contactRepo.getStatementEntries('cust-01');
      expect(statements, isEmpty);
    });
  });
}
