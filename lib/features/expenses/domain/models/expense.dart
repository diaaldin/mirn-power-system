enum ExpenseCategory {
  fuel('דלק', 'وقود / ديزل'),
  maintenance('טיפולים ותיקונים', 'صيانة وتصليح'),
  tires('צמיגים', 'عجلات وإطارات'),
  driverAllowance('אש\"ל נהגים', 'مصروف ومكافأة سائق'),
  licensingInsurance('רישוי וביטוח', 'ترخيص وتأمين'),
  rent('שכירות', 'إيجار'),
  utilities('חשמל ומים', 'كهرباء ومياه'),
  other('אחר', 'مصاريف أخرى');

  final String hebrewLabel;
  final String arabicLabel;
  const ExpenseCategory(this.hebrewLabel, this.arabicLabel);
}

enum ExpensePaymentMethod {
  cash('מזומן', 'نقداً'),
  bankTransfer('העברה בנקאית', 'تحويل بنكي'),
  check('שיק', 'شيك');

  final String hebrewLabel;
  final String arabicLabel;
  const ExpensePaymentMethod(this.hebrewLabel, this.arabicLabel);
}

class Expense {
  final String id;
  final String expenseNumber; // EXP-2026-xxxxx
  final DateTime date;
  final ExpenseCategory category;
  final double amount;
  final String description;
  final String? vehicleId;
  final String? driverId;
  final int? odometerReading;
  final ExpensePaymentMethod paymentMethod;
  final String? reference;
  final String? createdBy;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.expenseNumber,
    required this.date,
    required this.category,
    required this.amount,
    required this.description,
    this.vehicleId,
    this.driverId,
    this.odometerReading,
    required this.paymentMethod,
    this.reference,
    this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expenseNumber': expenseNumber,
      'date': date.toIso8601String(),
      'category': category.name,
      'amount': amount,
      'description': description,
      'vehicleId': vehicleId,
      'driverId': driverId,
      'odometerReading': odometerReading,
      'paymentMethod': paymentMethod.name,
      'reference': reference,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      expenseNumber: json['expenseNumber'] as String,
      date: DateTime.parse(json['date'] as String),
      category: ExpenseCategory.values.byName(json['category'] as String),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      vehicleId: json['vehicleId'] as String?,
      driverId: json['driverId'] as String?,
      odometerReading: (json['odometerReading'] as num?)?.toInt(),
      paymentMethod: ExpensePaymentMethod.values.byName(json['paymentMethod'] as String),
      reference: json['reference'] as String?,
      createdBy: json['createdBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
