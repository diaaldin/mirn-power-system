import 'package:test/test.dart';
import 'package:sales_logistics_system/features/inventory/domain/models/product.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/contact.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/statement_entry.dart';
import 'package:sales_logistics_system/features/returns/domain/models/credit_note.dart';
import 'package:sales_logistics_system/features/returns/domain/services/credit_note_service.dart';

void main() {
  group('Sales Returns & Credit Notes Engine (חשבונית מס זיכוי)', () {
    final customer = Contact(
      id: 'cust-20',
      type: ContactType.customer,
      name: 'Ramallah Luxury Homes',
      phone: '059-8888888',
      address: 'Ramallah',
      taxId: '519999000',
      debtWarningLimit: 20000.0,
      currentBalance: 5000.0, // owes ₪5,000
    );

    final marble = Product(
      id: 'prod-20',
      name: 'Italian Carrara 60x120',
      sku: 'MB-IT-60120',
      category: ProductCategory.marble,
      unitType: UnitType.meter,
      meterPerBox: 1.44,
      purchaseCost: 90.0,
      sellingPrice: 140.0,
      currentStock: 80.0, // 80 m2
    );

    test('restores inventory and credits customer debt ledger on return', () {
      final returnItem = CreditNoteLineItem(
        productId: marble.id,
        productName: marble.name,
        unitType: UnitType.box,
        quantity: 2, // 2 boxes = 2.88 m2
        unitPrice: 201.60, // 2 * 201.60 = 403.20 before VAT
        subtotal: 403.20,
      );

      // Total return = 403.20 * 1.17 = 471.74
      final result = CreditNoteService.processReturn(
        creditNoteSequenceNumber: 1,
        customer: customer,
        originalInvoiceNumber: 'INV-2026-00005',
        items: [returnItem],
        productsCatalog: {marble.id: marble},
        refundMethod: RefundMethod.debtCredit,
        vatRate: 0.17,
        reason: 'Client ordered 2 boxes excess marble',
      );

      // Verify Credit Note document
      expect(result.creditNote.creditNoteNumber, equals('CRN-2026-00001'));
      expect(result.creditNote.originalInvoiceNumber, equals('INV-2026-00005'));
      expect(result.creditNote.subtotal, equals(403.20));
      expect(result.creditNote.vatAmount, equals(68.54));
      expect(result.creditNote.totalAmount, equals(471.74));

      // Verify Inventory Restock: 80 + 2.88 = 82.88 m2
      final updatedMarble = result.updatedProducts[marble.id]!;
      expect(updatedMarble.currentStock, equals(82.88));

      // Verify Customer Debt Balance Reduced: 5000 - 471.74 = 4528.26
      expect(result.updatedCustomer.currentBalance, equals(4528.26));

      // Verify Statement Entry (Credit)
      expect(result.statementEntry, isNotNull);
      expect(result.statementEntry!.credit, equals(471.74));
      expect(result.statementEntry!.debit, equals(0.0));
      expect(result.statementEntry!.runningBalance, equals(4528.26));
      expect(result.statementEntry!.type, equals(StatementEntryType.creditNote));
      expect(result.statementEntry!.referenceNumber, equals('CRN-2026-00001'));
    });

    test('cash refund restores inventory without reducing on-account debt', () {
      final returnItem = CreditNoteLineItem(
        productId: marble.id,
        productName: marble.name,
        unitType: UnitType.meter,
        quantity: 5,
        unitPrice: 140.0,
        subtotal: 700.0,
      );

      final result = CreditNoteService.processReturn(
        creditNoteSequenceNumber: 2,
        customer: customer,
        items: [returnItem],
        productsCatalog: {marble.id: marble},
        refundMethod: RefundMethod.cashRefund,
        vatRate: 0.17,
      );

      // Stock restocked by 5 meters: 80 + 5 = 85
      expect(result.updatedProducts[marble.id]!.currentStock, equals(85.0));

      // Customer balance remains unchanged at 5000.0
      expect(result.updatedCustomer.currentBalance, equals(5000.0));
      expect(result.statementEntry, isNull);
    });
  });
}
