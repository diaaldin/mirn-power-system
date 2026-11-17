import 'package:sales_logistics_system/features/accounts/domain/models/contact.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/statement_entry.dart';
import 'package:sales_logistics_system/core/repositories/product_repository.dart';
import 'package:sales_logistics_system/core/repositories/contact_repository.dart';
import 'package:sales_logistics_system/core/repositories/sale_repository.dart';
import '../models/credit_note.dart';

class CreditNoteTransactionOrchestrator {
  final ProductRepository productRepository;
  final ContactRepository contactRepository;
  final SaleRepository saleRepository;

  const CreditNoteTransactionOrchestrator({
    required this.productRepository,
    required this.contactRepository,
    required this.saleRepository,
  });

  /// Restores stock for returned items, decreases customer balance, and writes a credit statement entry.
  Future<void> processCreditNoteTransaction({
    required CreditNote creditNote,
    required Contact customer,
  }) async {
    // 1. Restore product stock
    for (final item in creditNote.items) {
      await productRepository.updateStock(
        productId: item.productId,
        stockDelta: item.quantity,
      );
    }

    // 2. Reduce customer debt
    final returnTotal = creditNote.totalAmount;
    final newBalance = customer.currentBalance - returnTotal;

    await contactRepository.updateBalance(
      contactId: customer.id,
      balanceDelta: -returnTotal,
    );

    // 3. Post a credit entry on the customer statement of account
    final statement = StatementEntry(
      id: 'stmt-crn-${creditNote.id}',
      contactId: customer.id,
      contactType: ContactType.customer,
      date: creditNote.date,
      type: StatementEntryType.creditNote,
      referenceNumber: creditNote.creditNoteNumber,
      debit: 0.0,
      credit: returnTotal,
      runningBalance: newBalance,
      description: 'فاتورة إرجاع ضريبية / חשבונית זיכוי ${creditNote.creditNoteNumber}',
    );
    await contactRepository.addStatementEntry(statement);

    // 4. Save credit note
    await saleRepository.saveCreditNote(creditNote);
  }
}
