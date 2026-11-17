import 'package:test/test.dart';
import 'package:sales_logistics_system/core/repositories/product_repository.dart';
import 'package:sales_logistics_system/core/repositories/contact_repository.dart';
import 'package:sales_logistics_system/core/repositories/sale_repository.dart';
import 'package:sales_logistics_system/core/repositories/check_repository.dart';
import 'package:sales_logistics_system/core/repositories/purchase_repository.dart';
import 'package:sales_logistics_system/core/repositories/dispatch_repository.dart';
import 'package:sales_logistics_system/core/repositories/expense_repository.dart';

void main() {
  group('Repository Interface Contracts', () {
    test('ProductRepository type definition exists and is abstract', () {
      expect(ProductRepository, isNotNull);
    });

    test('ContactRepository type definition exists and is abstract', () {
      expect(ContactRepository, isNotNull);
    });

    test('SaleRepository type definition exists and is abstract', () {
      expect(SaleRepository, isNotNull);
    });

    test('CheckRepository type definition exists and is abstract', () {
      expect(CheckRepository, isNotNull);
    });

    test('PurchaseRepository type definition exists and is abstract', () {
      expect(PurchaseRepository, isNotNull);
    });

    test('DispatchRepository type definition exists and is abstract', () {
      expect(DispatchRepository, isNotNull);
    });

    test('ExpenseRepository type definition exists and is abstract', () {
      expect(ExpenseRepository, isNotNull);
    });
  });
}
