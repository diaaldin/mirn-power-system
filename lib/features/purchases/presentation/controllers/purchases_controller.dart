import '../../../accounts/domain/models/contact.dart';
import '../../../inventory/domain/models/product.dart';
import '../../../inventory/domain/services/unit_converter.dart';
import '../../domain/services/purchase_service.dart';

/// Presentation draft for a purchase line item with auto-calculated converted stock and subtotal.
class PurchaseItemDraft {
  final Product product;
  final UnitType unitType;
  final double quantity;
  final double unitCost;
  final double convertedStock;
  final double subtotal;

  PurchaseItemDraft({
    required this.product,
    required this.unitType,
    required num quantity,
    required num unitCost,
    num? convertedStock,
    num? subtotal,
  })  : quantity = quantity.toDouble(),
        unitCost = unitCost.toDouble(),
        convertedStock = convertedStock?.toDouble() ??
            UnitConverter.calculateStockAddition(
              product: product,
              quantity: quantity.toDouble(),
              purchasedUnit: unitType,
            ),
        subtotal = subtotal?.toDouble() ??
            _round2(quantity.toDouble() * unitCost.toDouble()) {
    if (this.quantity <= 0) {
      throw ArgumentError.value(
        this.quantity,
        'quantity',
        'Quantity must be greater than zero',
      );
    }
    if (this.unitCost < 0) {
      throw ArgumentError.value(
        this.unitCost,
        'unitCost',
        'Unit cost cannot be negative',
      );
    }
  }

  static double _round2(num val) => (val * 100).roundToDouble() / 100.0;

  PurchaseItemDraft copyWith({
    Product? product,
    UnitType? unitType,
    num? quantity,
    num? unitCost,
    num? convertedStock,
    num? subtotal,
  }) {
    return PurchaseItemDraft(
      product: product ?? this.product,
      unitType: unitType ?? this.unitType,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      convertedStock: convertedStock ?? this.convertedStock,
      subtotal: subtotal ?? this.subtotal,
    );
  }
}

/// Immutable snapshot representing the reactive state of the purchases intake form.
class PurchasesFormState {
  final Contact? supplier;
  final String invoiceNumber;
  final String? supplierInvoiceNumber;
  final DateTime date;
  final List<PurchaseItemDraft> items;
  final double vatRate;
  final bool isPaidImmediately;
  final double paidAmount;
  final String? notes;
  final double subtotal;
  final double vatAmount;
  final double totalAmount;
  final double effectivePaidAmount;
  final double onAccountAmount;
  final double? projectedSupplierBalance;
  final bool isValid;

  const PurchasesFormState({
    this.supplier,
    this.invoiceNumber = '',
    this.supplierInvoiceNumber,
    required this.date,
    this.items = const [],
    this.vatRate = 0.17,
    this.isPaidImmediately = false,
    this.paidAmount = 0.0,
    this.notes,
    required this.subtotal,
    required this.vatAmount,
    required this.totalAmount,
    required this.effectivePaidAmount,
    required this.onAccountAmount,
    this.projectedSupplierBalance,
    required this.isValid,
  });

  factory PurchasesFormState.initial({
    Contact? supplier,
    String invoiceNumber = '',
    String? supplierInvoiceNumber,
    DateTime? date,
    double vatRate = 0.17,
  }) {
    final d = date ?? DateTime.now();
    return PurchasesFormState(
      supplier: supplier,
      invoiceNumber: invoiceNumber,
      supplierInvoiceNumber: supplierInvoiceNumber,
      date: d,
      items: const [],
      vatRate: vatRate,
      isPaidImmediately: false,
      paidAmount: 0.0,
      notes: null,
      subtotal: 0.0,
      vatAmount: 0.0,
      totalAmount: 0.0,
      effectivePaidAmount: 0.0,
      onAccountAmount: 0.0,
      projectedSupplierBalance: supplier?.currentBalance,
      isValid: false,
    );
  }

  PurchasesFormState copyWith({
    Contact? supplier,
    String? invoiceNumber,
    String? supplierInvoiceNumber,
    DateTime? date,
    List<PurchaseItemDraft>? items,
    double? vatRate,
    bool? isPaidImmediately,
    double? paidAmount,
    String? notes,
    double? subtotal,
    double? vatAmount,
    double? totalAmount,
    double? effectivePaidAmount,
    double? onAccountAmount,
    double? projectedSupplierBalance,
    bool? isValid,
  }) {
    return PurchasesFormState(
      supplier: supplier ?? this.supplier,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      supplierInvoiceNumber:
          supplierInvoiceNumber ?? this.supplierInvoiceNumber,
      date: date ?? this.date,
      items: items ?? this.items,
      vatRate: vatRate ?? this.vatRate,
      isPaidImmediately: isPaidImmediately ?? this.isPaidImmediately,
      paidAmount: paidAmount ?? this.paidAmount,
      notes: notes ?? this.notes,
      subtotal: subtotal ?? this.subtotal,
      vatAmount: vatAmount ?? this.vatAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      effectivePaidAmount: effectivePaidAmount ?? this.effectivePaidAmount,
      onAccountAmount: onAccountAmount ?? this.onAccountAmount,
      projectedSupplierBalance:
          projectedSupplierBalance ?? this.projectedSupplierBalance,
      isValid: isValid ?? this.isValid,
    );
  }
}

