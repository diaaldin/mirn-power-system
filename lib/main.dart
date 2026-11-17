import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'core/localization/app_locale.dart';
import 'core/pdf/delivery_note_pdf_generator.dart';
import 'core/pdf/expense_pdf_generator.dart';
import 'core/pdf/invoice_pdf_generator.dart';
import 'core/pdf/purchase_pdf_generator.dart';
import 'core/theme/mirn_theme.dart';
import 'core/utils/currency_formatter.dart';
import 'features/accounts/domain/models/contact.dart';
import 'features/accounts/domain/models/statement_entry.dart';
import 'features/accounts/presentation/screens/statement_screen.dart';
import 'features/checks/domain/models/check_record.dart';
import 'features/checks/presentation/screens/checks_screen.dart';
import 'features/dashboard/presentation/widgets/navigation_shell.dart';
import 'features/expenses/domain/models/expense.dart';
import 'features/expenses/domain/services/expense_service.dart';
import 'features/expenses/presentation/controllers/expenses_controller.dart';
import 'features/fleet/domain/models/driver.dart';
import 'features/fleet/domain/models/vehicle.dart';
import 'features/inventory/domain/models/product.dart';
import 'features/inventory/domain/services/unit_converter.dart';
import 'features/logistics/domain/models/dispatch.dart';
import 'features/logistics/domain/services/dispatch_service.dart';
import 'features/logistics/presentation/controllers/fleet_dispatch_controller.dart';
import 'features/purchases/domain/models/purchase_invoice.dart';
import 'features/purchases/domain/services/purchase_service.dart';
import 'features/purchases/presentation/controllers/purchases_controller.dart';
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
    const Contact(
      id: 'supp-201',
      name: 'محاجر القدس وشركة الرخام / מחצבות ירושלים בע"מ',
      phone: '02-5819000',
      address: 'القدس - المنطقة الصناعية عطروت / אזור תעשייה עטרות',
      taxId: '512938475',
      type: ContactType.supplier,
      currentBalance: 45000.0,
      debtWarningLimit: 100000.0,
    ),
    const Contact(
      id: 'supp-202',
      name: 'سيراميك ومستوردات المتوسط ش.م.م / קרמיקה הים התיכון בע"מ',
      phone: '03-6821234',
      address: 'تل أبيب - شارع هرצל / תל אביב',
      taxId: '513847291',
      type: ContactType.supplier,
      currentBalance: 28500.0,
      debtWarningLimit: 75000.0,
    ),
  ];

  // Mock Purchase Invoices
  final List<PurchaseInvoice> _purchaseInvoices = [
    PurchaseInvoice(
      id: 'PUR-2026-00098',
      invoiceNumber: 'PUR-2026-00098',
      supplierInvoiceNumber: 'INV-SUP-8821',
      date: DateTime(2026, 11, 8),
      supplierId: 'supp-201',
      supplierName: 'محاجر القدس وشركة الرخام / מחצבות ירושלים בע"מ',
      supplierTaxId: '512938475',
      items: [
        PurchaseLineItem(
          productId: 'prod-001',
          productName: 'رخام كلكتا جولد إيطالي / שיش קלקטה גולד',
          unitType: UnitType.meter,
          quantity: 150.0,
          unitCost: 195.0,
          subtotal: 29250.0,
          convertedStockQuantity: 150.0,
        ),
      ],
      subtotal: 29250.0,
      vatRate: 0.17,
      vatAmount: 4972.50,
      totalAmount: 34222.50,
      paidAmount: 0.0,
      onAccountAmount: 34222.50,
      createdBy: 'diaaldin',
      createdAt: DateTime(2026, 11, 8),
    ),
    PurchaseInvoice(
      id: 'PUR-2026-00099',
      invoiceNumber: 'PUR-2026-00099',
      supplierInvoiceNumber: 'TX-2026-4401',
      date: DateTime(2026, 11, 12),
      supplierId: 'supp-202',
      supplierName: 'سيراميك ومستوردات المتوسط ش.م.م / קרמיקה הים התיכון בע"מ',
      supplierTaxId: '513847291',
      items: [
        PurchaseLineItem(
          productId: 'prod-003',
          productName: 'كرسي حمام معلق سمارت أسود مطفي / אסלה תלויה שחורה',
          unitType: UnitType.piece,
          quantity: 20.0,
          unitCost: 1150.0,
          subtotal: 23000.0,
          convertedStockQuantity: 20.0,
        ),
      ],
      subtotal: 23000.0,
      vatRate: 0.17,
      vatAmount: 3910.0,
      totalAmount: 26910.0,
      paidAmount: 26910.0,
      onAccountAmount: 0.0,
      createdBy: 'diaaldin',
      createdAt: DateTime(2026, 11, 12),
    ),
  ];

  // Mock Fleet & Dispatches
  final List<Vehicle> _vehicles = [
    const Vehicle(
      id: 'veh-01',
      name: 'مرسيدس أكتروس 3340 (شاحنة قلاب 30 طن) / מרצדס אקטרוס',
      plateNumber: '72-491-88',
      modelYear: 2021,
      currentOdometer: 142800,
      status: VehicleStatus.active,
      notes: 'قلاب تفريغ خلفي - مخصصة للصخور والأتربة',
    ),
    const Vehicle(
      id: 'veh-02',
      name: 'فولفو FH16 (قاطرة ومقطورة حجر وبلوكات) / וולוו פול-טריילר',
      plateNumber: '88-301-22',
      modelYear: 2023,
      currentOdometer: 98200,
      status: VehicleStatus.active,
      notes: 'مقطورة مسطحة مع رافعة شوكية خلفية',
    ),
    const Vehicle(
      id: 'veh-03',
      name: 'إيسوزو ريفارد 7.5 طن (توزيع سيراميك وصحي) / איסוזו חלוקה',
      plateNumber: '55-123-90',
      modelYear: 2020,
      currentOdometer: 184000,
      status: VehicleStatus.maintenance,
      notes: 'صيانة دورية للمكابح والإطارات',
    ),
  ];

  final List<Driver> _drivers = [
    const Driver(
      id: 'drv-01',
      fullName: 'محمود عيسى / מחמוד עיסא',
      phone: '052-9876543',
      licenseNumber: 'LIC-88192',
      status: DriverStatus.active,
      notes: 'رخصة شحن ثقيل فوق 15 طن',
    ),
    const Driver(
      id: 'drv-02',
      fullName: 'خليل سميح / חליל סמיח',
      phone: '054-3210987',
      licenseNumber: 'LIC-55421',
      status: DriverStatus.active,
      notes: 'رخصة قاطرة ومقطورة (E)',
    ),
    const Driver(
      id: 'drv-03',
      fullName: 'إبراهيم ناصر / אבראהים נאצר',
      phone: '050-7654321',
      licenseNumber: 'LIC-99302',
      status: DriverStatus.inactive,
      notes: 'إجازة سنوية',
    ),
  ];

  // Mock Controllers
  late final ChecksScreenController _checksController;
  late final StatementScreenController _statementController;
  late final FleetDispatchController _fleetController;
  late final ExpensesController _expensesController;
  int _fleetSubTabIndex = 0;
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

    final initialDispatches = [
      Dispatch(
        id: 'DSP-2026-00001',
        dispatchNumber: 'DSP-2026-00001',
        date: DateTime(2026, 11, 14, 10, 0),
        saleId: 'sale-001',
        invoiceNumber: 'INV-2026-00412',
        customerId: 'cust-101',
        customerName: 'شركة البراق للمقاولات / חברת אל-בוראק',
        customerPhone: '052-1234567',
        deliveryAddress: 'رام الله - حي الماصيون / רמאללה',
        cargoDescription: '150 م² رخام كرارا + 4 كراسي حمام جروهي',
        vehicleId: 'veh-01',
        vehicleName: 'مرسيدس أكتروس 3340',
        plateNumber: '72-491-88',
        driverId: 'drv-01',
        driverName: 'محمود عيسى',
        status: DispatchStatus.dispatched,
        notes: 'توصيل موقع البرج الطابق الأرضي',
        updatedAt: DateTime(2026, 11, 14, 10, 30),
      ),
      Dispatch(
        id: 'DSP-2026-00002',
        dispatchNumber: 'DSP-2026-00002',
        date: DateTime(2026, 11, 14, 8, 30),
        saleId: 'sale-002',
        invoiceNumber: 'INV-2026-00389',
        customerId: 'cust-102',
        customerName: 'مكتب القدس للتصميم الداخلي / ירושלים עיצוב',
        customerPhone: '054-9988776',
        deliveryAddress: 'القدس - شارع يافا 45 / ירושלים רחוב יפו',
        cargoDescription: '80 م² بورسلان إسباني + 2 خلاط مغسلة',
        vehicleId: 'veh-02',
        vehicleName: 'فولفو FH16',
        plateNumber: '88-301-22',
        driverId: 'drv-02',
        driverName: 'خليل سميح',
        status: DispatchStatus.delivered,
        notes: 'تم التسليم والتوقيع بالكامل',
        updatedAt: DateTime(2026, 11, 14, 13, 0),
      ),
      Dispatch(
        id: 'DSP-2026-00003',
        dispatchNumber: 'DSP-2026-00003',
        date: DateTime(2026, 11, 14, 14, 0),
        saleId: null,
        invoiceNumber: null,
        customerId: 'cust-101',
        customerName: 'شركة البراق للمقاولات / חברת אל-בוראק',
        customerPhone: '052-1234567',
        deliveryAddress: 'بيت لحم - المنطقة الصناعية / בית לחם',
        cargoDescription: '25 طن حصمة وحجر بناء أبيض مقاس 30',
        vehicleId: 'veh-01',
        vehicleName: 'مرسيدس أكتروس 3340',
        plateNumber: '72-491-88',
        driverId: 'drv-01',
        driverName: 'محمود عيسى',
        status: DispatchStatus.pending,
        notes: 'بانتظار اكتمال التحميل من الكسارة',
        updatedAt: DateTime(2026, 11, 14, 14, 0),
      ),
    ];

    _fleetController = FleetDispatchController(
      initial: initialDispatches,
      initialSeq: 4,
    );

    _expensesController = ExpensesController(
      initialExpenses: [
        Expense(
          id: 'EXP-2026-00001',
          expenseNumber: 'EXP-2026-00001',
          date: DateTime(2026, 11, 10),
          category: ExpenseCategory.fuel,
          amount: 850.0,
          description: 'سولار شاحنة مرسيدس أكتروس - محطة النور',
          vehicleId: 'veh-01',
          driverId: 'drv-01',
          odometerReading: 142500,
          paymentMethod: ExpensePaymentMethod.bankTransfer,
          reference: 'INV-FUEL-9921',
          createdAt: DateTime(2026, 11, 10),
        ),
        Expense(
          id: 'EXP-2026-00002',
          expenseNumber: 'EXP-2026-00002',
          date: DateTime(2026, 11, 12),
          category: ExpenseCategory.maintenance,
          amount: 2400.0,
          description: 'صيانة دورية وتغيير فلاتر هيدروليك - كراج النصر',
          vehicleId: 'veh-02',
          driverId: 'drv-02',
          odometerReading: 98200,
          paymentMethod: ExpensePaymentMethod.check,
          reference: 'CHK-8812',
          createdAt: DateTime(2026, 11, 12),
        ),
        Expense(
          id: 'EXP-2026-00003',
          expenseNumber: 'EXP-2026-00003',
          date: DateTime(2026, 11, 14),
          category: ExpenseCategory.tires,
          amount: 3600.0,
          description: 'استبدال طقم كوشوك خلفي (4 إطارات ميشلان)',
          vehicleId: 'veh-01',
          driverId: 'drv-01',
          odometerReading: 142800,
          paymentMethod: ExpensePaymentMethod.cash,
          reference: 'RCP-5510',
          createdAt: DateTime(2026, 11, 14),
        ),
        Expense(
          id: 'EXP-2026-00004',
          expenseNumber: 'EXP-2026-00004',
          date: DateTime(2026, 11, 15),
          category: ExpenseCategory.driverAllowance,
          amount: 450.0,
          description: 'بدل سفر وإكرامية نقل حجر بيت لحم',
          vehicleId: 'veh-02',
          driverId: 'drv-02',
          paymentMethod: ExpensePaymentMethod.cash,
          reference: 'ALW-102',
          createdAt: DateTime(2026, 11, 15),
        ),
      ],
      vehicles: _vehicles,
      drivers: _drivers,
      nextExpenseSeq: 5,
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
                icon: const Icon(Icons.inventory_2_outlined),
                selectedIcon: const Icon(Icons.inventory_2, color: goldColor),
                label: _getNavLabel(AppNavDestination.inventory),
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
        return _buildInventoryScreen();
      case 3:
        return _buildStatementScreen();
      case 4:
        return _buildChecksScreen();
      case 5:
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
                  initialValue: state.selectedCustomer ?? _contacts.firstWhere((c) => c.type != ContactType.supplier),
                  decoration: const InputDecoration(
                    labelText: 'الزبون / לקוח',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _contacts.where((c) => c.type != ContactType.supplier).map((c) {
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

  Widget _buildInventoryScreen() {
    final double totalStockValuation = _products.fold<double>(
      0.0,
      (acc, p) => acc + (p.currentStock * p.purchaseCost),
    );

    final int lowStockCount = _products.where((p) {
      if (p.unitType == UnitType.meter) return p.currentStock <= 500.0;
      return p.currentStock <= 40.0;
    }).length;

    final double totalMarbleMeters = _products
        .where((p) => p.unitType == UnitType.meter)
        .fold<double>(0.0, (acc, p) => acc + p.currentStock);

    final int activeProductsCount = _products.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header with action button
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentLanguage == AppLanguage.arabic
                            ? 'إدارة المستودع والمشتريات'
                            : _currentLanguage == AppLanguage.hebrew
                                ? 'ניהול מלאי ורכש'
                                : 'Inventory & Purchase Intake',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentLanguage == AppLanguage.arabic
                            ? 'متابعة حركات التوريد، الأرصدة، تكلفة الشراء، والوحدات المزدوجة'
                            : 'מעקב קליטת מלאי, יתרות, עלויות ממוצעות והמרת יחידות',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppColorValues.primaryGold),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: Text(
                    _currentLanguage == AppLanguage.arabic
                        ? 'توريد بضاعة وفاتورة مشتريات جديدة'
                        : _currentLanguage == AppLanguage.hebrew
                            ? 'קליטת רכש ומלאי חדש'
                            : 'New Purchase Intake',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _showNewPurchaseDialog,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Live KPI cards
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildKpiCard(
              title: _currentLanguage == AppLanguage.arabic
                  ? 'إجمالي تقييم المخزون'
                  : 'שווי מלאי כולל',
              value: formatCurrency(totalStockValuation),
              icon: Icons.account_balance,
              color: const Color(AppColorValues.primaryGold),
            ),
            _buildKpiCard(
              title: _currentLanguage == AppLanguage.arabic
                  ? 'تنبيهات نقص المخزون'
                  : 'התראות מלאי נמוך',
              value: '$lowStockCount أصناف',
              icon: Icons.warning_amber_rounded,
              color: lowStockCount > 0 ? Colors.redAccent : const Color(AppColorValues.successGreen),
            ),
            _buildKpiCard(
              title: _currentLanguage == AppLanguage.arabic
                  ? 'إجمالي مساحات الرخام'
                  : 'סה"כ שיש/גרניט (מ"ר)',
              value: '${totalMarbleMeters.toStringAsFixed(1)} م²',
              icon: Icons.grid_view,
              color: Colors.cyanAccent,
            ),
            _buildKpiCard(
              title: _currentLanguage == AppLanguage.arabic
                  ? 'الأصناف النشطة'
                  : 'מוצרים פעילים',
              value: '$activeProductsCount صنف',
              icon: Icons.inventory_2,
              color: const Color(AppColorValues.infoBlue),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Product Inventory Table
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
                      _currentLanguage == AppLanguage.arabic
                          ? 'جدول أرصدة المخزون والتكلفة الحالية'
                          : 'טבלת מלאי ועלויות רכש',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_products.length} أصناف مسجلة',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 16,
                    columns: [
                      DataColumn(label: Text(_currentLanguage == AppLanguage.arabic ? 'المنتج / الصنف' : 'מוצר')),
                      DataColumn(label: Text(_currentLanguage == AppLanguage.arabic ? 'التصنيف' : 'קטגוריה')),
                      DataColumn(label: Text(_currentLanguage == AppLanguage.arabic ? 'المخزون الحالي' : 'מלאי')),
                      DataColumn(label: Text(_currentLanguage == AppLanguage.arabic ? 'التعبئة والتحويل' : 'אריזה/המרה')),
                      DataColumn(label: Text(_currentLanguage == AppLanguage.arabic ? 'سعر التكلفة' : 'עלות רכש')),
                      DataColumn(label: Text(_currentLanguage == AppLanguage.arabic ? 'سعر البيع' : 'מחיר מכירה')),
                      DataColumn(label: Text(_currentLanguage == AppLanguage.arabic ? 'الحالة' : 'סטטוס')),
                    ],
                    rows: _products.map((p) {
                      final isLow = p.unitType == UnitType.meter
                          ? p.currentStock <= 500.0
                          : p.currentStock <= 40.0;
                      return DataRow(
                        cells: [
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text(p.sku, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (p.category == ProductCategory.marble
                                        ? const Color(AppColorValues.primaryGold)
                                        : Colors.blueAccent)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                p.category.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: p.category == ProductCategory.marble
                                      ? const Color(AppColorValues.primaryGold)
                                      : Colors.blueAccent,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${p.currentStock.toStringAsFixed(1)} ${p.unitType == UnitType.meter ? "م²" : "حبة"}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataCell(
                            p.meterPerBox != null
                                ? Text(
                                    '${(p.currentStock / p.meterPerBox!).toStringAsFixed(1)} كرتونة (${p.meterPerBox} م²/كرتونة)',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  )
                                : const Text('-', style: TextStyle(color: Colors.grey)),
                          ),
                          DataCell(
                            Text(formatCurrency(p.purchaseCost), style: const TextStyle(color: Colors.orangeAccent)),
                          ),
                          DataCell(
                            Text(formatCurrency(p.sellingPrice), style: const TextStyle(color: Colors.greenAccent)),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (isLow ? Colors.redAccent : Colors.green).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: (isLow ? Colors.redAccent : Colors.green).withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isLow ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                                    size: 13,
                                    color: isLow ? Colors.redAccent : Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isLow ? 'نقص بالمخزون' : 'وافر',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isLow ? Colors.redAccent : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Recent Purchases History Card
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
                      _currentLanguage == AppLanguage.arabic
                          ? 'سجل فواتير المشتريات والتوريد الأخيرة'
                          : 'היסטוריית חשבוניות רכש אחרונות',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_purchaseInvoices.length} فواتير توريد',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_purchaseInvoices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('لا توجد فواتير مشتريات مسجلة بعد', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  ..._purchaseInvoices.map((inv) {
                    final dateStr =
                        '${inv.date.year}-${inv.date.month.toString().padLeft(2, '0')}-${inv.date.day.toString().padLeft(2, '0')}';
                    final isFullyPaid = inv.onAccountAmount <= 0.01;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(AppColorValues.primaryGold).withValues(alpha: 0.2),
                            child: const Icon(Icons.receipt, color: Color(AppColorValues.primaryGold), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      inv.invoiceNumber,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    if (inv.supplierInvoiceNumber != null && inv.supplierInvoiceNumber!.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '(فاتورة المورد: ${inv.supplierInvoiceNumber})',
                                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'المورد: ${inv.supplierName} • $dateStr',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  children: inv.items.map((it) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white10,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${it.productName}: ${it.quantity} ${it.unitType.name} (+${it.convertedStockQuantity.toStringAsFixed(1)} للمخزون)',
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatCurrency(inv.totalAmount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(AppColorValues.primaryGold),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isFullyPaid ? Colors.green : Colors.orangeAccent).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isFullyPaid ? 'مسددة بالكامل' : 'ذمة على الحساب',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isFullyPaid ? Colors.greenAccent : Colors.orangeAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.picture_as_pdf, size: 14),
                                label: const Text('طباعة PDF', style: TextStyle(fontSize: 11)),
                                onPressed: () {
                                  final supp = _contacts.cast<Contact?>().firstWhere(
                                    (c) => c?.id == inv.supplierId,
                                    orElse: () => null,
                                  );
                                  _showPurchasePdfPreview(inv, supp);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
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
        // Sub-Tab Switcher
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(AppColorValues.cardDark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _fleetSubTabIndex = 0),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _fleetSubTabIndex == 0
                          ? const Color(AppColorValues.primaryGold)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _currentLanguage == AppLanguage.arabic
                          ? 'أوامر النقل والإرساليات (משלוחים)'
                          : 'משלוחים והובלה / أوامر النقل',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _fleetSubTabIndex == 0 ? Colors.black : Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _fleetSubTabIndex = 1),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _fleetSubTabIndex == 1
                          ? const Color(AppColorValues.primaryGold)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _currentLanguage == AppLanguage.arabic
                          ? 'مصاريف الأسطول وتكلفة الكيلومتر (הוצאות צי ועלות לק"מ)'
                          : 'הוצאות צי ועלות לק"מ / مصاريف وتكلفة الكيلومتر',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _fleetSubTabIndex == 1 ? Colors.black : Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_fleetSubTabIndex == 0)
          ..._buildFleetDispatchesTab()
        else
          ..._buildFleetExpensesTab(),
      ],
    );
  }

  List<Widget> _buildFleetDispatchesTab() {
    final state = _fleetController.state;
    final activeTrucksCount = _vehicles.where((v) => v.status == VehicleStatus.active).length;
    final totalFleetKm = _vehicles.fold<int>(0, (sum, v) => sum + v.currentOdometer);
    final activeDispatchesCount = state.dispatches
        .where((d) => d.status == DispatchStatus.pending || d.status == DispatchStatus.dispatched)
        .length;

    return [
      // 1. Header & Quick Action
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _buildSectionHeader(
              _currentLanguage == AppLanguage.arabic
                  ? 'إدارة أسطول الشاحنات واللوجستيات / צי רכב והובלות'
                  : 'צי רכב והובלות / أسطول الشاحنات واللوجستيات',
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppColorValues.primaryGold),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.add_road, size: 20),
            label: Text(
              _currentLanguage == AppLanguage.arabic
                  ? 'أمر إرسالية ونقل جديد'
                  : 'תעודת משלוח חדשה',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: _showNewDispatchDialog,
          ),
        ],
      ),
      const SizedBox(height: 16),

      // 2. Fleet KPI Banner
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildKpiCard(
            title: _currentLanguage == AppLanguage.arabic ? 'الشاحنات العاملة' : 'משאיות פעילות',
            value: '$activeTrucksCount / ${_vehicles.length}',
            icon: Icons.local_shipping,
            color: const Color(AppColorValues.successGreen),
          ),
          _buildKpiCard(
            title: _currentLanguage == AppLanguage.arabic ? 'إجمالي كيلومترات الأسطول' : 'סה"כ ק"מ צי',
            value: '$totalFleetKm كم',
            icon: Icons.speed,
            color: const Color(AppColorValues.infoBlue),
          ),
          _buildKpiCard(
            title: _currentLanguage == AppLanguage.arabic ? 'إرساليات قيد التنفيذ' : 'משלוחים בביצוע',
            value: '$activeDispatchesCount',
            icon: Icons.route,
            color: const Color(AppColorValues.warningOrange),
          ),
          _buildKpiCard(
            title: _currentLanguage == AppLanguage.arabic ? 'متوسط تكلفة التشغيل' : 'עלות ממוצעת לק"מ',
            value: '₪ 4.85 / كم',
            icon: Icons.analytics,
            color: Colors.teal,
          ),
        ],
      ),
      const SizedBox(height: 24),

      // 3. Status Filter Chips
      Row(
        children: [
          Text(
            _currentLanguage == AppLanguage.arabic ? 'تصفية الإرساليات:' : 'סינון משלוחים:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDispatchFilterChip(
                    label: _currentLanguage == AppLanguage.arabic ? 'الكل' : 'הכל',
                    isSelected: state.statusFilter == null,
                    onSelected: () {
                      setState(() => _fleetController.setStatusFilter(null));
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildDispatchFilterChip(
                    label: DispatchStatus.pending.arabicLabel,
                    isSelected: state.statusFilter == DispatchStatus.pending,
                    onSelected: () {
                      setState(() => _fleetController.setStatusFilter(DispatchStatus.pending));
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildDispatchFilterChip(
                    label: DispatchStatus.dispatched.arabicLabel,
                    isSelected: state.statusFilter == DispatchStatus.dispatched,
                    onSelected: () {
                      setState(() => _fleetController.setStatusFilter(DispatchStatus.dispatched));
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildDispatchFilterChip(
                    label: DispatchStatus.delivered.arabicLabel,
                    isSelected: state.statusFilter == DispatchStatus.delivered,
                    onSelected: () {
                      setState(() => _fleetController.setStatusFilter(DispatchStatus.delivered));
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildDispatchFilterChip(
                    label: _currentLanguage == AppLanguage.arabic ? 'معاد / ملغي' : 'הוחזר / מבוטל',
                    isSelected: state.statusFilter == DispatchStatus.cancelled ||
                        state.statusFilter == DispatchStatus.returned,
                    onSelected: () {
                      setState(() => _fleetController.setStatusFilter(DispatchStatus.cancelled));
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // 4. Dispatches Board / List
      if (state.filteredDispatches.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.inbox, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    _currentLanguage == AppLanguage.arabic
                        ? 'لا توجد إرساليات مطابقة للفلتر المحدد'
                        : 'אין משלוחים התואמים לסינון הנבחר',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        )
      else
        ...state.filteredDispatches.map((dispatch) => _buildDispatchCard(dispatch)),

      const SizedBox(height: 28),

      // 5. Fleet Trucks Directory
      _buildSectionHeader(
        _currentLanguage == AppLanguage.arabic
            ? 'دليل شاحنات ومركبات الأسطول / צי כלי רכב'
            : 'צי כלי רכב / دليل شاحنات ومركبات الأسطول',
      ),
      const SizedBox(height: 12),
      ..._vehicles.map((v) => _buildTruckCard(v)),
    ];
  }

  List<Widget> _buildFleetExpensesTab() {
    final summary = _expensesController.getFleetSummary();
    final expenseState = _expensesController.state;

    return [
      // 1. Header with action button
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _buildSectionHeader(
              _currentLanguage == AppLanguage.arabic
                  ? 'مصاريف الأسطول وتكلفة الكيلومتر / הוצאות צי ועלות לק"מ'
                  : 'הוצאות צי ועלות לק"מ / مصاريف الأسطول وتكلفة الكيلومتر',
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppColorValues.primaryGold),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.receipt_long, size: 20),
            label: Text(
              _currentLanguage == AppLanguage.arabic
                  ? 'تسجيل سند صرف ومصروف جديد'
                  : 'שובר הוצאה חדש / سند صرف جديد',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: _showNewExpenseDialog,
          ),
        ],
      ),
      const SizedBox(height: 16),

      // 2. KPI Banner
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildKpiCard(
            title: _currentLanguage == AppLanguage.arabic ? 'إجمالي مصاريف الأسطول' : 'סה"כ הוצאות צי',
            value: formatCurrency(summary.totalExpenses),
            icon: Icons.account_balance_wallet,
            color: const Color(AppColorValues.primaryGold),
          ),
          _buildKpiCard(
            title: _currentLanguage == AppLanguage.arabic ? 'مصاريف الوقود والديزل' : 'הוצאות דלק וסולר',
            value: formatCurrency(summary.totalFuel),
            icon: Icons.local_gas_station,
            color: const Color(AppColorValues.warningOrange),
          ),
          _buildKpiCard(
            title: _currentLanguage == AppLanguage.arabic ? 'صيانة دورية وإطارات' : 'טיפולים וצמיגים',
            value: formatCurrency(summary.totalMaintenance),
            icon: Icons.build,
            color: const Color(AppColorValues.infoBlue),
          ),
          _buildKpiCard(
            title: _currentLanguage == AppLanguage.arabic ? 'متوسط تكلفة الكيلومتر' : 'עלות ממוצעת לק"מ',
            value: '₪ ${summary.overallCostPerKm.toStringAsFixed(2)} / كم',
            icon: Icons.speed,
            color: Colors.teal,
          ),
        ],
      ),
      const SizedBox(height: 24),

      // 3. Vehicle Operational Efficiency Cards (cost-per-km breakdown per vehicle)
      _buildSectionHeader(
        _currentLanguage == AppLanguage.arabic
            ? 'كفاءة وتكلفة الشاحنات (Cost Per KM) / יעילות רכבים'
            : 'יעילות כלי רכב ועלות לק"מ / كفاءة وتكلفة الشاحنات',
      ),
      const SizedBox(height: 12),
      ..._vehicles.map((v) {
        final m = _expensesController.getVehicleMetrics(v);
        return _buildVehicleEfficiencyCard(v, m);
      }),
      const SizedBox(height: 24),

      // 4. Category Filter Chips
      Row(
        children: [
          Text(
            _currentLanguage == AppLanguage.arabic ? 'تصنيف المصاريف:' : 'סינון קטגוריה:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDispatchFilterChip(
                    label: _currentLanguage == AppLanguage.arabic ? 'الكل' : 'הכל',
                    isSelected: expenseState.categoryFilter == null,
                    onSelected: () {
                      setState(() => _expensesController.setCategoryFilter(null));
                    },
                  ),
                  const SizedBox(width: 8),
                  ...ExpenseCategory.values.map((cat) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _buildDispatchFilterChip(
                        label: _currentLanguage == AppLanguage.arabic ? cat.arabicLabel : cat.hebrewLabel,
                        isSelected: expenseState.categoryFilter == cat,
                        onSelected: () {
                          setState(() => _expensesController.setCategoryFilter(cat));
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // 5. Expense Vouchers List
      if (expenseState.filteredExpenses.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    _currentLanguage == AppLanguage.arabic
                        ? 'لا توجد سندات صرف مطابقة للتصفية المحددة'
                        : 'אין שוברי הוצאה התואמים לסינון הנבחר',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        )
      else
        ...expenseState.filteredExpenses.map((expense) => _buildExpenseCard(expense)),
    ];
  }

  Widget _buildVehicleEfficiencyCard(Vehicle vehicle, VehicleExpenseMetrics metrics) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(AppColorValues.primaryGold).withValues(alpha: 0.2),
                        child: const Icon(Icons.local_shipping, color: Color(AppColorValues.primaryGold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'رقم اللوحة: ${vehicle.plateNumber} | سنة الصنع: ${vehicle.modelYear}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal),
                  ),
                  child: Column(
                    children: [
                      const Text('تكلفة التشغيل/كم', style: TextStyle(fontSize: 10, color: Colors.tealAccent)),
                      Text(
                        '₪ ${metrics.costPerKm.toStringAsFixed(2)} / كم',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.tealAccent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(AppColorValues.surfaceDark),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricMiniCol('المسافة الإجمالية', '${vehicle.currentOdometer} كم', Icons.speed),
                  _buildMetricMiniCol('إجمالي المصاريف', formatCurrency(metrics.totalExpenses), Icons.payments),
                  _buildMetricMiniCol('وقود (₪/كم)', '₪ ${metrics.fuelCostPerKm.toStringAsFixed(2)}', Icons.local_gas_station),
                  _buildMetricMiniCol('صيانة (₪/كم)', '₪ ${metrics.maintenanceCostPerKm.toStringAsFixed(2)}', Icons.build),
                  _buildMetricMiniCol('السندات', '${metrics.expenseCount}', Icons.receipt),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricMiniCol(String title, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    Color catColor;
    IconData catIcon;
    switch (expense.category) {
      case ExpenseCategory.fuel:
        catColor = const Color(AppColorValues.warningOrange);
        catIcon = Icons.local_gas_station;
        break;
      case ExpenseCategory.maintenance:
        catColor = const Color(AppColorValues.infoBlue);
        catIcon = Icons.build;
        break;
      case ExpenseCategory.tires:
        catColor = Colors.deepOrange;
        catIcon = Icons.album;
        break;
      case ExpenseCategory.driverAllowance:
        catColor = const Color(AppColorValues.successGreen);
        catIcon = Icons.badge;
        break;
      case ExpenseCategory.licensingInsurance:
        catColor = Colors.purpleAccent;
        catIcon = Icons.verified_user;
        break;
      case ExpenseCategory.rent:
      case ExpenseCategory.utilities:
        catColor = Colors.blueGrey;
        catIcon = Icons.business;
        break;
      case ExpenseCategory.other:
        catColor = Colors.grey;
        catIcon = Icons.receipt;
        break;
    }

    final dateStr =
        '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}-${expense.date.day.toString().padLeft(2, '0')}';

    final vehicle = expense.vehicleId != null
        ? _vehicles.cast<Vehicle?>().firstWhere((v) => v?.id == expense.vehicleId, orElse: () => null)
        : null;
    final driver = expense.driverId != null
        ? _drivers.cast<Driver?>().firstWhere((d) => d?.id == expense.driverId, orElse: () => null)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(AppColorValues.primaryGold).withValues(alpha: 0.15),
                        border: Border.all(color: const Color(AppColorValues.primaryGold)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        expense.expenseNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(AppColorValues.primaryGold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.15),
                        border: Border.all(color: catColor.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(catIcon, size: 12, color: catColor),
                          const SizedBox(width: 4),
                          Text(
                            _currentLanguage == AppLanguage.arabic
                                ? expense.category.arabicLabel
                                : expense.category.hebrewLabel,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: catColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  formatCurrency(expense.amount),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(AppColorValues.primaryGold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              expense.description,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                if (vehicle != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_shipping, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${vehicle.name.split('(').first.trim()} [${vehicle.plateNumber}]',
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                if (driver != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        driver.fullName.split('/').first.trim(),
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                if (expense.odometerReading != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.speed, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${expense.odometerReading} كم',
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.payment, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _currentLanguage == AppLanguage.arabic
                          ? expense.paymentMethod.arabicLabel
                          : expense.paymentMethod.hebrewLabel,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    if (expense.reference != null) ...[
                      const SizedBox(width: 4),
                      Text('(${expense.reference})', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(AppColorValues.primaryGold),
                  side: const BorderSide(color: Color(AppColorValues.primaryGold)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: Text(
                  _currentLanguage == AppLanguage.arabic
                      ? 'معاينة سند صرف A4 PDF'
                      : 'הצגת שובר הוצאה A4 PDF',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _showExpensePdfPreview(expense),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDispatchFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.black : Colors.white)),
      selected: isSelected,
      selectedColor: const Color(AppColorValues.primaryGold),
      backgroundColor: const Color(AppColorValues.cardDark),
      onSelected: (_) => onSelected(),
    );
  }

  Widget _buildDispatchCard(Dispatch dispatch) {
    Color statusColor;
    IconData statusIcon;
    switch (dispatch.status) {
      case DispatchStatus.pending:
        statusColor = const Color(AppColorValues.warningOrange);
        statusIcon = Icons.hourglass_top;
        break;
      case DispatchStatus.dispatched:
        statusColor = const Color(AppColorValues.infoBlue);
        statusIcon = Icons.local_shipping;
        break;
      case DispatchStatus.delivered:
        statusColor = const Color(AppColorValues.successGreen);
        statusIcon = Icons.check_circle;
        break;
      case DispatchStatus.returned:
      case DispatchStatus.cancelled:
        statusColor = Colors.redAccent;
        statusIcon = Icons.cancel;
        break;
    }

    final dateStr =
        '${dispatch.date.year}-${dispatch.date.month.toString().padLeft(2, '0')}-${dispatch.date.day.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Dispatch #, Status, Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(AppColorValues.primaryGold).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(AppColorValues.primaryGold)),
                      ),
                      child: Text(
                        dispatch.dispatchNumber,
                        style: const TextStyle(
                          color: Color(AppColorValues.primaryGold),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            _currentLanguage == AppLanguage.arabic
                                ? dispatch.status.arabicLabel
                                : dispatch.status.hebrewLabel,
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  dateStr,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Customer & Delivery Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.person_pin_circle_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${dispatch.customerName} (${dispatch.customerPhone})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dispatch.deliveryAddress,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (dispatch.invoiceNumber != null && dispatch.invoiceNumber!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'فاتورة: ${dispatch.invoiceNumber}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Cargo Description Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(AppColorValues.surfaceDark),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 16, color: Color(AppColorValues.primaryGold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'الحمولة: ${dispatch.cargoDescription}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Vehicle & Driver Details
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, size: 16, color: Colors.teal),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${dispatch.vehicleName} [${dispatch.plateNumber}]',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.badge_outlined, size: 16, color: Colors.blueAccent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'السائق: ${dispatch.driverName}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Actions Row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // 1. Advance to Dispatched
                if (dispatch.status == DispatchStatus.pending)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(AppColorValues.infoBlue),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.directions_run, size: 16),
                    label: const Text('بدء النقل / יצא לדרך', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      setState(() {
                        _fleetController.advanceStatus(
                          dispatchId: dispatch.id,
                          newStatus: DispatchStatus.dispatched,
                        );
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم بدء نقل الإرسالية ${dispatch.dispatchNumber}'),
                          backgroundColor: const Color(AppColorValues.infoBlue),
                        ),
                      );
                    },
                  ),

                // 2. Complete Delivery
                if (dispatch.status == DispatchStatus.dispatched)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(AppColorValues.successGreen),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('تأكيد التسليم / אשר מסירה', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _showCompleteDeliveryDialog(dispatch),
                  ),

                // 3. Cancel
                if (!DispatchService.isTerminal(dispatch.status))
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('إلغاء / ביטול', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      setState(() {
                        _fleetController.cancelDispatch(dispatch.id, reason: 'ملغي من قبل المستخدم');
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم إلغاء الإرسالية ${dispatch.dispatchNumber}')),
                      );
                    },
                  ),

                // 4. A4 PDF Delivery Note Preview
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(AppColorValues.primaryGold),
                    side: const BorderSide(color: Color(AppColorValues.primaryGold)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                  label: const Text('توليد سند إرسالية A4 PDF', style: TextStyle(fontSize: 12)),
                  onPressed: () => _showDeliveryNotePdfPreview(dispatch),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTruckCard(Vehicle vehicle) {
    Color statusColor;
    switch (vehicle.status) {
      case VehicleStatus.active:
        statusColor = const Color(AppColorValues.successGreen);
        break;
      case VehicleStatus.maintenance:
        statusColor = const Color(AppColorValues.warningOrange);
        break;
      case VehicleStatus.inactive:
        statusColor = Colors.grey;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: statusColor.withValues(alpha: 0.2),
                child: Icon(Icons.local_shipping, color: statusColor),
              ),
              title: Text(vehicle.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                'رقم اللوحة: ${vehicle.plateNumber} | سنة الصنع: ${vehicle.modelYear ?? "N/A"}${vehicle.notes != null ? " | ${vehicle.notes}" : ""}',
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _currentLanguage == AppLanguage.arabic
                      ? vehicle.status.arabicLabel
                      : vehicle.status.hebrewLabel,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('العداد: ${vehicle.currentOdometer} كم', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Text('الوقود: ₪ 18,400', style: TextStyle(color: Colors.grey)),
                const Text('الصيانة: ₪ 4,600', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showNewDispatchDialog() {
    final activeVehicles = _vehicles.where((v) => v.status == VehicleStatus.active).toList();
    final activeDrivers = _drivers.where((d) => d.status == DriverStatus.active).toList();

    if (activeVehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد شاحنات فعالة ومتاحة للإرسال')),
      );
      return;
    }

    if (activeDrivers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد سائقون فعالون ومتاحون للخدمة')),
      );
      return;
    }

    final addressCtrl = TextEditingController(text: _contacts.first.address);
    final cargoCtrl = TextEditingController(text: '100 م² رخام كرارا + 2 خلاط نحاسي');
    final invoiceCtrl = TextEditingController(text: 'INV-2026-00412');
    final notesCtrl = TextEditingController();

    Contact selectedCustomer = _contacts.first;
    Vehicle selectedVehicle = activeVehicles.first;
    Driver selectedDriver = activeDrivers.first;
    String? validationError;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.add_road, color: Color(AppColorValues.primaryGold)),
                  SizedBox(width: 8),
                  Text('أمر إرسالية ونقل جديد / תעודת משלוח', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (validationError != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.redAccent),
                          ),
                          child: Text(validationError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                        ),

                      // Customer Selector
                      const Text('الزبون / לקוח', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<Contact>(
                        initialValue: selectedCustomer,
                        isExpanded: true,
                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        items: _contacts.map((c) {
                          return DropdownMenuItem(value: c, child: Text(c.name, overflow: TextOverflow.ellipsis));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedCustomer = val;
                              addressCtrl.text = val.address;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Delivery Address
                      const Text('عنوان التوصيل وموقع التفريغ / כתובת אספקה', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: addressCtrl,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'المدينة، الشارع، تفاصيل الموقع',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Cargo Description
                      const Text('وصف الحمولة والأصناف / פירוט המטען', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: cargoCtrl,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'مثال: 120 م² سيراميك، 4 أطقم خلاطات',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Vehicle & Driver Pickers
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('الشاحنة / משאית', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<Vehicle>(
                                  initialValue: selectedVehicle,
                                  isExpanded: true,
                                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                                  items: activeVehicles.map((v) {
                                    return DropdownMenuItem(value: v, child: Text(v.plateNumber, style: const TextStyle(fontSize: 13)));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setDialogState(() => selectedVehicle = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('السائق / נהג', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<Driver>(
                                  initialValue: selectedDriver,
                                  isExpanded: true,
                                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                                  items: activeDrivers.map((d) {
                                    return DropdownMenuItem(value: d, child: Text(d.fullName, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setDialogState(() => selectedDriver = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Invoice Reference & Notes
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('رقم الفاتورة المرتبطة (اختياري)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: invoiceCtrl,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'INV-2026-xxxxx',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('إلغاء / ביטול'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppColorValues.primaryGold),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('إنشاء الإرسالية / צור משלוח', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    final address = addressCtrl.text.trim();
                    final cargo = cargoCtrl.text.trim();
                    if (address.isEmpty) {
                      setDialogState(() => validationError = 'يرجى كتابة عنوان التوصيل');
                      return;
                    }
                    if (cargo.isEmpty) {
                      setDialogState(() => validationError = 'يرجى كتابة وصف الحمولة');
                      return;
                    }

                    try {
                      _fleetController.setCustomer(
                        id: selectedCustomer.id,
                        name: selectedCustomer.name,
                        phone: selectedCustomer.phone,
                      );
                      _fleetController.setVehicle(
                        id: selectedVehicle.id,
                        name: selectedVehicle.name,
                        plateNumber: selectedVehicle.plateNumber,
                        status: selectedVehicle.status,
                        currentOdometer: selectedVehicle.currentOdometer,
                      );
                      _fleetController.setDriver(
                        id: selectedDriver.id,
                        name: selectedDriver.fullName,
                        status: selectedDriver.status,
                      );
                      _fleetController.setDeliveryAddress(address);
                      _fleetController.setCargoDescription(cargo);
                      final inv = invoiceCtrl.text.trim();
                      if (inv.isNotEmpty) {
                        _fleetController.setInvoiceRef(invoiceNumber: inv);
                      }
                      final notes = notesCtrl.text.trim();
                      if (notes.isNotEmpty) {
                        _fleetController.setFormNotes(notes);
                      }

                      final newDispatch = _fleetController.submitNewDispatch();

                      setState(() {});
                      Navigator.of(dialogCtx).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم إنشاء أمر الإرسالية ${newDispatch.dispatchNumber} بنجاح'),
                          backgroundColor: const Color(AppColorValues.successGreen),
                          action: SnackBarAction(
                            label: 'معاينة PDF',
                            textColor: Colors.black,
                            onPressed: () => _showDeliveryNotePdfPreview(newDispatch),
                          ),
                        ),
                      );
                    } catch (e) {
                      setDialogState(() => validationError = 'خطأ في إنشاء أمر الإرسالية: $e');
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      addressCtrl.dispose();
      cargoCtrl.dispose();
      invoiceCtrl.dispose();
      notesCtrl.dispose();
    });
  }

  void _showCompleteDeliveryDialog(Dispatch dispatch) {
    final vehicle = _vehicles.firstWhere(
      (v) => v.id == dispatch.vehicleId,
      orElse: () => _vehicles.first,
    );
    final suggestedOdo = vehicle.currentOdometer + 45;
    final odoCtrl = TextEditingController(text: suggestedOdo.toString());
    String? errorMsg;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.check_circle, color: Color(AppColorValues.successGreen)),
                  SizedBox(width: 8),
                  Text('تأكيد تسليم الإرسالية / אישור מסירה', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الإرسالية: ${dispatch.dispatchNumber}'),
                  const SizedBox(height: 4),
                  Text('الشاحنة: ${vehicle.name} (${vehicle.plateNumber})'),
                  const SizedBox(height: 4),
                  Text('العداد السابق: ${vehicle.currentOdometer} كم', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  const Text('قراءة العداد عند اكتمال التسليم (كم):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: odoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      errorText: errorMsg,
                      suffixText: 'كم',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('إلغاء / ביטול'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppColorValues.successGreen),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('تأكيد التسليم / אשר מסירה', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    final odo = int.tryParse(odoCtrl.text.trim());
                    if (odo == null || odo < vehicle.currentOdometer) {
                      setDialogState(() {
                        errorMsg = 'يجب أن يكون العداد أكبر من أو يساوي ${vehicle.currentOdometer} كم';
                      });
                      return;
                    }

                    try {
                      final result = _fleetController.advanceStatus(
                        dispatchId: dispatch.id,
                        newStatus: DispatchStatus.delivered,
                        vehicle: vehicle,
                        completionOdometer: odo,
                      );

                      // Update vehicle in _vehicles list if returned
                      if (result.updatedVehicle != null) {
                        final vIdx = _vehicles.indexWhere((v) => v.id == result.updatedVehicle!.id);
                        if (vIdx >= 0) {
                          _vehicles[vIdx] = result.updatedVehicle!;
                        }
                      }

                      setState(() {});
                      Navigator.of(dialogCtx).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم تأكيد تسليم الإرسالية ${dispatch.dispatchNumber} وتحديث عداد الشاحنة إلى $odo كم'),
                          backgroundColor: const Color(AppColorValues.successGreen),
                        ),
                      );
                    } catch (e) {
                      setDialogState(() => errorMsg = 'خطأ: $e');
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      odoCtrl.dispose();
    });
  }

  void _showDeliveryNotePdfPreview(Dispatch dispatch) async {
    const company = CompanyInfo(
      name: 'M.I.R.N POWER Ltd.',
      nameArabic: 'شركة م.ي.ر.ن باور م.ض',
      nameHebrew: 'מ.י.ר.ן פאוור בע"מ',
      subtitleArabic: 'أدوات صحية، رخام، حجر، ونقل وشحن',
      subtitleHebrew: 'כלים סניטריים, שיש, אבן והובלה',
      taxId: '515892104',
      phone: '02-1234567',
      address: 'אזור התעשייה עטרות / عطروت, ירושלים',
    );

    try {
      final bytes = await DeliveryNotePdfGenerator.generate(
        dispatch: dispatch,
        company: company,
      );

      if (!mounted) return;

      showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Color(AppColorValues.primaryGold)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'معاينة سند الإرسالية: ${dispatch.dispatchNumber}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      border: Border.all(color: Colors.greenAccent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.greenAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'تم توليد سند الإرسالية A4 PDF بنجاح (${(bytes.length / 1024).toStringAsFixed(1)} KB) وفق معايير תעודת משלוח והובלה الرسمية.',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('الزبون / לקוח'),
                    subtitle: Text('${dispatch.customerName} - ${dispatch.customerPhone}'),
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('عنوان التوصيل'),
                    subtitle: Text(dispatch.deliveryAddress),
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('الشاحنة والسائق'),
                    subtitle: Text('${dispatch.vehicleName} [${dispatch.plateNumber}] - ${dispatch.driverName}'),
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('وصف الحمولة'),
                    subtitle: Text(dispatch.cargoDescription),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('إغلاق / סגור'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppColorValues.primaryGold),
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.print, size: 18),
                label: const Text('طباعة سند الإرسالية / הדפסה'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إرسال سند الإرسالية إلى الطابعة')),
                  );
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في توليد PDF: $e')),
      );
    }
  }

  void _showNewExpenseDialog() {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final odoCtrl = TextEditingController();
    final refCtrl = TextEditingController();

    ExpenseCategory selectedCategory = ExpenseCategory.fuel;
    ExpensePaymentMethod selectedPayment = ExpensePaymentMethod.cash;
    Vehicle? selectedVehicle = _vehicles.isNotEmpty ? _vehicles.first : null;
    Driver? selectedDriver = _drivers.isNotEmpty ? _drivers.first : null;
    String? validationError;

    if (selectedVehicle != null) {
      odoCtrl.text = selectedVehicle.currentOdometer.toString();
    }

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Color(AppColorValues.primaryGold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentLanguage == AppLanguage.arabic
                          ? 'تسجيل سند صرف ومصروف جديد / שובר הוצאה'
                          : 'שובר הוצאה חדש / سند صرف ومصروف',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (validationError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.redAccent),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  validationError!,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Category & Amount
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<ExpenseCategory>(
                              initialValue: selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'بند المصروف / קטגוריה',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: ExpenseCategory.values.map((cat) {
                                return DropdownMenuItem(
                                  value: cat,
                                  child: Text(
                                    _currentLanguage == AppLanguage.arabic
                                        ? '${cat.arabicLabel} (${cat.hebrewLabel})'
                                        : '${cat.hebrewLabel} (${cat.arabicLabel})',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => selectedCategory = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: amountCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'المبلغ (₪) / סכום *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Description
                      TextField(
                        controller: descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'البيان وتفاصيل المصروف / תיאור *',
                          hintText: 'مثال: سولار شاحنة، صيانة كراج، تبديل إطارات...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Vehicle & Driver
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<Vehicle?>(
                              initialValue: selectedVehicle,
                              decoration: const InputDecoration(
                                labelText: 'الشاحنة المخصصة / משאית',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: [
                                const DropdownMenuItem<Vehicle?>(
                                  value: null,
                                  child: Text('بدون تحديد شاحنة (عام)', style: TextStyle(fontSize: 12)),
                                ),
                                ..._vehicles.map((v) {
                                  return DropdownMenuItem<Vehicle?>(
                                    value: v,
                                    child: Text(
                                      '${v.name.split('(').first.trim()} [${v.plateNumber}]',
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (val) {
                                setDialogState(() {
                                  selectedVehicle = val;
                                  if (val != null) {
                                    odoCtrl.text = val.currentOdometer.toString();
                                  } else {
                                    odoCtrl.clear();
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<Driver?>(
                              initialValue: selectedDriver,
                              decoration: const InputDecoration(
                                labelText: 'السائق المسؤول / נהג',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: [
                                const DropdownMenuItem<Driver?>(
                                  value: null,
                                  child: Text('بدون تحديد سائق', style: TextStyle(fontSize: 12)),
                                ),
                                ..._drivers.map((d) {
                                  return DropdownMenuItem<Driver?>(
                                    value: d,
                                    child: Text(
                                      d.fullName.split('/').first.trim(),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (val) {
                                setDialogState(() => selectedDriver = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Odometer reading & Payment method
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: odoCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'قراءة العداد (كم) / מד אוץ',
                                helperText: selectedVehicle != null
                                    ? 'العداد الحالي: ${selectedVehicle!.currentOdometer} كم'
                                    : null,
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<ExpensePaymentMethod>(
                              initialValue: selectedPayment,
                              decoration: const InputDecoration(
                                labelText: 'طريقة الدفع / אמצעי תשלום',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: ExpensePaymentMethod.values.map((m) {
                                return DropdownMenuItem(
                                  value: m,
                                  child: Text(
                                    _currentLanguage == AppLanguage.arabic
                                        ? '${m.arabicLabel} (${m.hebrewLabel})'
                                        : '${m.hebrewLabel} (${m.arabicLabel})',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => selectedPayment = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Reference
                      TextField(
                        controller: refCtrl,
                        decoration: const InputDecoration(
                          labelText: 'رقم الإيصال / الفاتورة الضريبية / אסמכתא',
                          hintText: 'مثال: INV-9921, CHK-8812...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('إلغاء / ביטול'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppColorValues.primaryGold),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    final amt = double.tryParse(amountCtrl.text.trim());
                    if (amt == null || amt <= 0) {
                      setDialogState(() => validationError = 'يرجى إدخال مبلغ صحيح أكبر من صفر');
                      return;
                    }
                    final desc = descCtrl.text.trim();
                    if (desc.isEmpty) {
                      setDialogState(() => validationError = 'يرجى إدخال بيان ووصف المصروف');
                      return;
                    }

                    int? odo;
                    if (odoCtrl.text.trim().isNotEmpty) {
                      odo = int.tryParse(odoCtrl.text.trim());
                      if (odo == null) {
                        setDialogState(() => validationError = 'قراءة العداد غير صحيحة');
                        return;
                      }
                      if (selectedVehicle != null && odo < selectedVehicle!.currentOdometer) {
                        setDialogState(() => validationError =
                            'قراءة العداد ($odo كم) لا يمكن أن تكون أقل من قراءة العداد الحالية (${selectedVehicle!.currentOdometer} كم)');
                        return;
                      }
                    }

                    try {
                      _expensesController.setCategory(selectedCategory);
                      _expensesController.setAmount(amt);
                      _expensesController.setDescription(desc);
                      _expensesController.setVehicle(selectedVehicle);
                      _expensesController.setDriver(selectedDriver);
                      _expensesController.setOdometerReading(odo);
                      _expensesController.setPaymentMethod(selectedPayment);
                      _expensesController.setReference(refCtrl.text.trim().isNotEmpty ? refCtrl.text.trim() : null);

                      final newExpense = _expensesController.submitNewExpense();

                      // Update local _vehicles if vehicle odometer updated
                      if (selectedVehicle != null && odo != null && odo > selectedVehicle!.currentOdometer) {
                        final vIdx = _vehicles.indexWhere((v) => v.id == selectedVehicle!.id);
                        if (vIdx >= 0) {
                          _vehicles[vIdx] = selectedVehicle!.copyWith(currentOdometer: odo);
                        }
                      }

                      setState(() {});
                      Navigator.of(dialogCtx).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم تسجيل سند الصرف ${newExpense.expenseNumber} بنجاح'),
                          backgroundColor: const Color(AppColorValues.successGreen),
                          action: SnackBarAction(
                            label: 'معاينة PDF',
                            textColor: Colors.black,
                            onPressed: () => _showExpensePdfPreview(newExpense),
                          ),
                        ),
                      );
                    } catch (e) {
                      setDialogState(() => validationError = 'خطأ في تسجيل المصروف: $e');
                    }
                  },
                  child: const Text('تسجيل وحفظ السند', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      amountCtrl.dispose();
      descCtrl.dispose();
      odoCtrl.dispose();
      refCtrl.dispose();
    });
  }

  Future<void> _showExpensePdfPreview(Expense expense) async {
    const company = CompanyInfo(
      name: 'M.I.R.N POWER Ltd.',
      nameHebrew: 'חברת מ.י.ר.ן פאוור בע"מ',
      nameArabic: 'شركة מ.י.ר.ן باور م.ض',
      subtitleArabic: 'أدوات صحية، رخام، حجر، ونقل وشحن',
      subtitleHebrew: 'כלים סניטריים, שיש, אבן והובלה',
      taxId: '515892104',
      phone: '02-1234567',
      address: 'אזור התעשייה עטרות / عطروت, ירושלים',
    );

    Vehicle? matchedVehicle;
    if (expense.vehicleId != null) {
      matchedVehicle = _vehicles.cast<Vehicle?>().firstWhere(
            (v) => v?.id == expense.vehicleId,
            orElse: () => null,
          );
    }

    Driver? matchedDriver;
    if (expense.driverId != null) {
      matchedDriver = _drivers.cast<Driver?>().firstWhere(
            (d) => d?.id == expense.driverId,
            orElse: () => null,
          );
    }

    try {
      final bytes = await ExpensePdfGenerator.generate(
        expense: expense,
        company: company,
        vehicle: matchedVehicle,
        driver: matchedDriver,
      );

      if (!mounted) return;

      showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Color(AppColorValues.primaryGold)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'معاينة سند صرف A4: ${expense.expenseNumber}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      border: Border.all(color: Colors.greenAccent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.greenAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'تم توليد سند الصرف A4 PDF بنجاح (${(bytes.length / 1024).toStringAsFixed(1)} KB) وفق معايير שובר הוצאה ותשלום الرسمية.',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('بند المصروف والقيمة'),
                    subtitle: Text(
                      '${expense.category.arabicLabel} (${expense.category.hebrewLabel}) - ${formatCurrency(expense.amount)} [${expense.paymentMethod.arabicLabel}]',
                    ),
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('البيان والوصف'),
                    subtitle: Text(expense.description),
                  ),
                  if (matchedVehicle != null || matchedDriver != null)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('الشاحنة والسائق المنسوب لهما'),
                      subtitle: Text(
                        '${matchedVehicle?.name ?? "-"} | السائق: ${matchedDriver?.fullName ?? "-"} ${expense.odometerReading != null ? "(${expense.odometerReading} كم)" : ""}',
                      ),
                    ),
                  if (expense.reference != null)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('رقم المرجع / الإيصال'),
                      subtitle: Text(expense.reference!),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('إغلاق / סגור'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppColorValues.primaryGold),
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.print, size: 18),
                label: const Text('طباعة سند الصرف / הדפסה'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إرسال سند الصرف إلى الطابعة')),
                  );
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في توليد PDF: $e'), backgroundColor: Colors.red),
      );
    }
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

  void _showNewPurchaseDialog() {
    final availableSuppliers = _contacts
        .where((c) => c.type == ContactType.supplier || c.type == ContactType.both)
        .toList();

    if (availableSuppliers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد موردين مسجلين في النظام')),
      );
      return;
    }

    final nextNumber = 'PUR-2026-${(_purchaseInvoices.length + 101).toString().padLeft(5, '0')}';

    final invoiceNumberCtrl = TextEditingController(text: nextNumber);
    final supplierInvoiceCtrl = TextEditingController();
    final quantityCtrl = TextEditingController(text: '100');
    final unitCostCtrl = TextEditingController();
    final paidAmountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    Contact selectedSupplier = availableSuppliers.first;
    Product selectedProduct = _products.first;
    UnitType selectedUnit = selectedProduct.unitType;
    unitCostCtrl.text = selectedProduct.purchaseCost.toStringAsFixed(2);

    final List<PurchaseItemDraft> draftItems = [];
    bool isPaidImmediately = false;
    String? validationError;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final double currentQty = double.tryParse(quantityCtrl.text.trim()) ?? 0.0;
            final double currentUnitCost = double.tryParse(unitCostCtrl.text.trim()) ?? 0.0;

            final double previewConvertedStock = UnitConverter.calculateStockAddition(
              product: selectedProduct,
              quantity: currentQty > 0 ? currentQty : 1.0,
              purchasedUnit: selectedUnit,
            );

            // Compute effective items: if draftItems is not empty, use draftItems.
            // If empty and currentQty > 0, include single item preview.
            final List<PurchaseItemDraft> effectiveItems = List.from(draftItems);
            if (effectiveItems.isEmpty && currentQty > 0 && currentUnitCost >= 0) {
              effectiveItems.add(
                PurchaseItemDraft(
                  product: selectedProduct,
                  unitType: selectedUnit,
                  quantity: currentQty,
                  unitCost: currentUnitCost,
                ),
              );
            }

            final double subtotal = ((effectiveItems.fold<double>(0.0, (acc, item) => acc + item.subtotal)) * 100).roundToDouble() / 100.0;
            final double vatAmount = ((subtotal * 0.17) * 100).roundToDouble() / 100.0;
            final double totalAmount = ((subtotal + vatAmount) * 100).roundToDouble() / 100.0;

            final double enteredPaid = double.tryParse(paidAmountCtrl.text.trim()) ?? 0.0;
            final double effectivePaid = isPaidImmediately ? totalAmount : enteredPaid;
            final double onAccount = ((totalAmount - effectivePaid) * 100).roundToDouble() / 100.0;
            final double projectedBalance = ((selectedSupplier.currentBalance + onAccount) * 100).roundToDouble() / 100.0;

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.inventory_2, color: Color(AppColorValues.primaryGold)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'توريد بضاعة وفاتورة مشتريات جديدة / קליטת רכש ומלאי',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Supplier selection
                      DropdownButtonFormField<Contact>(
                        initialValue: selectedSupplier,
                        decoration: const InputDecoration(
                          labelText: 'المورد المسجل / ספק רשום',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: availableSuppliers.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text('${s.name} (رصيد: ${formatCurrency(s.currentBalance)})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedSupplier = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Invoice numbers
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: invoiceNumberCtrl,
                              decoration: const InputDecoration(
                                labelText: 'رقم الفاتورة الداخلي / מס\' חשבונית',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: supplierInvoiceCtrl,
                              decoration: const InputDecoration(
                                labelText: 'رقم فاتورة المورد / חשבונית ספק',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      const Text(
                        'إضافة صنف للتوريد / הוספת פריט:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),

                      // Product selection
                      DropdownButtonFormField<Product>(
                        initialValue: selectedProduct,
                        decoration: const InputDecoration(
                          labelText: 'المنتج / الصنف',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: _products.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text('${p.name} (المخزون الحالي: ${p.currentStock.toStringAsFixed(1)})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedProduct = val;
                              selectedUnit = val.unitType;
                              unitCostCtrl.text = val.purchaseCost.toStringAsFixed(2);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),

                      // Unit & Quantity & Unit Cost
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<UnitType>(
                              initialValue: selectedUnit,
                              decoration: const InputDecoration(
                                labelText: 'وحدة التوريد / יחידה',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: (selectedProduct.unitType == UnitType.piece
                                      ? [UnitType.piece]
                                      : [UnitType.meter, UnitType.box])
                                  .map((u) {
                                return DropdownMenuItem(
                                  value: u,
                                  child: Text(u == UnitType.meter
                                      ? 'متر مربع (م²)'
                                      : u == UnitType.box
                                          ? 'كرتونة (Box)'
                                          : 'حبة (Piece)'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    selectedUnit = val;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: quantityCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'الكمية / כמות',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: unitCostCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'التكلفة (₪)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Dual-unit conversion preview banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(AppColorValues.primaryGold).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(AppColorValues.primaryGold).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sync_alt, size: 16, color: Color(AppColorValues.primaryGold)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedProduct.meterPerBox != null
                                    ? (selectedUnit == UnitType.box
                                        ? 'التحويل: $currentQty كرتونة = ${previewConvertedStock.toStringAsFixed(2)} م² ستضاف للمخزون (معدل ${selectedProduct.meterPerBox} م²/كرتونة)'
                                        : 'التحويل: $currentQty م² = ${(currentQty / (selectedProduct.meterPerBox ?? 1.0)).toStringAsFixed(2)} كرتونة')
                                    : 'الكمية المضافة للمخزون: $currentQty ${selectedProduct.unitType == UnitType.meter ? "م²" : "حبة"}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(AppColorValues.primaryGold),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Add Item to Draft Button
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(AppColorValues.primaryGold),
                            side: const BorderSide(color: Color(AppColorValues.primaryGold)),
                          ),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('إضافة الصنف إلى المسودة'),
                          onPressed: () {
                            if (currentQty <= 0) {
                              setDialogState(() {
                                validationError = 'يرجى إدخال كمية توريد أكبر من الصفر';
                              });
                              return;
                            }
                            if (currentUnitCost < 0) {
                              setDialogState(() {
                                validationError = 'سعر التكلفة لا يمكن أن يكون سالباً';
                              });
                              return;
                            }
                            setDialogState(() {
                              draftItems.add(
                                PurchaseItemDraft(
                                  product: selectedProduct,
                                  unitType: selectedUnit,
                                  quantity: currentQty,
                                  unitCost: currentUnitCost,
                                ),
                              );
                              quantityCtrl.text = '';
                              validationError = null;
                            });
                          },
                        ),
                      ),

                      // Show Draft Items List
                      if (draftItems.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('الأصناف في المسودة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        ...draftItems.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.product.name} - ${item.quantity} ${item.unitType.name} × ${formatCurrency(item.unitCost)} (+${item.convertedStock.toStringAsFixed(1)} للمخزون)',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                                Text(
                                  formatCurrency(item.subtotal),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                  onPressed: () {
                                    setDialogState(() {
                                      draftItems.removeAt(idx);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 12),

                      // Financial Summary Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('المجموع الفرعي (قبل الضريبة):', style: TextStyle(fontSize: 12)),
                                Text(formatCurrency(subtotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('ضريبة القيمة المضافة (17% מע"מ):', style: TextStyle(fontSize: 12)),
                                Text(formatCurrency(vatAmount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('الإجمالي شامل الضريبة:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                Text(
                                  formatCurrency(totalAmount),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(AppColorValues.primaryGold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Payment Mode switch
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Switch(
                                value: isPaidImmediately,
                                activeThumbColor: const Color(AppColorValues.primaryGold),
                                onChanged: (val) {
                                  setDialogState(() {
                                    isPaidImmediately = val;
                                    if (val) {
                                      paidAmountCtrl.text = totalAmount.toStringAsFixed(2);
                                    } else {
                                      paidAmountCtrl.text = '0.00';
                                    }
                                  });
                                },
                              ),
                              Text(
                                isPaidImmediately ? 'مسددة فورياً بالكامل' : 'قيد على الحساب (آجل للمورد)',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),

                      if (!isPaidImmediately) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            'الرصيد المستحق للمورد بعد القيد: ${formatCurrency(projectedBalance)} (+${formatCurrency(onAccount)})',
                            style: const TextStyle(fontSize: 12, color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),

                      // Notes input
                      TextField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات وتفاصيل التوريد / הערות',
                          border: OutlineInputBorder(),
                          isDense: true,
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
                  label: const Text('تأكيد التوريد وتحديث الأرصدة'),
                  onPressed: () {
                    final invNumber = invoiceNumberCtrl.text.trim();
                    if (invNumber.isEmpty) {
                      setDialogState(() {
                        validationError = 'يرجى إدخال رقم الفاتورة الداخلي';
                      });
                      return;
                    }

                    if (effectiveItems.isEmpty) {
                      setDialogState(() {
                        validationError = 'يرجى إدخال صنف واحد على الأقل مع كمية صحيحة';
                      });
                      return;
                    }

                    try {
                      final input = CreatePurchaseInput(
                        invoiceNumber: invNumber,
                        supplierInvoiceNumber: supplierInvoiceCtrl.text.trim().isNotEmpty
                            ? supplierInvoiceCtrl.text.trim()
                            : null,
                        date: DateTime.now(),
                        supplier: selectedSupplier,
                        items: effectiveItems.map((i) {
                          return PurchaseLineItemInput(
                            product: i.product,
                            unitType: i.unitType,
                            quantity: i.quantity,
                            unitCost: i.unitCost,
                          );
                        }).toList(),
                        vatRate: 0.17,
                        paidAmount: effectivePaid,
                        notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                        createdBy: 'diaaldin',
                      );

                      final result = PurchaseService.processPurchase(input);

                      setState(() {
                        for (final updated in result.updatedProducts) {
                          final pIdx = _products.indexWhere((p) => p.id == updated.id);
                          if (pIdx != -1) {
                            _products[pIdx] = updated;
                          }
                        }
                        final sIdx = _contacts.indexWhere((c) => c.id == result.updatedSupplier.id);
                        if (sIdx != -1) {
                          _contacts[sIdx] = result.updatedSupplier;
                        }
                        if (result.statementEntry != null) {
                          _statementController.addEntry(result.statementEntry!);
                        }
                        _purchaseInvoices.insert(0, result.purchase);
                      });

                      Navigator.of(dialogCtx).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'تم تسجيل فاتورة التوريد رقم ${result.purchase.invoiceNumber} وتحديث أرصدة المخزون والمورد بنجاح',
                          ),
                          backgroundColor: const Color(AppColorValues.successGreen),
                          action: SnackBarAction(
                            label: 'معاينة PDF',
                            textColor: Colors.black,
                            onPressed: () {
                              _showPurchasePdfPreview(result.purchase, result.updatedSupplier);
                            },
                          ),
                        ),
                      );
                    } catch (e) {
                      setDialogState(() {
                        validationError = 'خطأ في معالجة فاتورة الشراء: $e';
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
      invoiceNumberCtrl.dispose();
      supplierInvoiceCtrl.dispose();
      quantityCtrl.dispose();
      unitCostCtrl.dispose();
      paidAmountCtrl.dispose();
      notesCtrl.dispose();
    });
  }

  void _showPurchasePdfPreview(PurchaseInvoice invoice, [Contact? supplier]) async {
    const company = CompanyInfo(
      name: 'M.I.R.N POWER Ltd.',
      nameArabic: 'شركة م.ي.ر.ن باور م.ض',
      nameHebrew: 'מ.י.ר.ן פאוור בע"מ',
      subtitleArabic: 'أدوات صحية، رخام، حجر، ونقل وشحن',
      subtitleHebrew: 'כלים סניטריים, שיש, אבן והובלה',
      taxId: '515892104',
      phone: '02-1234567',
      address: 'אזור התעשייה עטרות / عطروت, ירושלים',
    );

    try {
      final bytes = await PurchasePdfGenerator.generate(
        invoice: invoice,
        company: company,
        supplier: supplier,
      );

      if (!mounted) return;

      showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Color(AppColorValues.primaryGold)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'معاينة فاتورة توريد: ${invoice.invoiceNumber}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      border: Border.all(color: Colors.greenAccent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.greenAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'تم توليد مستند A4 PDF بنجاح (${(bytes.length / 1024).toStringAsFixed(1)} KB) وفق المعايير الرسمية المعتمدة.',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('المورد / ספק'),
                    subtitle: Text(invoice.supplierName),
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('رقم الفاتورة الخارجية'),
                    subtitle: Text(invoice.supplierInvoiceNumber ?? 'N/A'),
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('الإجمالي شامل الضريبة (17%)'),
                    subtitle: Text(
                      formatCurrency(invoice.totalAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(AppColorValues.primaryGold),
                      ),
                    ),
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('الأصناف الموردة'),
                    subtitle: Text('${invoice.items.length} أصناف مسجلة'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('إغلاق / סגור'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppColorValues.primaryGold),
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.print, size: 18),
                label: const Text('طباعة / הדפסה'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إرسال مستند التوريد إلى طابعة الفواتير')),
                  );
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في توليد PDF: $e')),
      );
    }
  }
}
