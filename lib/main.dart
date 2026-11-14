import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'core/localization/app_locale.dart';
import 'core/theme/mirn_theme.dart';
import 'core/utils/currency_formatter.dart';
import 'features/accounts/domain/models/contact.dart';
import 'features/accounts/domain/models/statement_entry.dart';
import 'features/accounts/presentation/screens/statement_screen.dart';
import 'features/checks/domain/models/check_record.dart';
import 'features/checks/presentation/screens/checks_screen.dart';
import 'features/dashboard/presentation/widgets/navigation_shell.dart';
import 'features/inventory/domain/models/product.dart';
import 'features/receipts/domain/models/payment_receipt.dart';
import 'features/receipts/domain/services/receipt_service.dart';
import 'features/sales/domain/models/payment_split.dart';
import 'features/sales/presentation/screens/sales_screen.dart';

void main() {
  runApp(const MirnPowerApp());
}

class MirnPowerApp extends StatefulWidget {
  const MirnPowerApp({super.key});

  @override
  State<MirnPowerApp> createState() => _MirnPowerAppState();
}

class _MirnPowerAppState extends State<MirnPowerApp> {
  AppLanguage _currentLanguage = AppLanguage.arabic;
  int _selectedTabIndex = 0;

  // Mock Products Database
  final List<Product> _products = [
    const Product(
      id: 'prod-001',
      name: 'رخام كلكتا جولد إيطالي / שיש קלקטה גולד',
      sku: 'MRB-CAL-001',
      category: ProductCategory.marble,
      unitType: UnitType.meter,
      meterPerBox: 1.44,
      purchaseCost: 200.0,
      sellingPrice: 280.0,
      currentStock: 420.0,
    ),
    const Product(
      id: 'prod-002',
      name: 'بورسلان إسباني 60x120 سوبر وايت / גרניט פורצלן ספרדי',
      sku: 'CER-ESP-002',
      category: ProductCategory.sanitary,
      unitType: UnitType.meter,
      meterPerBox: 1.44,
      purchaseCost: 95.0,
      sellingPrice: 145.0,
      currentStock: 1250.0,
    ),
    const Product(
      id: 'prod-003',
      name: 'كرسي حمام معلق سمارت أسود مطفي / אסלה תלויה שחורה',
      sku: 'SAN-TOI-003',
      category: ProductCategory.sanitary,
      unitType: UnitType.piece,
      purchaseCost: 1200.0,
      sellingPrice: 1850.0,
      currentStock: 35.0,
    ),
    const Product(
      id: 'prod-004',
      name: 'خلاط مغسلة نحاسي ذهبي فاخر / ברז יוקרתי זהב מוברש',
      sku: 'SAN-TAP-004',
      category: ProductCategory.sanitary,
      unitType: UnitType.piece,
      purchaseCost: 280.0,
      sellingPrice: 480.0,
      currentStock: 50.0,
    ),
  ];

  // Mock Contacts
  final List<Contact> _contacts = [
    const Contact(
      id: 'cust-101',
      name: 'شركة البراق للمقاولات العامة / חברת אל-בוראק לבנייה',
      phone: '052-1234567',
      address: 'رام الله - الماصيون / רמאללה',
      taxId: '515892104',
      type: ContactType.customer,
      currentBalance: 38200.0,
      debtWarningLimit: 50000.0,
    ),
    const Contact(
      id: 'cust-102',
      name: 'مكتب القدس للتصميم المعماري / סטודיו ירושלים לעיצוב',
      phone: '054-9876543',
      address: 'القدس - شارع صلاح الدين / ירושלים',
      taxId: '514392811',
      type: ContactType.customer,
      currentBalance: 12500.0,
      debtWarningLimit: 25000.0,
    ),
  ];

  // Mock Controllers
  late final ChecksScreenController _checksController;
  late final StatementScreenController _statementController;
  final SalesPosController _posController = SalesPosController();

