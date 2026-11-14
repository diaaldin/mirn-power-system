import '../../../accounts/domain/models/contact.dart';
import '../../../sales/domain/models/payment_split.dart';
import '../../domain/models/payment_receipt.dart';
import '../../domain/services/receipt_service.dart';

/// Presentation state for customer payment receipts and supplier payment vouchers.
class ReceiptFormState {
  final Contact? contact;
  final ReceiptType receiptType;
  final String receiptNumber;
  final DateTime date;
  final double totalAmount;
  final List<ReceiptPaymentItem> payments;
  final String? notes;
  final double allocatedAmount;
  final double remainingToAllocate;
  final double? projectedBalance;
  final bool isComplete;

  const ReceiptFormState({
    this.contact,
    this.receiptType = ReceiptType.customerReceipt,
    required this.receiptNumber,
    required this.date,
    required this.totalAmount,
    required this.payments,
    this.notes,
    required this.allocatedAmount,
    required this.remainingToAllocate,
    this.projectedBalance,
    required this.isComplete,
  });

  factory ReceiptFormState.initial({
    Contact? contact,
    ReceiptType receiptType = ReceiptType.customerReceipt,
    String receiptNumber = '',
    DateTime? date,
  }) {
    final d = date ?? DateTime.now();
    return ReceiptFormState(
      contact: contact,
      receiptType: receiptType,
      receiptNumber: receiptNumber,
      date: d,
      totalAmount: 0.0,
      payments: const [],
      notes: null,
      allocatedAmount: 0.0,
      remainingToAllocate: 0.0,
      projectedBalance: contact?.currentBalance,
      isComplete: false,
    );
  }
}

/// Reactive presentation controller managing the state machine of payment receipts
/// (customer debt settlement) and supplier payment vouchers (supplier payables).
class ReceiptsController {
  Contact? _contact;
  ReceiptType _receiptType;
  String _receiptNumber;
  DateTime _date;
  double _totalAmount = 0.0;
  final List<ReceiptPaymentItem> _payments = [];
  String? _notes;

  ReceiptsController({
    Contact? initialContact,
    ReceiptType initialType = ReceiptType.customerReceipt,
    String? initialReceiptNumber,
    DateTime? initialDate,
  })  : _contact = initialContact,
        _receiptType = initialType,
        _receiptNumber = initialReceiptNumber ?? '',
        _date = initialDate ?? DateTime.now();

  static double _round2(num val) => (val * 100).round() / 100.0;

  /// Current reactive snapshot of the receipt form state.
  ReceiptFormState get state => _computeState();

  void setContact(Contact? contact) {
    _contact = contact;
  }

  void setReceiptType(ReceiptType type) {
    _receiptType = type;
  }

  void setTotalAmount(double amount) {
    _totalAmount = amount;
  }

  void setDate(DateTime date) {
    _date = date;
  }

  void setReceiptNumber(String number) {
    _receiptNumber = number;
  }

  void setNotes(String? notes) {
    _notes = notes;
  }

  /// Appends a payment line item to the current receipt.
  void addPaymentLine({
    required PaymentMethod method,
    required double amount,
    String? reference,
    String? checkNumber,
    String? bankName,
    String? branchNumber,
    String? accountNumber,
    DateTime? dueDate,
    String? drawerName,
  }) {
    _payments.add(
      ReceiptPaymentItem(
        method: method,
        amount: amount,
        reference: reference,
        checkNumber: checkNumber,
        bankName: bankName,
        branchNumber: branchNumber,
        accountNumber: accountNumber,
        dueDate: dueDate,
        drawerName: drawerName,
      ),
    );
  }

  /// Removes payment line item at specified index if in range.
  void removePaymentLine(int index) {
    if (index >= 0 && index < _payments.length) {
      _payments.removeAt(index);
    }
  }

  /// Clears all allocated payment lines.
  void clearPayments() {
    _payments.clear();
  }

  /// Submits the customer receipt, settling customer balance, generating a statement entry,
  /// and automatically ingesting any received checks into the portfolio in pending status.
  ///
  /// Throws [StateError] if the contact is null or if the form is not completely allocated.
  ProcessCustomerReceiptResult submitCustomerReceipt({
    required String createdBy,
  }) {
    final currentState = state;
    if (currentState.contact == null) {
      throw StateError('Cannot submit customer receipt without a contact');
    }
    if (!currentState.isComplete) {
      throw StateError(
        'Cannot submit customer receipt: payment allocation is incomplete or unbalanced',
      );
    }

    final input = CreateReceiptInput(
      receiptNumber: currentState.receiptNumber,
      date: currentState.date,
      amount: currentState.totalAmount,
      payments: currentState.payments,
      notes: currentState.notes,
      createdBy: createdBy,
    );

    return ReceiptService.processCustomerReceipt(
      contact: currentState.contact!,
      input: input,
    );
  }

  /// Submits the supplier payment voucher, settling supplier payable, generating a statement entry,
  /// and automatically registering any issued checks into the portfolio in pending status.
  ///
  /// Throws [StateError] if the contact is null or if the form is not completely allocated.
  ProcessSupplierPaymentResult submitSupplierPayment({
    required String createdBy,
  }) {
    final currentState = state;
    if (currentState.contact == null) {
      throw StateError('Cannot submit supplier payment without a contact');
    }
    if (!currentState.isComplete) {
      throw StateError(
        'Cannot submit supplier payment: payment allocation is incomplete or unbalanced',
      );
    }

    final input = CreateSupplierPaymentInput(
      paymentNumber: currentState.receiptNumber,
      date: currentState.date,
      amount: currentState.totalAmount,
      payments: currentState.payments,
      notes: currentState.notes,
      createdBy: createdBy,
    );

    return ReceiptService.processSupplierPayment(
      contact: currentState.contact!,
      input: input,
    );
  }

  ReceiptFormState _computeState() {
    final allocatedAmount = _round2(
      _payments.fold<double>(0.0, (sum, p) => sum + p.amount),
    );
    final remainingToAllocate = _round2(_totalAmount - allocatedAmount);
    final isComplete = _totalAmount > 0 && remainingToAllocate.abs() <= 0.01;

    final double? projectedBalance = _contact != null
        ? _round2(_contact!.currentBalance - allocatedAmount)
        : null;

    return ReceiptFormState(
      contact: _contact,
      receiptType: _receiptType,
      receiptNumber: _receiptNumber,
      date: _date,
      totalAmount: _totalAmount,
      payments: List.unmodifiable(_payments),
      notes: _notes,
      allocatedAmount: allocatedAmount,
      remainingToAllocate: remainingToAllocate,
      projectedBalance: projectedBalance,
      isComplete: isComplete,
    );
  }
}
