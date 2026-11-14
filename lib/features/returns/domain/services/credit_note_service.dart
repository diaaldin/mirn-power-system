import '../../../inventory/domain/models/product.dart';
import '../../../inventory/domain/services/unit_converter.dart';
import '../../../accounts/domain/models/contact.dart';
import '../../../accounts/domain/models/statement_entry.dart';
import '../models/credit_note.dart';

class ProcessReturnResult {
  final CreditNote creditNote;
  final Map<String, Product> updatedProducts;
  final Contact updatedCustomer;
  final StatementEntry? statementEntry;

  const ProcessReturnResult({
    required this.creditNote,
    required this.updatedProducts,
    required this.updatedCustomer,
    this.statementEntry,
  });
}

class CreditNoteService {
  CreditNoteService._();

  static double _round2(num val) => (val * 100).roundToDouble() / 100.0;

  /// Processes a return, restoring stock and updating debtor balances when debt credit is chosen.
  static ProcessReturnResult processReturn({
    required int creditNoteSequenceNumber,
    required Contact customer,
    String? originalInvoiceId,
    String? originalInvoiceNumber,
    required List<CreditNoteLineItem> items,
    required Map<String, Product> productsCatalog,
    required RefundMethod refundMethod,
    double vatRate = 0.17,
    String? reason,
    String? createdBy,
    DateTime? date,
  }) {
    final returnDate = date ?? DateTime.now();
    final String seqStr = creditNoteSequenceNumber.toString().padLeft(5, '0');
    final String creditNoteNumber = 'CRN-${returnDate.year}-$seqStr';

    final double subtotal = _round2(items.fold(0.0, (acc, item) => acc + item.subtotal));
    final double vatAmount = _round2(subtotal * vatRate);
    final double totalAmount = _round2(subtotal + vatAmount);

    // Restock returned quantities into productsCatalog
    final Map<String, Product> updatedProducts = Map.of(productsCatalog);
    for (final item in items) {
      final product = updatedProducts[item.productId];
      if (product != null) {
        final stockToAdd = UnitConverter.calculateStockReduction(
          product: product,
          quantity: item.quantity,
          soldUnit: item.unitType,
        );
        updatedProducts[item.productId] = product.copyWith(
          currentStock: _round2(product.currentStock + stockToAdd),
          updatedAt: returnDate,
        );
      }
    }

    Contact updatedCustomer = customer;
    StatementEntry? statementEntry;

    // If refund is credited against customer's account balance, reduce debtor balance
    if (refundMethod == RefundMethod.debtCredit) {
      final newBalance = _round2(customer.currentBalance - totalAmount);
      updatedCustomer = customer.copyWith(
        currentBalance: newBalance,
        updatedAt: returnDate,
      );

      statementEntry = StatementEntry(
        id: 'stmt-$creditNoteNumber',
        contactId: customer.id,
        contactType: ContactType.customer,
        date: returnDate,
        type: StatementEntryType.creditNote,
        referenceNumber: creditNoteNumber,
        debit: 0.0,
        credit: totalAmount,
        runningBalance: newBalance,
        description: 'חשבונית זיכוי $creditNoteNumber (החזר סחורה)',
      );
    }

    final creditNote = CreditNote(
      id: creditNoteNumber,
      creditNoteNumber: creditNoteNumber,
      date: returnDate,
      originalInvoiceId: originalInvoiceId,
      originalInvoiceNumber: originalInvoiceNumber,
      customerId: customer.id,
      customerName: customer.name,
      customerTaxId: customer.taxId,
      items: items,
      subtotal: subtotal,
      vatRate: vatRate,
      vatAmount: vatAmount,
      totalAmount: totalAmount,
      refundMethod: refundMethod,
      reason: reason,
      createdBy: createdBy,
      createdAt: returnDate,
    );

    return ProcessReturnResult(
      creditNote: creditNote,
      updatedProducts: updatedProducts,
      updatedCustomer: updatedCustomer,
      statementEntry: statementEntry,
    );
  }
}
