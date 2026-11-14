import 'package:test/test.dart';
import 'package:sales_logistics_system/features/inventory/domain/models/product.dart';
import 'package:sales_logistics_system/features/inventory/domain/services/unit_converter.dart';

void main() {
  group('Dual-Unit Conversion Engine', () {
    test('converts boxes to square meters accurately', () {
      final meters = UnitConverter.boxesToMeters(boxes: 10, meterPerBox: 1.44);
      expect(meters, equals(14.4));
    });

    test('converts square meters to boxes with precision', () {
      final boxesExact = UnitConverter.metersToBoxes(meters: 14.4, meterPerBox: 1.44);
      expect(boxesExact, equals(10.0));

      final boxesFractional = UnitConverter.metersToBoxes(meters: 15.0, meterPerBox: 1.44);
      expect((boxesFractional * 100).round() / 100, equals(10.42));
    });

    test('calculates stock deduction based on primary unit and sold unit', () {
      final marbleProduct = Product(
        id: 'prod-001',
        name: 'Carrara Marble 60x120',
        sku: 'MB-60120',
        category: ProductCategory.marble,
        unitType: UnitType.meter,
        meterPerBox: 1.44,
        purchaseCost: 80.0,
        sellingPrice: 120.0,
        currentStock: 150.0, // 150 m2
        minStockAlert: 20.0,
      );

      // Selling 5 boxes should deduct 5 * 1.44 = 7.2 m2 from currentStock
      final deductionInBoxes = UnitConverter.calculateStockReduction(
        product: marbleProduct,
        quantity: 5,
        soldUnit: UnitType.box,
      );
      expect(deductionInBoxes, closeTo(7.2, 0.0001));

      // Selling 10 m2 directly should deduct 10.0 m2
      final deductionInMeters = UnitConverter.calculateStockReduction(
        product: marbleProduct,
        quantity: 10,
        soldUnit: UnitType.meter,
      );
      expect(deductionInMeters, equals(10.0));
    });

    test('calculates piece-based products without meter factor', () {
      final toiletProduct = Product(
        id: 'prod-002',
        name: 'Villeroy Toilet Wall-Hung',
        sku: 'SAN-TOI-01',
        category: ProductCategory.sanitary,
        unitType: UnitType.piece,
        purchaseCost: 450.0,
        sellingPrice: 750.0,
        currentStock: 15.0,
        minStockAlert: 3.0,
      );

      final deduction = UnitConverter.calculateStockReduction(
        product: toiletProduct,
        quantity: 2,
        soldUnit: UnitType.piece,
      );
      expect(deduction, equals(2.0));
    });
  });
}
