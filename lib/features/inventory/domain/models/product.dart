enum ProductCategory {
  sanitary,
  marble,
  stone,
  transport,
  other;

  String get displayName {
    switch (this) {
      case ProductCategory.sanitary:
        return 'كلים סניטריים / أدوات صحية';
      case ProductCategory.marble:
        return 'שיש / رخام';
      case ProductCategory.stone:
        return 'אבן / حجر';
      case ProductCategory.transport:
        return 'הובלה / نقل ושحن';
      case ProductCategory.other:
        return 'אחר / أخرى';
    }
  }
}

enum UnitType {
  meter('מ"ר', 'متر مربع'),
  box('קרטון', 'كرتونة'),
  piece('יח\'', 'حبة');

  final String hebrewLabel;
  final String arabicLabel;

  const UnitType(this.hebrewLabel, this.arabicLabel);
}

class Product {
  final String id;
  final String name;
  final String sku;
  final ProductCategory category;
  final UnitType unitType;
  final double? meterPerBox;
  final int? piecesPerBox;
  final double purchaseCost;
  final double sellingPrice;
  final double currentStock;
  final double minStockAlert;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.unitType,
    this.meterPerBox,
    this.piecesPerBox,
    required this.purchaseCost,
    required this.sellingPrice,
    required this.currentStock,
    this.minStockAlert = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  bool get isLowStock => currentStock <= minStockAlert;

  Product copyWith({
    String? id,
    String? name,
    String? sku,
    ProductCategory? category,
    UnitType? unitType,
    double? meterPerBox,
    int? piecesPerBox,
    double? purchaseCost,
    double? sellingPrice,
    double? currentStock,
    double? minStockAlert,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      unitType: unitType ?? this.unitType,
      meterPerBox: meterPerBox ?? this.meterPerBox,
      piecesPerBox: piecesPerBox ?? this.piecesPerBox,
      purchaseCost: purchaseCost ?? this.purchaseCost,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      currentStock: currentStock ?? this.currentStock,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'category': category.name,
      'unitType': unitType.name,
      'meterPerBox': meterPerBox,
      'piecesPerBox': piecesPerBox,
      'purchaseCost': purchaseCost,
      'sellingPrice': sellingPrice,
      'currentStock': currentStock,
      'minStockAlert': minStockAlert,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String,
      category: ProductCategory.values.byName(json['category'] as String),
      unitType: UnitType.values.byName(json['unitType'] as String),
      meterPerBox: (json['meterPerBox'] as num?)?.toDouble(),
      piecesPerBox: json['piecesPerBox'] as int?,
      purchaseCost: (json['purchaseCost'] as num).toDouble(),
      sellingPrice: (json['sellingPrice'] as num).toDouble(),
      currentStock: (json['currentStock'] as num).toDouble(),
      minStockAlert: (json['minStockAlert'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }
}
