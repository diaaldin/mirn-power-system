import '../../../inventory/domain/models/product.dart';
import '../../../inventory/domain/services/unit_converter.dart';
import '../../../accounts/domain/models/contact.dart';
import '../../../accounts/domain/models/statement_entry.dart';
import '../../../checks/domain/models/check_record.dart';
import '../models/payment_split.dart';
import '../models/sale_invoice.dart';
import 'vat_calculator.dart';

class InvalidPaymentTotalException implements Exception {
  final double expectedTotal;
  final double actualSum;

  InvalidPaymentTotalException(this.expectedTotal, this.actualSum);

  @override
  String toString() {
    return 'InvalidPaymentTotalException: Expected payment sum to equal ₪$expectedTotal, but got ₪$actualSum';
  }
}

class InvalidPaymentAmountException implements Exception {
  final double amount;
  InvalidPaymentAmountException(this.amount);

  @override
  String toString() {
    return 'InvalidPaymentAmountException: Payment amounts cannot be negative (got $amount)';
  }
}

class ProcessSaleResult {
  final SaleInvoice invoice;
  final Map<String, Product> updatedProducts;
  final Contact updatedCustomer;
  final StatementEntry? statementEntry;
  final List<CheckRecord> createdChecks;

  const ProcessSaleResult({
    required this.invoice,
    required this.updatedProducts,
    required this.updatedCustomer,
    this.statementEntry,
    this.createdChecks = const [],
  });
}

class SalesService {
  SalesService._();

  static double _round2(num val) => (val * 100).roundToDouble() / 100.0;

  /// Validates that split payment amounts are non-negative and equal the total invoice amount.
  static void validateSplitPayment({
    required num totalAmount,
    required List<PaymentSplit> payments,
  }) {
    for (final p in payments) {
      if (p.amount < 0) {
        throw InvalidPaymentAmountException(p.amount);
      }
    }

    final expected = _round2(totalAmount);
    final actualSum = _round2(payments.fold(0.0, (sum, p) => sum + p.amount));

    if ((expected - actualSum).abs() > 0.01) {
      throw InvalidPaymentTotalException(expected, actualSum);
    }
  }

  /// Atomically processes a sale invoice, deducting stock, recording check records,
  /// and mutating debtor balances without penny discrepancies.
  static ProcessSaleResult processSale({
    required int invoiceSequenceNumber,
    required Contact customer,
    required List<SaleLineItem> items,
    required Map<String, Product> productsCatalog,
    required bool isTaxInclusiveInput,
    double vatRate = 0.17,
    required List<PaymentSplit> payments,
    double? inclusiveTotalOverride,
    String? allocationNumber,
    String? dispatchId,
    String? notes,
    String? createdBy,
    DateTime? date,
  }) {
    final invoiceDate = date ?? DateTime.now();
    final String seqStr = invoiceSequenceNumber.toString().padLeft(5, '0');
    final String invoiceNumber = 'INV-${invoiceDate.year}-$seqStr';

    double subtotal;
    double vatAmount;
    double totalAmount;

    if (isTaxInclusiveInput) {
      if (inclusiveTotalOverride != null) {
        totalAmount = _round2(inclusiveTotalOverride);
      } else {
        totalAmount = _round2(items.fold(0.0, (acc, item) => acc + item.subtotal));
      }
      final vatRes = VatCalculator.calculateFromInclusive(
        totalInclusive: totalAmount,
        vatRate: vatRate,
      );
      subtotal = vatRes.subtotal;
      vatAmount = vatRes.vatAmount;
    } else {
      subtotal = _round2(items.fold(0.0, (acc, item) => acc + item.subtotal));
      vatAmount = _round2(subtotal * vatRate);
      totalAmount = _round2(subtotal + vatAmount);
    }

    // Validate payment split equals invoice total
    validateSplitPayment(totalAmount: totalAmount, payments: payments);

    // Calculate stock deductions for products
    final Map<String, Product> updatedProducts = Map.of(productsCatalog);
    for (final item in items) {
      final product = updatedProducts[item.productId];
      if (product != null) {
        final reduction = UnitConverter.calculateStockReduction(
          product: product,
          quantity: item.quantity,
          soldUnit: item.unitType,
        );
        updatedProducts[item.productId] = product.copyWith(
          currentStock: _round2(product.currentStock - reduction),
          updatedAt: invoiceDate,
        );
      }
    }

    // Process checks into pending CheckRecord items
    final List<CheckRecord> createdChecks = [];
    double debtAmount = 0.0;

    for (int i = 0; i < payments.length; i++) {
      final p = payments[i];
      if (p.method == PaymentMethod.debt) {
        debtAmount += p.amount;
      } else if (p.method == PaymentMethod.check) {
        createdChecks.add(
          CheckRecord(
            id: 'chk-$invoiceNumber-${i + 1}',
            checkNumber: p.reference ?? 'CHK-$invoiceNumber-${i + 1}',
            bankName: 'Bank',
            branchNumber: '',
            accountNumber: '',
            amount: p.amount,
            dueDate: invoiceDate,
            type: CheckType.received,
            partyId: customer.id,
            partyName: customer.name,
            relatedTransactionId: invoiceNumber,
            status: CheckStatus.pending,
            history: [],
            createdAt: invoiceDate,
          ),
        );
      }
    }
    debtAmount = _round2(debtAmount);

    Contact updatedCustomer = customer;
    StatementEntry? statementEntry;

    if (debtAmount > 0.0) {
      final newBalance = _round2(customer.currentBalance + debtAmount);
      updatedCustomer = customer.copyWith(
        currentBalance: newBalance,
        updatedAt: invoiceDate,
      );

      statementEntry = StatementEntry(
        id: 'stmt-$invoiceNumber',
        contactId: customer.id,
        contactType: ContactType.customer,
        date: invoiceDate,
        type: StatementEntryType.saleInvoice,
        referenceNumber: invoiceNumber,
        debit: debtAmount,
        credit: 0.0,
        runningBalance: newBalance,
        description: 'חשבונית מס קבלה $invoiceNumber (חלק על החשבון)',
      );
    }

    final invoice = SaleInvoice(
      id: invoiceNumber,
      invoiceNumber: invoiceNumber,
      date: invoiceDate,
      customerId: customer.id,
      customerName: customer.name,
      customerTaxId: customer.taxId,
      isTaxInclusiveInput: isTaxInclusiveInput,
      items: items,
      subtotal: subtotal,
      vatRate: vatRate,
      vatAmount: vatAmount,
      totalAmount: totalAmount,
      payments: payments,
      allocationNumber: allocationNumber,
      dispatchId: dispatchId,
      notes: notes,
      createdBy: createdBy,
      createdAt: invoiceDate,
    );

    return ProcessSaleResult(
      invoice: invoice,
      updatedProducts: updatedProducts,
      updatedCustomer: updatedCustomer,
      statementEntry: statementEntry,
      createdChecks: createdChecks,
    );
  }
}
