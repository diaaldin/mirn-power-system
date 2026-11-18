import '../repositories/check_repository.dart';
import '../repositories/contact_repository.dart';
import '../repositories/dispatch_repository.dart';
import '../repositories/expense_repository.dart';
import '../repositories/in_memory/in_memory_check_repository.dart';
import '../repositories/in_memory/in_memory_contact_repository.dart';
import '../repositories/in_memory/in_memory_dispatch_repository.dart';
import '../repositories/in_memory/in_memory_expense_repository.dart';
import '../repositories/in_memory/in_memory_product_repository.dart';
import '../repositories/in_memory/in_memory_purchase_repository.dart';
import '../repositories/in_memory/in_memory_sale_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/purchase_repository.dart';
import '../repositories/sale_repository.dart';
import '../../features/checks/domain/services/check_lifecycle_orchestrator.dart';
import '../../features/purchases/domain/services/purchase_transaction_orchestrator.dart';
import '../../features/returns/domain/services/credit_note_transaction_orchestrator.dart';
import '../../features/sales/domain/services/sale_transaction_orchestrator.dart';
import '../../features/inventory/domain/models/product.dart';
import '../../features/accounts/domain/models/contact.dart';
import '../../features/checks/domain/models/check_record.dart';

/// Centralized Service Locator for M.I.R.N POWER Management System.
/// Decoupled from third-party vendor SDKs to ensure clean dependency inversion.
class ServiceLocator {
  ServiceLocator._();
  static final ServiceLocator instance = ServiceLocator._();

  late ProductRepository productRepository;
  late ContactRepository contactRepository;
  late SaleRepository saleRepository;
  late CheckRepository checkRepository;
  late PurchaseRepository purchaseRepository;
  late DispatchRepository dispatchRepository;
  late ExpenseRepository expenseRepository;

  late SaleTransactionOrchestrator saleOrchestrator;
  late PurchaseTransactionOrchestrator purchaseOrchestrator;
  late CreditNoteTransactionOrchestrator creditNoteOrchestrator;
  late CheckLifecycleOrchestrator checkLifecycleOrchestrator;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  void initialize({
    ProductRepository? customProductRepository,
    ContactRepository? customContactRepository,
    SaleRepository? customSaleRepository,
    CheckRepository? customCheckRepository,
    PurchaseRepository? customPurchaseRepository,
    DispatchRepository? customDispatchRepository,
    ExpenseRepository? customExpenseRepository,
    List<Product>? initialProducts,
    List<Contact>? initialContacts,
    List<CheckRecord>? initialChecks,
  }) {
    productRepository = customProductRepository ??
        InMemoryProductRepository(initialProducts: initialProducts);
    contactRepository = customContactRepository ??
        InMemoryContactRepository(initialContacts: initialContacts);
    saleRepository = customSaleRepository ?? InMemorySaleRepository();
    checkRepository = customCheckRepository ??
        InMemoryCheckRepository(initialChecks: initialChecks);
    purchaseRepository = customPurchaseRepository ?? InMemoryPurchaseRepository();
    dispatchRepository = customDispatchRepository ?? InMemoryDispatchRepository();
    expenseRepository = customExpenseRepository ?? InMemoryExpenseRepository();

    saleOrchestrator = SaleTransactionOrchestrator(
      productRepository: productRepository,
      contactRepository: contactRepository,
      saleRepository: saleRepository,
      checkRepository: checkRepository,
    );

    purchaseOrchestrator = PurchaseTransactionOrchestrator(
      productRepository: productRepository,
      contactRepository: contactRepository,
      purchaseRepository: purchaseRepository,
    );

    creditNoteOrchestrator = CreditNoteTransactionOrchestrator(
      productRepository: productRepository,
      contactRepository: contactRepository,
      saleRepository: saleRepository,
    );

    checkLifecycleOrchestrator = CheckLifecycleOrchestrator(
      checkRepository: checkRepository,
      contactRepository: contactRepository,
    );

    _isInitialized = true;
  }

  void dispose() {
    if (productRepository is InMemoryProductRepository) {
      (productRepository as InMemoryProductRepository).dispose();
    }
    if (contactRepository is InMemoryContactRepository) {
      (contactRepository as InMemoryContactRepository).dispose();
    }
    if (saleRepository is InMemorySaleRepository) {
      (saleRepository as InMemorySaleRepository).dispose();
    }
    if (checkRepository is InMemoryCheckRepository) {
      (checkRepository as InMemoryCheckRepository).dispose();
    }
    if (purchaseRepository is InMemoryPurchaseRepository) {
      (purchaseRepository as InMemoryPurchaseRepository).dispose();
    }
    if (dispatchRepository is InMemoryDispatchRepository) {
      (dispatchRepository as InMemoryDispatchRepository).dispose();
    }
    if (expenseRepository is InMemoryExpenseRepository) {
      (expenseRepository as InMemoryExpenseRepository).dispose();
    }
    _isInitialized = false;
  }
}
