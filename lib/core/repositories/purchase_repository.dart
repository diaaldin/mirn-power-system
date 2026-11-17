import '../../features/purchases/domain/models/purchase_invoice.dart';

abstract class PurchaseRepository {
  Stream<List<PurchaseInvoice>> watchPurchases();
  Future<List<PurchaseInvoice>> getPurchases();
  Future<PurchaseInvoice?> getPurchaseById(String id);
  Future<void> savePurchase(PurchaseInvoice purchase);
}
