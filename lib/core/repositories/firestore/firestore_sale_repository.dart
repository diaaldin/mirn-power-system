import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../features/sales/domain/models/sale_invoice.dart';
import '../../../features/returns/domain/models/credit_note.dart';
import '../../firebase/firestore_schema.dart';
import '../sale_repository.dart';

class FirestoreSaleRepository implements SaleRepository {
  final FirebaseFirestore _firestore;

  FirestoreSaleRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _salesRef =>
      _firestore.collection(FirestoreCollections.sales);

  CollectionReference<Map<String, dynamic>> get _creditNotesRef =>
      _firestore.collection(FirestoreCollections.creditNotes);

  @override
  Stream<List<SaleInvoice>> watchSales() {
    return _salesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => SaleInvoice.fromJson(doc.data())).toList();
    });
  }

  @override
  Future<List<SaleInvoice>> getSales() async {
    final snapshot = await _salesRef.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => SaleInvoice.fromJson(doc.data())).toList();
  }

  @override
  Future<SaleInvoice?> getSaleById(String id) async {
    final doc = await _salesRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return SaleInvoice.fromJson(doc.data()!);
  }

  @override
  Future<void> saveSale(SaleInvoice sale) async {
    // Tax Invoices are immutable statutory documents per Israeli law
    await _salesRef.doc(sale.id).set(sale.toJson());
  }

  @override
  Stream<List<CreditNote>> watchCreditNotes() {
    return _creditNotesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CreditNote.fromJson(doc.data())).toList();
    });
  }

  @override
  Future<List<CreditNote>> getCreditNotes() async {
    final snapshot = await _creditNotesRef.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => CreditNote.fromJson(doc.data())).toList();
  }

  @override
  Future<CreditNote?> getCreditNoteById(String id) async {
    final doc = await _creditNotesRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return CreditNote.fromJson(doc.data()!);
  }

  @override
  Future<void> saveCreditNote(CreditNote creditNote) async {
    // Credit notes are immutable statutory documents
    await _creditNotesRef.doc(creditNote.id).set(creditNote.toJson());
  }
}
