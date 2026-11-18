import 'package:cloud_firestore/cloud_firestore.dart';
import 'service_locator.dart';
import '../repositories/firestore/firestore_check_repository.dart';
import '../repositories/firestore/firestore_contact_repository.dart';
import '../repositories/firestore/firestore_dispatch_repository.dart';
import '../repositories/firestore/firestore_expense_repository.dart';
import '../repositories/firestore/firestore_product_repository.dart';
import '../repositories/firestore/firestore_purchase_repository.dart';
import '../repositories/firestore/firestore_sale_repository.dart';

/// Bootstraps ServiceLocator with live Cloud Firestore repository implementations.
void setupFirestoreRepositories({FirebaseFirestore? firestore}) {
  ServiceLocator.instance.initialize(
    customProductRepository: FirestoreProductRepository(firestore: firestore),
    customContactRepository: FirestoreContactRepository(firestore: firestore),
    customSaleRepository: FirestoreSaleRepository(firestore: firestore),
    customCheckRepository: FirestoreCheckRepository(firestore: firestore),
    customPurchaseRepository: FirestorePurchaseRepository(firestore: firestore),
    customDispatchRepository: FirestoreDispatchRepository(firestore: firestore),
    customExpenseRepository: FirestoreExpenseRepository(firestore: firestore),
  );
}
