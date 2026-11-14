import '../models/product.dart';

class UnitConverter {
  UnitConverter._();

  /// Converts a count of boxes to total square meters based on `meterPerBox`.
  static double boxesToMeters({
    required num boxes,
    required double meterPerBox,
  }) {
    if (meterPerBox <= 0) return 0.0;
    return (boxes * meterPerBox * 10000).round() / 10000;
  }

  /// Converts square meters to equivalent count of boxes.
  static double metersToBoxes({
    required num meters,
    required double meterPerBox,
  }) {
    if (meterPerBox <= 0) return 0.0;
    return meters / meterPerBox;
  }

  /// Calculates the amount to deduct from `product.currentStock` (which is stored
  /// in `product.unitType`) when `quantity` is sold in `soldUnit`.
  static double calculateStockReduction({
    required Product product,
    required num quantity,
    required UnitType soldUnit,
  }) {
    final double qty = quantity.toDouble();
    if (product.unitType == soldUnit) {
      return qty;
    }

    final double factor = product.meterPerBox ?? 1.0;

    // Product is stored in meters, sold in boxes:
    if (product.unitType == UnitType.meter && soldUnit == UnitType.box) {
      return boxesToMeters(boxes: qty, meterPerBox: factor);
    }

    // Product is stored in boxes, sold in meters:
    if (product.unitType == UnitType.box && soldUnit == UnitType.meter) {
      return metersToBoxes(meters: qty, meterPerBox: factor);
    }

    // Piece-based or other units default to 1:1 deduction
    return qty;
  }
}
