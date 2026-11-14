import '../../../inventory/domain/models/product.dart';

enum RefundMethod {
  debtCredit('זיכוי כרטיס לקוח (חוב)', 'خصم من رصيد الذمة'),
  cashRefund('החזר מזומן', 'إرجاع نقدي'),
  bankTransfer('העברה בנקאית', 'حوالة بنكية');

  final String hebrewLabel;
  final String arabicLabel;

  const RefundMethod(this.hebrewLabel, this.arabicLabel);
}

class CreditNoteLineItem {
  final String productId;
  final String productName;
  final UnitType unitType;
  final double quantity;
  final double unitPrice; // Price before VAT
  final double subtotal;

  const CreditNoteLineItem({
    required this.productId,
    required this.productName,
    required this.unitType,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'unitType': unitType.name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'subtotal': subtotal,
    };
  }

  factory CreditNoteLineItem.fromJson(Map<String, dynamic> json) {
    return CreditNoteLineItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      unitType: UnitType.values.byName(json['unitType'] as String),
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }
}

class CreditNote {
  final String id;
  final String creditNoteNumber;
  final DateTime date;
  final String? originalInvoiceId;
  final String? originalInvoiceNumber;
  final String customerId;
  final String customerName;
  final String customerTaxId;
  final List<CreditNoteLineItem> items;
  final double subtotal;
  final double vatRate;
  final double vatAmount;
  final double totalAmount;
  final RefundMethod refundMethod;
  final String? reason;
  final String? createdBy;
  final DateTime createdAt;

  const CreditNote({
    required this.id,
    required this.creditNoteNumber,
    required this.date,
    this.originalInvoiceId,
    this.originalInvoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.customerTaxId,
    required this.items,
    required this.subtotal,
    required this.vatRate,
    required this.vatAmount,
    required this.totalAmount,
    required this.refundMethod,
    this.reason,
    this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creditNoteNumber': creditNoteNumber,
      'date': date.toIso8601String(),
      'originalInvoiceId': originalInvoiceId,
      'originalInvoiceNumber': originalInvoiceNumber,
      'customerId': customerId,
      'customerName': customerName,
      'customerTaxId': customerTaxId,
      'items': items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'vatRate': vatRate,
      'vatAmount': vatAmount,
      'totalAmount': totalAmount,
      'refundMethod': refundMethod.name,
      'reason': reason,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CreditNote.fromJson(Map<String, dynamic> json) {
    return CreditNote(
      id: json['id'] as String,
      creditNoteNumber: json['creditNoteNumber'] as String,
      date: DateTime.parse(json['date'] as String),
      originalInvoiceId: json['originalInvoiceId'] as String?,
      originalInvoiceNumber: json['originalInvoiceNumber'] as String?,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String,
      customerTaxId: json['customerTaxId'] as String? ?? '',
      items: (json['items'] as List)
          .map((i) => CreditNoteLineItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      vatRate: (json['vatRate'] as num).toDouble(),
      vatAmount: (json['vatAmount'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      refundMethod: RefundMethod.values.byName(json['refundMethod'] as String),
      reason: json['reason'] as String?,
      createdBy: json['createdBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
