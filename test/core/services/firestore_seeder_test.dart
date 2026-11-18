import 'package:test/test.dart';
import 'package:sales_logistics_system/core/di/service_locator.dart';
import 'package:sales_logistics_system/core/services/firestore_seeder.dart';

void main() {
  group('FirestoreSeeder Tests', () {
    setUp(() {
      ServiceLocator.instance.initialize();
    });

    test('seedAll populates products, contacts, and checks into repositories', () async {
      final result = await FirestoreSeeder.seedAll();

      expect(result.success, isTrue);
      expect(result.productsCount, equals(6));
      expect(result.contactsCount, equals(5));
      expect(result.checksCount, equals(2));

      // Verify records are retrievable
      final products = await ServiceLocator.instance.productRepository.getProducts();
      expect(products.length, greaterThanOrEqualTo(6));

      final contacts = await ServiceLocator.instance.contactRepository.getContacts();
      expect(contacts.length, greaterThanOrEqualTo(5));

      final checks = await ServiceLocator.instance.checkRepository.getChecks();
      expect(checks.length, greaterThanOrEqualTo(2));
    });

    test('seedAll is idempotent and does not create duplicate entries on second run', () async {
      // First run (or already seeded)
      await FirestoreSeeder.seedAll();

      // Second run should skip already existing IDs
      final secondRun = await FirestoreSeeder.seedAll();
      expect(secondRun.success, isTrue);
      expect(secondRun.productsCount, equals(0));
      expect(secondRun.contactsCount, equals(0));
      expect(secondRun.checksCount, equals(0));
    });
  });
}
