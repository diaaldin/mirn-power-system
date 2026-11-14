enum CheckType {
  received('התקבל מלקוח', 'وارد من عميل'),
  issued('נמסר לספק', 'صادر لمورد');

  final String hebrewLabel;
  final String arabicLabel;
  const CheckType(this.hebrewLabel, this.arabicLabel);
}

enum CheckStatus {
  pending('ממתין', 'قيد الانتظار'),
  deposited('הופקד בבנק', 'مودع بالبنك'),
  cleared('נפרע בהצלחה', 'مصروف / محصّل'),
  bounced('חזר ללא כיסוי', 'مرتجع / راجع'),
  returned('הוחזר ללקוח', 'معاد للساحب'),
  endorsed('הוסב לצד ג\'', 'مجير لمورد');

  final String hebrewLabel;
  final String arabicLabel;
  const CheckStatus(this.hebrewLabel, this.arabicLabel);
}

class CheckHistoryEntry {
  final CheckStatus status;
  final DateTime changedAt;
  final String? notes;
  final String? changedBy;

  const CheckHistoryEntry({
    required this.status,
    required this.changedAt,
    this.notes,
    this.changedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'changedAt': changedAt.toIso8601String(),
      'notes': notes,
      'changedBy': changedBy,
    };
  }

  factory CheckHistoryEntry.fromJson(Map<String, dynamic> json) {
    return CheckHistoryEntry(
      status: CheckStatus.values.byName(json['status'] as String),
      changedAt: DateTime.parse(json['changedAt'] as String),
      notes: json['notes'] as String?,
      changedBy: json['changedBy'] as String?,
    );
  }
}

class CheckRecord {
  final String id;
  final String checkNumber;
  final String bankName;
  final String branchNumber;
  final String accountNumber;
  final double amount;
  final DateTime dueDate;
  final CheckType type;
  final String partyId;
  final String partyName;
  final String relatedTransactionId;
  final CheckStatus status;
  final String? endorsedToPartyId;
  final List<CheckHistoryEntry> history;
  final DateTime createdAt;

  const CheckRecord({
    required this.id,
    required this.checkNumber,
    required this.bankName,
    required this.branchNumber,
    required this.accountNumber,
    required this.amount,
    required this.dueDate,
    required this.type,
    required this.partyId,
    required this.partyName,
    required this.relatedTransactionId,
    required this.status,
    this.endorsedToPartyId,
    required this.history,
    required this.createdAt,
  });

  CheckRecord copyWith({
    String? id,
    String? checkNumber,
    String? bankName,
    String? branchNumber,
    String? accountNumber,
    double? amount,
    DateTime? dueDate,
    CheckType? type,
    String? partyId,
    String? partyName,
    String? relatedTransactionId,
    CheckStatus? status,
    String? endorsedToPartyId,
    List<CheckHistoryEntry>? history,
    DateTime? createdAt,
  }) {
    return CheckRecord(
      id: id ?? this.id,
      checkNumber: checkNumber ?? this.checkNumber,
      bankName: bankName ?? this.bankName,
      branchNumber: branchNumber ?? this.branchNumber,
      accountNumber: accountNumber ?? this.accountNumber,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      type: type ?? this.type,
      partyId: partyId ?? this.partyId,
      partyName: partyName ?? this.partyName,
      relatedTransactionId: relatedTransactionId ?? this.relatedTransactionId,
      status: status ?? this.status,
      endorsedToPartyId: endorsedToPartyId ?? this.endorsedToPartyId,
      history: history ?? this.history,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'checkNumber': checkNumber,
      'bankName': bankName,
      'branchNumber': branchNumber,
      'accountNumber': accountNumber,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'type': type.name,
      'partyId': partyId,
      'partyName': partyName,
      'relatedTransactionId': relatedTransactionId,
      'status': status.name,
      'endorsedToPartyId': endorsedToPartyId,
      'history': history.map((h) => h.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CheckRecord.fromJson(Map<String, dynamic> json) {
    return CheckRecord(
      id: json['id'] as String,
      checkNumber: json['checkNumber'] as String,
      bankName: json['bankName'] as String,
      branchNumber: json['branchNumber'] as String,
      accountNumber: json['accountNumber'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['dueDate'] as String),
      type: CheckType.values.byName(json['type'] as String),
      partyId: json['partyId'] as String,
      partyName: json['partyName'] as String,
      relatedTransactionId: json['relatedTransactionId'] as String,
      status: CheckStatus.values.byName(json['status'] as String),
      endorsedToPartyId: json['endorsedToPartyId'] as String?,
      history: (json['history'] as List)
          .map((h) => CheckHistoryEntry.fromJson(h as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
