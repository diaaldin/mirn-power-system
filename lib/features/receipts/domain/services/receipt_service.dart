import '../../../accounts/domain/models/contact.dart';
import '../../../accounts/domain/models/statement_entry.dart';
import '../../../checks/domain/models/check_record.dart';
import '../../../sales/domain/models/payment_split.dart';
import '../models/payment_receipt.dart';

class CreateReceiptInput {
  final String? id;
  final String receiptNumber;
  final DateTime date;
  final double amount;
  final List<ReceiptPaymentItem> payments;
  final String? notes;
  final String createdBy;

  CreateReceiptInput({
    this.id,
    required this.receiptNumber,
    required this.date,
    required this.amount,
    required List<ReceiptPaymentItem> payments,
    this.notes,
    required this.createdBy,
  }) : payments = List.unmodifiable(payments);
}

class ProcessCustomerReceiptResult {
  final PaymentReceipt receipt;
  final Contact updatedContact;
  final StatementEntry statementEntry;
  final List<CheckRecord> createdChecks;

  ProcessCustomerReceiptResult({
    required this.receipt,
    required this.updatedContact,
    required this.statementEntry,
    required List<CheckRecord> createdChecks,
  }) : createdChecks = List.unmodifiable(createdChecks);
}

class CreateSupplierPaymentInput {
  final String? id;
  final String paymentNumber;
  final DateTime date;
  final double amount;
  final List<ReceiptPaymentItem> payments;
  final String? notes;
  final String createdBy;

  CreateSupplierPaymentInput({
    this.id,
    required this.paymentNumber,
    required this.date,
    required this.amount,
    required List<ReceiptPaymentItem> payments,
    this.notes,
    required this.createdBy,
  }) : payments = List.unmodifiable(payments);
}

class ProcessSupplierPaymentResult {
  final PaymentReceipt paymentVoucher;
  final Contact updatedSupplier;
  final StatementEntry statementEntry;
  final List<CheckRecord> issuedChecks;

  ProcessSupplierPaymentResult({
    required this.paymentVoucher,
    required this.updatedSupplier,
    required this.statementEntry,
    required List<CheckRecord> issuedChecks,
  }) : issuedChecks = List.unmodifiable(issuedChecks);
}

class ReceiptService {
  ReceiptService._();

  static double _round2(num val) => (val * 100).round() / 100.0;

  /// Settles customer debt against an open-balance ledger model and auto-ingests
  /// checks into the check portfolio in pending status.
  static ProcessCustomerReceiptResult processCustomerReceipt({
    required Contact contact,
    required CreateReceiptInput input,
  }) {
    // 1. Validate that contact is not supplier-only
    if (contact.type == ContactType.supplier) {
      throw ArgumentError(
        'Cannot process customer receipt for a supplier-only contact (${contact.name})',
      );
    }

    // 2. Validate receipt amount is strictly positive
    if (input.amount <= 0) {
      throw ArgumentError.value(
        input.amount,
        'amount',
        'Receipt amount must be greater than zero',
      );
    }

    // 3. Validate check items have required checkNumber and bankName
    for (final payment in input.payments) {
      if (payment.method == PaymentMethod.check) {
        if (payment.checkNumber == null || payment.checkNumber!.trim().isEmpty) {
          throw ArgumentError(
            'Check payment item missing required checkNumber',
          );
        }
        if (payment.bankName == null || payment.bankName!.trim().isEmpty) {
          throw ArgumentError(
            'Check payment item missing required bankName',
          );
        }
      }
    }

    // 4. Construct PaymentReceipt (enforces payment balancing within 0.01)
    final receiptId = (input.id != null && input.id!.trim().isNotEmpty)
        ? input.id!
        : 'rec-${input.receiptNumber}';

    final receipt = PaymentReceipt(
      id: receiptId,
      receiptNumber: input.receiptNumber,
      date: input.date,
      partyType: ContactType.customer,
      contactId: contact.id,
      contactName: contact.name,
      totalAmount: input.amount,
      payments: input.payments,
      notes: input.notes,
      createdBy: input.createdBy,
      createdAt: input.date,
    );

    // 5. Update contact debt balance: currentBalance - amount
    final updatedBalance = _round2(contact.currentBalance - input.amount);
    final updatedContact = contact.copyWith(
      currentBalance: updatedBalance,
      updatedAt: input.date,
    );

    // 6. Generate StatementEntry
    final description = (input.notes != null && input.notes!.trim().isNotEmpty)
        ? input.notes!.trim()
        : 'سند قبض دفعات على الحساب';

    final statementEntry = StatementEntry(
      id: 'stmt-${input.receiptNumber}',
      contactId: contact.id,
      contactType: ContactType.customer,
      date: input.date,
      type: StatementEntryType.paymentReceipt,
      referenceNumber: input.receiptNumber,
      debit: 0.0,
      credit: input.amount,
      runningBalance: updatedBalance,
      description: description,
    );

    // 7. Auto-generate CheckRecord items for check payments
    final List<CheckRecord> createdChecks = [];
    var checkCount = 0;
    for (final payment in input.payments) {
      if (payment.method == PaymentMethod.check) {
        checkCount++;
        createdChecks.add(
          CheckRecord(
            id: 'chk-${input.receiptNumber}-$checkCount',
            checkNumber: payment.checkNumber!.trim(),
            bankName: payment.bankName!.trim(),
            branchNumber: payment.branchNumber?.trim() ?? '',
            accountNumber: payment.accountNumber?.trim() ?? '',
            amount: payment.amount,
            dueDate: payment.dueDate ?? input.date,
            type: CheckType.received,
            partyId: contact.id,
            partyName: contact.name,
            relatedTransactionId: receipt.id,
            status: CheckStatus.pending,
            history: [
              CheckHistoryEntry(
                status: CheckStatus.pending,
                changedAt: input.date,
                notes: 'Ingested from receipt ${input.receiptNumber}',
                changedBy: input.createdBy,
              ),
            ],
            createdAt: input.date,
          ),
        );
      }
    }

    return ProcessCustomerReceiptResult(
      receipt: receipt,
      updatedContact: updatedContact,
      statementEntry: statementEntry,
      createdChecks: createdChecks,
    );
  }

