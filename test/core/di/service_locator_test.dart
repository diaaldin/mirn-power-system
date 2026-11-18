import 'package:test/test.dart';
import 'package:sales_logistics_system/core/di/service_locator.dart';
import 'package:sales_logistics_system/features/inventory/domain/models/product.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/contact.dart';

void main() {
  group('ServiceLocator Tests', () {
    tearDown(() {
      if (ServiceLocator.instance.isInitialized) {
        ServiceLocator.instance.dispose();
      }
    });

    test('initializes all repositories and orchestrators successfully', () async {
      expect(ServiceLocator.instance.isInitialized, isFalse);

      ServiceLocator.instance.initialize(
        initialProducts: [
          const Product(
            id: 'p1',
            name: 'Test Marble',
            sku: 'SKU1',
            category: ProductCategory.marble,
            unitType: UnitType.meter,
            purchaseCost: 100,
            sellingPrice: 150,
            currentStock: 25,
          ),
        ],
        initialContacts: [
          const Contact(
            id: 'c1',
            name: 'Client Alpha',
            phone: '0501112233',
            address: 'Jerusalem',
            taxId: '515892104',
            type: ContactType.customer,
            currentBalance: 0,
            debtWarningLimit: 10000,
          ),
        ],
      );

      expect(ServiceLocator.instance.isInitialized, isTrue);

      // Verify repositories are accessible
      final products = await ServiceLocator.instance.productRepository.getProducts();
      expect(products.length, equals(1));
      expect(products.first.name, equals('Test Marble'));

      final contacts = await ServiceLocator.instance.contactRepository.getContacts();
      expect(contacts.length, equals(1));

      // Verify orchestrators are instantiated
      expect(ServiceLocator.instance.saleOrchestrator, isNotNull);
      expect(ServiceLocator.instance.purchaseOrchestrator, isNotNull);
      expect(ServiceLocator.instance.creditNoteOrchestrator, isNotNull);
      expect(ServiceLocator.instance.checkLifecycleOrchestrator, isNotNull);
      expect(ServiceLocator.instance.authRepository, isNotNull);
      expect(ServiceLocator.instance.authRepository.currentUser, isNotNull);

      ServiceLocator.instance.dispose();
      expect(ServiceLocator.instance.isInitialized, isFalse);
    });
  });
}
