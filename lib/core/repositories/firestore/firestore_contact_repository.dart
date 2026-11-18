import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../features/accounts/domain/models/contact.dart';
import '../../../features/accounts/domain/models/statement_entry.dart';
import '../../firebase/firestore_schema.dart';
import '../contact_repository.dart';

class FirestoreContactRepository implements ContactRepository {
  final FirebaseFirestore _firestore;

  FirestoreContactRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _contactsRef =>
      _firestore.collection(FirestoreCollections.contacts);

  CollectionReference<Map<String, dynamic>> get _statementEntriesRef =>
      _firestore.collection(FirestoreCollections.statementEntries);

  @override
  Stream<List<Contact>> watchContacts({ContactType? type}) {
    Query<Map<String, dynamic>> query = _contactsRef;
    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Contact.fromJson(doc.data())).toList();
    });
  }

  @override
  Future<List<Contact>> getContacts({ContactType? type}) async {
    Query<Map<String, dynamic>> query = _contactsRef;
    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Contact.fromJson(doc.data())).toList();
  }

  @override
  Future<Contact?> getContactById(String id) async {
    final doc = await _contactsRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return Contact.fromJson(doc.data()!);
  }

  @override
  Future<void> saveContact(Contact contact) async {
    await _contactsRef.doc(contact.id).set(contact.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> updateBalance({
    required String contactId,
    required double balanceDelta,
  }) async {
    final docRef = _contactsRef.doc(contactId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('Contact $contactId not found in Firestore');
      }
      final currentBalance = (snapshot.data()!['currentBalance'] as num).toDouble();
      final newBalance = currentBalance + balanceDelta;
      transaction.update(docRef, {
        'currentBalance': newBalance,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    });
  }

  @override
  Stream<List<StatementEntry>> watchStatementEntries(String contactId) {
    return _statementEntriesRef
        .where('contactId', isEqualTo: contactId)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => StatementEntry.fromJson(doc.data())).toList();
    });
  }

  @override
  Future<List<StatementEntry>> getStatementEntries(String contactId) async {
    final snapshot = await _statementEntriesRef
        .where('contactId', isEqualTo: contactId)
        .orderBy('date', descending: false)
        .get();
    return snapshot.docs.map((doc) => StatementEntry.fromJson(doc.data())).toList();
  }

  @override
  Future<void> addStatementEntry(StatementEntry entry) async {
    // Statement entries are strictly immutable audit records per Israeli statutory standards
    await _statementEntriesRef.doc(entry.id).set(entry.toJson());
  }
}
