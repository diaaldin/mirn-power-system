import '../../features/accounts/domain/models/contact.dart';
import '../../features/accounts/domain/models/statement_entry.dart';

abstract class ContactRepository {
  Stream<List<Contact>> watchContacts({ContactType? type});
  Future<List<Contact>> getContacts({ContactType? type});
  Future<Contact?> getContactById(String id);
  Future<void> saveContact(Contact contact);
  Future<void> updateBalance({required String contactId, required double balanceDelta});
  Stream<List<StatementEntry>> watchStatementEntries(String contactId);
  Future<List<StatementEntry>> getStatementEntries(String contactId);
  Future<void> addStatementEntry(StatementEntry entry);
}
