import 'package:test/test.dart';
import 'package:sales_logistics_system/core/utils/currency_formatter.dart';
import 'package:sales_logistics_system/core/localization/app_locale.dart';

void main() {
  group('Currency Formatter Tests', () {
    test('formats positive amounts with ILS symbol and 2 decimal places', () {
      expect(formatCurrency(1250.5), equals('₪1,250.50'));
      expect(formatCurrency(0), equals('₪0.00'));
      expect(formatCurrency(1000000.75), equals('₪1,000,000.75'));
    });

    test('formats negative amounts cleanly', () {
      expect(formatCurrency(-500.0), equals('-₪500.00'));
    });
  });

  group('Localization Tests', () {
    test('verifies language codes and RTL directionality', () {
      expect(AppLanguage.arabic.code, equals('ar'));
      expect(AppLanguage.arabic.isRtl, isTrue);

      expect(AppLanguage.hebrew.code, equals('he'));
      expect(AppLanguage.hebrew.isRtl, isTrue);

      expect(AppLanguage.english.code, equals('en'));
      expect(AppLanguage.english.isRtl, isFalse);
    });
  });
}
