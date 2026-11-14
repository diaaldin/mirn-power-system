enum PaymentMethod {
  cash('מזומן', 'نقداً'),
  check('שיק', 'شيك'),
  bankTransfer('העברה בנקאית', 'تحويل بنكي'),
  debt('על החשבון (חוב)', 'على الحساب (ذمة)');

  final String hebrewLabel;
  final String arabicLabel;

  const PaymentMethod(this.hebrewLabel, this.arabicLabel);
}

class PaymentSplit {
  final PaymentMethod method;
  final double amount;
  final String? reference;
  final String? checkId;

  const PaymentSplit({
    required this.method,
    required this.amount,
    this.reference,
    this.checkId,
  });

  Map<String, dynamic> toJson() {
    return {
      'method': method.name,
      'amount': amount,
      'reference': reference,
      'checkId': checkId,
    };
  }

  factory PaymentSplit.fromJson(Map<String, dynamic> json) {
    return PaymentSplit(
      method: PaymentMethod.values.byName(json['method'] as String),
      amount: (json['amount'] as num).toDouble(),
      reference: json['reference'] as String?,
      checkId: json['checkId'] as String?,
    );
  }
}
