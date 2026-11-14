import '../../../accounts/domain/models/contact.dart';
import '../../../sales/domain/models/payment_split.dart';

enum ReceiptType {
  customerReceipt,
  supplierPayment;

  String get displayName {
    switch (this) {
      case ReceiptType.customerReceipt:
        return 'سند قبض / קבלה';
      case ReceiptType.supplierPayment:
        return 'سند صرف / תשלום ספק';
    }
  }
}

class ReceiptPaymentItem {
  final PaymentMethod method;
  final double amount;
  final String? reference;
  final String? checkNumber;
  final String? bankName;
  final String? branchNumber;
  final String? accountNumber;
  final DateTime? dueDate;
  final String? drawerName;

  const ReceiptPaymentItem({
    required this.method,
    required this.amount,
    this.reference,
    this.checkNumber,
    this.bankName,
    this.branchNumber,
    this.accountNumber,
    this.dueDate,
    this.drawerName,
  });

  ReceiptPaymentItem copyWith({
    PaymentMethod? method,
    double? amount,
    String? reference,
    String? checkNumber,
    String? bankName,
    String? branchNumber,
    String? accountNumber,
    DateTime? dueDate,
    String? drawerName,
  }) {
    return ReceiptPaymentItem(
      method: method ?? this.method,
      amount: amount ?? this.amount,
      reference: reference ?? this.reference,
      checkNumber: checkNumber ?? this.checkNumber,
      bankName: bankName ?? this.bankName,
      branchNumber: branchNumber ?? this.branchNumber,
      accountNumber: accountNumber ?? this.accountNumber,
      dueDate: dueDate ?? this.dueDate,
      drawerName: drawerName ?? this.drawerName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'method': method.name,
      'amount': amount,
      'reference': reference,
      'checkNumber': checkNumber,
      'bankName': bankName,
      'branchNumber': branchNumber,
      'accountNumber': accountNumber,
      'dueDate': dueDate?.toIso8601String(),
      'drawerName': drawerName,
    };
  }

  factory ReceiptPaymentItem.fromJson(Map<String, dynamic> json) {
    return ReceiptPaymentItem(
      method: PaymentMethod.values.byName(json['method'] as String),
      amount: (json['amount'] as num).toDouble(),
      reference: json['reference'] as String?,
      checkNumber: json['checkNumber'] as String?,
      bankName: json['bankName'] as String?,
      branchNumber: json['branchNumber'] as String?,
      accountNumber: json['accountNumber'] as String?,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      drawerName: json['drawerName'] as String?,
    );
  }
}

class PaymentReceipt {
  final String id;
  final String receiptNumber;
  final DateTime date;
  final ContactType partyType;
  final String contactId;
  final String contactName;
  final double totalAmount;
  final List<ReceiptPaymentItem> payments;
  final String? notes;
  final String createdBy;
  final DateTime createdAt;

  PaymentReceipt({
    required this.id,
    required this.receiptNumber,
    required this.date,
    required this.partyType,
    required this.contactId,
    required this.contactName,
    required this.totalAmount,
    required this.payments,
    this.notes,
    required this.createdBy,
    required this.createdAt,
  }) {
    if (totalAmount <= 0) {
      throw ArgumentError.value(
        totalAmount,
        'totalAmount',
        'Total amount must be greater than zero',
      );
    }

    for (final payment in payments) {
      if (payment.amount <= 0) {
        throw ArgumentError.value(
          payment.amount,
          'payments',
          'Payment item amount must be greater than zero',
        );
      }
    }

    if (!isPaymentBalanced) {
      final paymentsSum = payments.fold(0.0, (sum, p) => sum + p.amount);
      throw ArgumentError(
        'Payment items sum ($paymentsSum) does not match total amount ($totalAmount)',
      );
    }
  }

  bool get isPaymentBalanced =>
      (payments.fold(0.0, (sum, p) => sum + p.amount) - totalAmount).abs() <=
      0.01;

  ReceiptType get receiptType => partyType == ContactType.supplier
      ? ReceiptType.supplierPayment
      : ReceiptType.customerReceipt;

  bool get isCustomerReceipt => partyType == ContactType.customer;
  bool get isSupplierPayment => partyType == ContactType.supplier;

  PaymentReceipt copyWith({
    String? id,
    String? receiptNumber,
    DateTime? date,
    ContactType? partyType,
    String? contactId,
    String? contactName,
    double? totalAmount,
    List<ReceiptPaymentItem>? payments,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return PaymentReceipt(
      id: id ?? this.id,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      date: date ?? this.date,
      partyType: partyType ?? this.partyType,
      contactId: contactId ?? this.contactId,
      contactName: contactName ?? this.contactName,
      totalAmount: totalAmount ?? this.totalAmount,
      payments: payments ?? this.payments,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receiptNumber': receiptNumber,
      'date': date.toIso8601String(),
      'partyType': partyType.name,
      'contactId': contactId,
      'contactName': contactName,
      'totalAmount': totalAmount,
      'payments': payments.map((p) => p.toJson()).toList(),
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PaymentReceipt.fromJson(Map<String, dynamic> json) {
    return PaymentReceipt(
      id: json['id'] as String,
      receiptNumber: json['receiptNumber'] as String,
      date: DateTime.parse(json['date'] as String),
      partyType: ContactType.values.byName(json['partyType'] as String),
      contactId: json['contactId'] as String,
      contactName: json['contactName'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      payments: (json['payments'] as List)
          .map((p) => ReceiptPaymentItem.fromJson(p as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
