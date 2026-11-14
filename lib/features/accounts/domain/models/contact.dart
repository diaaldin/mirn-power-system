enum ContactType {
  customer,
  supplier,
  both;

  String get displayName {
    switch (this) {
      case ContactType.customer:
        return 'לקוח / زبون';
      case ContactType.supplier:
        return 'ספק / مورد';
      case ContactType.both:
        return 'לקוח וספק / زبون ومورد';
    }
  }
}

class Contact {
  final String id;
  final ContactType type;
  final String name;
  final String phone;
  final String address;
  final String taxId;
  final double debtWarningLimit;
  final double currentBalance;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Contact({
    required this.id,
    required this.type,
    required this.name,
    required this.phone,
    required this.address,
    required this.taxId,
    required this.debtWarningLimit,
    required this.currentBalance,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  bool get isDebtor => currentBalance > 0;
  bool get isCreditor => currentBalance < 0;

  Contact copyWith({
    String? id,
    ContactType? type,
    String? name,
    String? phone,
    String? address,
    String? taxId,
    double? debtWarningLimit,
    double? currentBalance,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contact(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      taxId: taxId ?? this.taxId,
      debtWarningLimit: debtWarningLimit ?? this.debtWarningLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'phone': phone,
      'address': address,
      'taxId': taxId,
      'debtWarningLimit': debtWarningLimit,
      'currentBalance': currentBalance,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      type: ContactType.values.byName(json['type'] as String),
      name: json['name'] as String,
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      taxId: json['taxId'] as String? ?? '',
      debtWarningLimit: (json['debtWarningLimit'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }
}
