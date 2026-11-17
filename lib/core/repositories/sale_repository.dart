import '../../features/sales/domain/models/sale_invoice.dart';
import '../../features/returns/domain/models/credit_note.dart';

abstract class SaleRepository {
  Stream<List<SaleInvoice>> watchSales();
  Future<List<SaleInvoice>> getSales();
  Future<SaleInvoice?> getSaleById(String id);
  Future<void> saveSale(SaleInvoice sale);

  Stream<List<CreditNote>> watchCreditNotes();
  Future<List<CreditNote>> getCreditNotes();
  Future<CreditNote?> getCreditNoteById(String id);
  Future<void> saveCreditNote(CreditNote creditNote);
}
