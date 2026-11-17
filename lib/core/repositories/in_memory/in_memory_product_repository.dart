import 'dart:async';
import '../../../features/inventory/domain/models/product.dart';
import '../product_repository.dart';

class InMemoryProductRepository implements ProductRepository {
  final Map<String, Product> _products = {};
  late final StreamController<List<Product>> _controller;

  InMemoryProductRepository({List<Product>? initialProducts}) {
    if (initialProducts != null) {
      for (final p in initialProducts) {
        _products[p.id] = p;
      }
    }
    _controller = StreamController<List<Product>>.broadcast(
      onListen: () => _controller.add(_currentList),
    );
  }

  List<Product> get _currentList => List.unmodifiable(_products.values);

  @override
  Stream<List<Product>> watchProducts() => _controller.stream;

  @override
  Future<List<Product>> getProducts() async => _currentList;

  @override
  Future<Product?> getProductById(String id) async => _products[id];

  @override
  Future<void> saveProduct(Product product) async {
    _products[product.id] = product;
    _controller.add(_currentList);
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
    _controller.add(_currentList);
  }

  void dispose() {
    _controller.close();
  }
}
