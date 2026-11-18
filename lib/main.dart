import 'dart:async';
import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'core/localization/app_locale.dart';
import 'core/pdf/delivery_note_pdf_generator.dart';
import 'core/pdf/expense_pdf_generator.dart';
import 'core/pdf/invoice_pdf_generator.dart';
import 'core/pdf/purchase_pdf_generator.dart';
import 'core/theme/mirn_theme.dart';
import 'core/utils/currency_formatter.dart';
import 'core/di/service_locator.dart';
import 'features/auth/domain/models/app_user.dart';
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
import 'features/sales/domain/models/sale_invoice.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/di/firestore_service_locator.dart';
import 'core/services/firestore_seeder.dart';
import 'features/returns/domain/models/credit_note.dart';
import 'features/sales/presentation/screens/sales_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    setupFirestoreRepositories();
    debugPrint('Firebase & Cloud Firestore initialized successfully for project mirn-power-system');
  } catch (e) {
    debugPrint('Running in standalone mode (Firebase initialization skipped: $e)');
  }
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
  AppUser? _currentUser;
  StreamSubscription<AppUser?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    if (!ServiceLocator.instance.isInitialized) {
      ServiceLocator.instance.initialize(
        initialProducts: _products,
        initialContacts: _contacts,
      );
    }
    _currentUser = ServiceLocator.instance.authRepository.currentUser;
    _authSubscription = ServiceLocator.instance.authRepository.watchCurrentUser().listen((user) {
      if (mounted) setState(() => _currentUser = user);
    });
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
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
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
              if (_currentUser != null)
                PopupMenuButton<String>(
                  tooltip: 'تبديل المستخدم والصلاحيات / החלף משתמש',
                  color: surfaceDark,
                  offset: const Offset(0, 48),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: goldColor.withValues(alpha: 0.15),
                      border: Border.all(color: goldColor.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_circle, size: 18, color: goldColor),
                        const SizedBox(width: 6),
                        Text(
                          '${_currentUser!.name.split(' / ').first} (${_currentLanguage == AppLanguage.arabic ? _currentUser!.role.arabicLabel : _currentUser!.role.hebrewLabel})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: goldColor),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 16, color: goldColor),
                      ],
                    ),
                  ),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem<String>(
                      enabled: false,
                      child: Text('اختر المستخدم / בחר משתמש', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ),
                    const PopupMenuItem<String>(
                      value: 'usr-admin',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.admin_panel_settings, color: Colors.amber),
                        title: Text('ضياء الدين (مدير النظام)'),
                        subtitle: Text('صلاحيات كاملة لجميع الأنظمة'),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'usr-acc',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.account_balance, color: Colors.lightBlue),
                        title: Text('أحمد النتشة (محاسب مالي)'),
                        subtitle: Text('كشوفات حساب، شيكات، فواتير'),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'usr-cashier',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.point_of_sale, color: Colors.green),
                        title: Text('سامح الجعبري (كاشير مبيعات)'),
                        subtitle: Text('كاونتر المبيعات وسندات القبض'),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'usr-disp',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.local_shipping, color: Colors.orange),
                        title: Text('خليل بركات (سيدر نقليات)'),
                        subtitle: Text('إرساليات الأسطول ومصاريف التشغيل'),
                      ),
                    ),
                  ],
                  onSelected: (userId) async {
                    await ServiceLocator.instance.authRepository.switchUser(userId);
                  },
                ),
              const SizedBox(width: 8),
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

  Widget _buildAccessRestrictedView(String requiredRole, IconData icon) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: const Color(AppColorValues.cardDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: Colors.redAccent),
            ),
            const SizedBox(height: 16),
            const Text(
              'صلاحية مقيدة / גישה מוגבלת (RBAC)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'هذه الشاشة تتطلب صلاحية: $requiredRole.\nמשתמש נוכחי חסר הרשאות מתאימות לצפייה במסך זה.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppColorValues.primaryGold),
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text('تبديل المستخدم إلى مدير النظام / החלף משתמש'),
              onPressed: () async {
                await ServiceLocator.instance.authRepository.switchUser('usr-admin');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    final user = _currentUser;
    switch (_selectedTabIndex) {
      case 0:
        return _buildDashboardScreen();
      case 1:
        if (user != null && !user.canAccessPos) {
          return _buildAccessRestrictedView('كاشير مبيعات أو مدير نظام (קופאי / מנהל)', Icons.point_of_sale);
        }
        return _buildSalesPosScreen();
      case 2:
        return _buildInventoryScreen();
      case 3:
        if (user != null && !user.canManageLedgers) {
          return _buildAccessRestrictedView('محاسب مالي أو مدير نظام (רואה חשבון / מנהל)', Icons.account_balance_wallet);
        }
        return _buildStatementScreen();
      case 4:
        if (user != null && !user.canManageChecks) {
          return _buildAccessRestrictedView('إدارة الشيكات والمقاصة (רואה חשבון / מנהל)', Icons.fact_check);
        }
        return _buildChecksScreen();
      case 5:
        if (user != null && !user.canDispatchFleet && !user.canRecordExpenses) {
          return _buildAccessRestrictedView('سيدر نقليات أو مدير أسطول (סדרן צי / מנהל)', Icons.local_shipping);
        }
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
        Card(
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(AppColorValues.primaryGold), width: 0.8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.cloud_upload_outlined, color: Color(AppColorValues.primaryGold), size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentLanguage == AppLanguage.arabic
                            ? 'تغذية السحابة بالبيانات الافتتاحية (Cloud Firestore Seeder)'
                            : 'טעינת נתונים ראשוניים לענן / Cloud Seeder',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentLanguage == AppLanguage.arabic
                            ? 'رفع أصناف الرخام والبورسلان، شركات المقاولات، وشاحنات النقل إلى مشروع mirn-power-system'
                            : 'העלאת קטלוג שיש, לקוחות וצי רכב לפרויקט mirn-power-system',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppColorValues.primaryGold),
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: Text(
                    _currentLanguage == AppLanguage.arabic ? 'تغذية السحابة الآن' : 'הפעל טעינה',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('جارِ رفع البيانات الافتتاحية إلى Cloud Firestore...')),
                    );
                    final res = await FirestoreSeeder.seedAll();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: res.success ? Colors.green.shade800 : Colors.red.shade800,
                          content: Text(res.message),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
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
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orangeAccent,
                            side: const BorderSide(color: Colors.orangeAccent),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          icon: const Icon(Icons.assignment_return, size: 16),
                          label: const Text('إرجاع وإصدار זיכוי (Credit Note)', style: TextStyle(fontSize: 12)),
                          onPressed: () => _showCreateCreditNoteDialog(context),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
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
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Contact>(
                        initialValue: state.selectedCustomer ??
                            (_contacts.any((c) => c.type != ContactType.supplier)
                                ? _contacts.firstWhere((c) => c.type != ContactType.supplier)
                                : null),
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
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'إضافة عميل جديد / הוסף לקוח חדש',
                      icon: const Icon(Icons.person_add, color: Color(AppColorValues.primaryGold)),
                      onPressed: () => _showAddContactDialog(context),
                    ),
                  ],
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'الأصناف في الفاتورة الحالية / פריטים בחשבונית',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(AppColorValues.primaryGold),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          icon: const Icon(Icons.add_shopping_cart, size: 16),
                          label: const Text('إضافة صنف / הוסף פריט', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () => _showAddPosItemDialog(context),
                        ),
                        if (state.items.isNotEmpty)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            ),
                            icon: const Icon(Icons.delete_sweep, size: 16),
                            label: const Text('تفريغ', style: TextStyle(fontSize: 12)),
                            onPressed: () => setState(() => _posController.clearItems()),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (state.items.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    alignment: Alignment.center,
                    child: const Text(
                      'السلة فارغة حالياً. اضغط "إضافة صنف" لإدراج منتجات للفاتورة.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ...state.items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.productName),
                      subtitle: Text('${item.quantity} ${item.unitType.name} × ${formatCurrency(item.unitPrice)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(formatCurrency(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            tooltip: 'حذف الصنف',
                            onPressed: () => setState(() => _posController.removeItem(idx)),
                          ),
                        ],
                      ),
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(AppColorValues.primaryGold),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 3,
                    ),
                    icon: const Icon(Icons.point_of_sale, size: 22),
                    label: const Text(
                      'إتمام عملية البيع والدفع (Checkout) / סיום קנייה ותשלום',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: state.items.isEmpty ? null : () => _showPaymentDialog(context),
                  ),
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(AppColorValues.primaryGold),
                        side: const BorderSide(color: Color(AppColorValues.primaryGold)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      icon: const Icon(Icons.add_box, size: 18),
                      label: Text(
                        _currentLanguage == AppLanguage.arabic
                            ? 'إضافة صنف جديد للمستودع'
                            : 'הוסף מוצר חדש למלאי',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _showAddProductDialog(context),
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
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(AppColorValues.primaryGold),
                            side: const BorderSide(color: Color(AppColorValues.primaryGold)),
                          ),
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('إضافة عميل/مورد / הוסף לקוח או ספק'),
                          onPressed: () => _showAddContactDialog(context),
                        ),
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

  void _showAddPosItemDialog(BuildContext context) {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد أصناف في المستودع لإضافتها')),
      );
      return;
    }

    Product selectedProduct = _products.first;
    final qtyCtrl = TextEditingController(text: '1.0');
    final priceCtrl = TextEditingController(
      text: selectedProduct.sellingPrice.toStringAsFixed(2),
    );
    UnitType selectedUnit = selectedProduct.unitType;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(AppColorValues.cardDark),
              title: const Row(
                children: [
                  Icon(Icons.add_shopping_cart, color: Color(AppColorValues.primaryGold)),
                  SizedBox(width: 8),
                  Text('إضافة صنف للفاتورة / הוסף פריט לסל', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<Product>(
                        initialValue: selectedProduct,
                        decoration: const InputDecoration(
                          labelText: 'الصنف / פריט *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: _products.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text(
                              '${p.sku} - ${p.name.split(' / ').first} (متوفر: ${p.currentStock.toStringAsFixed(1)} ${p.unitType.name})',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedProduct = val;
                              selectedUnit = val.unitType;
                              priceCtrl.text = val.sellingPrice.toStringAsFixed(2);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: qtyCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'الكمية / כמות *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<UnitType>(
                              initialValue: selectedUnit,
                              decoration: const InputDecoration(
                                labelText: 'الوحدة / יחידה',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: UnitType.values.map((u) {
                                return DropdownMenuItem(
                                  value: u,
                                  child: Text('${u.arabicLabel} (${u.hebrewLabel})', style: const TextStyle(fontSize: 12)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => selectedUnit = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'سعر الوحدة (${_posController.state.isTaxInclusiveInput ? "شامل الضريبة" : "قبل الضريبة"}) / מחיר',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('إلغاء / ביטול'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppColorValues.primaryGold),
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة إلى السلة'),
                  onPressed: () {
                    final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0.0;
                    final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                    if (qty <= 0 || price < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى إدخال كمية وسعر صحيحين')),
                      );
                      return;
                    }

                    setState(() {
                      _posController.addItem(
                        product: selectedProduct,
                        quantity: qty,
                        unit: selectedUnit,
                        unitPriceInput: price,
                      );
                    });

                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      qtyCtrl.dispose();
      priceCtrl.dispose();
    });
  }

  void _showPaymentDialog(BuildContext context) {
    final state = _posController.state;
    if (state.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سلة المبيعات فارغة، أضف أصنافاً أولاً')),
      );
      return;
    }

    final double totalToPay = state.totalAmount;
    final bool requiresAllocation = totalToPay >= 25000.0;

    final cashCtrl = TextEditingController();
    final checkCtrl = TextEditingController();
    final transferCtrl = TextEditingController();
    final debtCtrl = TextEditingController();
    final allocationNumberCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    // Check specific fields
    final checkNumberCtrl = TextEditingController();
    final bankNameCtrl = TextEditingController(text: 'בנק הפועלים (12)');
    final branchCtrl = TextEditingController(text: '680');
    final accountCtrl = TextEditingController();
    DateTime checkDueDate = DateTime.now().add(const Duration(days: 30));

    // Transfer specific field
    final transferRefCtrl = TextEditingController();

    // Default to cash payment full amount
    cashCtrl.text = totalToPay.toStringAsFixed(2);

    String? validationError;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final double cash = double.tryParse(cashCtrl.text.trim()) ?? 0.0;
            final double check = double.tryParse(checkCtrl.text.trim()) ?? 0.0;
            final double transfer = double.tryParse(transferCtrl.text.trim()) ?? 0.0;
            final double debt = double.tryParse(debtCtrl.text.trim()) ?? 0.0;

            final double totalPaid = cash + check + transfer + debt;
            final double difference = totalToPay - totalPaid;
            final bool isBalanced = difference.abs() < 0.01;

            return AlertDialog(
              backgroundColor: const Color(AppColorValues.cardDark),
              title: const Row(
                children: [
                  Icon(Icons.point_of_sale, color: Color(AppColorValues.primaryGold)),
                  SizedBox(width: 8),
                  Text(
                    'إتمام الدفع وإصدار الفاتورة الضريبية / תשלום וחשבונית',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                      // Financial Summary Header
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('المجموع الفرعي (قبل الضريبة):', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(formatCurrency(state.subtotal), style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('ضريبة القيمة المضافة (מע"מ 17%):', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(formatCurrency(state.vatAmount), style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            const Divider(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('الإجمالي المطلوب سداده:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text(
                                  formatCurrency(totalToPay),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(AppColorValues.primaryGold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Customer indicator
                      if (state.selectedCustomer != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person, size: 16, color: Colors.lightBlueAccent),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'الزبون: ${state.selectedCustomer!.name} (رصيد حالي: ${formatCurrency(state.selectedCustomer!.currentBalance)})',
                                  style: const TextStyle(fontSize: 12, color: Colors.lightBlueAccent),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),

                      // Statutory Allocation Number (Israel Tax Authority requirement)
                      if (requiresAllocation)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.gavel, color: Colors.amber, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'إلزامي قانونياً: فاتورة تتجاوز 25,000 ₪ تتطلب رقم تخصيص (מספר הקצאה)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.amber),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: allocationNumberCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'رقم التخصيص من سلطة الضرائب (9 أرقام) *',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Quick action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                side: const BorderSide(color: Colors.greenAccent),
                              ),
                              icon: const Icon(Icons.money, size: 16, color: Colors.greenAccent),
                              label: const Text('دفع كامل نقداً', style: TextStyle(fontSize: 12, color: Colors.greenAccent)),
                              onPressed: () {
                                setDialogState(() {
                                  cashCtrl.text = totalToPay.toStringAsFixed(2);
                                  checkCtrl.clear();
                                  transferCtrl.clear();
                                  debtCtrl.clear();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                side: const BorderSide(color: Colors.orangeAccent),
                              ),
                              icon: const Icon(Icons.account_balance_wallet, size: 16, color: Colors.orangeAccent),
                              label: const Text('كامل على الحساب', style: TextStyle(fontSize: 12, color: Colors.orangeAccent)),
                              onPressed: () {
                                setDialogState(() {
                                  debtCtrl.text = totalToPay.toStringAsFixed(2);
                                  cashCtrl.clear();
                                  checkCtrl.clear();
                                  transferCtrl.clear();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Split payment fields
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: cashCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'نقداً / מזומן (₪)',
                                prefixIcon: Icon(Icons.attach_money, size: 18),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: debtCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'على الحساب / חוב (₪)',
                                prefixIcon: Icon(Icons.person_outline, size: 18),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: checkCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'شيك بنكي / שיק (₪)',
                                prefixIcon: Icon(Icons.receipt, size: 18),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: transferCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'تحويل بنكي / העברה (₪)',
                                prefixIcon: Icon(Icons.account_balance, size: 18),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                        ],
                      ),

                      // Check Details Section if check > 0
                      if (check > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blueGrey),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('بيانات الشيك البنكي / פרטי השיק', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: checkNumberCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'رقم الشيك *',
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
                                        labelText: 'اسم البنك *',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: branchCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'الفرع',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: accountCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'رقم الحساب',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: const Text('تاريخ استحقاق الشيك / תאריך פירעון', style: TextStyle(fontSize: 12)),
                                subtitle: Text('${checkDueDate.year}-${checkDueDate.month.toString().padLeft(2, '0')}-${checkDueDate.day.toString().padLeft(2, '0')}'),
                                trailing: const Icon(Icons.calendar_today, size: 16),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: checkDueDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                  );
                                  if (picked != null) {
                                    setDialogState(() => checkDueDate = picked);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Transfer details if transfer > 0
                      if (transfer > 0) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: transferRefCtrl,
                          decoration: const InputDecoration(
                            labelText: 'رقم مرجع التحويل البنكي / אסמכתא',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),
                      TextField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات الفاتورة (اختياري)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Math status banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isBalanced
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isBalanced ? Colors.greenAccent : Colors.redAccent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isBalanced ? Icons.check_circle : Icons.error_outline,
                              color: isBalanced ? Colors.greenAccent : Colors.redAccent,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isBalanced
                                    ? 'المبلغ مطابق تماماً للإجمالي (${formatCurrency(totalPaid)})'
                                    : 'المتبقي للتغطية: ${formatCurrency(difference)} (المسدد: ${formatCurrency(totalPaid)})',
                                style: TextStyle(
                                  color: isBalanced ? Colors.greenAccent : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (validationError != null) ...[
                        const SizedBox(height: 8),
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
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: const Text('تأكيد وإصدار الفاتورة / הנפק חשבונית'),
                  onPressed: () async {
                    if (!isBalanced) {
                      setDialogState(() {
                        validationError = 'يرجى مطابقة مجموع طرق الدفع مع إجمالي الفاتورة بدقة';
                      });
                      return;
                    }

                    if (debt > 0 && state.selectedCustomer == null) {
                      setDialogState(() {
                        validationError = 'يرجى اختيار عميل لتسجيل المبلغ على الحساب ذمة';
                      });
                      return;
                    }

                    if (check > 0) {
                      if (checkNumberCtrl.text.trim().isEmpty || bankNameCtrl.text.trim().isEmpty) {
                        setDialogState(() {
                          validationError = 'يرجى إدخال رقم الشيك واسم البنك بدقة';
                        });
                        return;
                      }
                    }

                    if (requiresAllocation && allocationNumberCtrl.text.trim().isEmpty) {
                      setDialogState(() {
                        validationError = 'رقم التخصيص إلزامي للفواتير بقيمة 25,000 ₪ فأكثر وفق القانون';
                      });
                      return;
                    }

                    try {
                      final invoiceNumber = 'INV-2026-${(DateTime.now().millisecondsSinceEpoch % 100000).toString().padLeft(5, '0')}';

                      final List<PaymentSplit> payments = [];
                      if (cash > 0) payments.add(PaymentSplit(method: PaymentMethod.cash, amount: cash));
                      if (check > 0) {
                        payments.add(
                          PaymentSplit(
                            method: PaymentMethod.check,
                            amount: check,
                            reference: 'Check #${checkNumberCtrl.text.trim()}',
                          ),
                        );
                      }
                      if (transfer > 0) {
                        payments.add(
                          PaymentSplit(
                            method: PaymentMethod.bankTransfer,
                            amount: transfer,
                            reference: transferRefCtrl.text.trim().isEmpty ? null : transferRefCtrl.text.trim(),
                          ),
                        );
                      }
                      if (debt > 0) {
                        payments.add(PaymentSplit(method: PaymentMethod.debt, amount: debt, reference: 'على الحساب'));
                      }

                      CheckRecord? checkRecord;
                      if (check > 0) {
                        checkRecord = CheckRecord(
                          id: 'chk-${DateTime.now().millisecondsSinceEpoch}',
                          checkNumber: checkNumberCtrl.text.trim(),
                          bankName: bankNameCtrl.text.trim(),
                          branchNumber: branchCtrl.text.trim().isEmpty ? '001' : branchCtrl.text.trim(),
                          accountNumber: accountCtrl.text.trim().isEmpty ? '000000' : accountCtrl.text.trim(),
                          amount: check,
                          dueDate: checkDueDate,
                          type: CheckType.received,
                          partyId: state.selectedCustomer?.id ?? 'walk-in',
                          partyName: state.selectedCustomer?.name ?? 'زبون نقدي / לקוח מזומן',
                          relatedTransactionId: invoiceNumber,
                          status: CheckStatus.pending,
                          history: [
                            CheckHistoryEntry(
                              status: CheckStatus.pending,
                              changedAt: DateTime.now(),
                              notes: 'شيك مقبوض من فاتورة مبيعات $invoiceNumber',
                              changedBy: _currentUser?.name.split(' / ').first ?? 'diaaldin',
                            ),
                          ],
                          createdAt: DateTime.now(),
                        );
                      }

                      final saleInvoice = SaleInvoice(
                        id: 'sale-${DateTime.now().millisecondsSinceEpoch}',
                        invoiceNumber: invoiceNumber,
                        date: DateTime.now(),
                        customerId: state.selectedCustomer?.id ?? 'walk-in',
                        customerName: state.selectedCustomer?.name ?? 'زبون نقدي / לקוח מזומן',
                        customerTaxId: state.selectedCustomer?.taxId ?? '000000000',
                        isTaxInclusiveInput: state.isTaxInclusiveInput,
                        items: state.items,
                        subtotal: state.subtotal,
                        vatRate: state.vatRate,
                        vatAmount: state.vatAmount,
                        totalAmount: state.totalAmount,
                        payments: payments,
                        allocationNumber: allocationNumberCtrl.text.trim().isEmpty ? null : allocationNumberCtrl.text.trim(),
                        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                        createdBy: _currentUser?.name.split(' / ').first ?? 'diaaldin',
                        createdAt: DateTime.now(),
                      );

                      if (ServiceLocator.instance.isInitialized) {
                        await ServiceLocator.instance.saleOrchestrator.processSaleTransaction(
                          sale: saleInvoice,
                          customer: state.selectedCustomer,
                          checks: checkRecord != null ? [checkRecord] : null,
                        );
                      }

                      // In-memory local state synchronization
                      setState(() {
                        // 1. Decrement stock
                        for (final item in saleInvoice.items) {
                          final pIdx = _products.indexWhere((p) => p.id == item.productId);
                          if (pIdx != -1) {
                            final oldP = _products[pIdx];
                            _products[pIdx] = Product(
                              id: oldP.id,
                              name: oldP.name,
                              sku: oldP.sku,
                              category: oldP.category,
                              unitType: oldP.unitType,
                              meterPerBox: oldP.meterPerBox,
                              purchaseCost: oldP.purchaseCost,
                              sellingPrice: oldP.sellingPrice,
                              currentStock: (oldP.currentStock - item.quantity).clamp(0.0, double.infinity),
                              minStockAlert: oldP.minStockAlert,
                              createdAt: oldP.createdAt,
                            );
                          }
                        }

                        // 2. Customer debt update
                        if (debt > 0 && state.selectedCustomer != null) {
                          final cIdx = _contacts.indexWhere((c) => c.id == state.selectedCustomer!.id);
                          if (cIdx != -1) {
                            final oldC = _contacts[cIdx];
                            final updatedC = Contact(
                              id: oldC.id,
                              name: oldC.name,
                              taxId: oldC.taxId,
                              phone: oldC.phone,
                              address: oldC.address,
                              type: oldC.type,
                              currentBalance: oldC.currentBalance + debt,
                              debtWarningLimit: oldC.debtWarningLimit,
                            );
                            _contacts[cIdx] = updatedC;
                            _statementController.updateContact(updatedC);
                            _statementController.addEntry(
                              StatementEntry(
                                id: 'stmt-${saleInvoice.id}',
                                contactId: updatedC.id,
                                contactType: ContactType.customer,
                                date: saleInvoice.date,
                                type: StatementEntryType.saleInvoice,
                                referenceNumber: saleInvoice.invoiceNumber,
                                debit: debt,
                                credit: 0.0,
                                runningBalance: updatedC.currentBalance,
                                description: 'فاتورة ضريبية / חשבונית מס ${saleInvoice.invoiceNumber}',
                              ),
                            );
                            _posController.setCustomer(updatedC);
                          }
                        }

                        // 3. Add check
                        if (checkRecord != null) {
                          _checksController.addCheck(checkRecord);
                        }

                        // 4. Clear cart
                        _posController.clearItems();
                      });

                      Navigator.of(dialogCtx).pop();

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'تم إصدار الفاتورة الضريبية رقم ${saleInvoice.invoiceNumber} بنجاح',
                          ),
                          backgroundColor: const Color(AppColorValues.successGreen),
                          action: SnackBarAction(
                            label: 'معاينة PDF',
                            textColor: Colors.white,
                            onPressed: () => _showInvoicePdfPreview(saleInvoice, state.selectedCustomer),
                          ),
                        ),
                      );
                    } catch (e) {
                      setDialogState(() {
                        validationError = 'خطأ في معالجة الفاتورة: $e';
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
      cashCtrl.dispose();
      checkCtrl.dispose();
      transferCtrl.dispose();
      debtCtrl.dispose();
      allocationNumberCtrl.dispose();
      notesCtrl.dispose();
      checkNumberCtrl.dispose();
      bankNameCtrl.dispose();
      branchCtrl.dispose();
      accountCtrl.dispose();
      transferRefCtrl.dispose();
    });
  }

  void _showInvoicePdfPreview(SaleInvoice invoice, [Contact? customer]) async {
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
      final bytes = await InvoicePdfGenerator.generate(
        invoice: invoice,
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
                    'معاينة الفاتورة الضريبية: ${invoice.invoiceNumber}',
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
                            'تم توليد فاتورة ضريبية رسمية A4 PDF بنجاح (${(bytes.length / 1024).toStringAsFixed(1)} KB) مطابقة لقانون الضرائب الإسرائيلي 17%.',
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
                    subtitle: Text(invoice.customerName),
                  ),
                  if (invoice.allocationNumber != null)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('رقم التخصيص (מספר הקצאה)'),
                      subtitle: Text(
                        invoice.allocationNumber!,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                      ),
                    ),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('الإجمالي شامل الضريبة 17%'),
                    subtitle: Text(
                      formatCurrency(invoice.totalAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(AppColorValues.primaryGold),
                      ),
                    ),
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
                    const SnackBar(content: Text('تم إرسال الفاتورة إلى طابعة الفواتير')),
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
        SnackBar(content: Text('خطأ في توليد PDF الفاتورة: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAddProductDialog(BuildContext context) {
    final nameArCtrl = TextEditingController();
    final nameHeCtrl = TextEditingController();
    final skuCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final meterPerBoxCtrl = TextEditingController(text: '1.44');
    final minAlertCtrl = TextEditingController(text: '50');
    ProductCategory selectedCategory = ProductCategory.marble;
    UnitType selectedUnit = UnitType.meter;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isMeter = selectedUnit == UnitType.meter;
            return AlertDialog(
              backgroundColor: const Color(AppColorValues.cardDark),
              title: Row(
                children: const [
                  Icon(Icons.add_box, color: Color(AppColorValues.primaryGold)),
                  SizedBox(width: 8),
                  Text('إضافة صنف جديد للمستودع / הוספת מוצר חדש', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nameArCtrl,
                              decoration: const InputDecoration(
                                labelText: 'اسم الصنف (بالعربية) *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: nameHeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'שם המוצר (עברית) *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: skuCtrl,
                              decoration: const InputDecoration(
                                labelText: 'الرمز التجاري / מק"ט (SKU) *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<ProductCategory>(
                              initialValue: selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'التصنيف / קטגוריה',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: ProductCategory.values.map((cat) {
                                return DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat.displayName, style: const TextStyle(fontSize: 12)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => selectedCategory = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<UnitType>(
                              initialValue: selectedUnit,
                              decoration: const InputDecoration(
                                labelText: 'وحدة القياس / יחידת מידה',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: UnitType.values.map((u) {
                                return DropdownMenuItem(
                                  value: u,
                                  child: Text('${u.arabicLabel} (${u.hebrewLabel})', style: const TextStyle(fontSize: 12)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => selectedUnit = val);
                              },
                            ),
                          ),
                          if (isMeter) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: meterPerBoxCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'م² بالكرتونة / מ"ר לקרטון',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: costCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'تكلفة الشراء (₪) / מחיר עלות *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: priceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'سعر البيع (₪) / מחיר מכירה *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: stockCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'الرصيد الابتدائي للمخزون *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: minAlertCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'حد التنبيه (התראת מלאי)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
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
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('إلغاء / ביטול'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppColorValues.primaryGold),
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('حفظ الصنف / שמור מוצר'),
                  onPressed: () async {
                    final nameAr = nameArCtrl.text.trim();
                    final nameHe = nameHeCtrl.text.trim();
                    final sku = skuCtrl.text.trim();
                    final cost = double.tryParse(costCtrl.text.trim());
                    final price = double.tryParse(priceCtrl.text.trim());
                    final stock = double.tryParse(stockCtrl.text.trim()) ?? 0.0;
                    final meterPerBox = isMeter ? double.tryParse(meterPerBoxCtrl.text.trim()) : null;
                    final minAlert = double.tryParse(minAlertCtrl.text.trim()) ?? 0.0;

                    if (nameAr.isEmpty || sku.isEmpty || cost == null || price == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة بالصيغة الصحيحة')),
                      );
                      return;
                    }

                    if (cost < 0 || price < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('لا يمكن لتكلفة الشراء أو سعر البيع أن يكونا بالسالب')),
                      );
                      return;
                    }

                    if (isMeter && (meterPerBox == null || meterPerBox <= 0)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى إدخال معدل م² بالكرتونة صحيح أكبر من الصفر')),
                      );
                      return;
                    }

                    if (_products.any((p) => p.sku.trim().toLowerCase() == sku.toLowerCase())) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('الرمز التجاري $sku مسجل مسبقاً لصنف آخر')),
                      );
                      return;
                    }

                    final newProduct = Product(
                      id: 'prod-${DateTime.now().millisecondsSinceEpoch}',
                      name: nameHe.isNotEmpty ? '$nameAr / $nameHe' : nameAr,
                      sku: sku,
                      category: selectedCategory,
                      unitType: selectedUnit,
                      meterPerBox: meterPerBox,
                      purchaseCost: cost,
                      sellingPrice: price,
                      currentStock: stock,
                      minStockAlert: minAlert,
                      createdAt: DateTime.now(),
                    );

                    _products.add(newProduct);
                    try {
                      if (ServiceLocator.instance.isInitialized) {
                        await ServiceLocator.instance.productRepository.saveProduct(newProduct);
                      }
                    } catch (e) {
                      debugPrint('Error saving product to repository: $e');
                    }

                    Navigator.of(ctx).pop();
                    setState(() {});

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تمت إضافة الصنف $sku بنجاح إلى المستودع')),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      nameArCtrl.dispose();
      nameHeCtrl.dispose();
      skuCtrl.dispose();
      costCtrl.dispose();
      priceCtrl.dispose();
      stockCtrl.dispose();
      meterPerBoxCtrl.dispose();
      minAlertCtrl.dispose();
    });
  }

  void _showAddContactDialog(BuildContext context, {ContactType defaultType = ContactType.customer}) {
    final nameArCtrl = TextEditingController();
    final nameHeCtrl = TextEditingController();
    final taxIdCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final balanceCtrl = TextEditingController(text: '0.00');
    final limitCtrl = TextEditingController(text: '50000.00');
    ContactType contactType = defaultType;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(AppColorValues.cardDark),
              title: Row(
                children: [
                  Icon(contactType == ContactType.customer ? Icons.person_add : Icons.store,
                      color: const Color(AppColorValues.primaryGold)),
                  const SizedBox(width: 8),
                  Text(
                    contactType == ContactType.customer
                        ? 'إضافة عميل جديد / הוספת לקוח חדש'
                        : 'إضافة مورد جديد / הוספת ספק חדש',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<ContactType>(
                              title: const Text('عميل (לקוח)', style: TextStyle(fontSize: 12)),
                              value: ContactType.customer,
                              groupValue: contactType,
                              onChanged: (val) {
                                if (val != null) setDialogState(() => contactType = val);
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<ContactType>(
                              title: const Text('مورد (ספק)', style: TextStyle(fontSize: 12)),
                              value: ContactType.supplier,
                              groupValue: contactType,
                              onChanged: (val) {
                                if (val != null) setDialogState(() => contactType = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nameArCtrl,
                              decoration: const InputDecoration(
                                labelText: 'الاسم بالعربية *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: nameHeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'שם בעברית *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: taxIdCtrl,
                              decoration: const InputDecoration(
                                labelText: 'رقم المشتغل / ח.פ / ת.ז (Tax ID) *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: phoneCtrl,
                              decoration: const InputDecoration(
                                labelText: 'الهاتف / טלפון *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: addressCtrl,
                        decoration: const InputDecoration(
                          labelText: 'العنوان وموقع المشروع / כתובת',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: balanceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'الرصيد الافتتاحي (₪)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: limitCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'سقف الدين / מסגרת אשראי (₪)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
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
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('إلغاء / ביטול'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppColorValues.primaryGold),
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('حفظ السجل / שמור'),
                  onPressed: () async {
                    final nameAr = nameArCtrl.text.trim();
                    final nameHe = nameHeCtrl.text.trim();
                    final taxId = taxIdCtrl.text.trim();
                    final phone = phoneCtrl.text.trim();
                    final balance = double.tryParse(balanceCtrl.text.trim()) ?? 0.0;
                    final limit = double.tryParse(limitCtrl.text.trim()) ?? 50000.0;

                    if (nameAr.isEmpty || taxId.isEmpty || phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى إدخال الاسم، رقم الضريبة، ورقم الهاتف')),
                      );
                      return;
                    }

                    if (limit < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('سقف الدين لا يمكن أن يكون سالباً')),
                      );
                      return;
                    }

                    if (_contacts.any((c) => c.taxId.trim() == taxId.trim())) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('رقم المشتغل / الضريبة $taxId مسجل مسبقاً')),
                      );
                      return;
                    }

                    final newContact = Contact(
                      id: '${contactType == ContactType.customer ? "cust" : "supp"}-${DateTime.now().millisecondsSinceEpoch}',
                      name: nameHe.isNotEmpty ? '$nameAr / $nameHe' : nameAr,
                      taxId: taxId,
                      phone: phone,
                      address: addressCtrl.text.trim(),
                      type: contactType,
                      currentBalance: balance,
                      debtWarningLimit: limit,
                    );

                    _contacts.add(newContact);
                    try {
                      if (ServiceLocator.instance.isInitialized) {
                        await ServiceLocator.instance.contactRepository.saveContact(newContact);
                      }
                    } catch (e) {
                      debugPrint('Error saving contact to repository: $e');
                    }

                    Navigator.of(ctx).pop();
                    setState(() {});

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تمت إضافة ${newContact.name.split(' / ').first} بنجاح')),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      nameArCtrl.dispose();
      nameHeCtrl.dispose();
      taxIdCtrl.dispose();
      phoneCtrl.dispose();
      addressCtrl.dispose();
      balanceCtrl.dispose();
      limitCtrl.dispose();
    });
  }

  void _showCreateCreditNoteDialog(BuildContext context) {
    final customers = _contacts.where((c) => c.type != ContactType.supplier).toList();
    if (customers.isEmpty || _products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد زبائن أو أصناف مسجلة في النظام لإصدار إرجاع')),
      );
      return;
    }
    Contact selectedCustomer = customers.first;
    Product selectedProduct = _products.first;
    final qtyCtrl = TextEditingController(text: '1.0');
    final reasonCtrl = TextEditingController();
    RefundMethod refundMethod = RefundMethod.debtCredit;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final double qty = double.tryParse(qtyCtrl.text.trim()) ?? 0.0;
            final double itemSubtotal = qty * selectedProduct.sellingPrice;
            final double vatAmt = itemSubtotal * 0.17;
            final double totalReturn = itemSubtotal + vatAmt;

            return AlertDialog(
              backgroundColor: const Color(AppColorValues.cardDark),
              title: Row(
                children: const [
                  Icon(Icons.assignment_return, color: Color(AppColorValues.warningOrange)),
                  SizedBox(width: 8),
                  Text('إصدار فاتورة إرجاع وזיכוי / חשבונית זיכוי', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<Contact>(
                        initialValue: selectedCustomer,
                        decoration: const InputDecoration(
                          labelText: 'العميل / לקוח *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: _contacts.where((c) => c.type != ContactType.supplier).map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(c.name.split(' / ').first, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedCustomer = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Product>(
                        initialValue: selectedProduct,
                        decoration: const InputDecoration(
                          labelText: 'الصنف المرتجع / מוצר מוחזר *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: _products.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text('${p.sku} - ${p.name.split(' / ').first}', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedProduct = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: qtyCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'الكمية المرتجعة (${selectedProduct.unitType.arabicLabel}) *',
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<RefundMethod>(
                              initialValue: refundMethod,
                              decoration: const InputDecoration(
                                labelText: 'طريقة الإرجاع / זיכוי',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: RefundMethod.debtCredit,
                                  child: Text('تخفيض دين / זיכוי חוב', style: TextStyle(fontSize: 12)),
                                ),
                                DropdownMenuItem(
                                  value: RefundMethod.cashRefund,
                                  child: Text('استرداد نقدي / מזומן', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) setDialogState(() => refundMethod = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: reasonCtrl,
                        decoration: const InputDecoration(
                          labelText: 'سبب الإرجاع / סיבת החזרה',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('المجموع قبل الضريبة:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(formatCurrency(itemSubtotal), style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('ضريبة القيمة المضافة (17%):', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(formatCurrency(vatAmt), style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                              ],
                            ),
                            const Divider(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('إجمالي قيمة الإرجاع (כולל מע"מ):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text(formatCurrency(totalReturn), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(AppColorValues.primaryGold))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('إلغاء / ביטול'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppColorValues.warningOrange),
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('اعتماد الإرجاع وإصدار الفاتورة / אשר זיכוי'),
                  onPressed: () async {
                    if (qty <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى تحديد كمية إرجاع صحيحة')),
                      );
                      return;
                    }

                    final crnNumber = 'CRN-2026-${(DateTime.now().millisecondsSinceEpoch % 100000).toString().padLeft(5, '0')}';
                    final creditNote = CreditNote(
                      id: 'crn-${DateTime.now().millisecondsSinceEpoch}',
                      creditNoteNumber: crnNumber,
                      originalInvoiceId: 'INV-MANUAL-REF',
                      originalInvoiceNumber: 'INV-2026-REF',
                      customerId: selectedCustomer.id,
                      customerName: selectedCustomer.name,
                      customerTaxId: selectedCustomer.taxId,
                      date: DateTime.now(),
                      reason: reasonCtrl.text.trim().isEmpty ? 'إرجاع بضاعة صالحة للمستودع' : reasonCtrl.text.trim(),
                      refundMethod: refundMethod,
                      items: [
                        CreditNoteLineItem(
                          productId: selectedProduct.id,
                          productName: selectedProduct.name,
                          unitType: selectedProduct.unitType,
                          quantity: qty,
                          unitPrice: selectedProduct.sellingPrice,
                          subtotal: itemSubtotal,
                        ),
                      ],
                      subtotal: itemSubtotal,
                      vatRate: 0.17,
                      vatAmount: vatAmt,
                      totalAmount: totalReturn,
                      createdBy: _currentUser?.name.split(' / ').first ?? 'Admin',
                      createdAt: DateTime.now(),
                    );

                    try {
                      if (ServiceLocator.instance.isInitialized) {
                        await ServiceLocator.instance.creditNoteOrchestrator.processCreditNoteTransaction(
                          creditNote: creditNote,
                          customer: selectedCustomer,
                        );
                      }
                    } catch (e) {
                      debugPrint('Error in creditNoteOrchestrator: $e');
                    }

                    final prodIdx = _products.indexWhere((p) => p.id == selectedProduct.id);
                    if (prodIdx >= 0) {
                      _products[prodIdx] = _products[prodIdx].copyWith(
                        currentStock: _products[prodIdx].currentStock + qty,
                      );
                    }
                    if (refundMethod == RefundMethod.debtCredit) {
                      final custIdx = _contacts.indexWhere((c) => c.id == selectedCustomer.id);
                      if (custIdx >= 0) {
                        _contacts[custIdx] = _contacts[custIdx].copyWith(
                          currentBalance: _contacts[custIdx].currentBalance - totalReturn,
                        );
                      }
                    }

                    Navigator.of(ctx).pop();
                    setState(() {});

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم إصدار فاتورة الإرجاع $crnNumber وإعادة المخزون بنجاح')),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      qtyCtrl.dispose();
      reasonCtrl.dispose();
    });
  }

  void _showCheckActionDialog(BuildContext context, CheckRecord check) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(AppColorValues.cardDark),
          title: Row(
            children: [
              const Icon(Icons.account_balance, color: Color(AppColorValues.primaryGold)),
              const SizedBox(width: 8),
              Text('إجراء على الشيك #${check.checkNumber}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الطرف: ${check.partyName}'),
              const SizedBox(height: 4),
              Text('المبلغ: ${formatCurrency(check.amount)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(AppColorValues.primaryGold))),
              const SizedBox(height: 4),
              Text('البنك: ${check.bankName} | فرع: ${check.branchNumber}'),
              const SizedBox(height: 4),
              Text('الحالة الحالية: ${check.status.arabicLabel} (${check.status.hebrewLabel})'),
              const Divider(height: 24),
              const Text('اختر الإجراء المطلوب / בחר פעולה:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 12),
              if (check.status == CheckStatus.pending) ...[
                ListTile(
                  tileColor: Colors.blue.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  leading: const Icon(Icons.account_balance, color: Colors.blueAccent),
                  title: const Text('إيداع الشيك في البنك (הפקדה בבנק)'),
                  subtitle: const Text('تحويل الحالة إلى مودع بانتظار المقاصة'),
                  onTap: () async {
                    _checksController.depositCheck(
                      checkId: check.id,
                      notes: 'إيداع بنكي للمقاصة',
                      changedBy: _currentUser?.name.split(' / ').first ?? 'Admin',
                    );
                    if (ServiceLocator.instance.isInitialized) {
                      await ServiceLocator.instance.checkRepository.updateCheckStatus(
                        check.id,
                        CheckStatus.deposited,
                        note: 'إيداع بنكي للمقاصة',
                      );
                    }
                    Navigator.of(ctx).pop();
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم إيداع الشيك #${check.checkNumber} بالبنك بنجاح')),
                    );
                  },
                ),
              ],
              if (check.status == CheckStatus.deposited) ...[
                ListTile(
                  tileColor: Colors.green.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  leading: const Icon(Icons.check_circle, color: Colors.greenAccent),
                  title: const Text('مقاصة وصرف الشيك (פירעון שיק)'),
                  subtitle: const Text('تم تحصيل الشيك وقيد المبلغ في الحساب البنكي'),
                  onTap: () async {
                    _checksController.clearCheck(
                      checkId: check.id,
                      notes: 'تم الصرف والمقاصة البنكية',
                      changedBy: _currentUser?.name.split(' / ').first ?? 'Admin',
                    );
                    if (ServiceLocator.instance.isInitialized) {
                      await ServiceLocator.instance.checkRepository.updateCheckStatus(
                        check.id,
                        CheckStatus.cleared,
                        note: 'تم الصرف والمقاصة البنكية',
                      );
                    }
                    Navigator.of(ctx).pop();
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم صرف الشيك #${check.checkNumber} بنجاح')),
                    );
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  tileColor: Colors.red.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  leading: const Icon(Icons.cancel, color: Colors.redAccent),
                  title: const Text('شيك راجع (שיק חוזר / ללא כיסוי)'),
                  subtitle: const Text('إعادة قيد الدين على حساب العميل فوراً مع سجل تدقيق'),
                  onTap: () async {
                    final matchedContact = _contacts.cast<Contact?>().firstWhere(
                      (c) => c?.id == check.partyId,
                      orElse: () => null,
                    );
                    _checksController.bounceCheck(
                      checkId: check.id,
                      notes: 'شيك راجع لعدم كفاية الرصيد',
                      changedBy: _currentUser?.name.split(' / ').first ?? 'Admin',
                      contact: matchedContact,
                    );
                    if (ServiceLocator.instance.isInitialized && matchedContact != null) {
                      await ServiceLocator.instance.checkLifecycleOrchestrator.processCheckBounce(
                        checkId: check.id,
                        party: matchedContact,
                        reason: 'شيك راجع لعدم كفاية الرصيد',
                      );
                    }
                    if (matchedContact != null) {
                      final cIdx = _contacts.indexWhere((c) => c.id == matchedContact.id);
                      if (cIdx >= 0) {
                        _contacts[cIdx] = _contacts[cIdx].copyWith(
                          currentBalance: _contacts[cIdx].currentBalance + check.amount,
                        );
                      }
                    }
                    Navigator.of(ctx).pop();
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم تسجيل الشيك #${check.checkNumber} كشيك راجع وإعادة قيد الدين على العميل')),
                    );
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إغلاق / סגור'),
            ),
          ],
        );
      },
    );
  }

  void _showAddVehicleDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final plateCtrl = TextEditingController();
    final yearCtrl = TextEditingController(text: '2024');
    final odoCtrl = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(AppColorValues.cardDark),
          title: Row(
            children: const [
              Icon(Icons.local_shipping, color: Color(AppColorValues.primaryGold)),
              SizedBox(width: 8),
              Text('إضافة مركبة / شاحنة جديدة للأسطول (הוספת רכב)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'طراز الشاحنة والوصف (مرسيدس، فولفو، مان...) *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: plateCtrl,
                          decoration: const InputDecoration(
                            labelText: 'رقم اللوحة (מספר רישוי) *',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: yearCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'سنة الصنع (שנת ייצור)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: odoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'قراءة العداد الحالية (كم) *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'مواصفات وتجهيزات (قلاب، مقطورة، رافعة شوكية...)',
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
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء / ביטול'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppColorValues.primaryGold),
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('حفظ المركبة / שמור רכב'),
              onPressed: () {
                final name = nameCtrl.text.trim();
                final plate = plateCtrl.text.trim();
                final year = int.tryParse(yearCtrl.text.trim()) ?? 2024;
                final odo = int.tryParse(odoCtrl.text.trim()) ?? 0;

                if (name.isEmpty || plate.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى إدخال اسم المركبة ورقم اللوحة')),
                  );
                  return;
                }

                if (_vehicles.any((v) => v.plateNumber.trim() == plate)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('المركبة ذات رقم اللوحة $plate مسجلة مسبقاً في الأسطول')),
                  );
                  return;
                }

                final newVehicle = Vehicle(
                  id: 'veh-${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  plateNumber: plate,
                  modelYear: year,
                  currentOdometer: odo,
                  status: VehicleStatus.active,
                  notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                );

                _vehicles.add(newVehicle);
                Navigator.of(ctx).pop();
                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تمت إضافة المركبة $plate بنجاح إلى الأسطول')),
                );
              },
            ),
          ],
        );
      },
    ).whenComplete(() {
      nameCtrl.dispose();
      plateCtrl.dispose();
      yearCtrl.dispose();
      odoCtrl.dispose();
      notesCtrl.dispose();
    });
  }

  void _showAddCheckDialog(BuildContext context) {
    if (_contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد جهات اتصال مسجلة في النظام لربط الشيك بها')),
      );
      return;
    }

    final checkNumberCtrl = TextEditingController();
    final bankNameCtrl = TextEditingController(text: 'בנק הפועלים (12)');
    final branchCtrl = TextEditingController(text: '680');
    final accountCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final partyNameCtrl = TextEditingController(text: _contacts.first.name);
    DateTime dueDate = DateTime.now().add(const Duration(days: 30));
    CheckType checkType = CheckType.received;
    String selectedPartyId = _contacts.first.id;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(AppColorValues.cardDark),
              title: Row(
                children: const [
                  Icon(Icons.add_card, color: Color(AppColorValues.primaryGold)),
                  SizedBox(width: 8),
                  Text('تسجيل شيك بنكي جديد / הוספת שיק', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<CheckType>(
                              title: const Text('شيك وارد (من عميل)', style: TextStyle(fontSize: 12)),
                              value: CheckType.received,
                              groupValue: checkType,
                              onChanged: (val) {
                                if (val != null) setDialogState(() => checkType = val);
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<CheckType>(
                              title: const Text('شيك صادر (لمورد)', style: TextStyle(fontSize: 12)),
                              value: CheckType.issued,
                              groupValue: checkType,
                              onChanged: (val) {
                                if (val != null) setDialogState(() => checkType = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: checkNumberCtrl,
                              decoration: const InputDecoration(
                                labelText: 'رقم الشيك / מספר שיק *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: amountCtrl,
                              keyboardType: TextInputType.number,
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
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: bankNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'اسم البنك / שם הבנק *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: branchCtrl,
                              decoration: const InputDecoration(
                                labelText: 'الفرع / סניף',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: accountCtrl,
                        decoration: const InputDecoration(
                          labelText: 'رقم الحساب / מספר חשבון',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedPartyId,
                        decoration: const InputDecoration(
                          labelText: 'الطرف المعني / לקוח או ספק *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: _contacts.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name.split(' / ').first, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedPartyId = val;
                              partyNameCtrl.text = _contacts.firstWhere((c) => c.id == val).name;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        tileColor: Colors.black12,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        dense: true,
                        title: const Text('تاريخ الاستحقاق / תאריך פירעון'),
                        subtitle: Text('${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}'),
                        trailing: const Icon(Icons.calendar_today, size: 18),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dueDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setDialogState(() => dueDate = picked);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('إلغاء / ביטול'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppColorValues.primaryGold),
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('حفظ الشيك / שמור'),
                  onPressed: () async {
                    final numStr = checkNumberCtrl.text.trim();
                    final amt = double.tryParse(amountCtrl.text.trim());
                    if (numStr.isEmpty || amt == null || amt <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى إدخال رقم شيك صحيح ومبلغ إيجابي')),
                      );
                      return;
                    }

                    final newCheck = CheckRecord(
                      id: 'chk-${DateTime.now().millisecondsSinceEpoch}',
                      checkNumber: numStr,
                      bankName: bankNameCtrl.text.trim(),
                      branchNumber: branchCtrl.text.trim().isEmpty ? '001' : branchCtrl.text.trim(),
                      accountNumber: accountCtrl.text.trim().isEmpty ? '000000' : accountCtrl.text.trim(),
                      amount: amt,
                      dueDate: dueDate,
                      type: checkType,
                      partyId: selectedPartyId,
                      partyName: partyNameCtrl.text,
                      relatedTransactionId: 'MANUAL-${DateTime.now().millisecondsSinceEpoch}',
                      status: CheckStatus.pending,
                      history: [
                        CheckHistoryEntry(
                          status: CheckStatus.pending,
                          changedAt: DateTime.now(),
                          notes: 'تسجيل يدوي في حافظة الشيكات',
                          changedBy: _currentUser?.name.split(' / ').first ?? 'Admin',
                        ),
                      ],
                      createdAt: DateTime.now(),
                    );

                    _checksController.addCheck(newCheck);
                    try {
                      if (ServiceLocator.instance.isInitialized) {
                        await ServiceLocator.instance.checkRepository.saveCheck(newCheck);
                      }
                    } catch (e) {
                      debugPrint('Error saving check to repository: $e');
                    }

                    Navigator.of(ctx).pop();
                    setState(() {});

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم إضافة الشيك رقم $numStr بنجاح إلى الحافظة')),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      checkNumberCtrl.dispose();
      bankNameCtrl.dispose();
      branchCtrl.dispose();
      accountCtrl.dispose();
      amountCtrl.dispose();
      partyNameCtrl.dispose();
    });
  }

  Widget _buildChecksScreen() {
    final checks = _checksController.filteredChecks;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildSectionHeader('سجل الشيكات البنكية وحركات المقاصة / קופת שיקים'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppColorValues.primaryGold),
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('إضافة شيك جديد / הוסף שיק'),
              onPressed: () => _showAddCheckDialog(context),
            ),
          ],
        ),
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
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showCheckActionDialog(context, c),
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
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'اضغط لتغيير الحالة أو المقاصة (הפקדה / פירעון / החזרה) ➔',
                          style: TextStyle(fontSize: 11, color: Colors.amber.shade300, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(AppColorValues.primaryGold),
                  side: const BorderSide(color: Color(AppColorValues.primaryGold)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                icon: const Icon(Icons.add, size: 20),
                label: Text(
                  _currentLanguage == AppLanguage.arabic
                      ? 'إضافة شاحنة للأسطول'
                      : 'הוסף משאית לצי',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => _showAddVehicleDialog(context),
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

    final availableCustomers = _contacts.where((c) => c.type != ContactType.supplier).toList();
    if (availableCustomers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد عملاء مسجلون في النظام لإنشاء إرسالية لهم')),
      );
      return;
    }

    final addressCtrl = TextEditingController(text: availableCustomers.first.address);
    final cargoCtrl = TextEditingController(text: '100 م² رخام كرارا + 2 خلاط نحاسي');
    final invoiceCtrl = TextEditingController(text: 'INV-2026-00412');
    final notesCtrl = TextEditingController();

    Contact selectedCustomer = availableCustomers.first;
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
      nameArabic: 'شركة م.ي.ر.ن باور م.ض',
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
    final availableCustomers = _contacts.where((c) => c.type != ContactType.supplier).toList();
    if (availableCustomers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد عملاء مسجلون في النظام لإصدار سند قبض لهم')),
      );
      return;
    }

    Contact customer = availableCustomers.first;
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
                      DropdownButtonFormField<Contact>(
                        initialValue: customer,
                        decoration: const InputDecoration(
                          labelText: 'الزبون / לקוח *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: availableCustomers.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text('${c.name} (حساب: ${formatCurrency(c.currentBalance)})', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => customer = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
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
                        final cIdx = _contacts.indexWhere((c) => c.id == customer.id);
                        if (cIdx != -1) {
                          _contacts[cIdx] = result.updatedContact;
                        }
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

    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد أصناف في المستودع لإجراء الشراء عليها')),
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
