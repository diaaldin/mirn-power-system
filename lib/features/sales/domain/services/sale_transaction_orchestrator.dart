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
  /// Validates aggregated stock availability for all items before applying mutations.
  Future<void> processSaleTransaction({
    required SaleInvoice sale,
    Contact? customer,
    List<CheckRecord>? checks,
  }) async {
    // 1. Aggregate required quantities per product to handle duplicate line items
    final aggregatedQuantities = <String, double>{};
    for (final item in sale.items) {
      aggregatedQuantities[item.productId] =
          (aggregatedQuantities[item.productId] ?? 0.0) + item.quantity;
    }

    // 2. Validate stock sufficiency for all aggregated items
    for (final entry in aggregatedQuantities.entries) {
      final product = await productRepository.getProductById(entry.key);
      if (product == null) {
        throw StateError('Product with id ${entry.key} not found');
      }
      if (product.currentStock < entry.value) {
        throw StateError(
          'Insufficient stock for ${product.name}: available ${product.currentStock}, requested ${entry.value}',
        );
      }
    }

    // 3. Decrement inventory
    for (final item in sale.items) {
      await productRepository.updateStock(
        productId: item.productId,
        stockDelta: -item.quantity,
      );
    }

    // 4. Compute debt amount from payments
    final debtAmount = sale.payments
        .where((p) => p.method == PaymentMethod.debt)
        .fold<double>(0.0, (sum, p) => sum + p.amount);

    if (debtAmount > 0) {
      if (customer == null) {
        throw StateError('Customer must be provided when sale contains on-account debt');
      }

      // Fetch fresh customer to avoid running balance de-synchronization
      final freshCustomer = await contactRepository.getContactById(customer.id);
      if (freshCustomer == null) {
        throw StateError('Customer ${customer.id} not found in repository');
      }

      final newBalance = freshCustomer.currentBalance + debtAmount;

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

    // 5. Ingest checks if provided
    if (checks != null) {
      for (final check in checks) {
        await checkRepository.saveCheck(check);
      }
    }

    // 6. Persist the sale invoice
    await saleRepository.saveSale(sale);
  }
}
