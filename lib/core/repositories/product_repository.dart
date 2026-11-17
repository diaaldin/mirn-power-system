import '../../features/inventory/domain/models/product.dart';

abstract class ProductRepository {
  Stream<List<Product>> watchProducts();
  Future<List<Product>> getProducts();
  Future<Product?> getProductById(String id);
  Future<void> saveProduct(Product product);
  Future<void> updateStock({required String productId, required double stockDelta});
}
