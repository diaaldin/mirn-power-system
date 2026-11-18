import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../features/checks/domain/models/check_record.dart';
import '../../firebase/firestore_schema.dart';
import '../check_repository.dart';

class FirestoreCheckRepository implements CheckRepository {
  final FirebaseFirestore _firestore;

  FirestoreCheckRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _checksRef =>
      _firestore.collection(FirestoreCollections.checks);

  @override
  Stream<List<CheckRecord>> watchChecks() {
    return _checksRef
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CheckRecord.fromJson(doc.data())).toList();
    });
  }

  @override
  Future<List<CheckRecord>> getChecks() async {
    final snapshot = await _checksRef.orderBy('dueDate', descending: false).get();
    return snapshot.docs.map((doc) => CheckRecord.fromJson(doc.data())).toList();
  }

  @override
  Future<CheckRecord?> getCheckById(String id) async {
    final doc = await _checksRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return CheckRecord.fromJson(doc.data()!);
  }

  @override
  Future<void> saveCheck(CheckRecord check) async {
    await _checksRef.doc(check.id).set(check.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> updateCheckStatus(
    String id,
    CheckStatus status, {
    DateTime? date,
    String? note,
  }) async {
    final docRef = _checksRef.doc(id);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('Check $id not found in Firestore');
      }

      final existingCheck = CheckRecord.fromJson(snapshot.data()!);
      final historyEntry = CheckHistoryEntry(
        status: status,
        changedAt: date ?? DateTime.now(),
        notes: note,
      );
      final updatedCheck = existingCheck.copyWith(
        status: status,
        history: [...existingCheck.history, historyEntry],
      );

      transaction.update(docRef, {
        'status': updatedCheck.status.name,
        'history': updatedCheck.history.map((h) => h.toJson()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    });
  }
}
