import 'dart:async';
import '../../../features/purchases/domain/models/purchase_invoice.dart';
import '../purchase_repository.dart';

class InMemoryPurchaseRepository implements PurchaseRepository {
  final Map<String, PurchaseInvoice> _purchases = {};
  late final StreamController<List<PurchaseInvoice>> _controller;

  InMemoryPurchaseRepository({List<PurchaseInvoice>? initialPurchases}) {
    if (initialPurchases != null) {
      for (final p in initialPurchases) {
        _purchases[p.id] = p;
      }
    }
    _controller = StreamController<List<PurchaseInvoice>>.broadcast(
      onListen: () => _controller.add(_currentList),
    );
  }

  List<PurchaseInvoice> get _currentList => List.unmodifiable(_purchases.values);

  @override
  Stream<List<PurchaseInvoice>> watchPurchases() => _controller.stream;

  @override
  Future<List<PurchaseInvoice>> getPurchases() async => _currentList;

  @override
  Future<PurchaseInvoice?> getPurchaseById(String id) async => _purchases[id];

  @override
  Future<void> savePurchase(PurchaseInvoice purchase) async {
    _purchases[purchase.id] = purchase;
    _controller.add(_currentList);
  }

  void dispose() {
    _controller.close();
  }
}
