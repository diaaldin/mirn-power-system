import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../features/inventory/domain/models/product.dart';
import '../../firebase/firestore_schema.dart';
import '../product_repository.dart';

class FirestoreProductRepository implements ProductRepository {
  final FirebaseFirestore _firestore;

  FirestoreProductRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection(FirestoreCollections.products);

  @override
  Stream<List<Product>> watchProducts() {
    return _productsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromJson(doc.data())).toList();
    });
  }

  @override
  Future<List<Product>> getProducts() async {
    final snapshot = await _productsRef.get();
    return snapshot.docs.map((doc) => Product.fromJson(doc.data())).toList();
  }

  @override
  Future<Product?> getProductById(String id) async {
    final doc = await _productsRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return Product.fromJson(doc.data()!);
  }

  @override
  Future<void> saveProduct(Product product) async {
    await _productsRef.doc(product.id).set(product.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> updateStock({
    required String productId,
    required double stockDelta,
  }) async {
    final docRef = _productsRef.doc(productId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('Product $productId not found in Firestore');
      }
      final currentStock = (snapshot.data()!['currentStock'] as num).toDouble();
      final newStock = currentStock + stockDelta;
      if (newStock < -0.0001) {
        throw StateError('Insufficient stock for product $productId (available: $currentStock, delta: $stockDelta)');
      }
      transaction.update(docRef, {
        'currentStock': newStock,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    });
  }
}
