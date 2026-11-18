import '../../features/inventory/domain/models/product.dart';
import '../../features/accounts/domain/models/contact.dart';
import '../../features/fleet/domain/models/vehicle.dart';
import '../../features/checks/domain/models/check_record.dart';
import '../di/service_locator.dart';

/// Seeds initial production-grade reference data for M.I.R.N POWER Management System.
/// Adheres to statutory Israeli Tax ID 515892104, Jerusalem dual-language branding.
class FirestoreSeeder {
  static final List<Product> initialProducts = [
    Product(
      id: 'prod-mrb-001',
      name: 'رخام كرارة إيطالي نخب أول / שיש קררה איטלקי מובחר',
      sku: 'MRB-ITA-01',
      category: ProductCategory.marble,
      unitType: UnitType.meter,
      meterPerBox: 1.44,
      piecesPerBox: 2,
      purchaseCost: 180.0,
      sellingPrice: 280.0,
      currentStock: 450.0,
      minStockAlert: 50.0,
      createdAt: DateTime.now(),
    ),
    Product(
      id: 'prod-stn-002',
      name: 'حجر قدسي نخب أول منقور ومجلي / אבן ירושלמית מובחרת',
      sku: 'STN-JLM-01',
      category: ProductCategory.stone,
      unitType: UnitType.meter,
      meterPerBox: 1.0,
      purchaseCost: 110.0,
      sellingPrice: 175.0,
      currentStock: 820.0,
      minStockAlert: 100.0,
      createdAt: DateTime.now(),
    ),
    Product(
      id: 'prod-cer-003',
      name: 'بورسلان إسباني فاخر 60×120 / גרניט פורצלן ספרדי',
      sku: 'CER-ESP-60120',
      category: ProductCategory.sanitary,
      unitType: UnitType.meter,
      meterPerBox: 1.44,
      piecesPerBox: 2,
      purchaseCost: 65.0,
      sellingPrice: 115.0,
      currentStock: 650.0,
      minStockAlert: 80.0,
      createdAt: DateTime.now(),
    ),
    Product(
      id: 'prod-san-004',
      name: 'خلاط مغسلة جروهي ألماني ذكي / ברז פרח גרואה גרמני',
      sku: 'SAN-GRO-01',
      category: ProductCategory.sanitary,
      unitType: UnitType.piece,
      purchaseCost: 320.0,
      sellingPrice: 490.0,
      currentStock: 45.0,
      minStockAlert: 10.0,
      createdAt: DateTime.now(),
    ),
    Product(
      id: 'prod-mrb-005',
      name: 'جرانيت أسود جالكسي هندي / גרניט שחור גלקסי הודי',
      sku: 'MRB-BLK-GLX',
      category: ProductCategory.marble,
      unitType: UnitType.meter,
      meterPerBox: 1.0,
      purchaseCost: 260.0,
      sellingPrice: 420.0,
      currentStock: 210.0,
      minStockAlert: 30.0,
      createdAt: DateTime.now(),
    ),
    Product(
      id: 'prod-san-006',
      name: 'كرسي معلق شطاف إيطالي إيديل ستاندرد / אסלה תלויה אידיאל',
      sku: 'SAN-IDL-02',
      category: ProductCategory.sanitary,
      unitType: UnitType.piece,
      purchaseCost: 550.0,
      sellingPrice: 850.0,
      currentStock: 30.0,
      minStockAlert: 5.0,
      createdAt: DateTime.now(),
    ),
  ];