  @override
  void initState() {
    super.initState();
    _checksController = ChecksScreenController(
      initialChecks: [
        CheckRecord(
          id: 'chk-001',
          checkNumber: '10492',
          bankName: 'בנק הפועלים (12)',
          branchNumber: '680',
          accountNumber: '445910',
          amount: 12500.0,
          dueDate: DateTime(2026, 11, 25),
          type: CheckType.received,
          partyId: 'cust-101',
          partyName: 'شركة البراق للمقاولات',
          relatedTransactionId: 'INV-2026-00412',
          status: CheckStatus.pending,
          history: const [],
          createdAt: DateTime(2026, 11, 1),
        ),
        CheckRecord(
          id: 'chk-002',
          checkNumber: '30811',
          bankName: 'בנק לאומי (10)',
          branchNumber: '800',
          accountNumber: '112849',
          amount: 8400.0,
          dueDate: DateTime(2026, 11, 15),
          type: CheckType.received,
          partyId: 'cust-102',
          partyName: 'مكتب القدس للتصميم',
          relatedTransactionId: 'INV-2026-00389',
          status: CheckStatus.deposited,
          history: const [],
          createdAt: DateTime(2026, 10, 20),
        ),
        CheckRecord(
          id: 'chk-003',
          checkNumber: '22019',
          bankName: 'מזרחי טפחות (20)',
          branchNumber: '412',
          accountNumber: '990312',
          amount: 9500.0,
          dueDate: DateTime(2026, 11, 10),
          type: CheckType.received,
          partyId: 'cust-101',
          partyName: 'شركة البراق للمقاولات',
          relatedTransactionId: 'INV-2026-00430',
          status: CheckStatus.bounced,
          history: const [],
          createdAt: DateTime(2026, 10, 5),
        ),
      ],
    );

    _statementController = StatementScreenController(
      contact: _contacts.first,
      allEntries: [
        StatementEntry(
          id: 'st-01',
          contactId: 'cust-101',
          contactType: ContactType.customer,
          date: DateTime(2026, 10, 1),
          referenceNumber: 'INV-2026-00412',
          type: StatementEntryType.saleInvoice,
          description: 'فاتورة مبيعات رخام كلكتا إيطالي',
          debit: 25000.0,
          credit: 0.0,
          runningBalance: 25000.0,
        ),
        StatementEntry(
          id: 'st-02',
          contactId: 'cust-101',
          contactType: ContactType.customer,
          date: DateTime(2026, 10, 15),
          referenceNumber: 'RCP-2026-00108',
          type: StatementEntryType.paymentReceipt,
          description: 'دفعة نقدية وسند قبض',
          debit: 0.0,
          credit: 10000.0,
          runningBalance: 15000.0,
        ),
        StatementEntry(
          id: 'st-03',
          contactId: 'cust-101',
          contactType: ContactType.customer,
          date: DateTime(2026, 11, 5),
          referenceNumber: 'INV-2026-00495',
          type: StatementEntryType.saleInvoice,
          description: 'فاتورة سيراميك وأطقم حمامات',
          debit: 13700.0,
          credit: 0.0,
          runningBalance: 28700.0,
        ),
        StatementEntry(
          id: 'st-04',
          contactId: 'cust-101',
          contactType: ContactType.customer,
          date: DateTime(2026, 11, 10),
          referenceNumber: 'CHK-22019',
          type: StatementEntryType.checkBounced,
          description: 'شيك راجع ללא כיסוי מספיק - إعادة تقييد الذمة',
          debit: 9500.0,
          credit: 0.0,
          runningBalance: 38200.0,
        ),
      ],
    );

    _posController.setCustomer(_contacts.first);
    _posController.addItem(
      product: _products[0],
      quantity: 50.0,
      unit: UnitType.meter,
      unitPriceInput: 327.60,
    );
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(AppColorValues.primaryGold);
    const bgDark = Color(AppColorValues.deepBlack);
    const surfaceDark = Color(AppColorValues.surfaceDark);
    const cardDark = Color(AppColorValues.cardDark);

    return MaterialApp(
      title: 'M.I.R.N POWER Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgDark,
        colorScheme: const ColorScheme.dark(
          primary: goldColor,
          surface: surfaceDark,
        ),
        cardTheme: CardThemeData(
          color: cardDark,
          elevation: MirnThemeConfig.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MirnThemeConfig.defaultBorderRadius),
          ),
        ),
        useMaterial3: true,
      ),
      home: Directionality(
        textDirection: _currentLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: surfaceDark,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: goldColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'M.I.R.N',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'M.I.R.N POWER Management System',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              DropdownButton<AppLanguage>(
                value: _currentLanguage,
                underline: const SizedBox(),
                dropdownColor: surfaceDark,
                items: AppLanguage.values.map((lang) {
                  return DropdownMenuItem(
                    value: lang,
                    child: Text(lang.label, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _currentLanguage = val);
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: _buildCurrentScreen(),
          bottomNavigationBar: NavigationBar(
            backgroundColor: surfaceDark,
            indicatorColor: goldColor.withValues(alpha: 0.25),
            selectedIndex: _selectedTabIndex,
            onDestinationSelected: (idx) => setState(() => _selectedTabIndex = idx),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.dashboard_outlined),
                selectedIcon: const Icon(Icons.dashboard, color: goldColor),
                label: _getNavLabel(AppNavDestination.dashboard),
              ),
              NavigationDestination(
                icon: const Icon(Icons.point_of_sale_outlined),
                selectedIcon: const Icon(Icons.point_of_sale, color: goldColor),
                label: _getNavLabel(AppNavDestination.sales),
              ),
              NavigationDestination(
                icon: const Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: const Icon(Icons.account_balance_wallet, color: goldColor),
                label: _getNavLabel(AppNavDestination.accounts),
              ),
              NavigationDestination(
                icon: const Icon(Icons.fact_check_outlined),
                selectedIcon: const Icon(Icons.fact_check, color: goldColor),
                label: _getNavLabel(AppNavDestination.checks),
              ),
              NavigationDestination(
                icon: const Icon(Icons.local_shipping_outlined),
                selectedIcon: const Icon(Icons.local_shipping, color: goldColor),
                label: _getNavLabel(AppNavDestination.fleet),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getNavLabel(AppNavDestination dest) {
    switch (_currentLanguage) {
      case AppLanguage.arabic:
        return dest.arabicTitle;
      case AppLanguage.hebrew:
        return dest.hebrewTitle;
      case AppLanguage.english:
        return dest.englishTitle;
    }
  }

  Widget _buildCurrentScreen() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildDashboardScreen();
      case 1:
        return _buildSalesPosScreen();
      case 2:
        return _buildStatementScreen();
      case 3:
        return _buildChecksScreen();
      case 4:
        return _buildFleetScreen();
      default:
        return _buildDashboardScreen();
    }
  }

  Widget _buildDashboardScreen() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(
          _currentLanguage == AppLanguage.arabic
              ? 'نظرة عامة ومؤشرات الأداء الرئيسية'
              : _currentLanguage == AppLanguage.hebrew
                  ? 'מבט כללי ומדדי ביצוע מרכזיים'
                  : 'Executive Dashboard & Live KPIs',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildKpiCard(
              title: _currentLanguage == AppLanguage.arabic ? 'مبيعات اليوم' : 'מכירות היום',
              value: formatCurrency(45280.0),
              icon: Icons.trending_up,
              color: const Color(AppColorValues.successGreen),
            ),
            _buildKpiCard(
              title: _currentLanguage == AppLanguage.arabic ? 'فواتير مفتوحة' : 'חשבוניות פתוחות',
              value: '18',
              icon: Icons.receipt_long,
              color: const Color(AppColorValues.primaryGold),
            ),
            _buildKpiCard(
              title: _currentLanguage == AppLanguage.arabic ? 'شيكات قيد التحصيل' : 'שיקים בהמתנה',
              value: formatCurrency(20900.0),
              icon: Icons.access_time,
              color: const Color(AppColorValues.infoBlue),
            ),
            _buildKpiCard(
              title: _currentLanguage == AppLanguage.arabic ? 'ذمم الزبائن الإجمالية' : 'יתרת חוב לקוחות',
              value: formatCurrency(128400.0),
              icon: Icons.warning_amber_rounded,
              color: const Color(AppColorValues.warningOrange),
            ),
            _buildKpiCard(
              title: _currentLanguage == AppLanguage.arabic ? 'تكلفة تشغيل الأسطول/كم' : 'עלות הפעלת צי/ק"מ',
              value: '₪ 4.25 / km',
              icon: Icons.local_shipping,
              color: Colors.teal,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionHeader(
          _currentLanguage == AppLanguage.arabic ? 'إشعارات سريعة وتنبيهات النظام' : 'התראות מערכת מהירות',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: const [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.assignment_late, color: Colors.white, size: 20),
                  ),
                  title: Text('شيك راجع (راجع ללא כיסוי) #22019'),
                  subtitle: Text('تمت إعادة تقييد مبلغ ₪9,500.00 لحساب شركة البراق للمقاولات'),
                  trailing: Text('10/11/2026', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
                Divider(),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(AppColorValues.primaryGold),
                    child: Icon(Icons.inventory, color: Colors.black, size: 20),
                  ),
                  title: Text('تنبيه وصول حد الطلب: رخام كلكتا جولد'),
                  subtitle: Text('المخزون المتبقي: 420 م² (ما يعادل 291 كرتونة)'),
                  trailing: Text('اليوم', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesPosScreen() {
    final state = _posController.state;
    final warning = _posController.evaluateDebtWarning();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _currentLanguage == AppLanguage.arabic ? 'كاونتر المبيعات ونقاط البيع' : 'קופת מכירות',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Text(
                          state.isTaxInclusiveInput
                              ? (_currentLanguage == AppLanguage.arabic ? 'شامل ضريبة 17%' : 'כולל מע"מ 17%')
                              : (_currentLanguage == AppLanguage.arabic ? 'قبل الضريبة' : 'לפני מע"מ'),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Switch(
                          value: state.isTaxInclusiveInput,
                          activeThumbColor: const Color(AppColorValues.primaryGold),
                          onChanged: (val) {
                            setState(() {
                              _posController.setPricingMode(isTaxInclusive: val);
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Contact>(
                  initialValue: state.selectedCustomer ?? _contacts.first,
                  decoration: const InputDecoration(
                    labelText: 'الزبون / לקוח',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _contacts.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text('${c.name} (حساب: ${formatCurrency(c.currentBalance)})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _posController.setCustomer(val);
                    });
                  },
                ),
                if (warning != null && warning.isExceeded) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      border: Border.all(color: Colors.redAccent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'تحذير ائتماني: الزبون سيتجاوز السقف بـ ${formatCurrency(warning.exceededAmount)} '
                            '(الرصيد المتوقع: ${formatCurrency(warning.totalProjectedDebt)})',
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الأصناف في الفاتورة الحالية / פריטים בחשבונית', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...state.items.map((item) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.productName),
                    subtitle: Text('${item.quantity} ${item.unitType.name} × ${formatCurrency(item.unitPrice)}'),
                    trailing: Text(formatCurrency(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                }),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('المجموع الفرعي (قبل الضريبة):'),
                    Text(formatCurrency(state.subtotal)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ضريبة القيمة المضافة (מע"מ 17%):'),
                    Text(formatCurrency(state.vatAmount)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('الإجمالي النهائي (סה"כ לתשלום):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(formatCurrency(state.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(AppColorValues.primaryGold))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatementScreen() {
    final totals = _statementController.getTotals();
    final entries = _statementController.getFilteredEntries();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'كشف حساب: ${_contacts.first.name}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(AppColorValues.primaryGold),
                            foregroundColor: Colors.black,
                          ),
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: const Text('سند قبض جديد / קבלה חדשה'),
                          onPressed: _showNewReceiptDialog,
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(AppColorValues.primaryGold),
                            foregroundColor: Colors.black,
                          ),
                          icon: const Icon(Icons.picture_as_pdf, size: 18),
                          label: const Text('تصدير PDF'),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم توليد كشف الحساب A4 PDF بنجاح وفق المعايير الرسمية')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildBalanceMiniChip('الرصيد الافتتاحي', formatCurrency(totals.openingBalance), Colors.grey),
                    const SizedBox(width: 8),
                    _buildBalanceMiniChip('مجموع المدين (+)', formatCurrency(totals.totalDebits), Colors.orangeAccent),
                    const SizedBox(width: 8),
                    _buildBalanceMiniChip('مجموع الدائن (-)', formatCurrency(totals.totalCredits), Colors.greenAccent),
                    const SizedBox(width: 8),
                    _buildBalanceMiniChip('الرصيد الختامي', formatCurrency(totals.closingBalance), const Color(AppColorValues.primaryGold)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final e = entries[idx];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: e.credit > 0 ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                  child: Icon(
                    e.credit > 0 ? Icons.arrow_downward : Icons.arrow_upward,
                    color: e.credit > 0 ? Colors.greenAccent : Colors.orangeAccent,
                    size: 18,
                  ),
                ),
                title: Text('${e.description} (${e.referenceNumber})'),
                subtitle: Text('${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      e.debit > 0 ? '+${formatCurrency(e.debit)}' : '-${formatCurrency(e.credit)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: e.credit > 0 ? Colors.greenAccent : Colors.orangeAccent,
                      ),
                    ),
                    Text(
                      'رصيد: ${formatCurrency(e.runningBalance)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChecksScreen() {
    final checks = _checksController.filteredChecks;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('سجل الشيكات البنكية وحركات المقاصة / קופת שיקים'),
        const SizedBox(height: 12),
        ...checks.map((c) {
          Color statusColor;
          switch (c.status) {
            case CheckStatus.pending:
              statusColor = Colors.amber;
              break;
            case CheckStatus.deposited:
              statusColor = Colors.blueAccent;
              break;
            case CheckStatus.cleared:
              statusColor = Colors.greenAccent;
              break;
            case CheckStatus.bounced:
              statusColor = Colors.redAccent;
              break;
            case CheckStatus.returned:
              statusColor = Colors.grey;
              break;
            case CheckStatus.endorsed:
              statusColor = Colors.purpleAccent;
              break;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('شيك رقم #${c.checkNumber} - ${c.bankName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('الطرف: ${c.partyName}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          c.status.name.toUpperCase(),
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('استحقاق: ${c.dueDate.year}-${c.dueDate.month}-${c.dueDate.day}'),
                      Text(formatCurrency(c.amount), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(AppColorValues.primaryGold))),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFleetScreen() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('إدارة أسطول الشاحنات وتكلفة الكيلومتر / צי רכב והובלות'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.local_shipping, color: Colors.white),
                  ),
                  title: Text('مرسيدس أكتروس 3340 (شاحنة قلاب 30 طن)'),
                  subtitle: Text('رقم اللوحة: 72-491-88 | السائق: محمود عيسى'),
                  trailing: Text('₪ 4.60 / كم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(AppColorValues.primaryGold))),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    Text('العداد: 142,500 كم'),
                    Text('الوقود: ₪ 18,400'),
                    Text('الصيانة: ₪ 4,600'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: Icon(Icons.local_shipping, color: Colors.white),
                  ),
                  title: Text('فولفو FH16 (قاطرة ومقطورة حجر وبلوكات)'),
                  subtitle: Text('رقم اللوحة: 88-301-22 | السائق: خليل سميح'),
                  trailing: Text('₪ 5.10 / كم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(AppColorValues.primaryGold))),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    Text('العداد: 98,200 كم'),
                    Text('الوقود: ₪ 22,100'),
                    Text('الصيانة: ₪ 3,400'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(AppColorValues.primaryGold)),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 175,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(AppColorValues.cardDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBalanceMiniChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  void _showNewReceiptDialog() {
    final customer = _contacts.first;
    final currentEntriesCount = _statementController.getFilteredEntries().length;
    final nextNumber = 'RCP-2026-${(currentEntriesCount + 109).toString().padLeft(5, '0')}';

    final receiptNumberCtrl = TextEditingController(text: nextNumber);
    final totalAmountCtrl = TextEditingController();
    final cashAmountCtrl = TextEditingController();
    final checkAmountCtrl = TextEditingController();
    final checkNumberCtrl = TextEditingController();
    final bankNameCtrl = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 30));
    String? validationError;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final double rawTotal = double.tryParse(totalAmountCtrl.text.trim()) ?? 0.0;
            final double rawCash = double.tryParse(cashAmountCtrl.text.trim()) ?? 0.0;
            final double rawCheck = double.tryParse(checkAmountCtrl.text.trim()) ?? 0.0;

            final double effectivePayment = rawTotal > 0 ? rawTotal : (rawCash + rawCheck);
            final double projectedBalance = customer.currentBalance - effectivePayment;

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.receipt_long, color: Color(AppColorValues.primaryGold)),
                  SizedBox(width: 8),
                  Text('سند قبض جديد / קבלה חדשה', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'الرصيد الحالي: ${formatCurrency(customer.currentBalance)}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: receiptNumberCtrl,
                              decoration: const InputDecoration(
                                labelText: 'رقم السند / מספר קבלה',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: totalAmountCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'المبلغ الإجمالي / סכום כולל (₪)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(AppColorValues.primaryGold).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(AppColorValues.primaryGold).withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          'الرصيد بعد السداد: ${formatCurrency(projectedBalance)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(AppColorValues.primaryGold),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'تفاصيل الدفع / פירוט תשלום:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: cashAmountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'المبلغ نقداً / מזומן (₪)',
                          prefixIcon: Icon(Icons.money),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: checkAmountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'مبلغ الشيك / סכום שיק (₪)',
                          prefixIcon: Icon(Icons.payment),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: checkNumberCtrl,
                              decoration: const InputDecoration(
                                labelText: 'رقم الشيك / מספר שיק',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: bankNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'اسم البنك / שם הבנק',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dueDate,
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              dueDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade700),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'تاريخ استحقاق الشيك: ${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              const Icon(Icons.calendar_today, size: 16),
                            ],
                          ),
                        ),
                      ),
                      if (validationError != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          validationError!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('إلغاء / ביטול'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppColorValues.primaryGold),
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('إصدار السند وتحديث الكشف'),
                  onPressed: () {
                    final receiptNumber = receiptNumberCtrl.text.trim();
                    if (receiptNumber.isEmpty) {
                      setDialogState(() {
                        validationError = 'يرجى إدخال رقم السند';
                      });
                      return;
                    }

                    double total = double.tryParse(totalAmountCtrl.text.trim()) ?? 0.0;
                    final cash = double.tryParse(cashAmountCtrl.text.trim()) ?? 0.0;
                    final check = double.tryParse(checkAmountCtrl.text.trim()) ?? 0.0;

                    if (total <= 0) {
                      total = cash + check;
                    }

                    if (total <= 0) {
                      setDialogState(() {
                        validationError = 'يرجى إدخال مبلغ صحيح أكبر من الصفر';
                      });
                      return;
                    }

                    final List<ReceiptPaymentItem> payments = [];
                    if (cash > 0) {
                      payments.add(
                        ReceiptPaymentItem(
                          method: PaymentMethod.cash,
                          amount: cash,
                          reference: 'نقداً',
                        ),
                      );
                    }
                    if (check > 0) {
                      final chkNum = checkNumberCtrl.text.trim();
                      final bnk = bankNameCtrl.text.trim();
                      if (chkNum.isEmpty || bnk.isEmpty) {
                        setDialogState(() {
                          validationError = 'يرجى إدخال رقم الشيك واسم البنك';
                        });
                        return;
                      }
                      payments.add(
                        ReceiptPaymentItem(
                          method: PaymentMethod.check,
                          amount: check,
                          checkNumber: chkNum,
                          bankName: bnk,
                          dueDate: dueDate,
                          drawerName: customer.name,
                        ),
                      );
                    }

                    if (payments.isEmpty) {
                      payments.add(
                        ReceiptPaymentItem(
                          method: PaymentMethod.cash,
                          amount: total,
                          reference: 'نقداً',
                        ),
                      );
                    }

                    final allocatedSum = payments.fold<double>(0.0, (s, p) => s + p.amount);
                    if ((allocatedSum - total).abs() > 0.01) {
                      setDialogState(() {
                        validationError =
                            'مجموع طرق الدفع (${formatCurrency(allocatedSum)}) لا يطابق المبلغ الإجمالي (${formatCurrency(total)})';
                      });
                      return;
                    }

                    try {
                      final input = CreateReceiptInput(
                        receiptNumber: receiptNumber,
                        date: DateTime.now(),
                        amount: total,
                        payments: payments,
                        notes: 'سند قبض دفعات على الحساب',
                        createdBy: 'diaaldin',
                      );

                      final result = ReceiptService.processCustomerReceipt(
                        contact: customer,
                        input: input,
                      );

                      setState(() {
                        _contacts[0] = result.updatedContact;
                        _statementController.updateContact(result.updatedContact);
                        _statementController.addEntry(result.statementEntry);
                        for (final chk in result.createdChecks) {
                          _checksController.addCheck(chk);
                        }
                        _posController.setCustomer(result.updatedContact);
                      });

                      Navigator.of(dialogCtx).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'تم إصدار سند القبض رقم ${result.receipt.receiptNumber} بنجاح وتحديث كشف الحساب',
                          ),
                          backgroundColor: const Color(AppColorValues.successGreen),
                        ),
                      );
                    } catch (e) {
                      setDialogState(() {
                        validationError = 'خطأ في معالجة السند: $e';
                      });
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      receiptNumberCtrl.dispose();
      totalAmountCtrl.dispose();
      cashAmountCtrl.dispose();
      checkAmountCtrl.dispose();
      checkNumberCtrl.dispose();
      bankNameCtrl.dispose();
    });
  }
}
