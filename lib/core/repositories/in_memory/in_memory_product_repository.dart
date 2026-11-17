import 'dart:async';
import '../../../features/inventory/domain/models/product.dart';
import '../product_repository.dart';

class InMemoryProductRepository implements ProductRepository {
  final Map<String, Product> _products = {};
  final StreamController<List<Product>> _controller = StreamController<List<Product>>.broadcast();

  InMemoryProductRepository({List<Product>? initialProducts}) {
    if (initialProducts != null) {
      for (final p in initialProducts) {
        _products[p.id] = p;
      }
    }
  }

  List<Product> get _currentList => List.unmodifiable(_products.values);

  void _notify() {
    if (!_controller.isClosed) {
      _controller.add(_currentList);
    }
  }

  @override
  Stream<List<Product>> watchProducts() {
    late StreamController<List<Product>> subCtrl;
    StreamSubscription<List<Product>>? subscription;
    subCtrl = StreamController<List<Product>>.broadcast(
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
      onCancel: () {
        subscription?.cancel();
      },
    );
    return subCtrl.stream;
  }

  @override
  Future<List<Product>> getProducts() async => _currentList;

  @override
  Future<Product?> getProductById(String id) async => _products[id];

  @override
  Future<void> saveProduct(Product product) async {
    _products[product.id] = product;
    _notify();
  }

  @override
  Future<void> updateStock({required String productId, required double stockDelta}) async {
    final existing = _products[productId];
    if (existing == null) {
      throw ArgumentError('Product with id $productId not found');
    }
    final updated = existing.copyWith(
      currentStock: existing.currentStock + stockDelta,
    );
    _products[productId] = updated;
    _notify();
  }

  void dispose() {
    _controller.close();
  }
}
