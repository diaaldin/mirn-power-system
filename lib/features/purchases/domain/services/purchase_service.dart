import '../../../accounts/domain/models/contact.dart';
import '../../../accounts/domain/models/statement_entry.dart';
import '../../../inventory/domain/models/product.dart';
import '../../../inventory/domain/services/unit_converter.dart';
import '../models/purchase_invoice.dart';

class PurchaseLineItemInput {
  final Product product;
  final UnitType unitType;
  final num quantity;
  final num unitCost;

  const PurchaseLineItemInput({
    required this.product,
    required this.unitType,
    required this.quantity,
    required this.unitCost,
  });
}

class CreatePurchaseInput {
  final String? id;
  final String invoiceNumber;
  final String? supplierInvoiceNumber;
  final DateTime date;
  final Contact supplier;
  final List<PurchaseLineItemInput> items;
  final double vatRate;
  final num paidAmount;
  final String? notes;
  final String createdBy;

  const CreatePurchaseInput({
    this.id,
    required this.invoiceNumber,
    this.supplierInvoiceNumber,
    required this.date,
    required this.supplier,
    required this.items,
    this.vatRate = 0.17,
    this.paidAmount = 0.0,
    this.notes,
    required this.createdBy,
  });
}

class ProcessPurchaseResult {
  final PurchaseInvoice purchase;
  final List<Product> updatedProducts;
  final Contact updatedSupplier;
  final StatementEntry? statementEntry;

  ProcessPurchaseResult({
    required this.purchase,
    required List<Product> updatedProducts,
    required this.updatedSupplier,
    this.statementEntry,
  }) : updatedProducts = List.unmodifiable(updatedProducts);
}

class PurchaseService {
  PurchaseService._();

  static double _round2(num val) => (val * 100).roundToDouble() / 100.0;

  static ProcessPurchaseResult processPurchase(CreatePurchaseInput input) {
    if (input.supplier.type == ContactType.customer) {
      throw ArgumentError.value(
        input.supplier.type,
        'supplier',
        'Supplier cannot be a customer-only contact',
      );
    }

    if (input.items.isEmpty) {
      throw ArgumentError.value(
        input.items,
        'items',
        'Purchase invoice must contain at least one line item (cannot be empty)',
      );
    }

    final List<PurchaseLineItem> lineItems = [];
    final Map<String, Product> productMap = {};

    for (final item in input.items) {
      if (item.quantity <= 0) {
        throw ArgumentError.value(
          item.quantity,
          'quantity',
          'Quantity must be greater than zero',
        );
      }
      if (item.unitCost < 0) {
        throw ArgumentError.value(
          item.unitCost,
          'unitCost',
          'Unit cost cannot be negative',
        );
      }

      final convertedStock = UnitConverter.calculateStockAddition(
        product: item.product,
        quantity: item.quantity,
        purchasedUnit: item.unitType,
      );

      final lineSubtotal = _round2(item.quantity * item.unitCost);

      lineItems.add(
        PurchaseLineItem(
          productId: item.product.id,
          productName: item.product.name,
          unitType: item.unitType,
          quantity: item.quantity,
          unitCost: item.unitCost,
          subtotal: lineSubtotal,
          convertedStockQuantity: convertedStock,
        ),
      );

      // Stock replenishment & weighted average cost
      final currentProduct = productMap[item.product.id] ?? item.product;
      final newStock = currentProduct.currentStock + convertedStock;

      double costPerPrimaryUnit;
      if (item.product.unitType == item.unitType) {
        costPerPrimaryUnit = item.unitCost.toDouble();
      } else if (item.product.unitType == UnitType.meter &&
          item.unitType == UnitType.box) {
        final factor = item.product.meterPerBox ?? 1.0;
        costPerPrimaryUnit =
            factor > 0 ? (item.unitCost / factor) : item.unitCost.toDouble();
      } else if (item.product.unitType == UnitType.box &&
          item.unitType == UnitType.meter) {
        final factor = item.product.meterPerBox ?? 1.0;
        costPerPrimaryUnit = item.unitCost * factor;
      } else {
        costPerPrimaryUnit = item.unitCost.toDouble();
      }

      double newCost;
      if (currentProduct.currentStock <= 0) {
        newCost = _round2(costPerPrimaryUnit);
      } else {
        final totalExistingValue =
            currentProduct.currentStock * currentProduct.purchaseCost;
        final addedValue = convertedStock * costPerPrimaryUnit;
        final avgCost = (totalExistingValue + addedValue) / newStock;
        newCost = _round2(avgCost);
      }

      productMap[item.product.id] = currentProduct.copyWith(
        currentStock: newStock,
        purchaseCost: newCost,
        updatedAt: input.date,
      );
    }

    final subtotal = _round2(
      lineItems.fold<double>(0.0, (acc, item) => acc + item.subtotal),
    );
    final vatAmount = _round2(subtotal * input.vatRate);
    final totalAmount = _round2(subtotal + vatAmount);

    if (input.paidAmount < 0) {
      throw ArgumentError.value(
        input.paidAmount,
        'paidAmount',
        'Paid amount cannot be negative',
      );
    }
    if (input.paidAmount > totalAmount) {
      throw ArgumentError.value(
        input.paidAmount,
        'paidAmount',
        'Paid amount cannot exceed total invoice amount',
      );
    }

    final paidAmount = _round2(input.paidAmount);
    final onAccountAmount = _round2(totalAmount - paidAmount);

    Contact updatedSupplier = input.supplier;
    StatementEntry? statementEntry;

    if (onAccountAmount > 0) {
      final updatedBalance =
          _round2(input.supplier.currentBalance + onAccountAmount);
      updatedSupplier = input.supplier.copyWith(
        currentBalance: updatedBalance,
        updatedAt: input.date,
      );

      final description =
          (input.notes != null && input.notes!.trim().isNotEmpty)
              ? input.notes!
              : 'فاتورة مشتريات وتوريد مخزون - ${input.invoiceNumber}';

      statementEntry = StatementEntry(
        id: 'stmt-${input.invoiceNumber}',
        contactId: input.supplier.id,
        contactType: input.supplier.type,
        date: input.date,
        type: StatementEntryType.purchaseInvoice,
        referenceNumber: input.invoiceNumber,
        debit: 0.0,
        credit: onAccountAmount,
        runningBalance: updatedBalance,
        description: description,
      );
    }

    final purchaseInvoice = PurchaseInvoice(
      id: input.id ?? input.invoiceNumber,
      invoiceNumber: input.invoiceNumber,
      supplierInvoiceNumber: input.supplierInvoiceNumber,
      date: input.date,
      supplierId: input.supplier.id,
      supplierName: input.supplier.name,
      supplierTaxId: input.supplier.taxId,
      items: lineItems,
      subtotal: subtotal,
      vatRate: input.vatRate,
      vatAmount: vatAmount,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      onAccountAmount: onAccountAmount,
      notes: input.notes,
      createdBy: input.createdBy,
      createdAt: input.date,
    );

    return ProcessPurchaseResult(
      purchase: purchaseInvoice,
      updatedProducts: productMap.values.toList(),
      updatedSupplier: updatedSupplier,
      statementEntry: statementEntry,
    );
  }
}
