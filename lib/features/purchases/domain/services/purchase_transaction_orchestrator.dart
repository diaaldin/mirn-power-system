import 'package:sales_logistics_system/features/accounts/domain/models/contact.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/statement_entry.dart';
import 'package:sales_logistics_system/core/repositories/product_repository.dart';
import 'package:sales_logistics_system/core/repositories/contact_repository.dart';
import 'package:sales_logistics_system/core/repositories/purchase_repository.dart';
import '../models/purchase_invoice.dart';

class PurchaseTransactionOrchestrator {
  final ProductRepository productRepository;
  final ContactRepository contactRepository;
  final PurchaseRepository purchaseRepository;

  const PurchaseTransactionOrchestrator({
    required this.productRepository,
    required this.contactRepository,
    required this.purchaseRepository,
  });

  /// Processes stock intake, supplier AP balance increment, moving average cost, and purchase ledger entry.
  Future<void> processPurchaseTransaction({
    required PurchaseInvoice purchase,
    required Contact supplier,
  }) async {
    // 1. Precondition check: verify all products exist before executing mutations
    for (final item in purchase.items) {
      final product = await productRepository.getProductById(item.productId);
      if (product == null) {
        throw StateError('Product ${item.productId} (${item.productName}) not found');
      }
    }

    // 2. Update product stock and recalculate weighted moving average cost
    for (final item in purchase.items) {
      final product = (await productRepository.getProductById(item.productId))!;
      final currentStock = product.currentStock;
      final intakeQty = item.convertedStockQuantity;
      final newStock = currentStock + intakeQty;

      double newAvgCost;
      if (currentStock <= 0) {
        newAvgCost = item.unitCost;
      } else if (newStock > 0) {
        final totalCost = (currentStock * product.purchaseCost) + (intakeQty * item.unitCost);
        newAvgCost = totalCost / newStock;
      } else {
        newAvgCost = item.unitCost;
      }

      final updatedProduct = product.copyWith(
        currentStock: newStock,
        purchaseCost: ((newAvgCost * 100).round()) / 100.0,
      );
      await productRepository.saveProduct(updatedProduct);
    }

    // 3. Fetch fresh supplier to avoid running balance de-synchronization
    final freshSupplier = await contactRepository.getContactById(supplier.id);
    if (freshSupplier == null) {
      throw StateError('Supplier ${supplier.id} not found in repository');
    }

    final billTotal = purchase.totalAmount;
    final newBalance = freshSupplier.currentBalance + billTotal;

    await contactRepository.updateBalance(
      contactId: supplier.id,
      balanceDelta: billTotal,
    );

    // 4. Post a credit entry on the supplier ledger
    final statement = StatementEntry(
      id: 'stmt-pur-${purchase.id}',
      contactId: supplier.id,
      contactType: ContactType.supplier,
      date: purchase.date,
      type: StatementEntryType.purchaseInvoice,
      referenceNumber: purchase.invoiceNumber,
      debit: 0.0,
      credit: billTotal,
      runningBalance: newBalance,
      description: 'فاتورة مشتريات / חשבונית רכש ${purchase.invoiceNumber}',
    );
    await contactRepository.addStatementEntry(statement);

    // 5. Save purchase invoice
    await purchaseRepository.savePurchase(purchase);
  }
}
