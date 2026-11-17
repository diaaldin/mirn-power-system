import 'dart:async';
import '../../../features/accounts/domain/models/contact.dart';
import '../../../features/accounts/domain/models/statement_entry.dart';
import '../contact_repository.dart';

class InMemoryContactRepository implements ContactRepository {
  final Map<String, Contact> _contacts = {};
  final Map<String, List<StatementEntry>> _statements = {};
  late final StreamController<List<Contact>> _contactsController;
  final Map<String, StreamController<List<StatementEntry>>> _statementControllers = {};

  InMemoryContactRepository({List<Contact>? initialContacts}) {
    if (initialContacts != null) {
      for (final c in initialContacts) {
        _contacts[c.id] = c;
      }
    }
    _contactsController = StreamController<List<Contact>>.broadcast(
      onListen: () => _contactsController.add(_currentList),
    );
  }

  List<Contact> get _currentList => List.unmodifiable(_contacts.values);

  @override
  Stream<List<Contact>> watchContacts({ContactType? type}) {
    if (type == null) {
      return _contactsController.stream;
    }
    return _contactsController.stream.map(
      (list) => list.where((c) => c.type == type).toList(),
    );
  }

  @override
  Future<List<Contact>> getContacts({ContactType? type}) async {
    if (type == null) return _currentList;
    return _currentList.where((c) => c.type == type).toList();
  }

  @override
  Future<Contact?> getContactById(String id) async => _contacts[id];

  @override
  Future<void> saveContact(Contact contact) async {
    _contacts[contact.id] = contact;
    _contactsController.add(_currentList);
  }

  @override
  Future<void> updateBalance({required String contactId, required double balanceDelta}) async {
    final existing = _contacts[contactId];
    if (existing == null) {
      throw ArgumentError('Contact with id $contactId not found');
    }
    final updated = existing.copyWith(
      currentBalance: existing.currentBalance + balanceDelta,
    );
    _contacts[contactId] = updated;
    _contactsController.add(_currentList);
  }

  @override
  Stream<List<StatementEntry>> watchStatementEntries(String contactId) {
    var ctrl = _statementControllers[contactId];
    if (ctrl == null) {
      ctrl = StreamController<List<StatementEntry>>.broadcast(
        onListen: () => ctrl!.add(List.unmodifiable(_statements[contactId] ?? [])),
      );
      _statementControllers[contactId] = ctrl;
    }
    return ctrl.stream;
  }

  @override
  Future<List<StatementEntry>> getStatementEntries(String contactId) async {
    return List.unmodifiable(_statements[contactId] ?? []);
  }

  @override
  Future<void> addStatementEntry(StatementEntry entry) async {
    final list = _statements.putIfAbsent(entry.contactId, () => []);
    list.add(entry);
    _statementControllers[entry.contactId]?.add(List.unmodifiable(list));
  }

  void dispose() {
    _contactsController.close();
    for (final ctrl in _statementControllers.values) {
      ctrl.close();
    }
    _statementControllers.clear();
  }
}