  static final List<Contact> initialContacts = [
    Contact(
      id: 'cust-blq-101',
      type: ContactType.customer,
      name: 'شركة البراق للمقاولات العامة / אל בוראק בניה בע"מ',
      phone: '052-8899112',
      address: 'القدس - العيزرية / ירושלים',
      taxId: '515892104',
      debtWarningLimit: 80000.0,
      currentBalance: 38200.0,
      notes: 'عميل استراتيجي - مقاولات بناء ومشاريع عظم وتشطيب',
      createdAt: DateTime.now(),
    ),
    Contact(
      id: 'cust-jlm-102',
      type: ContactType.customer,
      name: 'مكتب القدس للتصميم الداخلي والمعماري / סטודיו ירושלים',
      phone: '054-7711223',
      address: 'القدس - بيت حنينا / ירושלים בית חנינא',
      taxId: '514992019',
      debtWarningLimit: 40000.0,
      currentBalance: 12500.0,
      notes: 'تصاميم فلل وشقق فاخرة - توريد رخام إيطالي وبورسلان',
      createdAt: DateTime.now(),
    ),
    Contact(
      id: 'cust-ram-103',
      type: ContactType.customer,
      name: 'شركة أبراج الرام للتطوير العقاري والاستثمار',
      phone: '050-9933445',
      address: 'القدس - ضاحية البريد / א-ראם',
      taxId: '516773344',
      debtWarningLimit: 120000.0,
      currentBalance: 0.0,
      notes: 'حساب جديد - مشروع مجمع سكني 40 شقة',
      createdAt: DateTime.now(),
    ),
    Contact(
      id: 'supp-hbr-201',
      type: ContactType.supplier,
      name: 'محاجر ومصانع حجر القدس وخليل الرحمن / מחצבות חברון',
      phone: '02-2234567',
      address: 'الخليل - المنطقة الصناعية / חברון',
      taxId: '512334455',
      debtWarningLimit: 150000.0,
      currentBalance: -45000.0,
      notes: 'مورد حجر بناء منقور وطوب ورخام خام',
      createdAt: DateTime.now(),
    ),
    Contact(
      id: 'supp-ita-202',
      type: ContactType.supplier,
      name: 'شركة الشرق الأوسط لاستيراد الرخام الإيطالي والجرانيت',
      phone: '03-9081234',
      address: 'ميناء أشدود / אשדוד',
      taxId: '519887766',
      debtWarningLimit: 200000.0,
      currentBalance: -78500.0,
      notes: 'استيراد ألواح رخام كرارة وبورسلان نخب أول',
      createdAt: DateTime.now(),
    ),
  ];

  static final List<Vehicle> initialVehicles = [
    const Vehicle(
      id: 'veh-act-001',
      name: 'مرسيدس أكتروس 3340 قلاب صخور ثقيل / מרצדס אקטרוס 3340',
      plateNumber: '62-819-34',
      modelYear: 2024,
      currentOdometer: 42500,
      status: VehicleStatus.active,
      notes: 'قلاب صخور 32 طن - نقل كتل حجر ورخام ورمل من المحاجر',
    ),
    const Vehicle(
      id: 'veh-man-002',
      name: 'مان TGS 26.440 رافعة شوكية لتنزيل طبالي / מאן מנוף פריקה',
      plateNumber: '74-129-56',
      modelYear: 2023,
      currentOdometer: 68200,
      status: VehicleStatus.active,
      notes: 'رافعة هيدروليكية 26 طن - تنزيل طبالي البورسلان ومغاسل المواقع',
    ),
    const Vehicle(
      id: 'veh-vol-003',
      name: 'فولفو FH16 540 مقطورة نقل كتل ضخمة / וולוו פול-טריילר',
      plateNumber: '88-445-12',
      modelYear: 2025,
      currentOdometer: 18300,
      status: VehicleStatus.active,
      notes: 'تريلا 40 طن - نقل دولي وخطوط الموانئ والمحاجر',
    ),
  ];

