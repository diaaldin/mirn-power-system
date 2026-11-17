import 'dart:async';
import '../../../features/accounts/domain/models/contact.dart';
import '../../../features/accounts/domain/models/statement_entry.dart';
import '../contact_repository.dart';

class InMemoryContactRepository implements ContactRepository {
  final Map<String, Contact> _contacts = {};
  final Map<String, List<StatementEntry>> _statements = {};
  final StreamController<List<Contact>> _contactsController = StreamController<List<Contact>>.broadcast();
  final Map<String, StreamController<List<StatementEntry>>> _statementControllers = {};

  InMemoryContactRepository({List<Contact>? initialContacts}) {
    if (initialContacts != null) {
      for (final c in initialContacts) {
        _contacts[c.id] = c;
      }
    }
  }

  List<Contact> get _currentList => List.unmodifiable(_contacts.values);

  void _notifyContacts() {
    if (!_contactsController.isClosed) {
      _contactsController.add(_currentList);
    }
  }

  @override
  Stream<List<Contact>> watchContacts({ContactType? type}) {
    late StreamController<List<Contact>> subCtrl;
    StreamSubscription<List<Contact>>? subscription;
    subCtrl = StreamController<List<Contact>>.broadcast(
      onListen: () {
        final initial = type == null ? _currentList : _currentList.where((c) => c.type == type).toList();
        subCtrl.add(initial);
        subscription = _contactsController.stream.listen(
          (data) {
            if (!subCtrl.isClosed) {
              final filtered = type == null ? data : data.where((c) => c.type == type).toList();
              subCtrl.add(filtered);
            }
          },
          onError: subCtrl.addError,
          onDone: subCtrl.close,
        );
      },
      onCancel: () {
        subscription?.cancel();
      },
    );
    return subCtrl.stream;
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
    _notifyContacts();
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
    _notifyContacts();
  }

  @override
  Stream<List<StatementEntry>> watchStatementEntries(String contactId) {
    late StreamController<List<StatementEntry>> subCtrl;
    StreamSubscription<List<StatementEntry>>? subscription;

    var ctrl = _statementControllers[contactId];
    if (ctrl == null) {
      ctrl = StreamController<List<StatementEntry>>.broadcast();
      _statementControllers[contactId] = ctrl;
    }

    subCtrl = StreamController<List<StatementEntry>>.broadcast(
      onListen: () {
        final currentEntries = List<StatementEntry>.unmodifiable(_statements[contactId] ?? []);
        subCtrl.add(currentEntries);
        subscription = ctrl!.stream.listen(
          (data) {
            if (!subCtrl.isClosed) subCtrl.add(data);
          },
          onError: subCtrl.addError,
          onDone: subCtrl.close,
        );
      },
      onCancel: () {
        subscription?.cancel();
      },
    );
    return subCtrl.stream;
  }

  @override
  Future<List<StatementEntry>> getStatementEntries(String contactId) async {
    return List.unmodifiable(_statements[contactId] ?? []);
  }

  @override
  Future<void> addStatementEntry(StatementEntry entry) async {
    final list = _statements.putIfAbsent(entry.contactId, () => []);
    list.add(entry);
    final snapshot = List<StatementEntry>.unmodifiable(list);
    final ctrl = _statementControllers[entry.contactId];
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.add(snapshot);
    }
  }

  void dispose() {
    _contactsController.close();
    for (final ctrl in _statementControllers.values) {
      ctrl.close();
    }
    _statementControllers.clear();
  }
}