/// Reactive presentation controller managing the state machine of supplier purchase invoices
/// and stock intake workflows.
class PurchasesController {
  Contact? _supplier;
  String _invoiceNumber;
  String? _supplierInvoiceNumber;
  DateTime _date;
  final List<PurchaseItemDraft> _items = [];
  double _vatRate;
  bool _isPaidImmediately;
  double _paidAmount;
  String? _notes;

  PurchasesController({
    Contact? initialSupplier,
    String? initialInvoiceNumber,
    String? initialSupplierInvoiceNumber,
    DateTime? initialDate,
    double initialVatRate = 0.17,
    bool initialPaidImmediately = false,
    double initialPaidAmount = 0.0,
    String? initialNotes,
  })  : _supplier = initialSupplier,
        _invoiceNumber = initialInvoiceNumber ?? '',
        _supplierInvoiceNumber = initialSupplierInvoiceNumber,
        _date = initialDate ?? DateTime.now(),
        _vatRate = initialVatRate,
        _isPaidImmediately = initialPaidImmediately,
        _paidAmount = initialPaidAmount,
        _notes = initialNotes;

  static double _round2(num val) => (val * 100).roundToDouble() / 100.0;

  /// Current reactive snapshot of the purchase intake form state.
  PurchasesFormState get state => _computeState();

  void setSupplier(Contact? supplier) {
    _supplier = supplier;
  }

  void setInvoiceNumber(String number) {
    _invoiceNumber = number;
  }

  void setSupplierInvoiceNumber(String? number) {
    _supplierInvoiceNumber = number;
  }

  void setDate(DateTime date) {
    _date = date;
  }

  void setVatRate(double rate) {
    _vatRate = rate;
  }

  void addItem({
    required Product product,
    required UnitType unitType,
    required num quantity,
    required num unitCost,
  }) {
    _items.add(
      PurchaseItemDraft(
        product: product,
        unitType: unitType,
        quantity: quantity,
        unitCost: unitCost,
      ),
    );
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
    }
  }

  void clearItems() {
    _items.clear();
  }

  void setPaidImmediately(bool paid) {
    _isPaidImmediately = paid;
  }

  void setPaidAmount(num amount) {
    _paidAmount = amount.toDouble();
  }

  void setNotes(String? notes) {
    _notes = notes;
  }

  void reset() {
    _supplier = null;
    _invoiceNumber = '';
    _supplierInvoiceNumber = null;
    _date = DateTime.now();
    _vatRate = 0.17;
    _isPaidImmediately = false;
    _paidAmount = 0.0;
    _notes = null;
    _items.clear();
  }

  /// Submits the purchase invoice: records inventory replenishment, updates supplier balance,
  /// generates statement entries, and resets the form state.
  ///
  /// Throws [StateError] if the form is invalid.
  ProcessPurchaseResult submitPurchase({
    required String createdBy,
  }) {
    final currentState = state;
    if (!currentState.isValid) {
      throw StateError('Cannot submit invalid purchase form');
    }

    final input = CreatePurchaseInput(
      invoiceNumber: currentState.invoiceNumber,
      supplierInvoiceNumber: currentState.supplierInvoiceNumber,
      date: currentState.date,
      supplier: currentState.supplier!,
      items: currentState.items
          .map(
            (i) => PurchaseLineItemInput(
              product: i.product,
              unitType: i.unitType,
              quantity: i.quantity,
              unitCost: i.unitCost,
            ),
          )
          .toList(),
      vatRate: currentState.vatRate,
      paidAmount: currentState.effectivePaidAmount,
      notes: currentState.notes,
      createdBy: createdBy,
    );

    final result = PurchaseService.processPurchase(input);
    reset();
    return result;
  }

  PurchasesFormState _computeState() {
    final subtotal = _round2(
      _items.fold<double>(0.0, (acc, item) => acc + item.subtotal),
    );
    final vatAmount = _round2(subtotal * _vatRate);
    final totalAmount = _round2(subtotal + vatAmount);

    final effectivePaidAmount = _isPaidImmediately
        ? totalAmount
        : _round2(_paidAmount);

    final onAccountAmount = _round2(totalAmount - effectivePaidAmount);

    final double? projectedSupplierBalance = _supplier != null
        ? _round2(_supplier!.currentBalance + onAccountAmount)
        : null;

    final isValid = _supplier != null &&
        _supplier!.type != ContactType.customer &&
        _invoiceNumber.trim().isNotEmpty &&
        _items.isNotEmpty &&
        totalAmount > 0 &&
        effectivePaidAmount >= 0 &&
        effectivePaidAmount <= totalAmount &&
        onAccountAmount >= 0;

    return PurchasesFormState(
      supplier: _supplier,
      invoiceNumber: _invoiceNumber,
      supplierInvoiceNumber: _supplierInvoiceNumber,
      date: _date,
      items: List.unmodifiable(_items),
      vatRate: _vatRate,
      isPaidImmediately: _isPaidImmediately,
      paidAmount: _paidAmount,
      notes: _notes,
      subtotal: subtotal,
      vatAmount: vatAmount,
      totalAmount: totalAmount,
      effectivePaidAmount: effectivePaidAmount,
      onAccountAmount: onAccountAmount,
      projectedSupplierBalance: projectedSupplierBalance,
      isValid: isValid,
    );
  }
}
