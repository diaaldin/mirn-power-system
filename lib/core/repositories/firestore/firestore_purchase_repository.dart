import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../features/purchases/domain/models/purchase_invoice.dart';
import '../../firebase/firestore_schema.dart';
import '../purchase_repository.dart';

class FirestorePurchaseRepository implements PurchaseRepository {
  final FirebaseFirestore _firestore;

  FirestorePurchaseRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _purchasesRef =>
      _firestore.collection(FirestoreCollections.purchases);

  @override
  Stream<List<PurchaseInvoice>> watchPurchases() {
    return _purchasesRef
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PurchaseInvoice.fromJson(doc.data())).toList();
    });
  }

  @override
  Future<List<PurchaseInvoice>> getPurchases() async {
    final snapshot = await _purchasesRef.orderBy('date', descending: true).get();
    return snapshot.docs.map((doc) => PurchaseInvoice.fromJson(doc.data())).toList();
  }

  @override
  Future<PurchaseInvoice?> getPurchaseById(String id) async {
    final doc = await _purchasesRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return PurchaseInvoice.fromJson(doc.data()!);
  }

  @override
  Future<void> savePurchase(PurchaseInvoice purchase) async {
    // Purchase Invoices are statutory expense documents
    await _purchasesRef.doc(purchase.id).set(purchase.toJson());
  }
}
