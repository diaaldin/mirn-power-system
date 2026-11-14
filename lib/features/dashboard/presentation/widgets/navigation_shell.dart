enum AppNavDestination {
  dashboard(
    hebrewTitle: 'לוח בקרה',
    arabicTitle: 'لوحة التحكم',
    englishTitle: 'Dashboard',
    route: '/dashboard',
  ),
  sales(
    hebrewTitle: 'מכירות וקופה',
    arabicTitle: 'المبيعات ونقاط البيع',
    englishTitle: 'Sales & POS',
    route: '/sales',
  ),
  inventory(
    hebrewTitle: 'מלאי ומוצרים',
    arabicTitle: 'المستودع والمنتجات',
    englishTitle: 'Inventory',
    route: '/inventory',
  ),
  accounts(
    hebrewTitle: 'כרטסת לקוחות וספקים',
    arabicTitle: 'كشف الحساب والذمم',
    englishTitle: 'Accounts & Ledgers',
    route: '/accounts',
  ),
  checks(
    hebrewTitle: 'קופת שיקים',
    arabicTitle: 'سجل الشيكات',
    englishTitle: 'Check Registry',
    route: '/checks',
  ),
  fleet(
    hebrewTitle: 'צי רכב והובלות',
    arabicTitle: 'الأسطول والنقل',
    englishTitle: 'Fleet & Logistics',
    route: '/fleet',
  ),
  reports(
    hebrewTitle: 'דוחות ורווחיות',
    arabicTitle: 'التقارير المالية',
    englishTitle: 'Reports',
    route: '/reports',
  );

  final String hebrewTitle;
  final String arabicTitle;
  final String englishTitle;
  final String route;

  const AppNavDestination({
    required this.hebrewTitle,
    required this.arabicTitle,
    required this.englishTitle,
    required this.route,
  });
}

class NavigationLayoutHelper {
  NavigationLayoutHelper._();

  static const double desktopBreakpoint = 900.0;

  static bool isDesktop(num screenWidth) {
    return screenWidth >= desktopBreakpoint;
  }

  static bool isMobile(num screenWidth) {
    return screenWidth < desktopBreakpoint;
  }
}
