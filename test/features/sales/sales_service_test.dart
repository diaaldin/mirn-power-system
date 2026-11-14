import 'package:test/test.dart';
import 'package:sales_logistics_system/features/inventory/domain/models/product.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/contact.dart';
import 'package:sales_logistics_system/features/sales/domain/models/sale_invoice.dart';
import 'package:sales_logistics_system/features/sales/domain/models/payment_split.dart';
import 'package:sales_logistics_system/features/sales/domain/services/sales_service.dart';

void main() {
  group('Sales Invoicing & Split Payment Engine', () {
    final customer = Contact(
      id: 'cust-10',
      type: ContactType.customer,
      name: 'Nablus Tile Center',
      phone: '059-9999999',
      address: 'Nablus',
      taxId: '512345678',
      debtWarningLimit: 10000.0,
      currentBalance: 2000.0,
    );

    final marble = Product(
      id: 'prod-10',
      name: 'Greek Thassos Marble',
      sku: 'MB-THAS',
      category: ProductCategory.marble,
      unitType: UnitType.meter,
      meterPerBox: 1.5,
      purchaseCost: 100.0,
      sellingPrice: 150.0,
      currentStock: 100.0, // 100 m2
    );

    test('rejects payment splits that do not equal the invoice total', () {
      final payments = [
        const PaymentSplit(method: PaymentMethod.cash, amount: 500.0),
        const PaymentSplit(method: PaymentMethod.debt, amount: 1400.0),
      ];

      expect(
        () => SalesService.validateSplitPayment(totalAmount: 2000.0, payments: payments),
        throwsA(isA<InvalidPaymentTotalException>()),
      );
    });

    test('accepts exact split payment matches (Cash + Check + Debt)', () {
      final payments = [
        const PaymentSplit(method: PaymentMethod.cash, amount: 500.0),
        const PaymentSplit(
          method: PaymentMethod.check,
          amount: 1000.0,
          reference: 'CHK-9912',
        ),
        const PaymentSplit(method: PaymentMethod.debt, amount: 500.0),
      ];

      expect(
        () => SalesService.validateSplitPayment(totalAmount: 2000.0, payments: payments),
        returnsNormally,
      );
    });

    test('processSale produces invoice, decrements stock, and updates customer ledger', () {
      final lineItem = SaleLineItem(
        productId: marble.id,
        productName: marble.name,
        unitType: UnitType.box,
        quantity: 10, // 10 boxes = 15.0 m2
        unitPrice: 225.0, // 10 * 225 = 2250
        discountPercent: 0.0,
        subtotal: 2250.0,
      );

      final payments = [
        const PaymentSplit(method: PaymentMethod.cash, amount: 1250.0),
        const PaymentSplit(method: PaymentMethod.debt, amount: 1382.50), // debt
      ];

      // Total = 2250 * 1.17 = 2632.50
      final result = SalesService.processSale(
        invoiceSequenceNumber: 1,
        customer: customer,
        items: [lineItem],
        productsCatalog: {marble.id: marble},
        isTaxInclusiveInput: false,
        vatRate: 0.17,
        payments: payments,
        allocationNumber: 'ALLOC-2026-X1',
      );

      // Verify Invoice
      expect(result.invoice.invoiceNumber, equals('INV-2026-00001'));
      expect(result.invoice.subtotal, equals(2250.0));
      expect(result.invoice.vatAmount, equals(382.50));
      expect(result.invoice.totalAmount, equals(2632.50));
      expect(result.invoice.allocationNumber, equals('ALLOC-2026-X1'));

      // Verify Stock Decrement: 10 boxes * 1.5 m2/box = 15 m2 deducted from 100 -> 85 m2
      final updatedMarble = result.updatedProducts[marble.id]!;
      expect(updatedMarble.currentStock, equals(85.0));

      // Verify Customer Balance & Statement: 2000 + 1382.50 = 3382.50
      expect(result.updatedCustomer.currentBalance, equals(3382.50));
      expect(result.statementEntry, isNotNull);
      expect(result.statementEntry!.debit, equals(1382.50));
      expect(result.statementEntry!.runningBalance, equals(3382.50));
      expect(result.statementEntry!.referenceNumber, equals('INV-2026-00001'));
    });
  });
}
