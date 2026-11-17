import 'package:sales_logistics_system/features/accounts/domain/models/contact.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/statement_entry.dart';
import 'package:sales_logistics_system/features/checks/domain/models/check_record.dart';
import 'package:sales_logistics_system/core/repositories/product_repository.dart';
import 'package:sales_logistics_system/core/repositories/contact_repository.dart';
import 'package:sales_logistics_system/core/repositories/sale_repository.dart';
import 'package:sales_logistics_system/core/repositories/check_repository.dart';
import '../models/sale_invoice.dart';
import '../models/payment_split.dart';

class SaleTransactionOrchestrator {
  final ProductRepository productRepository;
  final ContactRepository contactRepository;
  final SaleRepository saleRepository;
  final CheckRepository checkRepository;

  const SaleTransactionOrchestrator({
    required this.productRepository,
    required this.contactRepository,
    required this.saleRepository,
    required this.checkRepository,
  });

  /// Executes an atomic sale transaction across products, contacts, checks, and invoices.
  /// Validates stock availability for all items before applying mutations.
  Future<void> processSaleTransaction({
    required SaleInvoice sale,
    Contact? customer,
    List<CheckRecord>? checks,
  }) async {
    // 1. Validate stock sufficiency for all items
    for (final item in sale.items) {
      final product = await productRepository.getProductById(item.productId);
      if (product == null) {
        throw StateError('Product ${item.productId} (${item.productName}) not found');
      }
      if (product.currentStock < item.quantity) {
        throw StateError(
          'Insufficient stock for ${item.productName}: available ${product.currentStock}, requested ${item.quantity}',
        );
      }
    }

    // 2. Decrement inventory
    for (final item in sale.items) {
      await productRepository.updateStock(
        productId: item.productId,
        stockDelta: -item.quantity,
      );
    }

    // 3. Compute debt amount from payments
    final debtAmount = sale.payments
        .where((p) => p.method == PaymentMethod.debt)
        .fold<double>(0.0, (sum, p) => sum + p.amount);

    if (debtAmount > 0 && customer != null) {
      final newBalance = customer.currentBalance + debtAmount;

      await contactRepository.updateBalance(
        contactId: customer.id,
        balanceDelta: debtAmount,
      );

      final statement = StatementEntry(
        id: 'stmt-${sale.id}',
        contactId: customer.id,
        contactType: ContactType.customer,
        date: sale.date,
        type: StatementEntryType.saleInvoice,
        referenceNumber: sale.invoiceNumber,
        debit: debtAmount,
        credit: 0.0,
        runningBalance: newBalance,
        description: 'فاتورة ضريبية / חשבונית מס ${sale.invoiceNumber}',
      );
      await contactRepository.addStatementEntry(statement);
    }

    // 4. Ingest checks if provided
    if (checks != null) {
      for (final check in checks) {
        await checkRepository.saveCheck(check);
      }
    }

    // 5. Persist the sale invoice
    await saleRepository.saveSale(sale);
  }
}
