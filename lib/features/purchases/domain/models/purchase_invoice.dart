import '../../../inventory/domain/models/product.dart';

class PurchaseLineItem {
  final String productId;
  final String productName;
  final UnitType unitType;
  final double quantity;
  final double unitCost;
  final double subtotal;
  final double convertedStockQuantity;

  PurchaseLineItem({
    required this.productId,
    required this.productName,
    required this.unitType,
    required num quantity,
    required num unitCost,
    required num subtotal,
    required num convertedStockQuantity,
  })  : quantity = quantity.toDouble(),
        unitCost = unitCost.toDouble(),
        subtotal = subtotal.toDouble(),
        convertedStockQuantity = convertedStockQuantity.toDouble() {
    if (this.quantity <= 0) {
      throw ArgumentError.value(
        this.quantity,
        'quantity',
        'Quantity must be greater than zero',
      );
    }
    if (this.unitCost < 0) {
      throw ArgumentError.value(
        this.unitCost,
        'unitCost',
        'Unit cost cannot be negative',
      );
    }
  }

  PurchaseLineItem copyWith({
    String? productId,
    String? productName,
    UnitType? unitType,
    num? quantity,
    num? unitCost,
    num? subtotal,
    num? convertedStockQuantity,
  }) {
    return PurchaseLineItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitType: unitType ?? this.unitType,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      subtotal: subtotal ?? this.subtotal,
      convertedStockQuantity:
          convertedStockQuantity ?? this.convertedStockQuantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'unitType': unitType.name,
      'quantity': quantity,
      'unitCost': unitCost,
      'subtotal': subtotal,
      'convertedStockQuantity': convertedStockQuantity,
    };
  }

  factory PurchaseLineItem.fromJson(Map<String, dynamic> json) {
    return PurchaseLineItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      unitType: UnitType.values.byName(json['unitType'] as String),
      quantity: (json['quantity'] as num).toDouble(),
      unitCost: (json['unitCost'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      convertedStockQuantity:
          (json['convertedStockQuantity'] as num).toDouble(),
    );
  }
}

class PurchaseInvoice {
  final String id;
  final String invoiceNumber;
  final String? supplierInvoiceNumber;
  final DateTime date;
  final String supplierId;
  final String supplierName;
  final String supplierTaxId;
  final List<PurchaseLineItem> items;
  final double subtotal;
  final double vatRate;
  final double vatAmount;
  final double totalAmount;
  final double paidAmount;
  final double onAccountAmount;
  final String? notes;
  final String createdBy;
  final DateTime? createdAt;

  PurchaseInvoice({
    required this.id,
    required this.invoiceNumber,
    this.supplierInvoiceNumber,
    required this.date,
    required this.supplierId,
    required this.supplierName,
    required this.supplierTaxId,
    required List<PurchaseLineItem> items,
    required num subtotal,
    num vatRate = 0.17,
    required num vatAmount,
    required num totalAmount,
    num paidAmount = 0.0,
    required num onAccountAmount,
    this.notes,
    required this.createdBy,
    this.createdAt,
  })  : items = List.unmodifiable(items),
        subtotal = subtotal.toDouble(),
        vatRate = vatRate.toDouble(),
        vatAmount = vatAmount.toDouble(),
        totalAmount = totalAmount.toDouble(),
        paidAmount = paidAmount.toDouble(),
        onAccountAmount = onAccountAmount.toDouble() {
    if (this.items.isEmpty) {
      throw ArgumentError.value(
        items,
        'items',
        'Purchase invoice must contain at least one line item',
      );
    }
    if (this.paidAmount < 0) {
      throw ArgumentError.value(
        this.paidAmount,
        'paidAmount',
        'Paid amount cannot be negative',
      );
    }
    if (this.onAccountAmount < 0) {
      throw ArgumentError.value(
        this.onAccountAmount,
        'onAccountAmount',
        'On-account amount cannot be negative',
      );
    }
    final splitDiff =
        (this.paidAmount + this.onAccountAmount - this.totalAmount).abs();
    if (splitDiff >= 0.01) {
      throw ArgumentError(
        'Payment split does not balance with total: paidAmount ($paidAmount) + onAccountAmount ($onAccountAmount) != totalAmount ($totalAmount)',
      );
    }
    final totalDiff = (this.subtotal + this.vatAmount - this.totalAmount).abs();
    if (totalDiff >= 0.01) {
      throw ArgumentError(
        'Invoice total does not balance with subtotal + VAT: subtotal ($subtotal) + vatAmount ($vatAmount) != totalAmount ($totalAmount)',
      );
    }
  }

  PurchaseInvoice copyWith({
    String? id,
    String? invoiceNumber,
    String? supplierInvoiceNumber,
    DateTime? date,
    String? supplierId,
    String? supplierName,
    String? supplierTaxId,
    List<PurchaseLineItem>? items,
    num? subtotal,
    num? vatRate,
    num? vatAmount,
    num? totalAmount,
    num? paidAmount,
    num? onAccountAmount,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return PurchaseInvoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      supplierInvoiceNumber:
          supplierInvoiceNumber ?? this.supplierInvoiceNumber,
      date: date ?? this.date,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      supplierTaxId: supplierTaxId ?? this.supplierTaxId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      vatRate: vatRate ?? this.vatRate,
      vatAmount: vatAmount ?? this.vatAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      onAccountAmount: onAccountAmount ?? this.onAccountAmount,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'supplierInvoiceNumber': supplierInvoiceNumber,
      'date': date.toIso8601String(),
      'supplierId': supplierId,
      'supplierName': supplierName,
      'supplierTaxId': supplierTaxId,
      'items': items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'vatRate': vatRate,
      'vatAmount': vatAmount,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'onAccountAmount': onAccountAmount,
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory PurchaseInvoice.fromJson(Map<String, dynamic> json) {
    return PurchaseInvoice(
      id: json['id'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      supplierInvoiceNumber: json['supplierInvoiceNumber'] as String?,
      date: DateTime.parse(json['date'] as String),
      supplierId: json['supplierId'] as String,
      supplierName: json['supplierName'] as String,
      supplierTaxId: json['supplierTaxId'] as String? ?? '',
      items: (json['items'] as List)
          .map((item) =>
              PurchaseLineItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      vatRate: (json['vatRate'] as num?)?.toDouble() ?? 0.17,
      vatAmount: (json['vatAmount'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      onAccountAmount: (json['onAccountAmount'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}
