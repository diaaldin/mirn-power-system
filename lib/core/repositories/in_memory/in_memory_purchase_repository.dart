import 'dart:async';
import '../../../features/purchases/domain/models/purchase_invoice.dart';
import '../purchase_repository.dart';

class InMemoryPurchaseRepository implements PurchaseRepository {
  final Map<String, PurchaseInvoice> _purchases = {};
  final StreamController<List<PurchaseInvoice>> _controller = StreamController<List<PurchaseInvoice>>.broadcast();

  InMemoryPurchaseRepository({List<PurchaseInvoice>? initialPurchases}) {
    if (initialPurchases != null) {
      for (final p in initialPurchases) {
        _purchases[p.id] = p;
      }
    }
  }

  List<PurchaseInvoice> get _currentList => List.unmodifiable(_purchases.values);

  void _notify() {
    if (!_controller.isClosed) {
      _controller.add(_currentList);
    }
  }

  @override
  Stream<List<PurchaseInvoice>> watchPurchases() {
    late StreamController<List<PurchaseInvoice>> subCtrl;
    StreamSubscription<List<PurchaseInvoice>>? subscription;
    subCtrl = StreamController<List<PurchaseInvoice>>.broadcast(
      onListen: () {
        subCtrl.add(_currentList);
        subscription = _controller.stream.listen(
          (data) {
            if (!subCtrl.isClosed) subCtrl.add(data);
          },
          onError: subCtrl.addError,
          onDone: subCtrl.close,
        );
      },
      onCancel: () => subscription?.cancel(),
    );
    return subCtrl.stream;
  }

  @override
  Future<List<PurchaseInvoice>> getPurchases() async => _currentList;

  @override
  Future<PurchaseInvoice?> getPurchaseById(String id) async => _purchases[id];

  @override
  Future<void> savePurchase(PurchaseInvoice purchase) async {
    _purchases[purchase.id] = purchase;
    _notify();
  }

  void dispose() {
    _controller.close();
  }
}