  static final List<CheckRecord> initialChecks = [
    CheckRecord(
      id: 'chk-seed-001',
      checkNumber: '10492',
      bankName: 'בנק הפועלים (12)',
      branchNumber: '680',
      accountNumber: '445910',
      partyId: 'cust-blq-101',
      partyName: 'شركة البراق للمقاولات العامة',
      amount: 15000.0,
      dueDate: DateTime.now().add(const Duration(days: 15)),
      type: CheckType.received,
      relatedTransactionId: 'TX-SEED-01',
      status: CheckStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      history: [
        CheckHistoryEntry(
          status: CheckStatus.pending,
          changedAt: DateTime.now().subtract(const Duration(days: 5)),
          changedBy: 'Admin (ضياء الدين)',
          notes: 'تسجيل الشيك في الحافظة',
        ),
      ],
    ),
    CheckRecord(
      id: 'chk-seed-002',
      checkNumber: '30811',
      bankName: 'בנק לאומי (10)',
      branchNumber: '800',
      accountNumber: '112849',
      partyId: 'cust-jlm-102',
      partyName: 'مكتب القدس للتصميم المعماري',
      amount: 8400.0,
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
      type: CheckType.received,
      relatedTransactionId: 'TX-SEED-02',
      status: CheckStatus.deposited,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      history: [
        CheckHistoryEntry(
          status: CheckStatus.pending,
          changedAt: DateTime.now().subtract(const Duration(days: 10)),
          changedBy: 'Admin (ضياء الدين)',
          notes: 'استلام الشيك',
        ),
        CheckHistoryEntry(
          status: CheckStatus.deposited,
          changedAt: DateTime.now().subtract(const Duration(days: 2)),
          changedBy: 'Admin (ضياء الدين)',
          notes: 'إيداع برسم التحصيل بنك لئومي',
        ),
      ],
    ),
  ];

  /// Seeds all initial reference data into the active repository instances.
  /// If repositories are connected to Firestore, this writes directly to cloud collections.
  static Future<SeedingResult> seedAll() async {
    int productsCount = 0;
    int contactsCount = 0;
    int vehiclesCount = 0;
    int checksCount = 0;

    try {
      final loc = ServiceLocator.instance;

      // 1. Seed Products
      for (final p in initialProducts) {
        final existing = await loc.productRepository.getProductById(p.id);
        if (existing == null) {
          await loc.productRepository.saveProduct(p);
          productsCount++;
        }
      }

      // 2. Seed Contacts
      for (final c in initialContacts) {
        final existing = await loc.contactRepository.getContactById(c.id);
        if (existing == null) {
          await loc.contactRepository.saveContact(c);
          contactsCount++;
        }
      }

      // 3. Seed Checks
      for (final chk in initialChecks) {
        final existing = await loc.checkRepository.getCheckById(chk.id);
        if (existing == null) {
          await loc.checkRepository.saveCheck(chk);
          checksCount++;
        }
      }

      // ignore: avoid_print
      print('Seeding completed successfully: $productsCount products, $contactsCount contacts, $vehiclesCount vehicles, $checksCount checks.');
      return SeedingResult(
        success: true,
        productsCount: productsCount,
        contactsCount: contactsCount,
        vehiclesCount: vehiclesCount,
        checksCount: checksCount,
        message: 'تمت تغذية السحابة بالبيانات الافتتاحية بنجاح ($productsCount أصناف، $contactsCount جهات اتصال، $vehiclesCount مركبات، $checksCount شيكات)',
      );
    } catch (e, stack) {
      // ignore: avoid_print
      print('Seeding failed: $e\n$stack');
      return SeedingResult(
        success: false,
        productsCount: productsCount,
        contactsCount: contactsCount,
        vehiclesCount: vehiclesCount,
        checksCount: checksCount,
        errorMessage: e.toString(),
        message: 'حدث خطأ أثناء تغذية البيانات: $e',
      );
    }
  }
}

class SeedingResult {
  final bool success;
  final int productsCount;
  final int contactsCount;
  final int vehiclesCount;
  final int checksCount;
  final String message;
  final String? errorMessage;

  const SeedingResult({
    required this.success,
    required this.productsCount,
    required this.contactsCount,
    required this.vehiclesCount,
    required this.checksCount,
    required this.message,
    this.errorMessage,
  });
}
