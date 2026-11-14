import 'package:test/test.dart';
import 'package:sales_logistics_system/core/constants/app_colors.dart';
import 'package:sales_logistics_system/features/dashboard/presentation/widgets/navigation_shell.dart';

void main() {
  group('Luxury UI Shell & Navigation System', () {
    test('verifies all 7 core enterprise navigation destinations', () {
      final items = AppNavDestination.values;
      expect(items.length, equals(7));

      expect(AppNavDestination.dashboard.arabicTitle, equals('لوحة التحكم'));
      expect(AppNavDestination.dashboard.hebrewTitle, equals('לוח בקרה'));

      expect(AppNavDestination.sales.arabicTitle, equals('المبيعات ونقاط البيع'));
      expect(AppNavDestination.sales.hebrewTitle, equals('מכירות וקופה'));

      expect(AppNavDestination.inventory.arabicTitle, equals('المستودع والمنتجات'));
      expect(AppNavDestination.inventory.hebrewTitle, equals('מלאי ומוצרים'));

      expect(AppNavDestination.accounts.arabicTitle, equals('كشف الحساب والذمم'));
      expect(AppNavDestination.accounts.hebrewTitle, equals('כרטסת לקוחות וספקים'));

      expect(AppNavDestination.checks.arabicTitle, equals('سجل الشيكات'));
      expect(AppNavDestination.checks.hebrewTitle, equals('קופת שיקים'));

      expect(AppNavDestination.fleet.arabicTitle, equals('الأسطول والنقل'));
      expect(AppNavDestination.fleet.hebrewTitle, equals('צי רכב והובלות'));

      expect(AppNavDestination.reports.arabicTitle, equals('التقارير المالية'));
      expect(AppNavDestination.reports.hebrewTitle, equals('דוחות ורווחיות'));
    });

    test('verifies responsive desktop breakpoint threshold', () {
      expect(NavigationLayoutHelper.isDesktop(1200), isTrue);
      expect(NavigationLayoutHelper.isDesktop(899), isFalse);
      expect(NavigationLayoutHelper.isMobile(600), isTrue);
    });

    test('verifies branding color codes for luxury gold and charcoal', () {
      expect(AppColorValues.primaryGold, equals(0xFFC5A059));
      expect(AppColorValues.deepBlack, equals(0xFF121214));
      expect(AppColorValues.charcoalBlack, equals(0xFF1E1E24));
    });
  });
}
