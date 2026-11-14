class VatCalculationResult {
  final double subtotal;
  final double vatRate;
  final double vatAmount;
  final double totalAmount;

  const VatCalculationResult({
    required this.subtotal,
    required this.vatRate,
    required this.vatAmount,
    required this.totalAmount,
  });

  @override
  String toString() {
    return 'VatCalculationResult(subtotal: $subtotal, vat: $vatAmount, total: $totalAmount)';
  }
}

class VatCalculator {
  VatCalculator._();

  static const double defaultIsraelVatRate = 0.17; // 17%

  static double _round2(double value) {
    return (value * 100).roundToDouble() / 100.0;
  }

  /// Calculates VAT and total from a Tax-Exclusive price (לפני מע"מ).
  static VatCalculationResult calculateFromExclusive({
    required num subtotalExclusive,
    double vatRate = defaultIsraelVatRate,
  }) {
    final sub = _round2(subtotalExclusive.toDouble());
    final vat = _round2(sub * vatRate);
    final total = _round2(sub + vat);

    return VatCalculationResult(
      subtotal: sub,
      vatRate: vatRate,
      vatAmount: vat,
      totalAmount: total,
    );
  }

  /// Calculates base subtotal and VAT back from a Tax-Inclusive price (כולל מע"מ).
  ///
  /// Guarantees that: `subtotal + vatAmount == totalAmount` exactly to avoid penny discrepancies.
  static VatCalculationResult calculateFromInclusive({
    required num totalInclusive,
    double vatRate = defaultIsraelVatRate,
  }) {
    final total = _round2(totalInclusive.toDouble());

    if (vatRate <= 0.0) {
      return VatCalculationResult(
        subtotal: total,
        vatRate: vatRate,
        vatAmount: 0.0,
        totalAmount: total,
      );
    }

    final sub = _round2(total / (1.0 + vatRate));
    final vat = _round2(total - sub);

    return VatCalculationResult(
      subtotal: sub,
      vatRate: vatRate,
      vatAmount: vat,
      totalAmount: total,
    );
  }

  /// Validates the Israel Tax Authority Allocation Number (מספר הקצאה).
  static bool isValidAllocationNumber(String? allocationNumber) {
    if (allocationNumber == null) return false;
    final trimmed = allocationNumber.trim();
    return trimmed.isNotEmpty;
  }
}
