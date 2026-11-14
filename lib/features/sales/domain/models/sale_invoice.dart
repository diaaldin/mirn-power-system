import '../../../inventory/domain/models/product.dart';
import 'payment_split.dart';

class SaleLineItem {
  final String productId;
  final String productName;
  final UnitType unitType;
  final double quantity;
  final double unitPrice; // Base price before VAT
  final double discountPercent;
  final double subtotal;

  const SaleLineItem({
    required this.productId,
    required this.productName,
    required this.unitType,
    required this.quantity,
    required this.unitPrice,
    this.discountPercent = 0.0,
    required this.subtotal,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'unitType': unitType.name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discountPercent': discountPercent,
      'subtotal': subtotal,
    };
  }

  factory SaleLineItem.fromJson(Map<String, dynamic> json) {
    return SaleLineItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      unitType: UnitType.values.byName(json['unitType'] as String),
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }
}

class SaleInvoice {
  final String id;
  final String invoiceNumber;
  final DateTime date;
  final String customerId;
  final String customerName;
  final String customerTaxId;
  final bool isTaxInclusiveInput;
  final List<SaleLineItem> items;
  final double subtotal;
  final double vatRate;
  final double vatAmount;
  final double totalAmount;
  final List<PaymentSplit> payments;
  final String? allocationNumber;
  final String? dispatchId;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;

  const SaleInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    required this.customerId,
    required this.customerName,
    required this.customerTaxId,
    required this.isTaxInclusiveInput,
    required this.items,
    required this.subtotal,
    required this.vatRate,
    required this.vatAmount,
    required this.totalAmount,
    required this.payments,
    this.allocationNumber,
    this.dispatchId,
    this.notes,
    this.createdBy,
    required this.createdAt,
  });

  bool get isPaidInFull =>
      payments.where((p) => p.method == PaymentMethod.debt).isEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'date': date.toIso8601String(),
      'customerId': customerId,
      'customerName': customerName,
      'customerTaxId': customerTaxId,
      'isTaxInclusiveInput': isTaxInclusiveInput,
      'items': items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'vatRate': vatRate,
      'vatAmount': vatAmount,
      'totalAmount': totalAmount,
      'payments': payments.map((p) => p.toJson()).toList(),
      'allocationNumber': allocationNumber,
      'dispatchId': dispatchId,
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SaleInvoice.fromJson(Map<String, dynamic> json) {
    return SaleInvoice(
      id: json['id'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      date: DateTime.parse(json['date'] as String),
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String,
      customerTaxId: json['customerTaxId'] as String? ?? '',
      isTaxInclusiveInput: json['isTaxInclusiveInput'] as bool? ?? false,
      items: (json['items'] as List)
          .map((i) => SaleLineItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      vatRate: (json['vatRate'] as num).toDouble(),
      vatAmount: (json['vatAmount'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      payments: (json['payments'] as List)
          .map((p) => PaymentSplit.fromJson(p as Map<String, dynamic>))
          .toList(),
      allocationNumber: json['allocationNumber'] as String?,
      dispatchId: json['dispatchId'] as String?,
      notes: json['notes'] as String?,
      createdBy: json['createdBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
