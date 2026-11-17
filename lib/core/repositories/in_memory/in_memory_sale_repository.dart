import 'dart:async';
import '../../../features/sales/domain/models/sale_invoice.dart';
import '../../../features/returns/domain/models/credit_note.dart';
import '../sale_repository.dart';

class InMemorySaleRepository implements SaleRepository {
  final Map<String, SaleInvoice> _sales = {};
  final Map<String, CreditNote> _creditNotes = {};
  final StreamController<List<SaleInvoice>> _salesController = StreamController<List<SaleInvoice>>.broadcast();
  final StreamController<List<CreditNote>> _creditNotesController = StreamController<List<CreditNote>>.broadcast();

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
  }

  List<SaleInvoice> get _currentSalesList => List.unmodifiable(_sales.values);
  List<CreditNote> get _currentCreditNotesList => List.unmodifiable(_creditNotes.values);

  void _notifySales() {
    if (!_salesController.isClosed) {
      _salesController.add(_currentSalesList);
    }
  }

  void _notifyCreditNotes() {
    if (!_creditNotesController.isClosed) {
      _creditNotesController.add(_currentCreditNotesList);
    }
  }

  @override
  Stream<List<SaleInvoice>> watchSales() {
    late StreamController<List<SaleInvoice>> subCtrl;
    StreamSubscription<List<SaleInvoice>>? subscription;
    subCtrl = StreamController<List<SaleInvoice>>.broadcast(
      onListen: () {
        subCtrl.add(_currentSalesList);
        subscription = _salesController.stream.listen(
          (data) {
            if (!subCtrl.isClosed) subCtrl.add(data);
          },
          onError: subCtrl.addError,
          onDone: subCtrl.close,
        );
      },
      onCancel: () => subscription?.cancel(),
    );
    return subCtrl.stream;
  }

  @override
  Future<List<SaleInvoice>> getSales() async => _currentSalesList;

  @override
  Future<SaleInvoice?> getSaleById(String id) async => _sales[id];

  @override
  Future<void> saveSale(SaleInvoice sale) async {
    _sales[sale.id] = sale;
    _notifySales();
  }

  @override
  Stream<List<CreditNote>> watchCreditNotes() {
    late StreamController<List<CreditNote>> subCtrl;
    StreamSubscription<List<CreditNote>>? subscription;
    subCtrl = StreamController<List<CreditNote>>.broadcast(
      onListen: () {
        subCtrl.add(_currentCreditNotesList);
        subscription = _creditNotesController.stream.listen(
          (data) {
            if (!subCtrl.isClosed) subCtrl.add(data);
          },
          onError: subCtrl.addError,
          onDone: subCtrl.close,
        );
      },
      onCancel: () => subscription?.cancel(),
    );
    return subCtrl.stream;
  }

  @override
  Future<List<CreditNote>> getCreditNotes() async => _currentCreditNotesList;

  @override
  Future<CreditNote?> getCreditNoteById(String id) async => _creditNotes[id];

  @override
  Future<void> saveCreditNote(CreditNote creditNote) async {
    _creditNotes[creditNote.id] = creditNote;
    _notifyCreditNotes();
  }

  void dispose() {
    _salesController.close();
    _creditNotesController.close();
  }
}