  /// Settles supplier payables (سند صرف) against an open-balance ledger model and
  /// auto-generates issued checks into the check portfolio in pending status.
  static ProcessSupplierPaymentResult processSupplierPayment({
    required Contact contact,
    required CreateSupplierPaymentInput input,
  }) {
    // 1. Validate that contact is not customer-only
    if (contact.type == ContactType.customer) {
      throw ArgumentError(
        'Cannot process supplier payment for a customer-only contact (${contact.name})',
      );
    }

    // 2. Validate payment amount is strictly positive
    if (input.amount <= 0) {
      throw ArgumentError.value(
        input.amount,
        'amount',
        'Payment amount must be greater than zero',
      );
    }

    // 3. Validate check items have required checkNumber and bankName
    for (final payment in input.payments) {
      if (payment.method == PaymentMethod.check) {
        if (payment.checkNumber == null || payment.checkNumber!.trim().isEmpty) {
          throw ArgumentError(
            'Check payment item missing required checkNumber',
          );
        }
        if (payment.bankName == null || payment.bankName!.trim().isEmpty) {
          throw ArgumentError(
            'Check payment item missing required bankName',
          );
        }
      }
    }

    // 4. Construct PaymentReceipt (enforces payment balancing within 0.01)
    final voucherId = (input.id != null && input.id!.trim().isNotEmpty)
        ? input.id!
        : 'pay-${input.paymentNumber}';

    final paymentVoucher = PaymentReceipt(
      id: voucherId,
      receiptNumber: input.paymentNumber,
      date: input.date,
      partyType: ContactType.supplier,
      contactId: contact.id,
      contactName: contact.name,
      totalAmount: input.amount,
      payments: input.payments,
      notes: input.notes,
      createdBy: input.createdBy,
      createdAt: input.date,
    );

    // 5. Update supplier balance: paying supplier reduces payable (currentBalance - amount)
    final updatedBalance = _round2(contact.currentBalance - input.amount);
    final updatedSupplier = contact.copyWith(
      currentBalance: updatedBalance,
      updatedAt: input.date,
    );

    // 6. Generate StatementEntry
    final description = (input.notes != null && input.notes!.trim().isNotEmpty)
        ? input.notes!.trim()
        : 'سند صرف دفعات للمورد';

    final statementEntry = StatementEntry(
      id: 'stmt-${input.paymentNumber}',
      contactId: contact.id,
      contactType: ContactType.supplier,
      date: input.date,
      type: StatementEntryType.supplierPayment,
      referenceNumber: input.paymentNumber,
      debit: input.amount,
      credit: 0.0,
      runningBalance: updatedBalance,
      description: description,
    );

    // 7. Auto-generate CheckRecord items for check payments
    final List<CheckRecord> issuedChecks = [];
    var checkCount = 0;
    for (final payment in input.payments) {
      if (payment.method == PaymentMethod.check) {
        checkCount++;
        issuedChecks.add(
          CheckRecord(
            id: 'chk-${input.paymentNumber}-$checkCount',
            checkNumber: payment.checkNumber!.trim(),
            bankName: payment.bankName!.trim(),
            branchNumber: payment.branchNumber?.trim() ?? '',
            accountNumber: payment.accountNumber?.trim() ?? '',
            amount: payment.amount,
            dueDate: payment.dueDate ?? input.date,
            type: CheckType.issued,
            partyId: contact.id,
            partyName: contact.name,
            relatedTransactionId: paymentVoucher.id,
            status: CheckStatus.pending,
            history: [
              CheckHistoryEntry(
                status: CheckStatus.pending,
                changedAt: input.date,
                notes: 'Issued check for voucher ${input.paymentNumber}',
                changedBy: input.createdBy,
              ),
            ],
            createdAt: input.date,
          ),
        );
      }
    }

    return ProcessSupplierPaymentResult(
      paymentVoucher: paymentVoucher,
      updatedSupplier: updatedSupplier,
      statementEntry: statementEntry,
      issuedChecks: issuedChecks,
    );
  }
}
