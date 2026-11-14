import '../../../../features/accounts/domain/models/contact.dart';
import '../../../../features/accounts/domain/services/debt_warning_evaluator.dart';
import '../../../../features/inventory/domain/models/product.dart';
import '../../../../features/inventory/domain/services/unit_converter.dart';
import '../../domain/models/payment_split.dart';
import '../../domain/models/sale_invoice.dart';
import '../../domain/services/vat_calculator.dart';

class _PosItemInput {
  final Product product;
  final double quantity;
  final UnitType unit;
  final double unitPriceInput;

  const _PosItemInput({
    required this.product,
    required this.quantity,
    required this.unit,
    required this.unitPriceInput,
  });
}

class SalesPosState {
  final Contact? selectedCustomer;
  final bool isTaxInclusiveInput;
  final List<SaleLineItem> items;
  final List<PaymentSplit> payments;
  final String? allocationNumber;
  final String? notes;
  final double vatRate;
  final double subtotal;
  final double vatAmount;
  final double totalAmount;
  final double remainingPayment;
  final bool isPaymentComplete;

  const SalesPosState({
    this.selectedCustomer,
    required this.isTaxInclusiveInput,
    required this.items,
    required this.payments,
    this.allocationNumber,
    this.notes,
    this.vatRate = 0.17,
    required this.subtotal,
    required this.vatAmount,
    required this.totalAmount,
    required this.remainingPayment,
    required this.isPaymentComplete,
  });

  factory SalesPosState.initial() {
    return const SalesPosState(
      isTaxInclusiveInput: true,
      items: [],
      payments: [],
      vatRate: 0.17,
      subtotal: 0.0,
      vatAmount: 0.0,
      totalAmount: 0.0,
      remainingPayment: 0.0,
      isPaymentComplete: false,
    );
  }
}

class SalesPosController {
  Contact? _customer;
  bool _isTaxInclusive = true;
  final List<_PosItemInput> _inputs = [];
  final List<PaymentSplit> _payments = [];
  String? _allocationNumber;
  String? _notes;
  double _vatRate = 0.17;

  SalesPosController();

  SalesPosState get state => _computeState();

  void setCustomer(Contact? customer) {
    _customer = customer;
  }

  void setPricingMode({required bool isTaxInclusive}) {
    _isTaxInclusive = isTaxInclusive;
  }

  void setAllocationNumber(String? number) {
    _allocationNumber = number;
  }

  void setNotes(String? notes) {
    _notes = notes;
  }

  void setVatRate(double rate) {
    _vatRate = rate;
  }

  void addItem({
    required Product product,
    required num quantity,
    required UnitType unit,
    required num unitPriceInput,
  }) {
    _inputs.add(
      _PosItemInput(
        product: product,
        quantity: quantity.toDouble(),
        unit: unit,
        unitPriceInput: unitPriceInput.toDouble(),
      ),
    );
  }

  void removeItem(int index) {
    if (index >= 0 && index < _inputs.length) {
      _inputs.removeAt(index);
    }
  }

  void clearItems() {
    _inputs.clear();
    _payments.clear();
  }

  void addPayment(PaymentSplit payment) {
    _payments.add(payment);
  }

  void removePayment(int index) {
    if (index >= 0 && index < _payments.length) {
      _payments.removeAt(index);
    }
  }

  void clearPayments() {
    _payments.clear();
  }

  DebtWarningResult? evaluateDebtWarning() {
    if (_customer == null) return null;
    double debtAmount = 0.0;
    for (final p in _payments) {
      if (p.method == PaymentMethod.debt) {
        debtAmount += p.amount;
      }
    }
    if (debtAmount <= 0) return null;

    return DebtWarningEvaluator.evaluate(
      contact: _customer!,
      additionalDebt: debtAmount,
    );
  }

  SalesPosState _computeState() {
    final List<SaleLineItem> computedItems = [];
    double runningSubtotal = 0.0;
    double runningVat = 0.0;
    double runningTotal = 0.0;

    for (final input in _inputs) {
      // Determine effective quantity if product stock is meter-based and sold in boxes
      double effectiveQty = input.quantity;
      if (input.product.unitType == UnitType.meter && input.unit == UnitType.box) {
        effectiveQty = UnitConverter.boxesToMeters(
          boxes: input.quantity,
          meterPerBox: input.product.meterPerBox ?? 1.0,
        );
      }

      double itemSubtotal;
      double itemUnitPrice;

      if (_isTaxInclusive) {
        final lineTotalInclusive = (effectiveQty * input.unitPriceInput * 100).round() / 100.0;
        final res = VatCalculator.calculateFromInclusive(
          totalInclusive: lineTotalInclusive,
          vatRate: _vatRate,
        );
        itemSubtotal = res.subtotal;
        itemUnitPrice = effectiveQty > 0
            ? (res.subtotal / effectiveQty * 100).round() / 100.0
            : input.unitPriceInput;
        runningSubtotal += res.subtotal;
        runningVat += res.vatAmount;
        runningTotal += res.totalAmount;
      } else {
        itemSubtotal = (effectiveQty * input.unitPriceInput * 100).round() / 100.0;
        itemUnitPrice = input.unitPriceInput;
        final res = VatCalculator.calculateFromExclusive(
          subtotalExclusive: itemSubtotal,
          vatRate: _vatRate,
        );
        runningSubtotal += res.subtotal;
        runningVat += res.vatAmount;
        runningTotal += res.totalAmount;
      }

      computedItems.add(
        SaleLineItem(
          productId: input.product.id,
          productName: input.product.name,
          unitType: input.unit,
          quantity: input.quantity,
          unitPrice: itemUnitPrice,
          subtotal: itemSubtotal,
        ),
      );
    }

    final double subtotal = (runningSubtotal * 100).round() / 100.0;
    final double vatAmount = (runningVat * 100).round() / 100.0;
    final double totalAmount = (runningTotal * 100).round() / 100.0;

    final double paidSum =
        (_payments.fold(0.0, (acc, p) => acc + p.amount) * 100).round() / 100.0;
    final double remaining =
        ((totalAmount - paidSum) * 100).round() / 100.0;

    final bool isComplete = totalAmount > 0 && remaining.abs() <= 0.01;

    return SalesPosState(
      selectedCustomer: _customer,
      isTaxInclusiveInput: _isTaxInclusive,
      items: computedItems,
      payments: List.unmodifiable(_payments),
      allocationNumber: _allocationNumber,
      notes: _notes,
      vatRate: _vatRate,
      subtotal: subtotal,
      vatAmount: vatAmount,
      totalAmount: totalAmount,
      remainingPayment: remaining > 0 ? remaining : 0.0,
      isPaymentComplete: isComplete,
    );
  }
}
