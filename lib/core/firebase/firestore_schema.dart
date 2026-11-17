class FirestoreCollections {
  FirestoreCollections._();

  static const String products = 'products';
  static const String contacts = 'contacts';
  static const String sales = 'sales';
  static const String creditNotes = 'credit_notes';
  static const String checks = 'checks';
  static const String purchases = 'purchases';
  static const String dispatches = 'dispatches';
  static const String expenses = 'expenses';
  static const String statementEntries = 'statement_entries';
  static const String counters = 'counters';
  static const String users = 'users';

  static String productPath(String id) => '$products/$id';
  static String contactPath(String id) => '$contacts/$id';
  static String salePath(String id) => '$sales/$id';
  static String creditNotePath(String id) => '$creditNotes/$id';
  static String checkPath(String id) => '$checks/$id';
  static String purchasePath(String id) => '$purchases/$id';
  static String dispatchPath(String id) => '$dispatches/$id';
  static String expensePath(String id) => '$expenses/$id';
  static String statementEntryPath(String id) => '$statementEntries/$id';
  static String userPath(String id) => '$users/$id';
}
