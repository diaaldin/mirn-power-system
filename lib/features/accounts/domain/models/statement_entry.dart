import 'contact.dart';

enum StatementEntryType {
  saleInvoice('חשבונית מס / فاتورة مبيعات'),
  creditNote('חשבונית זיכוי / فاتورة إرجاع'),
  paymentReceipt('קבלה / سند قبض'),
  checkBounced('שיק חוזר / شيك راجع'),
  purchaseInvoice('חשבונית רכש / فاتورة مشتريات'),
  supplierPayment('תשלום לספק / سند صرف'),
  adjustment('התאמה ידנית / تسوية رصيد');

  final String localizedName;
  const StatementEntryType(this.localizedName);
}

class StatementEntry {
  final String id;
  final String contactId;
  final ContactType contactType;
  final DateTime date;
  final StatementEntryType type;
  final String referenceNumber;
  final double debit;
  final double credit;
  final double runningBalance;
  final String description;

  const StatementEntry({
    required this.id,
    required this.contactId,
    required this.contactType,
    required this.date,
    required this.type,
    required this.referenceNumber,
    required this.debit,
    required this.credit,
    required this.runningBalance,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contactId': contactId,
      'contactType': contactType.name,
      'date': date.toIso8601String(),
      'type': type.name,
      'referenceNumber': referenceNumber,
      'debit': debit,
      'credit': credit,
      'runningBalance': runningBalance,
      'description': description,
    };
  }

  factory StatementEntry.fromJson(Map<String, dynamic> json) {
    return StatementEntry(
      id: json['id'] as String,
      contactId: json['contactId'] as String,
      contactType: ContactType.values.byName(json['contactType'] as String),
      date: DateTime.parse(json['date'] as String),
      type: StatementEntryType.values.byName(json['type'] as String),
      referenceNumber: json['referenceNumber'] as String,
      debit: (json['debit'] as num).toDouble(),
      credit: (json['credit'] as num).toDouble(),
      runningBalance: (json['runningBalance'] as num).toDouble(),
      description: json['description'] as String,
    );
  }
}
