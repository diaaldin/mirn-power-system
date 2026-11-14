import 'package:test/test.dart';
import 'package:sales_logistics_system/features/inventory/domain/models/product.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/contact.dart';
import 'package:sales_logistics_system/features/sales/domain/models/payment_split.dart';
import 'package:sales_logistics_system/features/sales/presentation/screens/sales_screen.dart';

void main() {
  group('Sales POS State & Controller Engine', () {
    final customer = Contact(
      id: 'cust-50',
      type: ContactType.customer,
      name: 'Galilee Ceramic & Marble',
      phone: '054-1112233',
      address: 'Nazareth',
      taxId: '517777888',
      debtWarningLimit: 5000.0,
      currentBalance: 4000.0,
    );

    final marble = Product(
      id: 'prod-50',
      name: 'Spanish Nero Marquina Marble',
      sku: 'MB-NERO',
      category: ProductCategory.marble,
      unitType: UnitType.meter,
      meterPerBox: 1.44,
      purchaseCost: 90.0,
      sellingPrice: 117.0, // 117.0 inclusive -> 100 base + 17 VAT
      currentStock: 100.0,
    );

    test('adding items in tax-inclusive mode calculates line items and totals correctly', () {
      final controller = SalesPosController();
      controller.setCustomer(customer);
      expect(controller.state.isTaxInclusiveInput, isTrue);

      // Add 10 boxes (14.4 m2) at 117.0 inclusive per m2 -> total 14.4 * 117 = 1684.80 inclusive
      controller.addItem(
        product: marble,
        quantity: 10,
        unit: UnitType.box,
        unitPriceInput: 117.0,
      );

      final state = controller.state;
      expect(state.items.length, equals(1));
      // Base subtotal = 1684.80 / 1.17 = 1440.00
      expect(state.subtotal, equals(1440.00));
      expect(state.vatAmount, equals(244.80));
      expect(state.totalAmount, equals(1684.80));
      expect(state.remainingPayment, equals(1684.80));
    });

    test('toggling pricing mode updates calculation strategy dynamically', () {
      final controller = SalesPosController();
      controller.addItem(
        product: marble,
        quantity: 10,
        unit: UnitType.meter,
        unitPriceInput: 100.0, // in exclusive mode, 10 * 100 = 1000 subtotal
      );

      controller.setPricingMode(isTaxInclusive: false);
      expect(controller.state.isTaxInclusiveInput, isFalse);

      final state = controller.state;
      expect(state.subtotal, equals(1000.0));
      expect(state.vatAmount, equals(170.0));
      expect(state.totalAmount, equals(1170.0));
    });

    test('split payment settlement tracks remaining balance and completeness', () {
      final controller = SalesPosController();
      controller.setCustomer(customer);
      controller.setPricingMode(isTaxInclusive: false);
      controller.addItem(
        product: marble,
        quantity: 10,
        unit: UnitType.meter,
        unitPriceInput: 100.0, // total 1170.0
      );

      expect(controller.state.isPaymentComplete, isFalse);
      expect(controller.state.remainingPayment, equals(1170.0));

      // Add Cash 500
      controller.addPayment(const PaymentSplit(method: PaymentMethod.cash, amount: 500.0));
      expect(controller.state.remainingPayment, equals(670.0));
      expect(controller.state.isPaymentComplete, isFalse);

      // Add Check 500
      controller.addPayment(
        const PaymentSplit(
          method: PaymentMethod.check,
          amount: 500.0,
          reference: 'CHK-1234',
        ),
      );
      expect(controller.state.remainingPayment, equals(170.0));

      // Settle remaining 170 On Account (debt)
      controller.addPayment(const PaymentSplit(method: PaymentMethod.debt, amount: 170.0));
      expect(controller.state.remainingPayment, equals(0.0));
      expect(controller.state.isPaymentComplete, isTrue);
    });

    test('evaluates customer debt warning when on-account split is entered', () {
      final controller = SalesPosController();
      controller.setCustomer(customer); // current 4000, limit 5000
      controller.setPricingMode(isTaxInclusive: false);
      controller.addItem(
        product: marble,
        quantity: 20,
        unit: UnitType.meter,
        unitPriceInput: 100.0, // total 2340.0
      );

      // Paying all 2340 via debt: 4000 + 2340 = 6340 > 5000 (exceeded by 1340)
      controller.addPayment(const PaymentSplit(method: PaymentMethod.debt, amount: 2340.0));

      final warning = controller.evaluateDebtWarning();
      expect(warning, isNotNull);
      expect(warning!.isExceeded, isTrue);
      expect(warning.exceededAmount, equals(1340.0));
      expect(warning.canProceed, isTrue);
    });
  });
}
