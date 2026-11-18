enum UserRole {
  admin('מנהל מערכת', 'مدير النظام'),
  accountant('רואה חשבון / מנהל כספים', 'محاسب / مدير مالي'),
  cashier('קופאי / נציג מכירות', 'كاشير / موظف مبيعات'),
  dispatcher('סדרן עבודה / מנהל צי', 'سيدر نقليات / مأمور شحن');

  final String hebrewLabel;
  final String arabicLabel;

  const UserRole(this.hebrewLabel, this.arabicLabel);
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? pinCode;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.pinCode,
    this.isActive = true,
    this.createdAt,
    this.lastLoginAt,
  });

  // Permissions (RBAC)
  bool get canAccessPos => role == UserRole.admin || role == UserRole.cashier;
  bool get canManageChecks => role == UserRole.admin || role == UserRole.accountant;
  bool get canApproveCreditNotes => role == UserRole.admin || role == UserRole.accountant;
  bool get canManageLedgers => role == UserRole.admin || role == UserRole.accountant;
  bool get canManagePurchases => role == UserRole.admin || role == UserRole.accountant;
  bool get canDispatchFleet => role == UserRole.admin || role == UserRole.dispatcher;
  bool get canRecordExpenses =>
      role == UserRole.admin || role == UserRole.accountant || role == UserRole.dispatcher;
  bool get canViewReports => role == UserRole.admin || role == UserRole.accountant;
  bool get canAdministerUsers => role == UserRole.admin;

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? pinCode,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      pinCode: pinCode ?? this.pinCode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'pinCode': pinCode,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.values.byName(json['role'] as String),
      pinCode: json['pinCode'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
    );
  }
}
