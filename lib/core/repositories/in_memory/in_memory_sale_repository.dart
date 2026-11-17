import 'dart:async';
import '../../../features/sales/domain/models/sale_invoice.dart';
import '../../../features/returns/domain/models/credit_note.dart';
import '../sale_repository.dart';

class InMemorySaleRepository implements SaleRepository {
  final Map<String, SaleInvoice> _sales = {};
  final Map<String, CreditNote> _creditNotes = {};
  late final StreamController<List<SaleInvoice>> _salesController;
  late final StreamController<List<CreditNote>> _creditNotesController;

  InMemorySaleRepository({
    List<SaleInvoice>? initialSales,
    List<CreditNote>? initialCreditNotes,
  }) {
    if (initialSales != null) {
      for (final s in initialSales) {
        _sales[s.id] = s;
      }
    }
    if (initialCreditNotes != null) {
      for (final c in initialCreditNotes) {
        _creditNotes[c.id] = c;
      }
    }
    _salesController = StreamController<List<SaleInvoice>>.broadcast(
      onListen: () => _salesController.add(_currentSalesList),
    );
    _creditNotesController = StreamController<List<CreditNote>>.broadcast(
      onListen: () => _creditNotesController.add(_currentCreditNotesList),
    );
  }

  List<SaleInvoice> get _currentSalesList => List.unmodifiable(_sales.values);
  List<CreditNote> get _currentCreditNotesList => List.unmodifiable(_creditNotes.values);

  @override
  Stream<List<SaleInvoice>> watchSales() => _salesController.stream;

  @override
  Future<List<SaleInvoice>> getSales() async => _currentSalesList;

  @override
  Future<SaleInvoice?> getSaleById(String id) async => _sales[id];

  @override
  Future<void> saveSale(SaleInvoice sale) async {
    _sales[sale.id] = sale;
    _salesController.add(_currentSalesList);
  }

  @override
  Stream<List<CreditNote>> watchCreditNotes() => _creditNotesController.stream;

  @override
  Future<List<CreditNote>> getCreditNotes() async => _currentCreditNotesList;

  @override
  Future<CreditNote?> getCreditNoteById(String id) async => _creditNotes[id];

  @override
  Future<void> saveCreditNote(CreditNote creditNote) async {
    _creditNotes[creditNote.id] = creditNote;
    _creditNotesController.add(_currentCreditNotesList);
  }

  void dispose() {
    _salesController.close();
    _creditNotesController.close();
  }
}
