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
    // 1. Update product stock and recalculate weighted moving average cost
    for (final item in purchase.items) {
      final product = await productRepository.getProductById(item.productId);
      if (product != null) {
        final currentStock = product.currentStock;
        final intakeQty = item.convertedStockQuantity;
        final newStock = currentStock + intakeQty;

        double newAvgCost = product.purchaseCost;
        if (newStock > 0) {
          final totalCost = (currentStock * product.purchaseCost) + (intakeQty * item.unitCost);
          newAvgCost = totalCost / newStock;
        }

        final updatedProduct = product.copyWith(
          currentStock: newStock,
          purchaseCost: ((newAvgCost * 100).round()) / 100.0,
        );
        await productRepository.saveProduct(updatedProduct);
      }
    }

    // 2. Increase supplier accounts payable balance
    final billTotal = purchase.totalAmount;
    final newBalance = supplier.currentBalance + billTotal;

    await contactRepository.updateBalance(
      contactId: supplier.id,
      balanceDelta: billTotal,
    );

    // 3. Post a credit entry on the supplier ledger
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

    // 4. Save purchase invoice
    await purchaseRepository.savePurchase(purchase);
  }
}
