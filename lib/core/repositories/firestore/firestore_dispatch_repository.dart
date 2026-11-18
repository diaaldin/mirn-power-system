import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../features/logistics/domain/models/dispatch.dart';
import '../../firebase/firestore_schema.dart';
import '../dispatch_repository.dart';

class FirestoreDispatchRepository implements DispatchRepository {
  final FirebaseFirestore _firestore;

  FirestoreDispatchRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _dispatchesRef =>
      _firestore.collection(FirestoreCollections.dispatches);

  @override
  Stream<List<Dispatch>> watchDispatches() {
    return _dispatchesRef
        .orderBy('dispatchedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Dispatch.fromJson(doc.data())).toList();
    });
  }

  @override
  Future<List<Dispatch>> getDispatches() async {
    final snapshot = await _dispatchesRef.orderBy('dispatchedAt', descending: true).get();
    return snapshot.docs.map((doc) => Dispatch.fromJson(doc.data())).toList();
  }

  @override
  Future<Dispatch?> getDispatchById(String id) async {
    final doc = await _dispatchesRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return Dispatch.fromJson(doc.data()!);
  }

  @override
  Future<void> saveDispatch(Dispatch dispatch) async {
    await _dispatchesRef.doc(dispatch.id).set(dispatch.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> updateDispatchStatus(
    String id,
    DispatchStatus status, {
    String? notes,
  }) async {
    final updateData = <String, dynamic>{
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (notes != null) {
      updateData['notes'] = notes;
    }
    await _dispatchesRef.doc(id).update(updateData);
  }
}
