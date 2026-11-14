import 'package:test/test.dart';
import 'package:sales_logistics_system/features/sales/domain/services/vat_calculator.dart';

void main() {
  group('Israel VAT Calculation Engine', () {
    const defaultVatRate = 0.17; // 17% standard Israeli VAT

    test('calculates from Tax-Exclusive (before VAT) input', () {
      final result = VatCalculator.calculateFromExclusive(
        subtotalExclusive: 100.0,
        vatRate: defaultVatRate,
      );

      expect(result.subtotal, equals(100.0));
      expect(result.vatAmount, equals(17.0));
      expect(result.totalAmount, equals(117.0));
      expect(result.vatRate, equals(0.17));
    });

    test('calculates from Tax-Inclusive (כולל מע"מ) input with exact penny back-calculation', () {
      final result = VatCalculator.calculateFromInclusive(
        totalInclusive: 117.0,
        vatRate: defaultVatRate,
      );

      expect(result.subtotal, equals(100.0));
      expect(result.vatAmount, equals(17.0));
      expect(result.totalAmount, equals(117.0));
    });

    test('preserves exact arithmetic equality on fractional divisions (100.00 inclusive)', () {
      // 100 / 1.17 = 85.470085... -> rounded subtotal: 85.47
      // vatAmount = total - subtotal = 14.53
      // subtotal + vatAmount MUST equal exactly 100.00 without floating point drift
      final result = VatCalculator.calculateFromInclusive(
        totalInclusive: 100.0,
        vatRate: defaultVatRate,
      );

      expect(result.subtotal, equals(85.47));
      expect(result.vatAmount, equals(14.53));
      expect(result.totalAmount, equals(100.00));
      expect(((result.subtotal + result.vatAmount) * 100).round() / 100, equals(100.00));
    });

    test('handles zero amounts and custom VAT rates cleanly', () {
      final zeroResult = VatCalculator.calculateFromExclusive(
        subtotalExclusive: 0.0,
        vatRate: defaultVatRate,
      );
      expect(zeroResult.subtotal, equals(0.0));
      expect(zeroResult.vatAmount, equals(0.0));
      expect(zeroResult.totalAmount, equals(0.0));

      final zeroVatResult = VatCalculator.calculateFromInclusive(
        totalInclusive: 500.0,
        vatRate: 0.0, // Eilat tax-free zone
      );
      expect(zeroVatResult.subtotal, equals(500.0));
      expect(zeroVatResult.vatAmount, equals(0.0));
      expect(zeroVatResult.totalAmount, equals(500.0));
    });

    test('validates Israel Tax Authority Allocation Number (מספר הקצאה)', () {
      expect(VatCalculator.isValidAllocationNumber('123456789'), isTrue);
      expect(VatCalculator.isValidAllocationNumber(''), isFalse);
      expect(VatCalculator.isValidAllocationNumber(null), isFalse);
    });
  });
}
